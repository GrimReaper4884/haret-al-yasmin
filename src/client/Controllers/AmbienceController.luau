--!strict
-- Client-only life in the world (POLISH_PLAN workstream E). PV-E01: lanterns near the camera
-- flicker gently (Logic/Flicker, Config/Lighting). Each light keeps its built brightness as
-- "BaseBrightness" and may carry a "Boost" multiplier (the final-wave glow, MatchFxController).
-- Effects below "full" hold every lantern steady at its base.
-- PV-E03: the arenas' night road haze (emitters tagged "AmbientHaze", built disabled by
-- World/Arena) runs only at Effects full and within ArenaThemes.haze.radius of the camera.

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Look = require(Shared.Config.Lighting)
local ArenaThemes = require(Shared.Config.ArenaThemes)
local Flicker = require(Shared.Logic.Flicker)
local Fx = require(script.Parent.Parent.UI.Fx)

local AmbienceController = {}

local lights: { [Light]: number } = {} -- light -> seed
local hazes: { [ParticleEmitter]: boolean } = {}

local function track(d: Instance)
	if d:IsA("ParticleEmitter") and d:GetAttribute("AmbientHaze") then
		hazes[d] = true
		return
	end
	if (d:IsA("PointLight") or d:IsA("SpotLight")) and lights[d] == nil then
		if d:GetAttribute("BaseBrightness") == nil then
			d:SetAttribute("BaseBrightness", d.Brightness)
		end
		lights[d] = math.random() * 100
	end
end

local function base(l: Light): number
	local b = l:GetAttribute("BaseBrightness")
	local boost = l:GetAttribute("Boost")
	return (if type(b) == "number" then b else l.Brightness) * (if type(boost) == "number" then boost else 1)
end

-- Lights currently flickering (debug / tests).
function AmbienceController.active(): number
	local n = 0
	for l in lights do
		if l:GetAttribute("Flickering") then
			n += 1
		end
	end
	return n
end

function AmbienceController.start()
	for _, d in Workspace:GetDescendants() do
		track(d)
	end
	Workspace.DescendantAdded:Connect(track)
	Workspace.DescendantRemoving:Connect(function(d: Instance)
		if d:IsA("Light") then
			lights[d] = nil
		elseif d:IsA("ParticleEmitter") then
			hazes[d] = nil
		end
	end)
	local f = Look.flicker
	local acc = 0
	RunService.Heartbeat:Connect(function(dt: number)
		acc += dt
		if acc < 1 / f.hz then
			return
		end
		acc = 0
		local camera = Workspace.CurrentCamera
		local cam = if camera then camera.CFrame.Position else Vector3.zero
		local now = os.clock()
		local full = Fx.full()
		local hazeR = ArenaThemes.haze.radius
		for e in hazes do
			local p = e.Parent
			local on = full and p ~= nil and p:IsA("BasePart") and (p.Position - cam).Magnitude <= hazeR
			if e.Enabled ~= on then
				e.Enabled = on
			end
		end
		local n = 0
		for l, seed in lights do
			local parent = l.Parent
			local near = false
			if full and n < f.maxLights and parent and parent:IsA("BasePart") then
				near = (parent.Position - cam).Magnitude <= f.radius
			end
			if near then
				n += 1
				l.Brightness = base(l) * Flicker.value(now, seed, f.min, f.max)
				l:SetAttribute("Flickering", true)
			elseif l:GetAttribute("Flickering") or l:GetAttribute("Boost") ~= nil then
				l.Brightness = base(l)
				l:SetAttribute("Flickering", nil)
			end
		end
	end)
end

return AmbienceController
