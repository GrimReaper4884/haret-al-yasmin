--!strict
-- Late-afternoon Damascus light (docs/ART_BIBLE.md §7): warm sun, soft haze that hides the edge of
-- the world, gentle bloom on lanterns and the oven. All effects are mobile-safe (Roblox scales them
-- down automatically on low graphics quality).

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Look = require(ReplicatedStorage:WaitForChild("Shared").Config.Lighting)

local Atmosphere = {}

local function ensure(className: string, name: string): Instance
	local existing = Lighting:FindFirstChild(name)
	if existing and existing.ClassName == className then
		return existing
	end
	local inst = Instance.new(className)
	inst.Name = name
	inst.Parent = Lighting
	return inst
end

-- The place file ships Studio's default Atmosphere, Bloom and SunRays. Two hazes or two blooms
-- stack (the night read grey), so at runtime only ours stay (PV-E01; the place file is untouched).
local OURS = { LaneHaze = true, WarmGrade = true, SoftBloom = true, SunRays = true, HaretMoments = true, NightGrade = true, LaneGrade = true }
local function dropStrays()
	for _, c in Lighting:GetChildren() do
		local effect = c:IsA("Atmosphere") or c:IsA("BloomEffect") or c:IsA("SunRaysEffect") or c:IsA("ColorCorrectionEffect")
		if effect and not OURS[c.Name] then
			c:Destroy()
		end
	end
end

function Atmosphere.apply()
	dropStrays()
	Lighting.ClockTime = 15.6
	Lighting.GeographicLatitude = 33.5
	Lighting.Brightness = 2.4
	Lighting.Ambient = Color3.fromRGB(92, 80, 70)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 135, 118)
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.35
	Lighting.ShadowSoftness = 0.35
	Lighting.GlobalShadows = true

	local atm = ensure("Atmosphere", "LaneHaze") :: Atmosphere
	atm.Density = Look.day.density
	atm.Offset = 0.15
	atm.Color = Color3.fromHex(Look.day.hazeColor)
	atm.Decay = Color3.fromHex(Look.day.hazeDecay)
	atm.Glare = 0.2
	atm.Haze = 1.4

	local cc = ensure("ColorCorrectionEffect", "WarmGrade") :: ColorCorrectionEffect
	cc.Brightness = 0.02
	cc.Contrast = 0.08
	cc.Saturation = 0.06
	cc.TintColor = Color3.fromRGB(255, 246, 232)

	local bloom = ensure("BloomEffect", "SoftBloom") :: BloomEffect
	bloom.Intensity = Look.day.bloom
	bloom.Size = Look.day.bloomSize
	bloom.Threshold = 1.6

	local rays = ensure("SunRaysEffect", "SunRays") :: SunRaysEffect
	rays.Intensity = Look.day.sunRays
	rays.Spread = 0.6

	local sky = Lighting:FindFirstChildOfClass("Sky")
	if sky then
		sky.StarCount = Look.day.stars
	end
end

return Atmosphere
