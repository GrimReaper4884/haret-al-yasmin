--!strict
-- Old-Damascus style building block: stone ground floor with ablaq courses, plastered upper floor,
-- arched door, grilled windows, latticed bay on corbels, beam ends under the parapet, pots on
-- sills. A seed gives each building its own small variations (tint, window placement, pots).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Palette = require(ReplicatedStorage:WaitForChild("Shared").Config.Palette)
local Kit = require(script.Parent.Kit)
local Props = require(script.Parent.Props)

local M = Kit.M

local Facade = {}

export type Options = {
	door: boolean?, -- default true
	doorAt: number?, -- along-wall coordinate of the door (default: middle)
	jetty: boolean?, -- latticed bay on the upper floor
	beams: boolean?, -- beam ends under the parapet (default true)
	lantern: number?, -- along-wall coordinate for a wall lantern
	pots: boolean?, -- plant pots on window sills (default true)
	groundHeight: number?, -- default 12
}

local PLASTER_TINTS = {
	Palette.plaster,
	Color3.fromHex("#EADFC8"),
	Color3.fromHex("#E3D3B4"),
	Color3.fromHex("#F3E7D3"),
}

function Facade.build(
	parent: Instance,
	name: string,
	x0: number,
	z0: number,
	x1: number,
	z1: number,
	height: number,
	axis: "X" | "Z",
	faceDir: number,
	opts: Options?
): Model
	local o: Options = opts or {}
	local rng = Kit.rng(name)
	local m = Kit.model(parent, name)
	local gh = o.groundHeight or 12

	-- Masses
	Kit.box(m, "Ground", x0, 0, z0, x1, gh, z1, Kit.tint(Palette.stoneLight, rng, 0.04), M.Limestone)
	local plaster = PLASTER_TINTS[rng:NextInteger(1, #PLASTER_TINTS)]
	Kit.box(m, "Upper", x0, gh, z0, x1, height, z1, plaster, M.Plaster)
	Kit.box(m, "Parapet", x0, height, z0, x1, height + 1.2, z1, Palette.stoneWarm, M.Limestone)

	-- Face geometry
	local face = if axis == "X"
		then (if faceDir > 0 then math.max(x0, x1) else math.min(x0, x1))
		else (if faceDir > 0 then math.max(z0, z1) else math.min(z0, z1))
	local lo = if axis == "X" then math.min(z0, z1) else math.min(x0, x1)
	local hi = if axis == "X" then math.max(z0, z1) else math.max(x0, x1)
	local width = hi - lo
	local outward = if axis == "X" then Vector3.new(faceDir, 0, 0) else Vector3.new(0, 0, faceDir)

	local function at(along: number, y: number): CFrame
		local pos = if axis == "X" then Vector3.new(face, y, along) else Vector3.new(along, y, face)
		return Kit.faceFrame(pos, outward)
	end
	local function strip(nm: string, y0: number, y1: number, depth: number, color: Color3, mat: Enum.Material)
		local mid = (lo + hi) / 2
		return Kit.part(m, {
			name = nm,
			size = Vector3.new(width, y1 - y0, depth),
			cf = at(mid, (y0 + y1) / 2) * CFrame.new(0, 0, -depth / 2),
			color = color,
			material = mat,
			shadow = false,
		})
	end

	-- Ablaq courses, plinth and cornice
	strip("Plinth", 0, 1, 0.4, Palette.basalt, M.Basalt)
	for i, y in { 3, 5.5, 8 } do
		strip("Ablaq" .. i, y, y + 0.8, 0.15, Palette.basalt, M.Basalt)
	end
	strip("Cornice", gh - 0.4, gh + 0.2, 0.5, Palette.stoneWarm, M.Limestone)
	strip("Coping", height + 0.9, height + 1.3, 0.4, Palette.stoneWarm, M.Limestone)

	-- Door
	local doorAt = o.doorAt or (lo + hi) / 2
	if o.door ~= false then
		local woods = { Palette.wood, Color3.fromHex("#2F4F6B"), Color3.fromHex("#5B3A22"), Color3.fromHex("#3E5B3A") }
		Props.door(m, at(doorAt, 0), 4.5, 8, woods[rng:NextInteger(1, #woods)])
	end

	-- Ground-floor windows (away from the door)
	if width >= 14 then
		for _, side in { -1, 1 } do
			local x = doorAt + side * math.min(width / 2 - 2.5, 6)
			if x > lo + 2 and x < hi - 2 then
				Props.window(m, at(x, 8.6), 2, 2.2)
			end
		end
	end

	-- Upper floor: latticed bay or windows
	local mid = (lo + hi) / 2
	local bayW = math.clamp(width - 8, 6, 9)
	if o.jetty then
		Props.mashrabiya(m, at(mid, gh + 1.4), bayW, 5, 2.2)
	end
	local count = math.max(1, math.floor(width / 8))
	for i = 1, count do
		local x = lo + (i - 0.5) * width / count
		local clearOfBay = not o.jetty or math.abs(x - mid) > bayW / 2 + 1.6
		if clearOfBay then
			Props.window(m, at(x, gh + 4), 2.2, 3)
			if o.pots ~= false and rng:NextNumber() < 0.6 then
				local kinds = { "basil", "jasmine", "geranium" } :: { any }
				local sill = (at(x, gh + 2.35) * CFrame.new(0, 0, -0.35)).Position
				Props.pot(m, sill, kinds[rng:NextInteger(1, 3)], 0.55)
			end
		end
	end

	-- Beam ends under the parapet
	if o.beams ~= false then
		local n = math.floor(width / 2.5)
		for i = 1, n do
			local x = lo + (i - 0.5) * width / n
			Kit.part(m, { name = "Beam", size = Vector3.new(0.4, 0.4, 0.9), cf = at(x, height - 0.6) * CFrame.new(0, 0, -0.45), color = Palette.woodDark, material = M.Wood, collide = false, shadow = false })
		end
	end

	-- A patch of newer plaster for a lived-in look
	if rng:NextNumber() < 0.7 then
		local px = lo + rng:NextNumber(2, math.max(2.5, width - 2))
		Kit.part(m, {
			name = "Patch",
			size = Vector3.new(rng:NextNumber(2, 4), rng:NextNumber(1.5, 3), 0.05),
			cf = at(px, gh + rng:NextNumber(2, math.max(2.5, height - gh - 2))) * CFrame.new(0, 0, -0.03),
			color = Kit.tint(plaster, rng, 0.08),
			material = M.Plaster,
			collide = false,
			shadow = false,
		})
	end

	if o.lantern then
		Props.lantern(m, at(o.lantern, 10.5))
	end
	return m
end

return Facade
