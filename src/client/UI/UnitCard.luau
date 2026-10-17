--!strict
-- A defender card: 3D preview of the unit's rig in a ViewportFrame, rarity-coloured frame, name
-- and stars. Used by the summon reveal, the collection, the loadout bar and the match unit bar.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Units = require(Shared.Config.Units)
local Enemies = require(Shared.Config.Enemies)
local Palette = require(Shared.Config.Palette)
local RigBuilder = require(Shared.Util.RigBuilder)
local Looks = require(Shared.Config.CharacterLooks)
local BoneAnim = require(Shared.Anim.BoneAnim)
local Create = require(script.Parent.Create)
local Theme = require(script.Parent.Theme)
local Juice = require(script.Parent.Juice)
local Fx = require(script.Parent.Fx)

local UnitCard = {}

export type Options = {
	stars: number?,
	name: string?, -- localized; omitted = no label
	sub: string?, -- small line under the name (cost, rarity…)
	spin: boolean?,
	selected: boolean?,
	dim: boolean?,
	zindex: number?,
}

-- Imported (Meshy) figures sit in their T-pose bind pose unless a clip plays, and an Animator only
-- runs inside a WorldModel in a ViewportFrame. Moves the rig into one and plays its idle: looping on
-- showcase (spinning) cards, frozen on the idle's first pose elsewhere so a grid of portraits
-- costs nothing per frame. Primitive figures are posed by their build and are left alone.
local function posePreview(vp: ViewportFrame, rig: Model, unitId: string, loop: boolean)
	-- Baked signature clips (Anim/BoneAnim): pose bones directly, holding the character's props.
	if rig:GetAttribute("Imported") and BoneAnim.has(unitId) then
		local world = Instance.new("WorldModel")
		world.Parent = vp
		rig.Parent = world
		local p = BoneAnim.new(rig, unitId)
		if not p then
			return
		end
		-- Attackers have no idle: they pose on their walk.
		local slot = if BoneAnim.length(p, "idle") > 0 then "idle" else "walk"
		BoneAnim.loop(p, slot)
		if not loop then
			BoneAnim.pose(p, slot)
			return
		end
		local conn: RBXScriptConnection
		conn = RunService.RenderStepped:Connect(function(dt: number)
			if not vp.Parent or not rig.Parent then
				conn:Disconnect()
				return
			end
			BoneAnim.step(p, dt, true)
		end)
		return
	end
	local look = (Looks :: any)[unitId]
	local idle = look and look.anims and look.anims.idle
	if not rig:GetAttribute("Imported") or not idle then
		return
	end
	local animator = rig:FindFirstChildWhichIsA("Animator", true)
	if not animator then
		return
	end
	local world = Instance.new("WorldModel")
	world.Parent = vp
	rig.Parent = world
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://" .. tostring(idle)
	local ok, track = pcall(function()
		local t = (animator :: Animator):LoadAnimation(anim)
		t.Looped = loop
		t:Play(0)
		if not loop then
			t:AdjustSpeed(0)
		end
		return t
	end)
	local hips = rig:FindFirstChild("Hips", true)
	if not ok or not track or not (hips and hips:IsA("Bone")) then
		return
	end
	-- The idle clips turn the hips (~137° on the Meshy rigs), so a posed figure would show its back.
	-- Once the clip has loaded and posed, turn the whole figure back by the hips' yaw change.
	task.spawn(function()
		local deadline = os.clock() + 8
		while (track :: AnimationTrack).Length == 0 and os.clock() < deadline and rig.Parent do
			task.wait(0.1)
		end
		RunService.RenderStepped:Wait()
		RunService.RenderStepped:Wait()
		if not rig.Parent or (track :: AnimationTrack).Length == 0 then
			return
		end
		-- The world-space turn the clip applies to the hips, measured on world forward (independent of
		-- how the bone's own axes point)
		local bone = hips :: Bone
		local turn = bone.TransformedWorldCFrame.Rotation * bone.WorldCFrame.Rotation:Inverse()
		local a = Vector3.new(0, 0, -1)
		local b = turn:VectorToWorldSpace(a)
		local yaw = math.atan2(a.Z * b.X - a.X * b.Z, a.X * b.X + a.Z * b.Z)
		if math.abs(yaw) > math.rad(5) then
			rig:PivotTo(rig:GetPivot() * CFrame.Angles(0, -yaw, 0))
		end
	end)
end

-- A viewport showing the unit rig (feet at y 0, facing the camera).
-- `portrait` frames head and shoulders (boss bar); otherwise the whole figure. Works for
-- defenders and attackers (Config/Enemies) alike.
function UnitCard.preview(unitId: string, props: { [string]: any }, spin: boolean?, portrait: boolean?): ViewportFrame
	local def = (Units :: any)[unitId] or (Enemies :: any)[unitId]
	local vp = Create("ViewportFrame", props)
	vp.BackgroundColor3 = Palette.stoneWarm
	vp.BackgroundTransparency = 0.35
	vp.Ambient = Color3.fromRGB(170, 160, 150)
	vp.LightColor = Color3.fromRGB(255, 240, 220)
	vp.LightDirection = Vector3.new(-0.6, -1, -0.8)
	Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = vp })
	if not def then
		return vp
	end
	-- Cloned from a per-unit template: grids re-render often.
	local rig = RigBuilder.cached(vp, unitId, def.visual, unitId)
	posePreview(vp, rig, unitId, spin == true)
	local s = def.visual.scale or 1
	local camera = Instance.new("Camera")
	camera.FieldOfView = 35
	camera.Parent = vp
	vp.CurrentCamera = camera
	local isCat = def.visual.weapon == "cat"
	local height = if isCat then 1.2 * s elseif portrait then 4.1 * s else 3.0 * s
	local dist = if isCat then 6 * s elseif portrait then 4.2 * s else 9.6 * s
	local function place(yawDeg: number)
		local yaw = math.rad(yawDeg)
		local target = Vector3.new(0, height, 0)
		local eye = target + Vector3.new(math.sin(yaw) * dist, dist * 0.22, -math.cos(yaw) * dist)
		camera.CFrame = CFrame.lookAt(eye, target)
	end
	place(20)
	if spin and Fx.any() then
		local yaw = 20
		local conn: RBXScriptConnection
		conn = RunService.RenderStepped:Connect(function(dt: number)
			if not vp.Parent or not rig.Parent then
				conn:Disconnect()
				return
			end
			yaw += dt * 35
			place(yaw)
		end)
	end
	return vp
end

function UnitCard.create(unitId: string, props: { [string]: any }, opts: Options?): Frame
	local o: Options = opts or {}
	local def = (Units :: any)[unitId]
	local rarity = if def then def.rarity else "rare"
	local color = Theme.rarityColor(rarity)
	local z = o.zindex or 11
	local card = Create("Frame", props, { Create("UICorner", { CornerRadius = UDim.new(0, 12) }) })
	card.BackgroundColor3 = color
	card.BackgroundTransparency = if o.dim then 0.55 else 0
	card.BorderSizePixel = 0
	card.ZIndex = z
	-- Rarity gradient (bright top, deep bottom) + thick dark border; gold border when selected.
	Create("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.42, 0.42, 0.42)), Parent = card })
	local border = Theme.border(card, if o.selected then 3.5 else 2.5)
	if o.selected then
		border.Color = Theme.colors.gold
	end
	if not o.dim and (rarity == "legendary" or rarity == "mythic" or rarity == "secret") then
		Juice.shine(card, 2.6)
	end

	local hasText = o.name ~= nil
	local vp = UnitCard.preview(unitId, {
		Position = UDim2.fromOffset(4, 4),
		Size = UDim2.new(1, -8, if hasText then 0.62 else 1, if hasText then 0 else -8),
		ZIndex = z,
	}, o.spin)
	vp.BackgroundTransparency = 1
	vp.Parent = card
	if o.dim then
		vp.ImageTransparency = 0.5
	end
	if o.stars and o.stars > 0 then
		local stars = Theme.display({
			Text = string.rep("★", o.stars),
			TextSize = 13,
			TextColor3 = Color3.fromHex("#FFD970"),
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -6, 0, 8),
			Size = UDim2.fromOffset(60, 14),
			ZIndex = z + 1,
			Parent = card,
		})
		stars.TextXAlignment = Enum.TextXAlignment.Right
	end
	if hasText then
		local name = Theme.display({
			Text = o.name :: string,
			TextSize = 12,
			Position = UDim2.new(0, 4, 0.62, 2),
			Size = UDim2.new(1, -8, 0, 30),
			ZIndex = z + 1,
			Parent = card,
		})
		name.TextXAlignment = Enum.TextXAlignment.Center
		name.TextYAlignment = Enum.TextYAlignment.Top
		if o.sub then
			local sub = Theme.display({
				Text = o.sub,
				TextSize = 13,
				TextColor3 = Color3.fromHex("#FFD970"),
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, -4),
				Size = UDim2.new(1, -8, 0, 16),
				ZIndex = z + 1,
				Parent = card,
			})
			sub.TextXAlignment = Enum.TextXAlignment.Center
		end
	end
	return card
end

return UnitCard
