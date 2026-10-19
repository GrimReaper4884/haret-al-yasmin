--!strict
-- Lane extras for the tower-defense update: the Play hall in the square, the coffee house
-- (qahwa) on the square's west side, the barber shop on the lane, painted shop signs, the gate
-- nameplate, the watchman's corner and the notice board.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Palette = require(Shared.Config.Palette)
local Strings = require(Shared.Config.Strings)
local Events = require(Shared.Config.Events)
local EventLogic = require(Shared.Logic.EventLogic)
local Story = require(Shared.Config.Story)
local World = script.Parent.Parent
local Kit = require(World.Kit)
local Props = require(World.Props)
local Props2 = require(World.Props2)

local M = Kit.M

local Extras = {}

local function ar(key: string): string
	return Strings.ar[key] or key
end

-- An arched gateway on the square's wall side: a tiled pad under a striped (ablaq) arch with a
-- lantern and a hanging board. Returns the pad.
local function archway(parent: Instance, px: number, pz: number, width: number, boardText: string, color: Color3): BasePart
	local half = width / 2
	local pad = Kit.part(parent, { name = "Pad", size = Vector3.new(8, 0.4, width), cf = CFrame.new(px, 0.2, pz), color = color, material = M.CeramicTiles })
	Kit.part(parent, { name = "Inlay", size = Vector3.new(7, 0.42, 7), cf = CFrame.new(px, 0.2, pz) * CFrame.Angles(0, math.rad(45), 0), color = Palette.jasmine, material = M.CeramicTiles, shadow = false, collide = false })
	local sign = if px < 0 then -1 else 1
	local bx = px + sign * 4.6
	for _, dz in { -half, half } do
		Kit.part(parent, { name = "Pillar", size = Vector3.new(1.6, 11, 1.6), cf = CFrame.new(bx, 5.5, pz + dz), color = Palette.stoneLight, material = M.Limestone })
		for _, y in { 2, 5, 8 } do
			Kit.part(parent, { name = "Band", size = Vector3.new(1.65, 0.7, 1.65), cf = CFrame.new(bx, y, pz + dz), color = Palette.basalt, material = M.Basalt, shadow = false, collide = false })
		end
	end
	Kit.part(parent, { name = "Lintel", size = Vector3.new(2, 1.8, width + 2.4), cf = CFrame.new(bx, 12, pz), color = Palette.stoneWarm, material = M.Limestone })
	local n = 7
	for i = 1, n do
		local z = pz - half + (i - 0.5) * width / n
		Kit.part(parent, { name = "Voussoir", size = Vector3.new(2.05, 1, width / n), cf = CFrame.new(bx, 11.2, z), color = if i % 2 == 0 then Palette.basalt else Palette.stoneLight, material = if i % 2 == 0 then M.Basalt else M.Limestone, shadow = false, collide = false })
	end
	for _, dz in { -half + 1.4, half - 1.4 } do
		Props.lantern(parent, Kit.faceFrame(Vector3.new(bx - sign * 1, 9.6, pz + dz), Vector3.new(-sign, 0, 0)), 14)
	end
	Props2.sign(parent, Kit.faceFrame(Vector3.new(bx - sign * 1.05, 8.6, pz), Vector3.new(-sign, 0, 0)), 9, boardText, nil, color)
	return pad
end

-- The Play hall on the square's west side: walking in opens the Play panel (story, endless,
-- event) on the client. The old per-mode portals were folded into it.
local function playHall(map: Instance)
	local m = Kit.model(map, "PlayHall")
	local pad = archway(m, -19, 8, 12, ar("play.hall"), Palette.fabricRed)
	CollectionService:AddTag(pad, "PlayGate")
end

-- A string of paper lanterns from `a` to `b`: a cord and `n` glowing lanterns hanging off it.
local LANTERN_COLORS = { Color3.fromHex("#E8A33A"), Color3.fromHex("#C0392B"), Color3.fromHex("#2E8B87"), Color3.fromHex("#F2D16B") }
local function lanternString(m: Model, a: Vector3, b: Vector3, n: number)
	local mid = (a + b) / 2
	Kit.part(m, { name = "Cord", size = Vector3.new(0.06, 0.06, (b - a).Magnitude), cf = CFrame.lookAt(mid, b), color = Palette.ink, material = M.Fabric, collide = false, shadow = false })
	for i = 1, n do
		local pos = a:Lerp(b, i / (n + 1)) - Vector3.new(0, 0.55, 0)
		Kit.part(m, { name = "Hook", size = Vector3.new(0.05, 0.5, 0.05), cf = CFrame.new(pos + Vector3.new(0, 0.3, 0)), color = Palette.ink, material = M.Fabric, collide = false, shadow = false })
		Kit.ball(m, "PaperLantern", pos, 0.7, LANTERN_COLORS[(i - 1) % #LANTERN_COLORS + 1], M.Neon, false)
	end
end

-- The running event, or in Studio the one the Workspace attribute `HarnessEvent` names (set it in Edit
-- before Play: the corner is built when the world is).
local function runningEvent(): string?
	if RunService:IsStudio() then
		local h = Workspace:GetAttribute("HarnessEvent")
		if type(h) == "string" and (Events :: any)[h] then
			return h
		end
	end
	return EventLogic.active(Events :: any, os.time())[1]
end

-- The event corner on the square's east side, mirroring the Play hall: built only while an event
-- runs (Config/Events). Walking in opens Play → Event. Dressed for its event: the olive harvest has
-- young olive trees, crates of olives and oil jars; Lantern Nights (LP-D12) strings of paper lanterns,
-- a brass lantern on each pier and a low table with a tray of sweets.
local function eventCorner(map: Instance)
	local id = runningEvent()
	if not id then
		return
	end
	local def = (Events :: any)[id]
	local m = Kit.model(map, "EventCorner")
	local pad = archway(m, 19, 8, 12, ar(def.nameKey), Color3.fromHex(if id == "ramadan" then "#6B3A7A" else "#2F7D6B"))
	pad:SetAttribute("Tab", "event")
	CollectionService:AddTag(pad, "PlayGate")
	if id == "ramadan" then
		lanternString(m, Vector3.new(19, 10.5, 1.4), Vector3.new(19, 10.5, 14.6), 6)
		lanternString(m, Vector3.new(14.5, 12.2, 1), Vector3.new(16.5, 12.8, 15), 5) -- above the arch's sign
		Props.lantern(m, Kit.faceFrame(Vector3.new(20.4, 7.2, 1.6), Vector3.new(-1, 0, 0)), 14)
		Props.lantern(m, Kit.faceFrame(Vector3.new(20.4, 7.2, 14.4), Vector3.new(-1, 0, 0)), 14)
		Props2.coffeeTable(m, CFrame.new(14.6, 0, 2.2), false)
		Props.copperPot(m, Vector3.new(12.7, 0, 2.5), 0.8)
		return
	end
	local OLIVE = Color3.fromHex("#55602F")
	Props.tree(m, Vector3.new(14.5, 0, 15.5), OLIVE, 0.75)
	Props.crate(m, CFrame.new(16, 0, 1.2) * CFrame.Angles(0, math.rad(12), 0), OLIVE)
	Props.crate(m, CFrame.new(17.6, 0, 0.6) * CFrame.Angles(0, math.rad(-8), 0), Color3.fromHex("#2B2F1A"))
	Props.copperPot(m, Vector3.new(13.6, 0, 1.4), 1.1)
	Props.copperPot(m, Vector3.new(12.7, 0, 2.5), 0.8)
end

-- The coffee house on the square's west side (x -40..-24, z -26..0): open ground floor behind
-- two columns, benches along the walls, low tables with tea and backgammon, a samovar.
local function coffeeHouse(map: Instance)
	local m = Kit.model(map, "CoffeeHouse")
	Kit.box(m, "Back", -40, 0, -26, -37, 21, 0, Palette.stoneLight, M.Limestone)
	Kit.box(m, "SideS", -37, 0, -26, -24, 12, -25, Palette.stoneLight, M.Limestone)
	Kit.box(m, "SideN", -37, 0, -1, -24, 12, 0, Palette.stoneLight, M.Limestone)
	Kit.box(m, "Upper", -37, 12, -26, -24, 21, 0, Palette.plaster, M.Plaster)
	Kit.box(m, "Parapet", -40, 21, -26, -24, 22.2, 0, Palette.stoneWarm, M.Limestone)
	Kit.box(m, "Floor", -37, 0, -25, -24, 0.3, -1, Palette.stoneWarm, M.Limestone).CastShadow = false
	Kit.box(m, "Lintel", -24.6, 11, -25, -23.8, 12.2, -1, Palette.woodDark, M.Wood)
	for _, z in { -17.3, -8.7 } do
		Kit.column(m, "Column", Vector3.new(-24.2, 0, z), 11, 1.4, Palette.stoneLight, M.Limestone)
		Kit.part(m, { name = "Capital", size = Vector3.new(1.9, 0.6, 1.9), cf = CFrame.new(-24.2, 10.7, z), color = Palette.basalt, material = M.Basalt, shadow = false, collide = false })
	end
	for _, y in { 3, 5.5, 8 } do
		Kit.box(m, "AblaqS", -24.15, y, -26, -23.95, y + 0.8, -25, Palette.basalt, M.Basalt).CastShadow = false
		Kit.box(m, "AblaqN", -24.15, y, -1, -23.95, y + 0.8, 0, Palette.basalt, M.Basalt).CastShadow = false
	end
	-- Upper windows with pots
	for _, z in { -20, -13, -6 } do
		Props.window(m, Kit.faceFrame(Vector3.new(-24, 16, z), Vector3.new(1, 0, 0)), 2.2, 3)
	end
	Props.pot(m, Vector3.new(-24.35, 14.35, -20), "jasmine", 0.55)
	-- Benches along the back and the south wall, tables in front of them
	Props2.dikkeh(m, CFrame.new(-35.8, 0.3, -9.5) * CFrame.Angles(0, math.rad(90), 0), 13)
	Props2.dikkeh(m, CFrame.new(-30, 0.3, -23.8), 10)
	Props2.coffeeTable(m, CFrame.new(-32.5, 0.3, -19), true)
	Props2.coffeeTable(m, CFrame.new(-32.5, 0.3, -12), false)
	Props2.coffeeTable(m, CFrame.new(-32.5, 0.3, -5), true)
	Props2.samovar(m, Vector3.new(-35.5, 0.3, -3))
	Props.copperPot(m, Vector3.new(-26, 0.3, -24), 0.9)
	Props.lantern(m, Kit.faceFrame(Vector3.new(-37, 9, -13), Vector3.new(1, 0, 0)), 16)
	Props.lantern(m, Kit.faceFrame(Vector3.new(-24.2, 9.5, -13), Vector3.new(1, 0, 0)), 14)
	Props.cat(m, CFrame.new(-26.5, 0.3, -2.5) * CFrame.Angles(0, math.rad(140), 0), Color3.fromHex("#DADADA"))
	-- Striped awning over the opening
	Kit.part(m, { name = "Awning", size = Vector3.new(5, 0.3, 22), cf = CFrame.new(-22, 11, -13) * CFrame.Angles(0, 0, math.rad(-16)), color = Palette.vine, material = M.Fabric })
	for _, z in { -20, -13, -6 } do
		Kit.part(m, { name = "AwningStripe", size = Vector3.new(5.02, 0.32, 1), cf = CFrame.new(-22, 11, z) * CFrame.Angles(0, 0, math.rad(-16)), color = Palette.jasmine, material = M.Fabric, collide = false, shadow = false })
	end
	Props2.sign(m, Kit.faceFrame(Vector3.new(-23.7, 12.9, -13), Vector3.new(1, 0, 0)), 9, ar("sign.coffee"), "Qahwat al-Hara", Palette.vine)
	-- The stair door at the back to the Hakawati's room upstairs (the AFK chamber): walking onto
	-- the mat opens the room's panel on the client (AfkController).
	Props.door(m, Kit.faceFrame(Vector3.new(-37, 0.3, -20.5), Vector3.new(1, 0, 0)), 3.2, 7, Palette.woodDark)
	Props2.sign(m, Kit.faceFrame(Vector3.new(-36.9, 9.4, -20.5), Vector3.new(1, 0, 0)), 5, ar("afk.room"), "Majlis al-Hakawati", Palette.fabricRed)
	local mat = Kit.part(m, { name = "AfkMat", size = Vector3.new(3, 0.12, 3.6), cf = CFrame.new(-35.3, 0.36, -20.5), color = Palette.fabricRed, material = M.Fabric, shadow = false })
	Kit.part(m, { name = "AfkMatBorder", size = Vector3.new(2.4, 0.13, 3), cf = CFrame.new(-35.3, 0.365, -20.5), color = Palette.fabricIndigo, material = M.Fabric, collide = false, shadow = false })
	CollectionService:AddTag(mat, "AfkGate")
end

-- The barber on the lane's east side (x 8..24, z 24..48): open front like the tailor's.
local function barber(map: Instance)
	local m = Kit.model(map, "Barber")
	Kit.box(m, "Back", 16, 0, 24, 24, 23, 48, Palette.stoneLight, M.Limestone)
	Kit.box(m, "Roof", 8, 12, 24, 16, 23, 48, Palette.plaster, M.Plaster)
	Kit.box(m, "Parapet", 8, 23, 24, 24, 24.2, 48, Palette.stoneWarm, M.Limestone)
	Kit.box(m, "WallN", 8, 0, 47, 16, 12, 48, Palette.stoneLight, M.Limestone)
	Kit.box(m, "WallS", 8, 0, 24, 16, 12, 25, Palette.stoneLight, M.Limestone)
	Kit.box(m, "Lintel", 7.8, 11, 24, 8.6, 12.2, 48, Palette.woodDark, M.Wood)
	for _, y in { 3, 5.5, 8 } do
		Kit.box(m, "AblaqN", 7.95, y, 47, 8.15, y + 0.8, 48, Palette.basalt, M.Basalt).CastShadow = false
		Kit.box(m, "AblaqS", 7.95, y, 24, 8.15, y + 0.8, 25, Palette.basalt, M.Basalt).CastShadow = false
	end
	Kit.box(m, "Floor", 8, 0, 25, 16, 0.3, 47, Palette.stoneWarm, M.Marble).CastShadow = false
	Props2.barberChair(m, CFrame.new(12, 0.3, 36) * CFrame.Angles(0, math.rad(-90), 0))
	Props2.mirror(m, Kit.faceFrame(Vector3.new(16, 6, 36), Vector3.new(-1, 0, 0)), 4, 5)
	Props2.bottleShelf(m, Kit.faceFrame(Vector3.new(16, 7.5, 42), Vector3.new(-1, 0, 0)), 5)
	Props2.bottleShelf(m, Kit.faceFrame(Vector3.new(16, 5.5, 42), Vector3.new(-1, 0, 0)), 5)
	Kit.box(m, "Basin", 14, 0.3, 28, 15.8, 3, 31, Palette.woodDark, M.Wood)
	Kit.disc(m, "Bowl", Vector3.new(14.9, 3.1, 29.5), 1.6, 0.3, Palette.copper, M.Metal, false)
	Props2.dikkeh(m, CFrame.new(12, 0.3, 45.8), 7)
	Props.lantern(m, Kit.faceFrame(Vector3.new(15.9, 9.5, 36), Vector3.new(-1, 0, 0)), 14)
	for _, z in { 30, 42 } do
		Props.window(m, Kit.faceFrame(Vector3.new(8, 16.5, z), Vector3.new(-1, 0, 0)), 2.2, 3)
	end
	Props.mashrabiya(m, Kit.faceFrame(Vector3.new(8, 13.4, 36), Vector3.new(-1, 0, 0)), 6, 5, 2.2)
	Kit.part(m, { name = "Awning", size = Vector3.new(5, 0.3, 22), cf = CFrame.new(6, 11, 36) * CFrame.Angles(0, 0, math.rad(18)), color = Palette.fabricIndigo, material = M.Fabric })
	for _, z in { 28, 36, 44 } do
		Kit.part(m, { name = "AwningStripe", size = Vector3.new(5.02, 0.32, 1), cf = CFrame.new(6, 11, z) * CFrame.Angles(0, 0, math.rad(18)), color = Palette.jasmine, material = M.Fabric, collide = false, shadow = false })
	end
	Props2.sign(m, Kit.faceFrame(Vector3.new(7.7, 12.9, 36), Vector3.new(-1, 0, 0)), 8, ar("sign.barber"), "Hallaq al-Hara", Palette.fabricIndigo)
end

local function signs(map: Instance)
	local m = Kit.model(map, "Signs")
	Props2.sign(m, Kit.faceFrame(Vector3.new(-7.7, 12.9, 60), Vector3.new(1, 0, 0)), 9, ar("sign.bakery"), "Furn Abu Baseer", Palette.fabricIndigo)
	Props2.sign(m, Kit.faceFrame(Vector3.new(7.7, 12.9, 56), Vector3.new(-1, 0, 0)), 8, ar("sign.tailor"), "Khayyat Khalil", Palette.fabricRed)
	Props2.sign(m, Kit.faceFrame(Vector3.new(-23.7, 11.5, 10), Vector3.new(1, 0, 0)), 9, ar("sign.spice"), "Attara al-Hajj Rashid", Palette.vine)
	-- Notice board by the spawn: where codes and news are pinned
	local f = Kit.faceFrame(Vector3.new(-7.9, 5.2, 74), Vector3.new(1, 0, 0))
	Kit.part(m, { name = "Board", size = Vector3.new(5, 3.4, 0.3), cf = f * CFrame.new(0, 0, -0.15), color = Palette.woodDark, material = M.Wood, collide = false, shadow = false })
	local paper = Kit.part(m, { name = "Paper", size = Vector3.new(4.4, 2.8, 0.1), cf = f * CFrame.new(0, 0, -0.36), color = Palette.jasmine, material = M.SmoothPlastic, collide = false, shadow = false })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(440, 280)
	gui.LightInfluence = 0.6
	gui.Parent = paper
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Text = ar("sign.board") .. "\n" .. "YASMIN · HARA · SHABRIYEH"
	label.TextColor3 = Palette.ink
	label.TextScaled = true
	label.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
	label.Parent = gui
end

-- Nameplates on both faces of the gate, the watchman's stool and lantern by the wicket, and the pickle cart
-- against the west wall (S1-A08; its "Look" lines are Story.cart).
local function gateDressing(map: Instance)
	local m = Kit.model(map, "GateDressing")
	Props2.nameplate(m, Kit.faceFrame(Vector3.new(0, 17.4, 87.9), Vector3.new(0, 0, -1)), 9, ar("sign.lane"))
	Props2.nameplate(m, Kit.faceFrame(Vector3.new(0, 17.4, 94.1), Vector3.new(0, 0, 1)), 9, ar("sign.lane"))
	Props2.stool(m, Vector3.new(6.6, 0, 82))
	Props.copperPot(m, Vector3.new(7.3, 0, 83.6), 0.7)
	Props.pot(m, Vector3.new(-6.8, 0.35, 86), "jasmine", 0.9)
	local cart = Props.pickleCart(m, CFrame.new(Story.cart.at[1], 0, Story.cart.at[2]))
	CollectionService:AddTag(cart, Story.cart.tag)
end

function Extras.build(map: Instance)
	playHall(map)
	eventCorner(map)
	coffeeHouse(map)
	barber(map)
	signs(map)
	gateDressing(map)
end

return Extras
