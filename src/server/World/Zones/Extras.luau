--!strict
-- Lane extras for the tower-defense update: the mode portals in the square, the coffee house
-- (qahwa) on the square's west side, the barber shop on the lane, painted shop signs, the gate
-- nameplate, the watchman's corner and the notice board.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Palette = require(Shared.Config.Palette)
local Modes = require(Shared.Config.Modes)
local Strings = require(Shared.Config.Strings)
local World = script.Parent.Parent
local Kit = require(World.Kit)
local Props = require(World.Props)
local Props2 = require(World.Props2)

local M = Kit.M

local Extras = {}

local function ar(key: string): string
	return Strings.ar[key] or key
end

local function portals(map: Instance)
	local m = Kit.model(map, "Portals")
	for modeId, mode in Modes :: { [string]: any } do
		local px, pz = mode.portal[1], mode.portal[2]
		local p = Kit.model(m, "Portal_" .. modeId)
		local pad = Kit.part(p, { name = "Pad", size = Vector3.new(8, 0.4, 8), cf = CFrame.new(px, 0.2, pz), color = if mode.kind == "infinite" then Palette.fabricIndigo else Palette.tile, material = M.CeramicTiles })
		pad:SetAttribute("ModeId", modeId)
		pad:SetAttribute("Order", mode.order)
		CollectionService:AddTag(pad, "Portal")
		Kit.part(p, { name = "Inlay", size = Vector3.new(6, 0.42, 6), cf = CFrame.new(px, 0.2, pz) * CFrame.Angles(0, math.rad(45), 0), color = Palette.jasmine, material = M.CeramicTiles, shadow = false, collide = false })
		-- Arch on the wall side of the pad, opening toward the fountain
		local sign = if px < 0 then -1 else 1
		local bx = px + sign * 3.6
		for _, dz in { -4, 4 } do
			Kit.part(p, { name = "Pillar", size = Vector3.new(1.4, 9, 1.4), cf = CFrame.new(bx, 4.5, pz + dz), color = Palette.stoneLight, material = M.Limestone })
			for _, y in { 2, 4.5, 7 } do
				Kit.part(p, { name = "Band", size = Vector3.new(1.45, 0.6, 1.45), cf = CFrame.new(bx, y, pz + dz), color = Palette.basalt, material = M.Basalt, shadow = false, collide = false })
			end
		end
		Kit.part(p, { name = "Lintel", size = Vector3.new(1.8, 1.6, 10.4), cf = CFrame.new(bx, 9.8, pz), color = Palette.stoneWarm, material = M.Limestone })
		for i = 1, 5 do
			local z = pz - 4 + (i - 0.5) * 8 / 5
			Kit.part(p, { name = "Voussoir", size = Vector3.new(1.85, 0.9, 8 / 5), cf = CFrame.new(bx, 9.1, z), color = if i % 2 == 0 then Palette.basalt else Palette.stoneLight, material = if i % 2 == 0 then M.Basalt else M.Limestone, shadow = false, collide = false })
		end
		Props.lantern(p, Kit.faceFrame(Vector3.new(bx - sign * 0.9, 8.2, pz), Vector3.new(-sign, 0, 0)), 12)
		-- Hanging board with the mode's Arabic name (the client adds a localized billboard too)
		Props2.sign(p, Kit.faceFrame(Vector3.new(bx - sign * 0.95, 7.2, pz), Vector3.new(-sign, 0, 0)), 7, ar(mode.nameKey), nil, if mode.kind == "infinite" then Palette.fabricIndigo else Palette.fabricRed)
	end
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
	Props2.dikkeh(m, CFrame.new(-35.8, 0.3, -13) * CFrame.Angles(0, math.rad(90), 0), 20)
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
	Props2.sign(m, Kit.faceFrame(Vector3.new(-7.7, 12.9, 60), Vector3.new(1, 0, 0)), 9, ar("sign.bakery"), "Furn Abu Nadim", Palette.fabricIndigo)
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

-- Nameplates on both faces of the gate, the watchman's stool and lantern by the wicket.
local function gateDressing(map: Instance)
	local m = Kit.model(map, "GateDressing")
	Props2.nameplate(m, Kit.faceFrame(Vector3.new(0, 17.4, 87.9), Vector3.new(0, 0, -1)), 9, ar("sign.lane"))
	Props2.nameplate(m, Kit.faceFrame(Vector3.new(0, 17.4, 94.1), Vector3.new(0, 0, 1)), 9, ar("sign.lane"))
	Props2.stool(m, Vector3.new(6.6, 0, 82))
	Props.copperPot(m, Vector3.new(7.3, 0, 83.6), 0.7)
	Props.pot(m, Vector3.new(-6.8, 0.35, 86), "jasmine", 0.9)
end

function Extras.build(map: Instance)
	portals(map)
	coffeeHouse(map)
	barber(map)
	signs(map)
	gateDressing(map)
end

return Extras
