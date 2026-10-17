--!strict
-- The Hakawati's room (the AFK chamber, docs/AFK_CHAMBER.md): an upstairs room of the coffee
-- house, built off-map at Config/Afk.ORIGIN like the arenas. A closed room under a painted Damascene
-- ceiling: cushioned benches with seats on three walls, two rows of stools, and the storyteller's
-- raised chair on a dais at the north end. Local coordinates: interior x -18..18, z -13..13, the
-- hakawati faces -Z. Returns the model and the seats (front rows first).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Palette = require(Shared.Config.Palette)
local Strings = require(Shared.Config.Strings)
local World = script.Parent
local Kit = require(World.Kit)
local Props = require(World.Props)
local Props2 = require(World.Props2)

local M = Kit.M

local AfkRoom = {}

AfkRoom.HALF_X = 18
AfkRoom.HALF_Z = 13
AfkRoom.HEIGHT = 15
AfkRoom.SEAT_TAG = "AfkSeat"
AfkRoom.EXIT_TAG = "AfkExit"

local BRASS = Color3.fromHex("#C9A13B")
local CEILING = Color3.fromHex("#3B2A1C")

local function seat(parent: Instance, cf: CFrame, order: number): Seat
	local s = Instance.new("Seat")
	s.Name = "Seat"
	s.Anchored = true
	s.Size = Vector3.new(1.8, 0.4, 1.8)
	s.CFrame = cf
	s.Transparency = 1
	s.CanCollide = false
	s.CastShadow = false
	s.CanTouch = false -- the server seats players itself (no seat-snatching by walking over them)
	s:SetAttribute("Order", order)
	CollectionService:AddTag(s, AfkRoom.SEAT_TAG)
	s.Parent = parent
	return s
end

-- A cushioned bench along a wall with `n` seats; `cf` at ground level, bench along local X, the
-- sitter facing local -Z.
local function bench(
	parent: Instance,
	cf: CFrame,
	length: number,
	n: number,
	seats: { Seat },
	order: number
): number
	Props2.dikkeh(parent, cf * CFrame.Angles(0, math.rad(180), 0), length)
	for i = 1, n do
		local x = -length / 2 + (i - 0.5) * length / n
		table.insert(seats, seat(parent, cf * CFrame.new(x, 1.75, 0.2), order))
		order += 1
	end
	return order
end

local function stool(parent: Instance, cf: CFrame, seats: { Seat }, order: number)
	Kit.disc(
		parent,
		"StoolTop",
		(cf * CFrame.new(0, 1.2, 0)).Position,
		1.6,
		0.25,
		Palette.fabricRed,
		M.Fabric,
		true
	)
	Kit.part(
		parent,
		{
			name = "StoolBase",
			size = Vector3.new(1.1, 1.1, 1.1),
			cf = cf * CFrame.new(0, 0.55, 0),
			color = Palette.woodDark,
			material = M.Wood,
			collide = false,
			shadow = false,
		}
	)
	table.insert(seats, seat(parent, cf * CFrame.new(0, 1.55, 0), order))
end

-- The painted wooden ceiling ('ajami): dark boards, gilded beams and a coffer grid.
local function ceiling(m: Model, o: CFrame)
	local hx, hz, h = AfkRoom.HALF_X, AfkRoom.HALF_Z, AfkRoom.HEIGHT
	Kit.part(
		m,
		{
			name = "Ceiling",
			size = Vector3.new(hx * 2 + 2, 1, hz * 2 + 2),
			cf = o * CFrame.new(0, h + 0.5, 0),
			color = CEILING,
			material = M.Wood,
		}
	)
	for x = -hx + 4, hx - 4, 6 do
		Kit.part(
			m,
			{
				name = "Beam",
				size = Vector3.new(0.9, 0.8, hz * 2),
				cf = o * CFrame.new(x, h - 0.4, 0),
				color = Palette.woodDark,
				material = M.Wood,
				shadow = false,
			}
		)
		Kit.part(
			m,
			{
				name = "BeamGilt",
				size = Vector3.new(0.95, 0.12, hz * 2),
				cf = o * CFrame.new(x, h - 0.82, 0),
				color = BRASS,
				material = M.Metal,
				collide = false,
				shadow = false,
			}
		)
	end
	for z = -hz + 4.5, hz - 4.5, 6 do
		Kit.part(
			m,
			{
				name = "Coffer",
				size = Vector3.new(hx * 2, 0.4, 0.5),
				cf = o * CFrame.new(0, h - 0.2, z),
				color = Palette.fabricIndigo,
				material = M.Wood,
				collide = false,
				shadow = false,
			}
		)
	end
	-- A brass chandelier over the stools
	Kit.part(
		m,
		{
			name = "ChandelierChain",
			size = Vector3.new(0.1, 3, 0.1),
			cf = o * CFrame.new(0, h - 1.5, -1),
			color = Palette.ink,
			material = M.Metal,
			collide = false,
			shadow = false,
		}
	)
	local ring =
		Kit.disc(m, "Chandelier", (o * CFrame.new(0, h - 3.2, -1)).Position, 3.2, 0.3, BRASS, M.Metal, false)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 190, 115)
	light.Range = 26
	light.Brightness = 1.4
	light.Shadows = false
	light.Parent = ring
	for k = 0, 5 do
		local a = k * math.pi / 3
		Kit.part(
			m,
			{
				name = "Candle",
				size = Vector3.new(0.25, 0.5, 0.25),
				cf = o * CFrame.new(math.cos(a) * 1.4, h - 2.85, -1 + math.sin(a) * 1.4),
				color = Color3.fromHex("#FFE3A3"),
				material = M.Neon,
				collide = false,
				shadow = false,
			}
		)
	end
end

local function walls(m: Model, o: CFrame)
	local hx, hz, h = AfkRoom.HALF_X, AfkRoom.HALF_Z, AfkRoom.HEIGHT
	Kit.part(
		m,
		{
			name = "Floor",
			size = Vector3.new(hx * 2 + 2, 1, hz * 2 + 2),
			cf = o * CFrame.new(0, -0.5, 0),
			color = Palette.stoneWarm,
			material = M.Limestone,
		}
	)
	for _, w in
		{
			{ 0, hz + 0.5, hx * 2 + 2, 1 },
			{ 0, -hz - 0.5, hx * 2 + 2, 1 },
			{ hx + 0.5, 0, 1, hz * 2 },
			{ -hx - 0.5, 0, 1, hz * 2 },
		}
	do
		Kit.part(
			m,
			{
				name = "Wall",
				size = Vector3.new(w[3], h, w[4]),
				cf = o * CFrame.new(w[1], h / 2, w[2]),
				color = Palette.plaster,
				material = M.Plaster,
			}
		)
		-- Ablaq dado: striped stone courses along the foot of every wall
		local sx = if w[3] > 1 then hx * 2 else 1.06
		local sz = if w[4] > 1 then hz * 2 else 1.06
		for i, y in { 0.6, 1.8, 3.0 } do
			Kit.part(
				m,
				{
					name = "Ablaq",
					size = Vector3.new(sx, 1.2, sz),
					cf = o * CFrame.new(w[1], y, w[2]),
					color = if i % 2 == 0 then Palette.basalt else Palette.stoneLight,
					material = if i % 2 == 0 then M.Basalt else M.Limestone,
					collide = false,
					shadow = false,
				}
			)
		end
	end
	-- Carpets
	Kit.part(
		m,
		{
			name = "Carpet",
			size = Vector3.new(20, 0.06, 13),
			cf = o * CFrame.new(0, 0.03, -2.5),
			color = Palette.fabricRed,
			material = M.Fabric,
			collide = false,
			shadow = false,
		}
	)
	Kit.part(
		m,
		{
			name = "CarpetBorder",
			size = Vector3.new(18.4, 0.07, 11.4),
			cf = o * CFrame.new(0, 0.035, -2.5),
			color = Palette.fabricIndigo,
			material = M.Fabric,
			collide = false,
			shadow = false,
		}
	)
	Kit.part(
		m,
		{
			name = "CarpetField",
			size = Vector3.new(17, 0.08, 10),
			cf = o * CFrame.new(0, 0.04, -2.5),
			color = Color3.fromHex("#8A2A24"),
			material = M.Fabric,
			collide = false,
			shadow = false,
		}
	)
	Kit.part(
		m,
		{
			name = "CarpetMedallion",
			size = Vector3.new(4, 0.09, 4),
			cf = o * CFrame.new(0, 0.045, -2.5) * CFrame.Angles(0, math.rad(45), 0),
			color = BRASS,
			material = M.Fabric,
			collide = false,
			shadow = false,
		}
	)
	-- Latticed windows high on the side walls with moonlight behind
	for _, side in { -1, 1 } do
		for _, z in { -6, 3 } do
			local f = Kit.faceFrame(Vector3.new(side * hx, 10, z), Vector3.new(-side, 0, 0))
			Props.mashrabiya(m, o * f, 4, 3.6, 0.8)
		end
	end
	-- Wall lanterns
	for _, side in { -1, 1 } do
		for _, z in { -9, 0, 8 } do
			Props.lantern(m, o * Kit.faceFrame(Vector3.new(side * hx, 7.5, z), Vector3.new(-side, 0, 0)), 16)
		end
	end
	for _, x in { -9, 9 } do
		Props.lantern(m, o * Kit.faceFrame(Vector3.new(x, 7.5, -hz), Vector3.new(0, 0, 1)), 16)
	end
end

-- The storyteller's dais: a raised platform, a high carved chair, a reading stand with the old
-- book of tales, a brass tray of tea, and the board naming the room.
local function dais(m: Model, o: CFrame)
	local hz = AfkRoom.HALF_Z
	Kit.part(
		m,
		{
			name = "Dais",
			size = Vector3.new(12, 1.2, 5),
			cf = o * CFrame.new(0, 0.6, hz - 2.5),
			color = Palette.wood,
			material = M.WoodPlanks,
		}
	)
	Kit.part(
		m,
		{
			name = "DaisStep",
			size = Vector3.new(6, 0.6, 1.2),
			cf = o * CFrame.new(0, 0.3, hz - 5.6),
			color = Palette.woodDark,
			material = M.Wood,
		}
	)
	Kit.part(
		m,
		{
			name = "DaisRug",
			size = Vector3.new(10, 0.06, 4),
			cf = o * CFrame.new(0, 1.23, hz - 2.5),
			color = Palette.fabricIndigo,
			material = M.Fabric,
			collide = false,
			shadow = false,
		}
	)
	-- The high chair (kursi) behind the storyteller
	Kit.part(
		m,
		{
			name = "ChairBack",
			size = Vector3.new(3.4, 6, 0.5),
			cf = o * CFrame.new(0, 4.2, hz - 0.9),
			color = Palette.woodDark,
			material = M.Wood,
		}
	)
	Kit.part(
		m,
		{
			name = "ChairInlay",
			size = Vector3.new(2.6, 4.6, 0.1),
			cf = o * CFrame.new(0, 4.4, hz - 1.2),
			color = Palette.tile,
			material = M.SmoothPlastic,
			collide = false,
			shadow = false,
		}
	)
	Kit.part(
		m,
		{
			name = "ChairCrest",
			size = Vector3.new(1.2, 1.2, 0.3),
			cf = o * CFrame.new(0, 7.5, hz - 0.9) * CFrame.Angles(0, 0, math.rad(45)),
			color = BRASS,
			material = M.Metal,
			collide = false,
			shadow = false,
		}
	)
	-- Reading stand with the open book
	Kit.part(
		m,
		{
			name = "StandPost",
			size = Vector3.new(0.3, 2.6, 0.3),
			cf = o * CFrame.new(2.6, 2.5, hz - 4),
			color = Palette.woodDark,
			material = M.Wood,
			collide = false,
			shadow = false,
		}
	)
	Kit.part(
		m,
		{
			name = "StandTop",
			size = Vector3.new(1.6, 0.15, 1.1),
			cf = o * CFrame.new(2.6, 3.85, hz - 4) * CFrame.Angles(math.rad(-25), 0, 0),
			color = Palette.wood,
			material = M.Wood,
			collide = false,
			shadow = false,
		}
	)
	Kit.part(
		m,
		{
			name = "Book",
			size = Vector3.new(1.4, 0.12, 0.95),
			cf = o * CFrame.new(2.6, 3.97, hz - 4.05) * CFrame.Angles(math.rad(-25), 0, 0),
			color = Palette.jasmine,
			material = M.SmoothPlastic,
			collide = false,
			shadow = false,
		}
	)
	Props2.coffeeTable(m, o * CFrame.new(-3.2, 1.2, hz - 3.6), false)
	Props2.samovar(m, (o * CFrame.new(-5, 1.2, hz - 1.4)).Position)
	Props.pot(m, (o * CFrame.new(5.2, 1.2, hz - 1.2)).Position, "jasmine", 0.9)
	Props2.sign(
		m,
		o * Kit.faceFrame(Vector3.new(0, 11.4, hz), Vector3.new(0, 0, -1)),
		11,
		Strings.ar["afk.room"] or "",
		"Majlis al-Hakawati",
		Palette.fabricRed
	)
end

-- The way back: an arched door in the south wall with a prompt (the panel's Leave button does
-- the same). Returns the door's prompt part.
local function exitDoor(m: Model, o: CFrame): BasePart
	local hz = AfkRoom.HALF_Z
	local f = o * Kit.faceFrame(Vector3.new(0, 0, -hz), Vector3.new(0, 0, 1))
	Props.door(m, f, 4, 7.5, Palette.woodDark)
	local anchor = Kit.part(
		m,
		{
			name = "ExitPrompt",
			size = Vector3.new(4, 7, 0.4),
			cf = o * CFrame.new(0, 3.5, -hz + 0.4),
			color = Palette.wood,
			transparency = 1,
			collide = false,
			shadow = false,
		}
	)
	CollectionService:AddTag(anchor, AfkRoom.EXIT_TAG)
	return anchor
end

function AfkRoom.build(parent: Instance, origin: CFrame): (Model, { Seat }, BasePart)
	local m = Kit.model(parent, "HakawatiRoom")
	walls(m, origin)
	ceiling(m, origin)
	dais(m, origin)
	local exit = exitDoor(m, origin)

	local hx, hz = AfkRoom.HALF_X, AfkRoom.HALF_Z
	local seats: { Seat } = {}
	-- Stools facing the dais: two rows of six (the best seats, filled first)
	local order = 1
	for _, z in { 2.5, -1.5 } do
		for i = 1, 6 do
			local x = -8.75 + (i - 1) * 3.5
			stool(m, origin * CFrame.new(x, 0, z) * CFrame.Angles(0, math.pi, 0), seats, order)
			order += 1
		end
	end
	-- Benches on the side walls and the back wall (sitters face into the room)
	order = bench(
		m,
		origin * CFrame.new(-hx + 1.3, 0, -0.5) * CFrame.Angles(0, math.rad(-90), 0),
		18,
		7,
		seats,
		order
	)
	order = bench(
		m,
		origin * CFrame.new(hx - 1.3, 0, -0.5) * CFrame.Angles(0, math.rad(90), 0),
		18,
		7,
		seats,
		order
	)
	order = bench(
		m,
		origin * CFrame.new(-10.5, 0, -hz + 1.3) * CFrame.Angles(0, math.rad(180), 0),
		11,
		4,
		seats,
		order
	)
	bench(
		m,
		origin * CFrame.new(10.5, 0, -hz + 1.3) * CFrame.Angles(0, math.rad(180), 0),
		11,
		4,
		seats,
		order
	)
	table.sort(seats, function(a, b)
		return (a:GetAttribute("Order") :: number) < (b:GetAttribute("Order") :: number)
	end)

	-- Streams as one piece once a player is inside (AfkService requests streaming around the room
	-- before moving anyone in), so lobby phones don't hold it in memory.
	m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	return m, seats, exit
end

return AfkRoom
