--!strict
-- More lane props: the iconic barred gate (double leaves, iron studs, wicket, the night bar on
-- its hooks), shop signs with Arabic lettering, a notice board, coffee-house furniture and a
-- barber's chair. Same conventions as Props: façade frames from Kit.faceFrame, local -Z is out.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Palette = require(ReplicatedStorage:WaitForChild("Shared").Config.Palette)
local Kit = require(script.Parent.Kit)

local M = Kit.M
local part, model = Kit.part, Kit.model

local Props2 = {}

local IRON = Color3.fromHex("#2B2724")
local BRASS = Color3.fromHex("#C9A13B")

-- The big lane gate: two heavy leaves in a stone arch. `open` leaves them folded back against the
-- pillars; closed leaves are barred with the night beam. Frame `f` sits on the ground at the
-- centre of the opening, -Z facing outward (toward the road). Width/height are of the opening.
function Props2.gate(parent: Instance, f: CFrame, w: number, h: number, open: boolean): Model
	local m = model(parent, "Gate")
	local leafW = w / 2
	for _, side in { -1, 1 } do
		-- Hinge line at the jamb; open leaves swing 100° inward (into the lane), closed leaves fill
		-- the opening.
		local hinge = f * CFrame.new(side * w / 2, 0, 0)
		local swing = if open then CFrame.Angles(0, math.rad(side * 100), 0) else CFrame.identity
		local leafFrame = hinge * swing * CFrame.new(-side * leafW / 2, h / 2, 0)
		local leaf = part(m, { name = if side < 0 then "LeafW" else "LeafE", size = Vector3.new(leafW - 0.1, h, 0.5), cf = leafFrame, color = Palette.wood, material = M.WoodPlanks })
		leaf:SetAttribute("Side", side)
		-- Iron straps and a grid of studs
		for _, y in { -h * 0.32, 0, h * 0.32 } do
			part(m, { name = "Strap", size = Vector3.new(leafW - 0.2, 0.22, 0.56), cf = leafFrame * CFrame.new(0, y, 0), color = IRON, material = M.Metal, shadow = false, collide = false })
		end
		for i = 0, 2 do
			for j = 0, 3 do
				local x = -leafW / 2 + 0.8 + i * (leafW - 1.6) / 2
				local y = -h / 2 + 1.0 + j * (h - 2) / 3
				part(m, { name = "Stud", size = Vector3.new(0.22, 0.22, 0.12), cf = leafFrame * CFrame.new(x, y, -0.3), color = IRON, material = M.Metal, shadow = false, collide = false })
			end
		end
		-- Knocker rings
		part(m, { name = "Knocker", size = Vector3.new(0.12, 0.7, 0.7), cf = leafFrame * CFrame.new(-side * 0.6, -h * 0.05, -0.4) * CFrame.Angles(0, math.rad(90), 0), color = Palette.copper, material = M.Metal, shape = Enum.PartType.Cylinder, shadow = false, collide = false })
	end
	-- The wicket (khokha): a small door cut into the east leaf, drawn as a darker inset
	local wicketFrame = if open
		then f * CFrame.new(w / 2, 0, 0) * CFrame.Angles(0, math.rad(100), 0) * CFrame.new(-leafW * 0.35, 0, 0)
		else f * CFrame.new(leafW * 0.65, 0, 0)
	part(m, { name = "Wicket", size = Vector3.new(2.2, 4.6, 0.1), cf = wicketFrame * CFrame.new(0, 2.3, -0.3), color = Palette.woodDark, material = M.Wood, shadow = false, collide = false })
	part(m, { name = "WicketRing", size = Vector3.new(0.08, 0.35, 0.35), cf = wicketFrame * CFrame.new(0.7, 2.4, -0.4) * CFrame.Angles(0, math.rad(90), 0), color = Palette.copper, material = M.Metal, shape = Enum.PartType.Cylinder, shadow = false, collide = false })
	-- Hooks for the bar on both jambs; the bar itself rests across closed leaves
	for _, side in { -1, 1 } do
		part(m, { name = "Hook", size = Vector3.new(0.4, 0.4, 0.8), cf = f * CFrame.new(side * (w / 2 + 0.5), h * 0.45, 0.6), color = IRON, material = M.Metal, shadow = false, collide = false })
	end
	local bar = part(m, { name = "Bar", size = Vector3.new(w + 1.6, 0.6, 0.6), cf = f * CFrame.new(0, h * 0.45, 0.6), color = Palette.woodDark, material = M.Wood, collide = false })
	bar.Transparency = if open then 1 else 0
	if open then
		-- The bar leans against the wall by day
		local lean = part(m, { name = "BarLeaning", size = Vector3.new(0.6, w + 1.6, 0.6), cf = f * CFrame.new(w / 2 + 1.6, (w + 1.6) / 2 - 0.4, 1.4) * CFrame.Angles(0, 0, math.rad(12)), color = Palette.woodDark, material = M.Wood, collide = false })
		lean.CastShadow = false
	end
	return m
end

-- A painted wooden sign with Arabic (and optionally Latin) lettering on a façade frame.
function Props2.sign(parent: Instance, f: CFrame, w: number, text: string, sub: string?, bg: Color3?, fg: Color3?): Model
	local m = model(parent, "Sign")
	local board = part(m, { name = "Board", size = Vector3.new(w, 1.5, 0.25), cf = f * CFrame.new(0, 0, -0.15), color = bg or Palette.fabricIndigo, material = M.WoodPlanks, collide = false, shadow = false })
	part(m, { name = "Frame", size = Vector3.new(w + 0.3, 1.8, 0.15), cf = f * CFrame.new(0, 0, -0.05), color = Palette.woodDark, material = M.Wood, collide = false, shadow = false })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(w * 100, 150)
	gui.LightInfluence = 0.6
	gui.AlwaysOnTop = false
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, if sub then 0.62 else 1)
	label.Text = text
	label.TextColor3 = fg or Color3.fromHex("#FBF8F1")
	label.TextScaled = true
	label.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
	label.Parent = gui
	if sub then
		local s = Instance.new("TextLabel")
		s.BackgroundTransparency = 1
		s.Position = UDim2.fromScale(0, 0.62)
		s.Size = UDim2.fromScale(1, 0.38)
		s.Text = sub
		s.TextColor3 = BRASS
		s.TextScaled = true
		s.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium)
		s.Parent = gui
	end
	-- The board hangs from two short chains
	for _, x in { -w / 2 + 0.4, w / 2 - 0.4 } do
		part(m, { name = "Chain", size = Vector3.new(0.08, 0.7, 0.08), cf = f * CFrame.new(x, 1.1, -0.25), color = IRON, material = M.Metal, collide = false, shadow = false })
	end
	return m
end

-- Carved stone nameplate (for the gate crown): text on a basalt slab.
function Props2.nameplate(parent: Instance, f: CFrame, w: number, text: string): Model
	local m = model(parent, "Nameplate")
	local slab = part(m, { name = "Slab", size = Vector3.new(w, 2.2, 0.3), cf = f * CFrame.new(0, 0, -0.15), color = Palette.basalt, material = M.Basalt, collide = false, shadow = false })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(w * 100, 220)
	gui.LightInfluence = 0.7
	gui.Parent = slab
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Text = text
	label.TextColor3 = BRASS
	label.TextScaled = true
	label.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.ExtraBold)
	label.Parent = gui
	return m
end

-- Low coffee-house table with a tea tray, and a backgammon board.
function Props2.coffeeTable(parent: Instance, cf: CFrame, backgammon: boolean): Model
	local m = model(parent, "CoffeeTable")
	part(m, { name = "Top", size = Vector3.new(2.6, 0.25, 2.6), cf = cf * CFrame.new(0, 1.6, 0), color = Palette.wood, material = M.WoodPlanks })
	part(m, { name = "Leg", size = Vector3.new(0.3, 1.5, 0.3), cf = cf * CFrame.new(0, 0.75, 0), color = Palette.woodDark, material = M.Wood, collide = false })
	Kit.disc(m, "Tray", (cf * CFrame.new(0.5, 1.78, -0.4)).Position, 1.2, 0.08, Palette.copper, M.Metal, false)
	for i = 0, 2 do
		part(m, { name = "Cup", size = Vector3.new(0.22, 0.3, 0.22), cf = cf * CFrame.new(0.2 + i * 0.3, 1.95, -0.4) * Kit.CYL_UP, color = Palette.jasmine, material = M.Glass, shape = Enum.PartType.Cylinder, collide = false, shadow = false })
	end
	part(m, { name = "Teapot", size = Vector3.new(0.6, 0.6, 0.6), cf = cf * CFrame.new(0.5, 2.05, 0.1), color = Palette.copper, material = M.Metal, shape = Enum.PartType.Ball, collide = false, shadow = false })
	if backgammon then
		part(m, { name = "Board", size = Vector3.new(1.3, 0.08, 1.0), cf = cf * CFrame.new(-0.7, 1.77, 0.5), color = Palette.woodDark, material = M.Wood, collide = false, shadow = false })
		for i = 0, 5 do
			part(m, { name = "Point", size = Vector3.new(0.12, 0.09, 0.4), cf = cf * CFrame.new(-1.2 + i * 0.2, 1.78, 0.3), color = if i % 2 == 0 then Palette.fabricRed else Palette.jasmine, material = M.SmoothPlastic, collide = false, shadow = false })
		end
	end
	return m
end

-- Cushioned bench (dikkeh) along a wall: `cf` at ground, bench along local X.
function Props2.dikkeh(parent: Instance, cf: CFrame, length: number): Model
	local m = model(parent, "Dikkeh")
	part(m, { name = "Base", size = Vector3.new(length, 1.3, 2.2), cf = cf * CFrame.new(0, 0.65, 0), color = Palette.stoneWarm, material = M.Limestone })
	part(m, { name = "Cushion", size = Vector3.new(length - 0.2, 0.4, 2.0), cf = cf * CFrame.new(0, 1.5, 0), color = Palette.fabricRed, material = M.Fabric })
	local n = math.max(1, math.floor(length / 2.2))
	for i = 1, n do
		local x = -length / 2 + (i - 0.5) * length / n
		part(m, { name = "Pillow", size = Vector3.new(1.4, 1.0, 0.4), cf = cf * CFrame.new(x, 2.2, 0.9) * CFrame.Angles(math.rad(-12), 0, 0), color = if i % 2 == 0 then Palette.fabricIndigo else Palette.tile, material = M.Fabric, collide = false, shadow = false })
	end
	return m
end

-- Barber's chair, mirror and shelf of bottles.
function Props2.barberChair(parent: Instance, cf: CFrame): Model
	local m = model(parent, "BarberChair")
	part(m, { name = "Seat", size = Vector3.new(2.0, 0.5, 2.0), cf = cf * CFrame.new(0, 1.6, 0), color = Palette.fabricIndigo, material = M.Fabric })
	part(m, { name = "Back", size = Vector3.new(2.0, 2.4, 0.4), cf = cf * CFrame.new(0, 2.9, 0.8), color = Palette.fabricIndigo, material = M.Fabric })
	part(m, { name = "Post", size = Vector3.new(0.5, 1.4, 0.5), cf = cf * CFrame.new(0, 0.7, 0), color = IRON, material = M.Metal, collide = false })
	Kit.disc(m, "Foot", (cf * CFrame.new(0, 0.1, 0)).Position, 2.2, 0.2, IRON, M.Metal, false)
	for _, x in { -1.1, 1.1 } do
		part(m, { name = "ArmRest", size = Vector3.new(0.3, 0.3, 1.8), cf = cf * CFrame.new(x, 2.4, 0.2), color = Palette.woodDark, material = M.Wood, collide = false, shadow = false })
	end
	return m
end

function Props2.mirror(parent: Instance, f: CFrame, w: number, h: number): Model
	local m = model(parent, "Mirror")
	part(m, { name = "Frame", size = Vector3.new(w + 0.4, h + 0.4, 0.2), cf = f * CFrame.new(0, 0, -0.1), color = BRASS, material = M.Metal, collide = false, shadow = false })
	local glass = part(m, { name = "Glass", size = Vector3.new(w, h, 0.1), cf = f * CFrame.new(0, 0, -0.22), color = Color3.fromHex("#BFE3EE"), material = M.Glass, collide = false, shadow = false })
	glass.Reflectance = 0.6
	return m
end

function Props2.bottleShelf(parent: Instance, f: CFrame, w: number): Model
	local m = model(parent, "Shelf")
	part(m, { name = "Shelf", size = Vector3.new(w, 0.2, 0.9), cf = f * CFrame.new(0, 0, -0.45), color = Palette.wood, material = M.WoodPlanks, collide = false, shadow = false })
	local colors = { "#2E8B87", "#C9A13B", "#A4302A", "#5E7D3A", "#2F3E6B" }
	local n = math.floor(w / 0.7)
	for i = 1, n do
		local x = -w / 2 + (i - 0.5) * w / n
		part(m, { name = "Bottle", size = Vector3.new(0.35, 0.8, 0.35), cf = f * CFrame.new(x, 0.5, -0.45), color = Color3.fromHex(colors[(i - 1) % #colors + 1]), material = M.Glass, transparency = 0.25, collide = false, shadow = false })
	end
	return m
end

-- Brass samovar / coffee urn on a stand.
function Props2.samovar(parent: Instance, pos: Vector3): Model
	local m = model(parent, "Samovar")
	Kit.column(m, "Stand", pos, 1.2, 1.4, Palette.woodDark, M.Wood)
	Kit.column(m, "Body", pos + Vector3.new(0, 1.2, 0), 1.8, 1.1, Palette.copper, M.Metal, false)
	Kit.column(m, "Neck", pos + Vector3.new(0, 3.0, 0), 0.5, 0.5, BRASS, M.Metal, false)
	Kit.ball(m, "Lid", pos + Vector3.new(0, 3.6, 0), 0.5, BRASS, M.Metal, false)
	part(m, { name = "Tap", size = Vector3.new(0.15, 0.15, 0.6), cf = CFrame.new(pos + Vector3.new(0, 1.6, -0.7)), color = BRASS, material = M.Metal, collide = false, shadow = false })
	return m
end

-- A stool for the watchman, with his lantern on the ground.
function Props2.stool(parent: Instance, pos: Vector3): Model
	local m = model(parent, "Stool")
	Kit.disc(m, "Seat", pos + Vector3.new(0, 1.3, 0), 1.3, 0.2, Palette.wood, M.WoodPlanks, true)
	for i = 0, 2 do
		local a = i * 2.09
		part(m, { name = "Leg", size = Vector3.new(0.15, 1.3, 0.15), cf = CFrame.new(pos + Vector3.new(math.cos(a) * 0.45, 0.65, math.sin(a) * 0.45)), color = Palette.woodDark, material = M.Wood, collide = false, shadow = false })
	end
	return m
end

return Props2
