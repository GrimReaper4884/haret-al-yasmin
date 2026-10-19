--!strict
-- The lane clock (LOOK_AND_PLAY_PLAN §4.3, LP-D09): dawn, day, evening and night over a 12-minute
-- cycle on the server's clock (Logic/LobbyLife.clock, Config/LobbyLife.CLOCK), so every player sees
-- the same light. In the lobby this eases Lighting (clock time, brightness, ambients), the lane haze,
-- a colour grade and the lobby lanterns toward the current phase's look (Config/Lighting `lane`),
-- fading over `fade` s at each boundary. It steps aside in a match (MatchFxController owns the light
-- there; the rest goes back to the day look) and with Lane life "off" holds the day look. Client only; nothing on the server.
--
-- Studio harness: a number in the LocalPlayer attribute "HarnessClockOffset" shifts the clock by that
-- many seconds (captures of each phase without waiting), Studio only.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Cfg = require(Shared.Config.LobbyLife)
local Look = require(Shared.Config.Lighting)
local LobbyLife = require(Shared.Logic.LobbyLife)
local Fx = require(script.Parent.Parent.UI.Fx)
local MatchController = require(script.Parent.MatchController)

local LaneClockController = {}

local HZ = 10 -- light updates per second
local EASE = 1.6 -- per second: how fast the drawn light follows its target (smooths a resume after a match)

type Mix = {
	clockTime: number,
	brightness: number,
	ambient: Color3,
	outdoor: Color3,
	density: number,
	hazeColor: Color3,
	hazeDecay: Color3,
	tint: Color3,
	contrast: number,
	lanterns: number,
}

local function rgb(t: { number }): Color3
	return Color3.fromRGB(t[1], t[2], t[3])
end

local function look(id: string): Mix
	local l = (Look.lane :: any)[id] or Look.lane.day
	return {
		clockTime = l.clockTime,
		brightness = l.brightness,
		ambient = rgb(l.ambient),
		outdoor = rgb(l.outdoor),
		density = l.density,
		hazeColor = Color3.fromHex(l.hazeColor),
		hazeDecay = Color3.fromHex(l.hazeDecay),
		tint = Color3.fromHex(l.tint),
		contrast = l.contrast,
		lanterns = l.lanterns,
	}
end

local function lerp(a: number, b: number, k: number): number
	return a + (b - a) * k
end

-- Clock time wraps at 24: blend the short way round (20.6 -> 6.4 goes through midnight).
local function lerpClock(a: number, b: number, k: number): number
	local d = (b - a) % 24
	if d > 12 then
		d -= 24
	end
	return (a + d * k) % 24
end

local function mix(a: Mix, b: Mix, k: number): Mix
	return {
		clockTime = lerpClock(a.clockTime, b.clockTime, k),
		brightness = lerp(a.brightness, b.brightness, k),
		ambient = a.ambient:Lerp(b.ambient, k),
		outdoor = a.outdoor:Lerp(b.outdoor, k),
		density = lerp(a.density, b.density, k),
		hazeColor = a.hazeColor:Lerp(b.hazeColor, k),
		hazeDecay = a.hazeDecay:Lerp(b.hazeDecay, k),
		tint = a.tint:Lerp(b.tint, k),
		contrast = lerp(a.contrast, b.contrast, k),
		lanterns = lerp(a.lanterns, b.lanterns, k),
	}
end

local function now(): number
	local t = Workspace:GetServerTimeNow()
	if RunService:IsStudio() then
		local off = Players.LocalPlayer:GetAttribute("HarnessClockOffset")
		if type(off) == "number" then
			t += off
		end
	end
	return t
end

-- The light the lane should show right now.
function LaneClockController.target(): (Mix, string)
	if Fx.laneLife() == "off" then
		return look("day"), "day"
	end
	local from, to, k = LobbyLife.lightBlend(now(), Cfg.CLOCK)
	return mix(look(from), look(to), k), (LobbyLife.clock(now(), Cfg.CLOCK))
end

-- The phase id at this moment (for beats and probes).
function LaneClockController.phase(): string
	return (select(2, LaneClockController.target()))
end

local drawn: Mix? = nil
local lanterns: { [Light]: boolean } = {}

local function grade(): ColorCorrectionEffect
	local g = Lighting:FindFirstChild("LaneGrade")
	if g and g:IsA("ColorCorrectionEffect") then
		return g
	end
	local n = Instance.new("ColorCorrectionEffect")
	n.Name = "LaneGrade"
	n.Parent = Lighting
	return n
end

local function apply(m: Mix)
	Lighting.ClockTime = m.clockTime
	Lighting.Brightness = m.brightness
	Lighting.Ambient = m.ambient
	Lighting.OutdoorAmbient = m.outdoor
	local haze = Lighting:FindFirstChild("LaneHaze")
	if haze and haze:IsA("Atmosphere") then
		haze.Density = m.density
		haze.Color = m.hazeColor
		haze.Decay = m.hazeDecay
	end
	local g = grade()
	g.TintColor = m.tint
	g.Contrast = m.contrast
	for l in lanterns do
		if l.Parent then
			l:SetAttribute("Boost", m.lanterns) -- AmbienceController multiplies its flicker by this
		else
			lanterns[l] = nil
		end
	end
end

local function track(d: Instance)
	if d:IsA("PointLight") or d:IsA("SpotLight") then
		lanterns[d :: Light] = true
		if drawn then
			d:SetAttribute("Boost", drawn.lanterns)
		end
	end
end

local acc = 0
local function step(dt: number)
	acc += dt
	if acc < 1 / HZ then
		return
	end
	local span = acc
	acc = 0
	if MatchController.state() then
		drawn = nil -- the match owns the light; ease back in from whatever it leaves
		return
	end
	local target = LaneClockController.target()
	local cur = drawn
	if not cur then
		cur = {
			clockTime = Lighting.ClockTime,
			brightness = Lighting.Brightness,
			ambient = Lighting.Ambient,
			outdoor = Lighting.OutdoorAmbient,
			density = target.density,
			hazeColor = target.hazeColor,
			hazeDecay = target.hazeDecay,
			tint = target.tint,
			contrast = target.contrast,
			lanterns = target.lanterns,
		}
	end
	local nxt = mix(cur :: Mix, target, math.min(1, span * EASE))
	drawn = nxt
	apply(nxt)
end

-- A match keeps the look it always had: MatchFxController takes clock time, brightness and haze from
-- here, and the ambients, the lane grade and the lanterns go back to the day look until it ends.
local function handOver()
	drawn = nil
	local d = look("day")
	Lighting.Ambient = d.ambient
	Lighting.OutdoorAmbient = d.outdoor
	local g = grade()
	g.TintColor = d.tint
	g.Contrast = d.contrast
	for l in lanterns do
		if l.Parent then
			l:SetAttribute("Boost", nil)
		end
	end
end

function LaneClockController.start()
	MatchController.Started:Connect(handOver)
	task.spawn(function()
		local map = Workspace:WaitForChild("Map", 60)
		if not map then
			return
		end
		for _, d in map:GetDescendants() do
			track(d)
		end
		map.DescendantAdded:Connect(track)
	end)
	RunService.Heartbeat:Connect(step)
end

return LaneClockController
