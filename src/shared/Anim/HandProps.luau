--!strict
-- Props held in an imported character's hands, built from a few small parts and moved with the
-- hand bone every animated frame (Anim/BoneAnim). Meshy's T-pose step drops most hand-held items
-- (hammer, sword, lantern…), so the signature object is put back here: Abu Hatem's tea glass,
-- Abu Shehab's shibriyeh, Abu Khater's hammer, the watchman's lantern, the 'Arada's sword and
-- shield…
--
-- Prop space: grip at the origin, all lengths in units of the figure's height H. Two mounts:
--   "fist": the long axis toward -Z through the fist (thumb side), like a hammer or a sword;
--   "hang": +Y points from the fingers back toward the wrist, so with the arm down +Y is up: a
--           lantern or pot hangs below (-Y), a glass stands in the hand (+Y), a cane reaches down.
-- At bind time each prop is placed at the fist in the T-pose, and that offset from the hand bone
-- is kept, so the prop follows every clip.

local HandProps = {}

export type Prop = { part: BasePart, bone: Bone, offset: CFrame, kind: string, hiddenUntil: number }

type Builder = (m: Model, H: number) -> ()

local function piece(m: Model, shape: Enum.PartType, size: Vector3, cf: CFrame, color: string, mat: Enum.Material, transp: number?): BasePart
	local p = Instance.new("Part")
	p.Shape = shape
	p.Size = size
	p.CFrame = cf
	p.Color = Color3.fromHex(color)
	p.Material = mat
	p.Transparency = transp or 0
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = m
	return p
end

local CYL = Enum.PartType.Cylinder
local BLOCK = Enum.PartType.Block
local BALL = Enum.PartType.Ball
local UP = CFrame.Angles(0, 0, math.rad(90)) -- a cylinder standing upright (axis +Y)
local ALONG = CFrame.Angles(0, math.rad(90), 0) -- a cylinder lying along Z
local M = Enum.Material

local BUILD: { [string]: Builder } = {
	teaglass = function(m, H)
		local s = H * 0.055
		piece(m, CYL, Vector3.new(s * 1.5, s, s), CFrame.new(0, s * 0.55, 0) * UP, "#F4F1EA", M.Glass, 0.35)
		piece(m, CYL, Vector3.new(s * 1.1, s * 0.82, s * 0.82), CFrame.new(0, s * 0.45, 0) * UP, "#B5531C", M.SmoothPlastic)
		piece(m, CYL, Vector3.new(s * 0.12, s * 1.05, s * 1.05), CFrame.new(0, s * 1.28, 0) * UP, "#D9B44A", M.Metal)
	end,
	shibriyeh = function(m, H)
		local L = H * 0.3
		piece(m, BLOCK, Vector3.new(L * 0.1, L * 0.1, L * 0.34), CFrame.new(0, 0, L * 0.05), "#2B1D14", M.Wood)
		piece(m, BLOCK, Vector3.new(L * 0.32, L * 0.06, L * 0.07), CFrame.new(0, 0, -L * 0.14), "#D9B44A", M.Metal)
		piece(m, BLOCK, Vector3.new(L * 0.04, L * 0.13, L * 0.32), CFrame.new(0, L * 0.01, -L * 0.33), "#E8ECEF", M.Metal)
		piece(m, BLOCK, Vector3.new(L * 0.035, L * 0.11, L * 0.26), CFrame.new(0, L * 0.06, -L * 0.57) * CFrame.Angles(math.rad(18), 0, 0), "#E8ECEF", M.Metal)
		piece(m, BLOCK, Vector3.new(L * 0.03, L * 0.08, L * 0.2), CFrame.new(0, L * 0.16, -L * 0.77) * CFrame.Angles(math.rad(40), 0, 0), "#E8ECEF", M.Metal)
	end,
	cane = function(m, H)
		-- Gripped near the top, the shaft reaching down to the ground (hang mount).
		local L = H * 0.5
		piece(m, CYL, Vector3.new(L, H * 0.032, H * 0.032), CFrame.new(0, -L * 0.42, 0) * UP, "#5A3A22", M.Wood)
		piece(m, BALL, Vector3.new(H * 0.055, H * 0.055, H * 0.055), CFrame.new(0, L * 0.1, 0), "#D9B44A", M.Metal)
	end,
	dallah = function(m, H)
		-- Brass Arabic coffee pot carried by its handle (hang mount): bulb, waist, lid with a
		-- finial, and the long beaked spout.
		local s = H * 0.1
		piece(m, BALL, Vector3.new(s * 1.1, s * 0.95, s * 1.1), CFrame.new(0, -s * 1.15, 0), "#C9A13B", M.Metal)
		piece(m, CYL, Vector3.new(s * 0.55, s * 0.5, s * 0.5), CFrame.new(0, -s * 0.5, 0) * UP, "#D9B44A", M.Metal)
		piece(m, CYL, Vector3.new(s * 0.2, s * 0.72, s * 0.72), CFrame.new(0, -s * 0.2, 0) * UP, "#C9A13B", M.Metal)
		piece(m, BALL, Vector3.new(s * 0.22, s * 0.3, s * 0.22), CFrame.new(0, s * 0.02, 0), "#E6C766", M.Metal)
		piece(m, CYL, Vector3.new(s * 0.95, s * 0.13, s * 0.13), CFrame.new(0, -s * 0.75, -s * 0.72) * CFrame.Angles(math.rad(-50), 0, 0) * ALONG, "#C9A13B", M.Metal)
		piece(m, BLOCK, Vector3.new(s * 0.08, s * 0.7, s * 0.12), CFrame.new(0, -s * 0.7, s * 0.55), "#B8913A", M.Metal)
	end,
	razor = function(m, H)
		local L = H * 0.16
		piece(m, BLOCK, Vector3.new(L * 0.16, L * 0.22, L * 0.6), CFrame.new(0, 0, 0), "#3B2A20", M.Wood)
		piece(m, BLOCK, Vector3.new(L * 0.06, L * 0.3, L * 0.6), CFrame.new(0, L * 0.05, -L * 0.6), "#EEF2F4", M.Metal)
	end,
	jar = function(m, H)
		local s = H * 0.07
		piece(m, CYL, Vector3.new(s * 1.3, s, s), CFrame.new(0, s * 0.5, 0) * UP, "#5FA36A", M.Glass, 0.2)
		piece(m, CYL, Vector3.new(s * 0.35, s * 0.55, s * 0.55), CFrame.new(0, s * 1.3, 0) * UP, "#A8835A", M.Wood)
	end,
	stick = function(m, H)
		local L = H * 0.42
		piece(m, CYL, Vector3.new(L, H * 0.03, H * 0.03), CFrame.new(0, 0, -L * 0.3) * ALONG, "#B08A5A", M.Wood)
	end,
	bread = function(m, H)
		local d = H * 0.2
		piece(m, CYL, Vector3.new(H * 0.025, d, d), CFrame.new(0, d * 0.1, -d * 0.35) * UP, "#D9A55B", M.Sand)
	end,
	lantern = function(m, H)
		local s = H * 0.11
		-- Hangs below the fist from a short handle: iron cap, glowing glass, iron base.
		piece(m, CYL, Vector3.new(s * 0.5, s * 0.08, s * 0.08), CFrame.new(0, -s * 0.25, 0) * UP, "#1F1B18", M.Metal)
		piece(m, CYL, Vector3.new(s * 0.25, s * 0.75, s * 0.75), CFrame.new(0, -s * 0.6, 0) * UP, "#1F1B18", M.Metal)
		local glass = piece(m, CYL, Vector3.new(s * 0.9, s * 0.62, s * 0.62), CFrame.new(0, -s * 1.15, 0) * UP, "#FFC861", M.Neon, 0.15)
		piece(m, CYL, Vector3.new(s * 0.2, s * 0.8, s * 0.8), CFrame.new(0, -s * 1.7, 0) * UP, "#1F1B18", M.Metal)
		local light = Instance.new("PointLight")
		light.Color = Color3.fromHex("#FFB347")
		light.Range = 12
		light.Brightness = 1.6
		light.Shadows = false
		light.Parent = glass
	end,
	hammer = function(m, H)
		local L = H * 0.42
		piece(m, CYL, Vector3.new(L, H * 0.04, H * 0.04), CFrame.new(0, 0, -L * 0.3) * ALONG, "#6B4A2E", M.Wood)
		piece(m, BLOCK, Vector3.new(H * 0.09, H * 0.2, H * 0.11), CFrame.new(0, H * 0.02, -L * 0.82), "#3A3A3C", M.Metal)
	end,
	sword = function(m, H)
		local L = H * 0.5
		piece(m, BLOCK, Vector3.new(L * 0.07, L * 0.07, L * 0.2), CFrame.new(0, 0, L * 0.02), "#2B1D14", M.Wood)
		piece(m, BLOCK, Vector3.new(L * 0.26, L * 0.05, L * 0.05), CFrame.new(0, 0, -L * 0.1), "#D9B44A", M.Metal)
		piece(m, BLOCK, Vector3.new(L * 0.025, L * 0.08, L * 0.75), CFrame.new(0, 0, -L * 0.5), "#E8ECEF", M.Metal)
	end,
	shield = function(m, H)
		local d = H * 0.32
		piece(m, CYL, Vector3.new(H * 0.03, d, d), CFrame.new(-H * 0.04, 0, 0), "#C9A13B", M.Metal)
		piece(m, BALL, Vector3.new(d * 0.22, d * 0.22, d * 0.22), CFrame.new(-H * 0.06, 0, 0), "#E6C766", M.Metal)
	end,
	rifle = function(m, H)
		-- Carried at the side, muzzle up (hang mount): wooden stock below the fist, barrel above.
		local L = H * 0.72
		piece(m, BLOCK, Vector3.new(H * 0.05, L * 0.45, H * 0.07), CFrame.new(0, -L * 0.12, 0), "#6B4A2E", M.Wood)
		piece(m, CYL, Vector3.new(L * 0.7, H * 0.03, H * 0.03), CFrame.new(0, L * 0.3, H * 0.015) * UP, "#2B2B2E", M.Metal)
	end,
	broom = function(m, H)
		-- Straw broom: long wooden handle through the fist, bound straw head at the far end.
		local L = H * 0.62
		piece(m, CYL, Vector3.new(L * 0.8, H * 0.03, H * 0.03), CFrame.new(0, 0, -L * 0.25) * ALONG, "#9C7A4E", M.Wood)
		piece(m, CYL, Vector3.new(L * 0.07, H * 0.075, H * 0.075), CFrame.new(0, 0, -L * 0.68) * ALONG, "#7A2E3A", M.Fabric)
		piece(m, BLOCK, Vector3.new(H * 0.2, H * 0.06, L * 0.3), CFrame.new(0, 0, -L * 0.85), "#D9B45A", M.Grass)
	end,
	bowl = function(m, H)
		local d = H * 0.16
		piece(m, CYL, Vector3.new(d * 0.35, d, d), CFrame.new(0, d * 0.05, 0) * UP, "#B8733A", M.Metal)
		piece(m, CYL, Vector3.new(d * 0.08, d * 0.85, d * 0.85), CFrame.new(0, d * 0.22, 0) * UP, "#E8C778", M.SmoothPlastic)
	end,
}

-- Chibi figures read best with oversized props: per-kind enlargement over the builders' sizes.
local BOOST: { [string]: number } = {
	teaglass = 1.6,
	jar = 1.35,
	razor = 1.5,
	shibriyeh = 1.3,
	lantern = 1.3,
	hammer = 1.3,
	bread = 1.25,
	stick = 1.15,
	broom = 1.1,
	bowl = 1.2,
}

-- What each character holds. `throws` = hidden for a moment after it leaves the hand (ThrowFx).
HandProps.HELD = {
	qahwaji = {
		-- One glass to sip (his idle drinks with the left hand), one to throw (and grab another).
		{ kind = "teaglass", hand = "RightHand", mount = "hang", throws = "attack" },
		{ kind = "teaglass", hand = "LeftHand", mount = "hang" },
	},
	zaim_akbar = { { kind = "shibriyeh", hand = "RightHand", mount = "fist", throws = "ability" } },
	zaim = { { kind = "cane", hand = "RightHand", mount = "hang" } },
	hallaq = { { kind = "razor", hand = "RightHand", mount = "fist" } },
	umm_hara = { { kind = "jar", hand = "RightHand", mount = "hang", throws = "attack" } },
	mukhtar = { { kind = "stick", hand = "RightHand", mount = "fist", tilt = 50 } },
	saqqa = { { kind = "broom", hand = "RightHand", mount = "fist", tilt = 55 } },
	khayyat = { { kind = "bowl", hand = "LeftHand", mount = "hang" } },
	farran = { { kind = "bread", hand = "RightHand", mount = "hang", throws = "attack" } },
	natour = { { kind = "lantern", hand = "RightHand", mount = "hang" } },
	haddad = { { kind = "hammer", hand = "RightHand", mount = "fist", tilt = 45 } },
	arada = {
		{ kind = "sword", hand = "RightHand", mount = "fist", tilt = 20 },
		{ kind = "shield", hand = "LeftHand", mount = "fist" },
	},
	gendarme = { { kind = "rifle", hand = "RightHand", mount = "hang" } },
} :: { [string]: { { kind: string, hand: string, mount: string, throws: string?, tilt: number? } } }

-- Builds and binds the props for `id` on `model`. Must run while the bones are at rest (no
-- Transform yet), which is how a figure arrives. Returns the bound props (possibly empty).
function HandProps.attach(model: Model, id: string, bones: { [string]: Bone }): { Prop }
	local out: { Prop } = {}
	local list = HandProps.HELD[id]
	local root = model.PrimaryPart
	if not list or not root then
		return out
	end
	local H = root.Size.Y
	local folder = Instance.new("Model")
	folder.Name = "HandProps"
	folder.Parent = model
	for _, spec in list do
		local bone = bones[spec.hand]
		local build = BUILD[spec.kind]
		if bone and build then
			local m = Instance.new("Model")
			build(m, H * (BOOST[spec.kind] or 1))
			-- Weld the pieces to the first one and move only that part each frame.
			local parts = m:GetChildren()
			local main = parts[1] :: BasePart
			for i = 2, #parts do
				local p = parts[i] :: BasePart
				p.Anchored = false
				p.Massless = true
				local w = Instance.new("WeldConstraint")
				w.Part0 = main
				w.Part1 = p
				w.Parent = p
			end
			-- Grip pose at bind: fist centre a little past the wrist along the hand, slightly below
			-- the bone line. "fist": axis-aligned with the model (long axis forward = thumb side);
			-- "hang": +Y back along the hand toward the wrist, -Z still forward.
			local hand = bone.WorldCFrame
			local fingers = hand.UpVector
			local grip = hand.Position + fingers * (H * 0.035) - root.CFrame.UpVector * (H * 0.012)
			local gripCf = CFrame.new(grip) * root.CFrame.Rotation
			if spec.tilt then
				-- Fist mount, long axis tipped from the thumb side toward the fingers: at rest the
				-- broom / hammer points down to the ground ahead, raised for a swing it points up.
				local side = if fingers:Dot(root.CFrame.RightVector) >= 0 then 1 else -1
				gripCf = gripCf * CFrame.Angles(0, -side * math.rad(spec.tilt), 0)
			end
			if spec.mount == "hang" then
				local up = -fingers
				local back = -root.CFrame.LookVector
				back = (back - up * back:Dot(up)).Unit
				gripCf = CFrame.fromMatrix(grip, up:Cross(back), up)
			end
			-- Pieces were built around the origin; express the main part relative to the grip.
			local mainLocal = main.CFrame
			m.Parent = folder
			table.insert(out, {
				part = main,
				bone = bone,
				offset = hand:ToObjectSpace(gripCf) * mainLocal,
				kind = spec.kind,
				hiddenUntil = 0,
			})
			main.CFrame = gripCf * mainLocal
		end
	end
	return out
end

-- Moves the props with their hands (call after the bones were written).
function HandProps.update(props: { Prop }, now: number)
	for _, p in props do
		if p.hiddenUntil > 0 then
			if now >= p.hiddenUntil then
				p.hiddenUntil = 0
				for _, d in (p.part.Parent :: Instance):GetChildren() do
					if d:IsA("BasePart") then
						d.LocalTransparencyModifier = 0
					end
				end
			end
		end
		p.part.CFrame = p.bone.TransformedWorldCFrame * p.offset
	end
end

-- Hides the props that leave the hand for `slot` ("attack" / "ability") for `seconds`.
function HandProps.thrown(props: { Prop }, id: string, slot: string, seconds: number)
	local list = HandProps.HELD[id]
	if not list then
		return
	end
	local now = os.clock()
	for i, p in props do
		local spec = list[i]
		if spec and spec.throws == slot then
			p.hiddenUntil = now + seconds
			for _, d in (p.part.Parent :: Instance):GetChildren() do
				if d:IsA("BasePart") then
					d.LocalTransparencyModifier = 1
				end
			end
		end
	end
end

return HandProps
