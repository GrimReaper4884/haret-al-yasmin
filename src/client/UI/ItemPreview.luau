--!strict
-- 3D item previews: a tailor's dummy (standard R15 proportions) inside a ViewportFrame, dressed with
-- the real cosmetic via CosmeticBuilder, so the preview matches what other players see.
-- Non-cosmetics fall back to the flat drawn icon (UI/Icons).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared.Config.Items)
local Palette = require(Shared.Config.Palette)
local CosmeticBuilder = require(Shared.Util.CosmeticBuilder)
local Create = require(script.Parent.Create)
local Icons = require(script.Parent.Icons)

local ItemPreview = {}

-- name, size, center (feet at y = 0, facing -Z)
local DUMMY: { { any } } = {
	{ "LeftFoot", Vector3.new(1, 0.3, 1), Vector3.new(-0.5, 0.15, 0) },
	{ "RightFoot", Vector3.new(1, 0.3, 1), Vector3.new(0.5, 0.15, 0) },
	{ "LeftLowerLeg", Vector3.new(1, 1.2, 1), Vector3.new(-0.5, 0.9, 0) },
	{ "RightLowerLeg", Vector3.new(1, 1.2, 1), Vector3.new(0.5, 0.9, 0) },
	{ "LeftUpperLeg", Vector3.new(1, 1.2, 1), Vector3.new(-0.5, 2.1, 0) },
	{ "RightUpperLeg", Vector3.new(1, 1.2, 1), Vector3.new(0.5, 2.1, 0) },
	{ "LowerTorso", Vector3.new(2, 0.4, 1), Vector3.new(0, 2.9, 0) },
	{ "UpperTorso", Vector3.new(2, 1.6, 1), Vector3.new(0, 3.9, 0) },
	{ "LeftUpperArm", Vector3.new(1, 1.2, 1), Vector3.new(-1.5, 4.1, 0) },
	{ "RightUpperArm", Vector3.new(1, 1.2, 1), Vector3.new(1.5, 4.1, 0) },
	{ "LeftLowerArm", Vector3.new(1, 1.1, 1), Vector3.new(-1.5, 2.95, 0) },
	{ "RightLowerArm", Vector3.new(1, 1.1, 1), Vector3.new(1.5, 2.95, 0) },
	{ "Head", Vector3.new(1.2, 1.2, 1.2), Vector3.new(0, 5.3, 0) },
}

-- Camera framing per slot: look-at height, distance, yaw (degrees; 0 = front).
local FRAMING: { [string]: { y: number, dist: number, yaw: number } } = {
	head = { y = 5.6, dist = 4.2, yaw = 25 },
	torso = { y = 3.2, dist = 9, yaw = 25 },
	legs = { y = 2.0, dist = 7.5, yaw = 25 },
	waist = { y = 3.0, dist = 6.5, yaw = 30 },
	back = { y = 3.4, dist = 8.5, yaw = 150 },
}

local function buildDummy(parent: Instance): Model
	local rig = Instance.new("Model")
	rig.Name = "Dummy"
	for _, d in DUMMY do
		local p = Instance.new("Part")
		p.Name = d[1]
		p.Size = d[2]
		p.CFrame = CFrame.new(d[3])
		p.Anchored = true
		p.Color = Palette.plaster
		p.Material = Enum.Material.SmoothPlastic
		p.Shape = if d[1] == "Head" then Enum.PartType.Ball else Enum.PartType.Block
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = rig
	end
	-- Wooden stand under the dummy
	local stand = Instance.new("Part")
	stand.Name = "Stand"
	stand.Shape = Enum.PartType.Cylinder
	stand.Size = Vector3.new(0.3, 3, 3)
	stand.CFrame = CFrame.new(0, -0.15, 0) * CFrame.Angles(0, 0, math.rad(90))
	stand.Anchored = true
	stand.Color = Palette.woodDark
	stand.Material = Enum.Material.Wood
	stand.Parent = rig
	rig.Parent = parent
	return rig
end

-- Creates a preview for `itemId`. Returns the frame (ViewportFrame for cosmetics, Frame otherwise).
-- spin = true slowly rotates the camera (use for one focused preview, not for long lists).
function ItemPreview.create(itemId: string, props: { [string]: any }, spin: boolean?): GuiObject
	local def = (Items :: any)[itemId]
	if not def or def.kind ~= "cosmetic" then
		local holder = Create("Frame", props)
		holder.BackgroundTransparency = 1
		if def then
			Icons.draw(def.icon, holder, def.iconColor)
		end
		return holder
	end

	local vp = Create("ViewportFrame", props)
	vp.BackgroundColor3 = Palette.stoneWarm
	vp.BackgroundTransparency = 0.35
	vp.Ambient = Color3.fromRGB(170, 160, 150)
	vp.LightColor = Color3.fromRGB(255, 240, 220)
	vp.LightDirection = Vector3.new(-0.6, -1, -0.8)
	Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = vp })

	local dummy = buildDummy(vp)
	CosmeticBuilder.build(dummy, itemId, "Item", false)

	local camera = Instance.new("Camera")
	camera.FieldOfView = 40
	camera.Parent = vp
	vp.CurrentCamera = camera

	local f = FRAMING[def.slot or "torso"] or FRAMING.torso
	local function place(yawDeg: number)
		local yaw = math.rad(yawDeg)
		local target = Vector3.new(0, f.y, 0)
		local eye = target + Vector3.new(math.sin(yaw) * f.dist, f.dist * 0.18, -math.cos(yaw) * f.dist)
		camera.CFrame = CFrame.lookAt(eye, target)
	end
	place(f.yaw)

	if spin then
		local yaw = f.yaw
		local conn: RBXScriptConnection
		conn = RunService.RenderStepped:Connect(function(dt: number)
			if not vp.Parent then
				conn:Disconnect()
				return
			end
			yaw += dt * 40
			place(yaw)
		end)
	end
	return vp
end

return ItemPreview
