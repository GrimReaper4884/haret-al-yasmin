--!strict
-- The gendarmerie post (makhfar) outside the gate (LOOK_AND_PLAY_PLAN §4.1, LP-D06): west of the orchard
-- road, a walled yard (x -42..-16, z 98..122) open to the road: the stone post building with barred
-- windows at its back facing the road, the kit's police_post sentry box at its mouth, a flag pole with a
-- plain pennant, two straw practice dummies in kepis, and a "wanted" poster of Al-Adashari (the secret
-- unit's tease). Abu Jawdan and
-- Corporal Houri stand in the yard. Built into `Zone_post` by WorldService when Config/LaneZones marks
-- it built; it is laid out together with the orchard road (both open the gate's outer wall).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Palette = require(Shared.Config.Palette)
local Strings = require(Shared.Config.Strings)
local World = script.Parent.Parent
local Kit = require(World.Kit)
local Props = require(World.Props)
local Props2 = require(World.Props2)
local KitLayout = require(World.KitLayout)
local Facade = require(World.Facade)

local M = Kit.M

local Post = {}

local WALL_H = 16
local KEPI = Color3.fromHex("#2F3E6B")
local STRAW = Color3.fromHex("#D9B56A")
local PAPER = Color3.fromHex("#EFE3C6")

local function ar(key: string): string
	return Strings.ar[key] or key
end

local function deco(p: BasePart): BasePart
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	return p
end

-- A straw practice dummy on a post, a kepi on its head, facing +X (the road).
local function dummy(m: Model, x: number, z: number)
	Kit.column(m, "DummyPost", Vector3.new(x, 0, z), 3.2, 0.3, Palette.woodDark, M.Wood, true)
	Kit.part(m, { name = "DummyBody", size = Vector3.new(1.2, 2.2, 1.6), cf = CFrame.new(x, 3.4, z), color = STRAW, material = M.Fabric, collide = false })
	deco(Kit.part(m, { name = "DummyArms", size = Vector3.new(0.4, 0.4, 3.2), cf = CFrame.new(x, 4, z), color = Palette.woodDark, material = M.Wood }))
	Kit.ball(m, "DummyHead", Vector3.new(x, 5.1, z), 1.2, STRAW, M.Fabric, false)
	Kit.column(m, "Kepi", Vector3.new(x, 5.5, z), 0.6, 1.1, KEPI, M.Fabric, false)
	deco(Kit.part(m, { name = "KepiPeak", size = Vector3.new(0.5, 0.08, 0.8), cf = CFrame.new(x + 0.55, 5.55, z), color = Palette.ink, material = M.SmoothPlastic }))
	deco(Kit.part(m, { name = "Belt", size = Vector3.new(1.25, 0.25, 1.65), cf = CFrame.new(x, 2.8, z), color = Palette.woodDark, material = M.Fabric }))
end

function Post.build(zone: Model)
	-- Yard floor and walls (the south side is the gate's outer wall, west of x -30 it is the yard's own)
	Kit.box(zone, "Yard", -42, -1, 98, -16, 0, 122, Color3.fromHex("#CDB892"), M.Ground)
	Kit.box(zone, "WallW", -44, 0, 96, -42, WALL_H, 124, Palette.stoneWarm, M.Limestone)
	Kit.box(zone, "WallN", -44, 0, 122, -16, WALL_H, 124, Palette.stoneWarm, M.Limestone)
	Kit.box(zone, "WallS", -44, 0, 96, -30, WALL_H, 98, Palette.stoneWarm, M.Limestone)
	deco(Kit.box(zone, "Cobbles", -18, 0, 106, -16, 0.06, 114, Palette.stoneWarm, M.Cobblestone)) -- the yard's mouth on the road

	-- The post building at the back of the yard, facing the road (+X), and the checkpoint's sentry box
	-- (the kit's police_post) at the yard's mouth
	Facade.build(zone, "Makhfar", -42, 98, -34, 122, 14, "X", 1, { doorAt = 111, lantern = 106, jetty = false, groundHeight = 9 })
	KitLayout.place(zone, "police_post", CFrame.new(-19.5, 0, 117) * CFrame.Angles(0, math.rad(-90), 0), 0.7)
	
	-- Flag pole with a plain pennant (no real-world flag)
	Kit.column(zone, "FlagBase", Vector3.new(-24, 0, 119), 0.8, 2, Palette.stoneLight, M.Limestone, true)
	Kit.column(zone, "FlagPole", Vector3.new(-24, 0.8, 119), 14, 0.3, Palette.ink, M.Metal, false)
	deco(Kit.part(zone, { name = "Pennant", size = Vector3.new(0.08, 1.6, 3), cf = CFrame.new(-24, 13.6, 120.6), color = Palette.basalt, material = M.Fabric }))
	deco(Kit.part(zone, { name = "PennantStripe", size = Vector3.new(0.1, 0.4, 3), cf = CFrame.new(-24, 13.6, 120.6), color = Palette.copper, material = M.Fabric }))

	dummy(zone, -26, 101.5)
	dummy(zone, -22.5, 101.5)

	-- The wanted poster on the yard's north wall, and a bench beside the door
	Props2.sign(zone, Kit.faceFrame(Vector3.new(-30, 6.2, 122), Vector3.new(0, 0, -1)), 4.4, ar("sign.wanted"), "Wanted · Al-Adashari", PAPER, Palette.ink)
	Props.bench(zone, CFrame.new(-36, 0, 120.6))
	KitLayout.place(zone, "sack_pile", CFrame.new(-40, 0, 100.4), 0.7)
end

return Post
