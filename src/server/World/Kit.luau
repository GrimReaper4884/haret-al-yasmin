--!strict
-- Primitive-building helpers shared by the world modules. Everything is anchored; small parts
-- don't cast shadows (cheaper on mobile).

local Kit = {}

Kit.M = Enum.Material
Kit.CYL_UP = CFrame.Angles(0, 0, math.rad(90)) -- Part cylinders run along X; this stands them up

export type PartProps = {
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?,
	shape: Enum.PartType?,
	name: string?,
	collide: boolean?,
	transparency: number?,
	shadow: boolean?,
}

function Kit.part(parent: Instance, p: PartProps): Part
	local x = Instance.new("Part")
	x.Anchored = true
	x.Size = p.size
	x.CFrame = p.cf
	x.Color = p.color
	x.Material = p.material or Enum.Material.Limestone
	x.Shape = p.shape or Enum.PartType.Block
	x.Name = p.name or "Part"
	x.CanCollide = if p.collide == nil then true else p.collide
	x.Transparency = p.transparency or 0
	x.TopSurface = Enum.SurfaceType.Smooth
	x.BottomSurface = Enum.SurfaceType.Smooth
	x.CastShadow = if p.shadow == nil then x.Size.Magnitude > 4 else p.shadow
	if not x.CanCollide then
		x.CanQuery = false
		x.CanTouch = false
	end
	x.Parent = parent
	return x
end

-- Axis-aligned box from two corners.
function Kit.box(parent: Instance, name: string, x0: number, y0: number, z0: number, x1: number, y1: number, z1: number, color: Color3, material: Enum.Material?): Part
	return Kit.part(parent, {
		name = name,
		size = Vector3.new(math.abs(x1 - x0), math.abs(y1 - y0), math.abs(z1 - z0)),
		cf = CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2),
		color = color,
		material = material,
	})
end

function Kit.model(parent: Instance, name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

-- Vertical cylinder standing on `base` (bottom centre).
function Kit.column(parent: Instance, name: string, base: Vector3, height: number, diameter: number, color: Color3, material: Enum.Material?, collide: boolean?): Part
	return Kit.part(parent, {
		name = name,
		size = Vector3.new(height, diameter, diameter),
		cf = CFrame.new(base + Vector3.new(0, height / 2, 0)) * Kit.CYL_UP,
		color = color,
		material = material,
		shape = Enum.PartType.Cylinder,
		collide = collide,
	})
end

-- Flat disc lying on the ground / a surface (centre `pos`).
function Kit.disc(parent: Instance, name: string, pos: Vector3, diameter: number, thickness: number, color: Color3, material: Enum.Material?, collide: boolean?): Part
	return Kit.part(parent, {
		name = name,
		size = Vector3.new(thickness, diameter, diameter),
		cf = CFrame.new(pos) * Kit.CYL_UP,
		color = color,
		material = material,
		shape = Enum.PartType.Cylinder,
		collide = collide,
	})
end

function Kit.ball(parent: Instance, name: string, pos: Vector3, diameter: number, color: Color3, material: Enum.Material?, collide: boolean?): Part
	return Kit.part(parent, {
		name = name,
		size = Vector3.one * diameter,
		cf = CFrame.new(pos),
		color = color,
		material = material,
		shape = Enum.PartType.Ball,
		collide = collide,
	})
end

function Kit.wedge(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): WedgePart
	local w = Instance.new("WedgePart")
	w.Name = name
	w.Anchored = true
	w.Size = size
	w.CFrame = cf
	w.Color = color
	w.Material = material or Enum.Material.Limestone
	w.CastShadow = size.Magnitude > 4
	w.Parent = parent
	return w
end

-- A frame on a façade: origin at `pos`, LookVector = outward normal, RightVector along the wall.
function Kit.faceFrame(pos: Vector3, outward: Vector3): CFrame
	local right = outward:Cross(Vector3.yAxis)
	return CFrame.fromMatrix(pos, right, Vector3.yAxis)
end

-- Deterministic variety: the same seed always gives the same "random" building.
function Kit.rng(seed: string): Random
	local h = 5381
	for i = 1, #seed do
		h = (h * 33 + string.byte(seed, i)) % 2147483647
	end
	return Random.new(h)
end

-- Slightly vary a colour's brightness (amount 0..1).
function Kit.tint(c: Color3, rng: Random, amount: number): Color3
	local h, s, v = c:ToHSV()
	return Color3.fromHSV(h, s, math.clamp(v * (1 + rng:NextNumber(-amount, amount)), 0, 1))
end

return Kit
