--!strict
-- Late-afternoon Damascus light (docs/ART_BIBLE.md §7): warm sun, soft haze that hides the edge of
-- the world, gentle bloom on lanterns and the oven. All effects are mobile-safe (Roblox scales them
-- down automatically on low graphics quality).

local Lighting = game:GetService("Lighting")

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

function Atmosphere.apply()
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
	atm.Density = 0.32
	atm.Offset = 0.15
	atm.Color = Color3.fromRGB(222, 200, 170)
	atm.Decay = Color3.fromRGB(150, 120, 100)
	atm.Glare = 0.2
	atm.Haze = 1.4

	local cc = ensure("ColorCorrectionEffect", "WarmGrade") :: ColorCorrectionEffect
	cc.Brightness = 0.02
	cc.Contrast = 0.08
	cc.Saturation = 0.06
	cc.TintColor = Color3.fromRGB(255, 246, 232)

	local bloom = ensure("BloomEffect", "SoftBloom") :: BloomEffect
	bloom.Intensity = 0.35
	bloom.Size = 22
	bloom.Threshold = 1.6

	local rays = ensure("SunRaysEffect", "SunRays") :: SunRaysEffect
	rays.Intensity = 0.04
	rays.Spread = 0.6
end

return Atmosphere
