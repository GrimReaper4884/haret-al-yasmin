--!nocheck
-- Headless rig preview, step 1: builds every unit and enemy figure with Util/RigBuilder under
-- Lune's roblox library and writes their parts (shape, size, CFrame, colour) to <outDir>/rigs.json.
-- Fails loudly if any figure errors. Step 2 is tools/rigpreview/render.py.
--   lune run tools/rigpreview/export . <outDir>
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local process = require("@lune/process")

local repo = process.args[1]
local Looks = luau.load(fs.readFile(repo .. "/src/shared/Config/CharacterLooks.luau"))()
local Units = luau.load(fs.readFile(repo .. "/src/shared/Config/Units.luau"))()
local Enemies = luau.load(fs.readFile(repo .. "/src/shared/Config/Enemies.luau"))()

local env = setmetatable({
	Instance = roblox.Instance,
	Vector3 = roblox.Vector3,
	CFrame = roblox.CFrame,
	Color3 = roblox.Color3,
	Enum = roblox.Enum,
	UDim2 = roblox.UDim2,
	game = { GetService = function() return { FindFirstChild = function() return nil end } end },
	script = { Parent = { Parent = { Config = { CharacterLooks = "LOOKS" } } } },
	require = function(x)
		if x == "LOOKS" then
			return Looks
		end
		error("unexpected require")
	end,
}, { __index = _G })

local RigBuilder = luau.load(fs.readFile(repo .. "/src/shared/Util/RigBuilder.luau"), { environment = env })()

local serde = require("@lune/serde")
local out = {}
local function dump(kind, id, visual)
	local m = RigBuilder.build(nil, id, visual, id)
	local parts = {}
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "Root" then
			local cf = d.CFrame
			local rx, ry, rz = cf:ToEulerAnglesXYZ()
			local p = cf.Position
			table.insert(parts, {
				name = d.Name, shape = d.Shape.Name,
				size = { d.Size.X, d.Size.Y, d.Size.Z },
				pos = { p.X, p.Y, p.Z },
				rot = { cf.XVector.X, cf.XVector.Y, cf.XVector.Z, cf.YVector.X, cf.YVector.Y, cf.YVector.Z, cf.ZVector.X, cf.ZVector.Y, cf.ZVector.Z },
				color = { d.Color.R, d.Color.G, d.Color.B },
				transparency = d.Transparency,
				neon = d.Material.Name == "Neon",
			})
		end
	end
	out[id] = { kind = kind, parts = parts }
end
for id, def in Units do dump("unit", id, def.visual) end
for id, def in Enemies do dump("enemy", id, def.visual) end
fs.writeFile(process.args[2] .. "/rigs.json", serde.encode("json", out))
print("wrote rigs.json")
