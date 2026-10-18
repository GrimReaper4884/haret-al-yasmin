--!strict
-- Allocates arena slots far from the lobby, builds/destroys arenas, and builds tower models.
-- Slots are spaced 600 studs apart along +X starting at x = 3000 so streaming keeps the lobby
-- and every arena separate.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Units = require(Shared.Config.Units)
local Arenas = require(Shared.Config.Arenas)
local TD = require(Shared.Config.TD)
local Path = require(Shared.Logic.Path)
local RigBuilder = require(Shared.Util.RigBuilder)
local Arena = require(script.Parent.Parent:WaitForChild("World"):WaitForChild("Arena"))
local PropDressing = require(script.Parent.Parent:WaitForChild("World"):WaitForChild("PropDressing"))
local KitLayout = require(script.Parent.Parent:WaitForChild("World"):WaitForChild("KitLayout"))

local ArenaService = {}

export type Slot = { index: number, origin: CFrame, model: Model, gate: Model, towers: Folder, arenaId: string }

local SLOT_X0 = 3000
local SLOT_STEP = 600

local used: { [number]: boolean } = {}
local folder: Folder

function ArenaService.start()
	folder = Instance.new("Folder")
	folder.Name = "Arenas"
	folder.Parent = Workspace
end

function ArenaService.capacity(): number
	return TD.MAX_MATCHES
end

-- Builds an arena in a free slot. Returns nil when every slot is busy.
function ArenaService.allocate(arenaId: string): Slot?
	for i = 1, TD.MAX_MATCHES do
		if not used[i] then
			used[i] = true
			local origin = CFrame.new(SLOT_X0 + (i - 1) * SLOT_STEP, 0, 0)
			local model, gate = Arena.build(folder, arenaId, origin)
			PropDressing.dressArena(model, arenaId, origin, Arenas[arenaId].path)
			-- The Blender kit (S1-M03), before the swaps so tagged primitives still get their props.
			KitLayout.dress(model, arenaId, origin)
			PropDressing.swap(model)
			model.Name = string.format("Arena_%d_%s", i, arenaId)
			local towers = Instance.new("Folder")
			towers.Name = "Towers"
			towers.Parent = model
			return { index = i, origin = origin, model = model, gate = gate, towers = towers, arenaId = arenaId }
		end
	end
	return nil
end

function ArenaService.release(slot: Slot)
	used[slot.index] = nil
	if slot.model then
		slot.model:Destroy()
	end
end

-- Where the party stands at the start (world CFrame, facing the gate).
function ArenaService.spawnCFrame(slot: Slot, k: number): CFrame
	local def = Arenas[slot.arenaId]
	local sp = def.playerSpawn
	local last = def.path[#def.path]
	local pos = slot.origin * CFrame.new(sp[1] + (k - 1) * 2.5 - 3.5, 3.5, sp[2])
	return CFrame.lookAt(pos.Position, (slot.origin * CFrame.new(last[1], 3.5, last[2])).Position)
end

function ArenaService.toLocal(slot: Slot, worldPos: Vector3): (number, number)
	local l = slot.origin:PointToObjectSpace(worldPos)
	return l.X, l.Z
end

-- Builds the visible defender for a tower record, facing the nearest point of the road.
function ArenaService.buildTower(slot: Slot, tower: any, ownerName: string): Model
	local def = Arenas[slot.arenaId]
	local unit = (Units :: any)[tower.unitId]
	local path = Path.build(def.path)
	-- Face the road: sample the path for the closest point
	local bestD, bx, bz = math.huge, 0, 0
	for d = 0, path.length, 4 do
		local px, pz = Path.position(path, d)
		local dist = (px - tower.x) ^ 2 + (pz - tower.z) ^ 2
		if dist < bestD then
			bestD, bx, bz = dist, px, pz
		end
	end
	local model = RigBuilder.cached(nil, "Tower_" .. tower.id, unit.visual, tower.unitId)
	-- Stream the figure in whole: an imported rig whose root arrived before its skinned mesh and
	-- Animator was left un-animated in its T-pose bind pose (player report "models bugging out").
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	local at = slot.origin * CFrame.new(tower.x, 0, tower.z)
	local look = slot.origin * CFrame.new(bx, 0, bz)
	model:PivotTo(CFrame.lookAt(at.Position, look.Position))
	model:SetAttribute("TowerId", tower.id)
	model:SetAttribute("UnitId", tower.unitId)
	model:SetAttribute("Owner", ownerName)
	model:SetAttribute("Level", tower.level)
	model:SetAttribute("Range", tower.stats.range)
	model.Parent = slot.towers
	return model
end

-- A gold "▲ +15%" badge over a defender a support is buffing (mul ≤ 1 removes it).
function ArenaService.setBuff(model: Model, mul: number)
	local badge = model:FindFirstChild("BuffBadge")
	if mul <= 1 then
		if badge then
			badge:Destroy()
		end
		return
	end
	local root = model.PrimaryPart
	if not root then
		return
	end
	local label: TextLabel
	if badge then
		label = badge:FindFirstChild("Text") :: TextLabel
	else
		local cf, size = model:GetBoundingBox()
		local gui = Instance.new("BillboardGui")
		gui.Name = "BuffBadge"
		gui.Adornee = root
		gui.Size = UDim2.fromOffset(64, 22)
		gui.StudsOffsetWorldSpace = Vector3.new(0, cf.Position.Y + size.Y / 2 - root.Position.Y + 0.9, 0)
		gui.MaxDistance = 120
		gui.LightInfluence = 0
		label = Instance.new("TextLabel")
		label.Name = "Text"
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.TextColor3 = Color3.fromHex("#FFD24A")
		label.TextStrokeColor3 = Color3.fromHex("#3A2A10")
		label.TextStrokeTransparency = 0
		label.Parent = gui
		gui.Parent = model
	end
	label.Text = string.format("▲ +%d%%", math.floor((mul - 1) * 100 + 0.5))
end

function ArenaService.findTower(slot: Slot, towerId: number): Model?
	local m = slot.towers:FindFirstChild("Tower_" .. towerId)
	return if m and m:IsA("Model") then m else nil
end

return ArenaService
