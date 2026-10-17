--!strict
-- Signature projectiles for the cast's attacks, launched from the hand on the clip's impact frame
-- (RigAnimController) and flown in an arc to the target: Abu Hatem's tea glass that shatters,
-- the shibriyeh (curved dagger) that Abu Shehab / Mo'taz / Za'im Abu Saleh throw as their
-- ultimate, the boy's sling stone, Abu Ghalib's chickpeas, Abu Bashir's flatbread, the watchman's
-- lantern flash, Abu Issam's remedy jar.
--
-- Built from a few small parts (no uploaded meshes), pooled per kind, moved in one RenderStepped
-- loop; nothing here touches the server. The Effects setting "off" draws nothing.

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Fx = require(script.Parent.Parent.UI.Fx)

local ThrowFx = {}

-- Which projectile each character throws, per slot. Units not listed keep the plain strike streak.
ThrowFx.KINDS = {
	qahwaji = { attack = "teacup" },
	zaim_akbar = { ability = "shabriyeh" },
	qabaday = { ability = "shabriyeh" },
	zaim = { ability = "shabriyeh" },
	walad = { attack = "stone" },
	khayyat = { attack = "chickpeas" },
	farran = { attack = "bread" },
	natour = { attack = "lantern" },
	umm_hara = { attack = "remedy" },
} :: { [string]: { [string]: string } }

type Flight = { model: Model, from: Vector3, to: Vector3, t: number, dur: number, arc: number, spin: Vector3, kind: string, onLand: (() -> ())? }

local flights: { Flight } = {}
local pools: { [string]: { Model } } = {}
local folder: Folder? = nil

local function container(): Folder
	local f = folder
	if f and f.Parent then
		return f
	end
	local n = Instance.new("Folder")
	n.Name = "Throws"
	n.Parent = Workspace
	folder = n
	return n
end

local function piece(m: Model, shape: Enum.PartType, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material, transp: number?): BasePart
	local p = Instance.new("Part")
	p.Shape = shape
	p.Size = size
	p.CFrame = cf
	p.Color = color
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
local UP = CFrame.Angles(0, 0, math.rad(90)) -- cylinders run along X; this stands them up

-- Builders work around the origin; the first part is the model's PrimaryPart.
local BUILD: { [string]: (Model) -> () } = {
	teacup = function(m)
		-- A small tulip tea glass with amber tea and a gold rim, on a saucer.
		local glass = piece(m, CYL, Vector3.new(0.55, 0.36, 0.36), UP, Color3.fromHex("#F4F1EA"), Enum.Material.Glass, 0.35)
		piece(m, CYL, Vector3.new(0.42, 0.3, 0.3), CFrame.new(0, -0.05, 0) * UP, Color3.fromHex("#B5531C"), Enum.Material.SmoothPlastic, 0.05)
		piece(m, CYL, Vector3.new(0.05, 0.38, 0.38), CFrame.new(0, 0.27, 0) * UP, Color3.fromHex("#D9B44A"), Enum.Material.Metal)
		piece(m, CYL, Vector3.new(0.05, 0.62, 0.62), CFrame.new(0, -0.3, 0) * UP, Color3.fromHex("#FBF8F1"), Enum.Material.SmoothPlastic)
		m.PrimaryPart = glass
	end,
	shabriyeh = function(m)
		-- Curved Damascene dagger: three blade segments bending up to the tip, brass guard, dark hilt.
		local hilt = piece(m, BLOCK, Vector3.new(0.16, 0.16, 0.55), CFrame.new(0, 0, 0.45), Color3.fromHex("#2B1D14"), Enum.Material.Wood)
		piece(m, BLOCK, Vector3.new(0.5, 0.1, 0.12), CFrame.new(0, 0, 0.16), Color3.fromHex("#D9B44A"), Enum.Material.Metal)
		local steel = Color3.fromHex("#E8ECEF")
		piece(m, BLOCK, Vector3.new(0.07, 0.2, 0.5), CFrame.new(0, 0.02, -0.12), steel, Enum.Material.Metal)
		piece(m, BLOCK, Vector3.new(0.06, 0.17, 0.42), CFrame.new(0, 0.1, -0.52) * CFrame.Angles(math.rad(18), 0, 0), steel, Enum.Material.Metal)
		piece(m, BLOCK, Vector3.new(0.05, 0.12, 0.32), CFrame.new(0, 0.26, -0.85) * CFrame.Angles(math.rad(40), 0, 0), steel, Enum.Material.Metal)
		local glint = piece(m, BALL, Vector3.new(0.35, 0.35, 0.35), CFrame.new(0, 0.1, -0.4), Color3.fromHex("#FFF6D8"), Enum.Material.Neon, 0.55)
		glint.Name = "Glint"
		m.PrimaryPart = hilt
	end,
	stone = function(m)
		m.PrimaryPart = piece(m, BALL, Vector3.new(0.38, 0.32, 0.36), CFrame.new(), Color3.fromHex("#8A8178"), Enum.Material.Slate)
	end,
	chickpeas = function(m)
		local core = piece(m, BALL, Vector3.new(0.2, 0.2, 0.2), CFrame.new(), Color3.fromHex("#E1BE6A"), Enum.Material.SmoothPlastic)
		for i = 1, 5 do
			local a = i * 1.26
			piece(m, BALL, Vector3.new(0.18, 0.18, 0.18), CFrame.new(math.cos(a) * 0.32, (i % 2) * 0.15, math.sin(a) * 0.32), Color3.fromHex("#E8C778"), Enum.Material.SmoothPlastic)
		end
		m.PrimaryPart = core
	end,
	bread = function(m)
		-- A round flatbread, a little puffed, flying like a disc.
		local disc = piece(m, CYL, Vector3.new(0.14, 1.1, 1.1), UP, Color3.fromHex("#D9A55B"), Enum.Material.Sand)
		piece(m, CYL, Vector3.new(0.1, 0.7, 0.7), CFrame.new(0, 0.06, 0) * UP, Color3.fromHex("#B87A3A"), Enum.Material.Sand)
		m.PrimaryPart = disc
	end,
	lantern = function(m)
		local orb = piece(m, BALL, Vector3.new(0.6, 0.6, 0.6), CFrame.new(), Color3.fromHex("#FFC861"), Enum.Material.Neon, 0.1)
		local light = Instance.new("PointLight")
		light.Color = Color3.fromHex("#FFB347")
		light.Range = 10
		light.Brightness = 2
		light.Parent = orb
		m.PrimaryPart = orb
	end,
	remedy = function(m)
		-- A small green glass remedy jar with a cork.
		local jar = piece(m, CYL, Vector3.new(0.5, 0.34, 0.34), UP, Color3.fromHex("#5FA36A"), Enum.Material.Glass, 0.25)
		piece(m, CYL, Vector3.new(0.14, 0.2, 0.2), CFrame.new(0, 0.3, 0) * UP, Color3.fromHex("#A8835A"), Enum.Material.Wood)
		m.PrimaryPart = jar
	end,
}

local function take(kind: string): Model?
	local pool = pools[kind]
	if pool and #pool > 0 then
		local m = table.remove(pool) :: Model
		m.Parent = container()
		return m
	end
	local build = BUILD[kind]
	if not build then
		return nil
	end
	local m = Instance.new("Model")
	m.Name = kind
	build(m)
	m.Parent = container()
	return m
end

local function give(kind: string, m: Model)
	m.Parent = nil
	local pool = pools[kind]
	if not pool then
		pool = {}
		pools[kind] = pool
	end
	if #pool < 10 then
		table.insert(pool, m)
	else
		m:Destroy()
	end
end

-- Landing touches, from the shared Fx pool.
local function shatter(at: Vector3, color: Color3, splash: Color3?)
	if not Fx.full() then
		return
	end
	for i = 1, 5 do
		local s = Fx.part()
		if not s then
			break
		end
		s.Material = Enum.Material.Glass
		s.Color = color
		s.Transparency = 0.2
		s.Size = Vector3.new(0.14, 0.05, 0.2)
		local a = i * 1.257 + math.random()
		s.CFrame = CFrame.new(at) * CFrame.Angles(math.random() * 3, a, 0)
		local out = Vector3.new(math.cos(a), 0.5 + math.random() * 0.6, math.sin(a)) * (1.4 + math.random())
		Fx.fade(s, 0.35, { CFrame = CFrame.new(at + out) * CFrame.Angles(math.random() * 6, math.random() * 6, 0), Transparency = 1 })
	end
	if splash then
		local d = Fx.part(Enum.PartType.Cylinder)
		if d then
			d.Material = Enum.Material.SmoothPlastic
			d.Color = splash
			d.Transparency = 0.15
			d.Size = Vector3.new(0.08, 0.6, 0.6)
			d.CFrame = CFrame.new(at.X, at.Y - 1.2, at.Z) * UP
			Fx.fade(d, 0.5, { Size = Vector3.new(0.05, 2.4, 2.4), Transparency = 1 })
		end
	end
end

local function puff(at: Vector3, color: Color3, size: number)
	if not Fx.any() then
		return
	end
	local b = Fx.part(Enum.PartType.Ball)
	if b then
		b.Material = Enum.Material.SmoothPlastic
		b.Color = color
		b.Transparency = 0.3
		b.Size = Vector3.one * size * 0.4
		b.CFrame = CFrame.new(at)
		Fx.fade(b, 0.3, { Size = Vector3.one * size, Transparency = 1 })
	end
end

local LAND: { [string]: (Vector3) -> () } = {
	teacup = function(at)
		shatter(at, Color3.fromHex("#F4F1EA"), Color3.fromHex("#B5531C"))
	end,
	remedy = function(at)
		shatter(at, Color3.fromHex("#5FA36A"), Color3.fromHex("#9BE3A6"))
	end,
	stone = function(at)
		puff(at, Color3.fromHex("#C9B48F"), 1.6)
	end,
	chickpeas = function(at)
		puff(at, Color3.fromHex("#E8C778"), 2.2)
	end,
	bread = function(at)
		puff(at, Color3.fromHex("#F1E2C2"), 2.4)
	end,
	lantern = function(at)
		puff(at, Color3.fromHex("#FFC861"), 3)
	end,
	shabriyeh = function(at)
		puff(at, Color3.fromHex("#FFF6D8"), 2)
	end,
}

-- The projectile kind a character throws for this slot ("attack" / "ability"), if any.
function ThrowFx.kindFor(unitId: string?, slot: string): string?
	local k = unitId and ThrowFx.KINDS[unitId]
	return k and k[slot] or nil
end

-- Flies `kind` from `from` to `to`; calls onLand (if given) when it arrives.
function ThrowFx.throw(kind: string, from: Vector3, to: Vector3, onLand: (() -> ())?)
	if not Fx.any() then
		if onLand then
			onLand()
		end
		return
	end
	local m = take(kind)
	if not m then
		if onLand then
			onLand()
		end
		return
	end
	local dist = (to - from).Magnitude
	local flat = kind == "shabriyeh" or kind == "lantern"
	local spin = if kind == "shabriyeh"
		then Vector3.new(-26, 0, 0)
		elseif kind == "bread" then Vector3.new(0, 18, 0)
		elseif kind == "teacup" or kind == "remedy" then Vector3.new(9, 0, 5)
		else Vector3.new(6, 3, 0)
	table.insert(flights, {
		model = m,
		from = from,
		to = to,
		t = 0,
		dur = math.clamp(dist / (if flat then 60 else 38), 0.12, 0.5),
		arc = if flat then dist * 0.06 else math.min(4, dist * 0.22),
		spin = spin,
		kind = kind,
		onLand = onLand,
	})
end

local function step(dt: number)
	for i = #flights, 1, -1 do
		local f = flights[i]
		f.t += dt
		local k = math.min(1, f.t / f.dur)
		local pos = f.from:Lerp(f.to, k) + Vector3.new(0, 4 * f.arc * k * (1 - k), 0)
		local dir = f.to - f.from
		local face = if dir.Magnitude > 0.01 then CFrame.lookAt(pos, pos + Vector3.new(dir.X, 0, dir.Z)) else CFrame.new(pos)
		local s = f.spin * f.t
		f.model:PivotTo(face * CFrame.Angles(s.X, s.Y, s.Z))
		if k >= 1 then
			table.remove(flights, i)
			give(f.kind, f.model)
			local land = LAND[f.kind]
			if land then
				land(f.to)
			end
			if f.onLand then
				f.onLand()
			end
		end
	end
end

function ThrowFx.start()
	RunService.RenderStepped:Connect(step)
end

return ThrowFx
