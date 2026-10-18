--!strict
-- Haptics (MOBILE_HUD_PLAN B8): one shared UIClick and one UINotification HapticEffect under
-- HaretHud. Every Theme button plays the click on press (GuiButton.PressHapticEffect, so Place,
-- Upgrade, Sell, Summon and Claim all buzz); actions without a button press of their own (a quick
-- place ground tap, each repeat of a held Upgrade) call `click`, and a gate hit calls `notify`.
-- All of it follows the sfx setting (SettingsController calls `setEnabled`) and is inert where the
-- device has no haptic motor (desktop).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hud = require(ReplicatedStorage:WaitForChild("Shared").Config.Hud)
local Root = require(script.Parent.Root)

local Haptics = {}

local enabled = true
local effects: { [string]: HapticEffect } = {}
-- Not weak-keyed: an Instance's Lua proxy can be collected while the Instance lives, which would drop
-- live buttons; entries leave on Destroying instead.
local bound: { [GuiButton]: boolean } = {}
local lastNotify = -math.huge

local function effect(name: string, kind: Enum.HapticEffectType): HapticEffect
	local h = effects[name]
	if h and h.Parent then
		return h
	end
	local made = Instance.new("HapticEffect")
	made.Name = name
	made.Type = kind
	made.Parent = Root.get()
	effects[name] = made
	return made
end

local function clickEffect(): HapticEffect
	return effect("UIClickHaptic", Enum.HapticEffectType.UIClick)
end

local function applyPress(b: GuiButton)
	-- PressHapticEffect is typed non-optional, but nil is how a button stops buzzing.
	(b :: any).PressHapticEffect = if enabled then clickEffect() else nil
end

-- A button that buzzes on press while haptics are on.
function Haptics.bind(b: GuiButton)
	bound[b] = true
	applyPress(b)
	b.Destroying:Connect(function()
		bound[b] = nil
	end)
end

function Haptics.click()
	if not enabled then
		return
	end
	pcall(function()
		clickEffect():Play()
	end)
end

-- The gate was hit (at most one buzz per Hud.HAPTICS.notifyGapS, whatever the wave sends).
function Haptics.notify()
	local now = os.clock()
	if not enabled or now - lastNotify < Hud.HAPTICS.notifyGapS then
		return
	end
	lastNotify = now
	pcall(function()
		effect("UINotificationHaptic", Enum.HapticEffectType.UINotification):Play()
	end)
end

function Haptics.setEnabled(on: boolean)
	if on == enabled then
		return
	end
	enabled = on
	for b in bound do
		applyPress(b)
	end
end

function Haptics.isEnabled(): boolean
	return enabled
end

return Haptics
