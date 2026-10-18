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
local IconIds = require(Shared.Config.Icons)
local BoneAnim = require(Shared.Anim.BoneAnim)
local Create = require(script.Parent.Create)
local Theme = require(script.Parent.Theme)
local Juice = require(script.Parent.Juice)
local Fx = require(script.Parent.Fx)
local Icons = require(script.Parent.Icons)

local UnitCard = {}

export type Options = {
	stars: number?,
	name: string?, -- localized; omitted = no label
	sub: string?, -- small line under the name (cost, rarity…)
	spin: boolean?,
	selected: boolean?,
	dim: boolean?,
	zindex: number?,
	role: string?, -- draws the role glyph in the top-left corner (LP-B05)
	reach: { string }?, -- small marks over the portrait's foot: "stealth" | "lantern" | "douse"
}

-- The mark drawn for each reach (UnitLogic.kind): eye (sees stealth), a gold eye (lights a lantern
-- for others), fire (douses the gate's burn).
local REACH_ICON: { [string]: { icon: string, color: string? } } = {
	stealth = { icon = "eye" },
	lantern = { icon = "eye", color = "#F2C14E" },
	douse = { icon = "mech_burn" },
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

-- The painted portrait's image id (Config/Icons.portraits, PV-C05) while it still matches the
-- character's model, else nil.
function UnitCard.portraitId(unitId: string): number?
	local p = IconIds.portraits[unitId]
	if not p or p.id == 0 then
		return nil
	end
	local look = (Looks :: any)[unitId]
	local model = if look and look.model then look.model else ""
	return if p.model == model then p.id else nil
end

-- Head and shoulders for slots, hotbars and the boss bar: the painted portrait (no per-frame cost) or,
-- without a current one, the live figure framed the same way.
function UnitCard.portrait(unitId: string, props: { [string]: any }): GuiObject
	local id = UnitCard.portraitId(unitId)
	if not id then
		return UnitCard.preview(unitId, props, false, true)
	end
	local img = Create("ImageLabel", props)
	img.Name = "Portrait"
	img.Image = "rbxassetid://" .. tostring(id)
	img.ScaleType = Enum.ScaleType.Crop
	img.BackgroundColor3 = Palette.stoneWarm
	img.BackgroundTransparency = 0.35
	Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = img })
	return img
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
	-- Grids show the painted portrait; only a spinning showcase card keeps a live viewport
	-- (ANIME_VANGUARDS_STUDY §7: a grid of viewports costs a render each).
	local figureProps = {
		Position = UDim2.fromOffset(4, 4),
		Size = UDim2.new(1, -8, if hasText then 0.62 else 1, if hasText then 0 else -8),
		ZIndex = z,
	}
	if o.spin or not UnitCard.portraitId(unitId) then
		local vp = UnitCard.preview(unitId, figureProps, o.spin)
		vp.BackgroundTransparency = 1
		vp.ImageTransparency = if o.dim then 0.5 else 0
		vp.Parent = card
	else
		local img = UnitCard.portrait(unitId, figureProps) :: ImageLabel
		img.BackgroundTransparency = 1
		img.ImageTransparency = if o.dim then 0.5 else 0
		img.Parent = card
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
	if o.role then
		local glyph = Create("Frame", { Name = "Role", Position = UDim2.fromOffset(4, 4), Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1, ZIndex = z + 2, Parent = card })
		Icons.draw("role_" .. o.role, glyph)
		for _, d in glyph:GetDescendants() do
			if d:IsA("GuiObject") then
				d.ZIndex = z + 2
			end
		end
	end
	if o.reach and #o.reach > 0 then
		local marks = Create("Frame", { Name = "Reach", Position = UDim2.new(0, 4, 0.62, -18), Size = UDim2.new(1, -8, 0, 16), BackgroundTransparency = 1, ZIndex = z + 2, Parent = card })
		Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 2), Parent = marks })
		for _, r in o.reach do
			local spec = REACH_ICON[r]
			if spec then
				local m = Create("Frame", { Size = UDim2.fromOffset(16, 16), BackgroundColor3 = Color3.fromHex("#2A1E14"), BackgroundTransparency = 0.3, ZIndex = z + 2, Parent = marks }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
				Icons.draw(spec.icon, m, spec.color)
				for _, d in m:GetDescendants() do
					if d:IsA("GuiObject") then
						d.ZIndex = z + 3
					end
				end
			end
		end
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
