--!strict
-- The client's layout profile and UIScale (docs/MOBILE_HUD_PLAN.md B1). Reads the engine's device
-- signals (UserInputService.PreferredInput, GuiService.ViewportDisplaySize, the HaretHud safe-area
-- size, GuiService.TopbarInset and TouchControlsEnabled, Roblox's jump button) and the player's
-- `uiScale` preset, feeds them to Logic/HudLayout and writes the single UIScale in UI/Root.
-- Controllers read Device.profile() / scale() / reserved() and re-lay out on Device.Changed, which
-- fires at most once a frame and only when something they use moved.
--
-- Studio only: the Workspace attribute `DebugHudProfile` ("touch-phone", "touch-tablet", "desktop")
-- pins the profile, because the harness keys flip PreferredInput to KeyboardAndMouse in the Device
-- Simulator (TEST_REPORT_SLICE "MH baseline").

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Hud = require(Shared.Config.Hud)
local TD = require(Shared.Config.TD)
local HudLayout = require(Shared.Logic.HudLayout)
local Signal = require(Shared.Util.Signal)
local Root = require(script.Parent.Root)

local Device = {}

Device.Changed = Signal.new()

local PROFILES = { ["touch-phone"] = true, ["touch-tablet"] = true, desktop = true }

local current = {
	profile = "desktop" :: HudLayout.Profile,
	scale = 1,
	safe = { x = 0, y = 0 } :: HudLayout.Size,
	touchControls = true,
	reserved = {} :: HudLayout.Reserved,
	fingerprint = "",
}
local preset = "default"
local slotCount = TD.LOADOUT_SLOTS
-- While a defender is aimed on touch the thumbstick and jump hide (B3); the layout keeps the corners
-- they had so the hotbar does not jump, and Place / Cancel take those corners.
local aimHold = false
local lastJump: HudLayout.Rect? = nil
-- Who wants Roblox's thumbstick and jump hidden right now ("overhead", "aim", "sheet", "panel"); they show
-- only when nobody does. A sheet keeps the corners reserved, like aiming, so nothing moves under it.
local blocks: { [string]: true } = {}
local started = false
local queued = false
local jumpConns: { RBXScriptConnection } = {}

local function rectOf(gui: GuiObject, origin: Vector2): HudLayout.Rect
	local p = gui.AbsolutePosition - origin
	local s = gui.AbsoluteSize
	return { x0 = p.X, y0 = p.Y, x1 = p.X + s.X, y1 = p.Y + s.Y }
end

local function jumpButton(): GuiObject?
	local pg = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local touchGui = pg and pg:FindFirstChild("TouchGui")
	local frame = touchGui and touchGui:FindFirstChild("TouchControlFrame")
	local jump = frame and frame:FindFirstChild("JumpButton")
	if jump and jump:IsA("GuiObject") then
		return jump
	end
	return nil
end

local function forcedProfile(): HudLayout.Profile?
	if not RunService:IsStudio() then
		return nil
	end
	local v = Workspace:GetAttribute("DebugHudProfile")
	if type(v) == "string" and PROFILES[v] then
		return v :: any
	end
	return nil
end

local function recompute()
	queued = false
	local gui = Root.get()
	local abs = gui.AbsoluteSize
	if abs.X <= 0 or abs.Y <= 0 then
		return
	end
	local safe = { x = abs.X, y = abs.Y }
	-- (cast: the solver widens the module's string-literal union across the require)
	local profile: HudLayout.Profile = forcedProfile()
		or HudLayout.profile(Hud, {
			preferredInput = UserInputService.PreferredInput.Name,
			displaySize = GuiService.ViewportDisplaySize.Name,
			safeSize = safe,
		}) :: any
	local scale = HudLayout.scale(Hud, profile, safe, preset, slotCount)
	-- Until every screen fits a 282 px canvas (MH-13/14), keep at least the canvas the old layouts were
	-- fitted to; see Config/Hud SCALE.legacyCanvas.
	local legacy = Hud.SCALE.legacyCanvas
	if legacy then
		scale = math.min(scale, safe.x / legacy[1], safe.y / legacy[2])
	end
	local hold = aimHold or blocks.sheet == true or blocks.panel == true
	local touchControls = GuiService.TouchControlsEnabled or hold
	local measured: HudLayout.Measured = {}
	local jump = jumpButton()
	if jump and jump.Visible and jump.AbsoluteSize.X > 0 and GuiService.TouchControlsEnabled then
		measured.jump = rectOf(jump, gui.AbsolutePosition)
		lastJump = measured.jump
	elseif hold then
		measured.jump = lastJump
	end
	local reserved = HudLayout.reserved(Hud, profile, touchControls, safe, measured)
	local function r(rect: HudLayout.Rect?): string
		return if rect then string.format("%d,%d,%d,%d", rect.x0, rect.y0, rect.x1, rect.y1) else "-"
	end
	local fingerprint = string.format("%s|%.4f|%dx%d|%s|%s", profile, scale, safe.x, safe.y, r(reserved.left), r(reserved.right))
	current.safe = safe
	current.touchControls = touchControls
	if fingerprint == current.fingerprint then
		return
	end
	local profileChanged = profile ~= current.profile
	current.profile = profile
	current.scale = scale
	current.reserved = reserved
	current.fingerprint = fingerprint
	local ui = gui:FindFirstChildOfClass("UIScale")
	if ui then
		ui.Scale = scale
	end
	Device.Changed:Fire(profileChanged)
end

-- Debounced to one recompute per frame, however many signals fire.
local function schedule()
	if queued or not started then
		return
	end
	queued = true
	task.defer(recompute)
end

local function watchJump()
	for _, c in jumpConns do
		c:Disconnect()
	end
	table.clear(jumpConns)
	local jump = jumpButton()
	if jump then
		table.insert(jumpConns, jump:GetPropertyChangedSignal("AbsolutePosition"):Connect(schedule))
		table.insert(jumpConns, jump:GetPropertyChangedSignal("AbsoluteSize"):Connect(schedule))
		table.insert(jumpConns, jump:GetPropertyChangedSignal("Visible"):Connect(schedule))
	end
	schedule()
end

function Device.profile(): HudLayout.Profile
	return current.profile
end

function Device.isTouch(): boolean
	return HudLayout.isTouch(current.profile)
end

function Device.isPhone(): boolean
	return current.profile == "touch-phone"
end

function Device.scale(): number
	return current.scale
end

-- The safe area in screen px, and in design px (what offsets under the UIScale span).
function Device.safeSize(): HudLayout.Size
	return current.safe
end

function Device.designSize(): HudLayout.Size
	return { x = current.safe.x / current.scale, y = current.safe.y / current.scale }
end

-- Roblox's thumbstick / jump corners in screen px ({} on desktop or while the touch controls hide).
function Device.reserved(): HudLayout.Reserved
	return current.reserved
end

-- The bottom band clear of both corners, in screen px.
function Device.freeBand(): { x0: number, x1: number }
	return HudLayout.freeBand(current.safe, current.reserved)
end

-- The player's Settings `uiScale` preset (SettingsController) and the loadout size (Extra Slot pass).
function Device.setPreset(p: string)
	if Hud.SCALE.presets[p] and p ~= preset then
		preset = p
		schedule()
	end
end

-- Hides Roblox's touch controls while any reason holds (the watchtower view, aiming, an open sheet).
function Device.blockTouchControls(reason: string, on: boolean)
	if on then
		blocks[reason] = true
	else
		blocks[reason] = nil
	end
	GuiService.TouchControlsEnabled = next(blocks) == nil
	schedule()
end

-- PlacementController holds the corners while it aims on touch (see aimHold).
function Device.setAimHold(on: boolean)
	if aimHold ~= on then
		aimHold = on
		schedule()
	end
end

function Device.setSlotCount(n: number)
	if n ~= slotCount and n >= 1 then
		slotCount = n
		schedule()
	end
end

function Device.start()
	if started then
		return
	end
	started = true
	local gui = Root.get()
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(schedule)
	UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(schedule)
	GuiService:GetPropertyChangedSignal("ViewportDisplaySize"):Connect(schedule)
	GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(schedule)
	GuiService:GetPropertyChangedSignal("TouchControlsEnabled"):Connect(schedule)
	Workspace:GetAttributeChangedSignal("DebugHudProfile"):Connect(schedule)
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	pg.DescendantAdded:Connect(function(d: Instance)
		if d.Name == "JumpButton" or d.Name == "TouchGui" or d.Name == "TouchControlFrame" then
			task.defer(watchJump)
		end
	end)
	watchJump()
	recompute()
end

return Device
