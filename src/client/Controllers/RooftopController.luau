--!strict
-- Fawza calls down from her roof (LOOK_AND_PLAY_PLAN §4.3 "Rooftop women", LP-D07): on the shared
-- clock (Logic/LobbyLife.callAt, Config/LobbyLife `rooftop`) a speech bubble over her shows one of
-- her lines for a few seconds, and she waves her broom as it starts (her attack clip, when Effects
-- allow motion). No prompt, nothing on the server; every player sees the same line at the same time.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Cfg = require(Shared.Config.LobbyLife)
local LaneZones = require(Shared.Config.LaneZones)
local LaneZoneLogic = require(Shared.Logic.LaneZoneLogic)
local LobbyLife = require(Shared.Logic.LobbyLife)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Fx = require(UI.Fx)
local LocaleController = require(script.Parent.LocaleController)
local RigAnimController = require(script.Parent.RigAnimController)

local RooftopController = {}

local HZ = 4 -- checks per second
local MAX_DISTANCE = 90 -- studs at which the bubble still shows

local gui: BillboardGui? = nil
local label: TextLabel? = nil
local shownLine: number? = nil
local wavedPeriod = -1

local function ensureBubble(): boolean
	local r = Cfg.rooftop
	local npcs = Workspace:FindFirstChild("Npcs")
	local m = npcs and npcs:FindFirstChild(r.npc)
	local root = if m and m:IsA("Model") then m.PrimaryPart else nil
	if not root then
		return false
	end
	if gui and gui.Parent == root then
		return true
	end
	local g = Create("BillboardGui", {
		Name = "RoofCall",
		Adornee = root,
		Size = UDim2.fromOffset(240, 64),
		StudsOffset = Vector3.new(0, root.Size.Y / 2 + 3.4, 0),
		MaxDistance = MAX_DISTANCE,
		AlwaysOnTop = false, -- a call from a roof hides behind the walls like the roof does
		LightInfluence = 0,
		Enabled = false,
		Parent = root,
	}) :: BillboardGui
	local panel = Create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.colors.panel,
		BackgroundTransparency = 0.05,
		Parent = g,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = panel })
	Create("UIStroke", { Color = Theme.colors.panelStroke, Thickness = 2, Parent = panel })
	Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = panel })
	label = Theme.label({
		Size = UDim2.fromScale(1, 1),
		TextSize = 15,
		TextWrapped = true,
		Parent = panel,
	})
	gui = g
	return true
end

local acc = 0
local function step(dt: number)
	acc += dt
	if acc < 1 / HZ then
		return
	end
	acc = 0
	if not ensureBubble() then
		return
	end
	local r = Cfg.rooftop
	local now = Workspace:GetServerTimeNow()
	local idx, wave = LobbyLife.callAt(now, r.every, r.show, #r.lines, r.offset, r.wave)
	local g, l = gui :: BillboardGui, label :: TextLabel
	if idx ~= shownLine then
		shownLine = idx
		if idx then
			l.Text = LocaleController.t(r.lines[idx])
			l.TextXAlignment = if LocaleController.isRtl() then Enum.TextXAlignment.Right else Enum.TextXAlignment.Left
		end
		g.Enabled = idx ~= nil
	end
	local period = math.floor((now - r.offset) / r.every)
	if wave and period ~= wavedPeriod and LobbyLife.tier(Fx.laneLife()).motion then
		if RigAnimController.npcPlay(r.npc, "attack") then
			wavedPeriod = period
		end
	end
end

function RooftopController.start()
	if not LaneZoneLogic.built(LaneZones.zones, "rooftop_view") then
		return
	end
	RunService.Heartbeat:Connect(step)
	LocaleController.Changed:Connect(function()
		shownLine = nil -- redraw the line in the new language on the next check
	end)
end

return RooftopController
