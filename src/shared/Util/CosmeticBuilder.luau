--!strict
-- Builds a cosmetic (Config/CosmeticVisuals spec) onto any rig: a player's character (welded,
-- server) or the tailor's mannequin in a ViewportFrame (anchored, client previews). One algorithm,
-- so the 3D preview always matches what other players will see.

local CosmeticVisuals = require(script.Parent.Parent.Config.CosmeticVisuals)

local CosmeticBuilder = {}

-- R6 rigs have fewer, bigger parts; clothes for R15 parts map onto them.
CosmeticBuilder.R6_MAP = {
	UpperTorso = "Torso",
	LowerTorso = "Torso",
	LeftUpperLeg = "Left Leg",
	LeftLowerLeg = "Left Leg",
	RightUpperLeg = "Right Leg",
	RightLowerLeg = "Right Leg",
	LeftUpperArm = "Left Arm",
	RightUpperArm = "Right Arm",
} :: { [string]: string }

local function bodyPart(rig: Instance, name: string): BasePart?
	local p = rig:FindFirstChild(name) or rig:FindFirstChild(CosmeticBuilder.R6_MAP[name] or "")
	return if p and p:IsA("BasePart") then p else nil
end

-- Returns a Model holding the cosmetic's parts, or nil for an unknown visual id.
-- weld = true: unanchored, massless, welded to the body (characters).
-- weld = false: anchored (static previews).
function CosmeticBuilder.build(rig: Instance, visualId: string, name: string, weld: boolean): Model?
	local spec = CosmeticVisuals[visualId]
	if not spec then
		return nil
	end
	local holder = Instance.new("Model")
	holder.Name = name
	for _, p in spec do
		local attachName = p.attach or "HeadTop"
		local base = bodyPart(rig, if attachName == "HeadTop" then "Head" else attachName)
		if base then
			local x = Instance.new("Part")
			x.Name = p.name
			x.Shape = p.shape
			x.Color = p.color
			x.Material = p.material
			if attachName == "HeadTop" then
				x.Size = p.size or Vector3.one
				x.CFrame = base.CFrame * CFrame.new(0, base.Size.Y / 2, 0) * (p.offset or CFrame.identity)
			else
				x.Size = base.Size * (p.fit or Vector3.one) + (p.pad or Vector3.zero)
				local rot = p.rot or Vector3.zero
				x.CFrame = base.CFrame
					* CFrame.new((p.at or Vector3.zero) * base.Size)
					* CFrame.Angles(math.rad(rot.X), math.rad(rot.Y), math.rad(rot.Z))
			end
			x.CanCollide = false
			x.CanQuery = false
			x.CanTouch = false
			x.CastShadow = false
			x.TopSurface = Enum.SurfaceType.Smooth
			x.BottomSurface = Enum.SurfaceType.Smooth
			if weld then
				x.Anchored = false
				x.Massless = true
				local w = Instance.new("WeldConstraint")
				w.Part0 = base
				w.Part1 = x
				w.Parent = x
			else
				x.Anchored = true
			end
			x.Parent = holder
		end
	end
	holder.Parent = rig
	return holder
end

return CosmeticBuilder
