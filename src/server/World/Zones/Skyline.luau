--!strict
-- Distant city around the lane (outside the play area, no collision): neighbouring roofs, domes, a
-- minaret and cypresses, so the lane sits inside an old city instead of floating in the void.
-- Large and few parts; no shadows (cheap on mobile). Softened by the Atmosphere haze.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Palette = require(ReplicatedStorage:WaitForChild("Shared").Config.Palette)
local World = script.Parent.Parent
local Kit = require(World.Kit)

local M = Kit.M

local Skyline = {}

local function ghost(p: BasePart)
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
end

function Skyline.build(map: Instance)
	local m = Kit.model(map, "Skyline")
	local rng = Kit.rng("skyline")
	-- A ring of rooftops beyond the walls
	local blocks = {
		{ -80, -60, -50, 100 },
		{ 45, 80, -50, 100 },
		{ -80, 80, -110, -66 },
		{ -60, 60, 100, 130 },
	}
	for _, b in blocks do
		local x0, x1, z0, z1 = b[1], b[2], b[3], b[4]
		local nx = math.max(1, math.floor((x1 - x0) / 22))
		local nz = math.max(1, math.floor((z1 - z0) / 22))
		for i = 0, nx - 1 do
			for j = 0, nz - 1 do
				local h = rng:NextNumber(16, 30)
				local bx0 = x0 + i * (x1 - x0) / nx
				local bz0 = z0 + j * (z1 - z0) / nz
				ghost(Kit.box(m, "Roofs", bx0, -1, bz0, bx0 + (x1 - x0) / nx - 1, h, bz0 + (z1 - z0) / nz - 1, Kit.tint(Palette.plaster, rng, 0.08), M.Plaster))
			end
		end
	end
	-- Domes
	for _, d in { { 55, 30, -80, 18 }, { -62, 24, 60, 12 }, { 30, 22, 112, 10 } } do
		local x, drum, z, r = d[1], d[2], d[3], d[4]
		ghost(Kit.column(m, "Drum", Vector3.new(x, 0, z), drum, r * 2, Palette.stoneLight, M.Limestone))
		ghost(Kit.ball(m, "Dome", Vector3.new(x, drum, z), r * 2, Color3.fromHex("#7F8E8C"), M.Slate))
		ghost(Kit.column(m, "Finial", Vector3.new(x, drum + r - 0.5, z), 4, 0.6, Palette.copper, M.Metal))
	end
	-- Minaret
	local mx, mz = -48, -92
	ghost(Kit.column(m, "MinaretShaft", Vector3.new(mx, 0, mz), 58, 7, Palette.stoneLight, M.Limestone))
	for _, y in { 18, 30, 42 } do
		ghost(Kit.column(m, "MinaretBand", Vector3.new(mx, y, mz), 1.2, 7.4, Palette.basalt, M.Basalt))
	end
	ghost(Kit.column(m, "Balcony", Vector3.new(mx, 50, mz), 1.2, 10, Palette.stoneWarm, M.Limestone))
	ghost(Kit.column(m, "Lantern", Vector3.new(mx, 58, mz), 7, 4.5, Palette.stoneLight, M.Limestone))
	ghost(Kit.ball(m, "Cap", Vector3.new(mx, 65.5, mz), 5, Color3.fromHex("#5E7D3A"), M.Slate))
	ghost(Kit.column(m, "Spire", Vector3.new(mx, 67.5, mz), 4, 0.5, Palette.copper, M.Metal))
	-- Cypresses
	for _, c in { { -56, -60 }, { -54, 70 }, { 52, 60 }, { 50, -40 }, { -30, 108 }, { 38, -84 } } do
		for k = 0, 2 do
			ghost(Kit.ball(m, "Cypress", Vector3.new(c[1], 22 + k * 5, c[2]), 6 - k * 1.5, Color3.fromHex("#2F4A2A"), M.Grass))
		end
	end
end

return Skyline
