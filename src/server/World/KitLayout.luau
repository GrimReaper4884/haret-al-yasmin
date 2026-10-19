--!strict
-- Places the hara kit in an arena (docs/STORY_PLAN.md §8.3, S1-M03): an arena with `kit = "<id>"` in
-- Config/Arenas gets every module of Config/ArenaLayouts/<id> (exported from Blender by
-- tools/blender/export_layout.py), cloned from ReplicatedStorage.PropModels.kit_<module>, scaled to
-- its true size (Config/KitModules) and set where its Blender origin was. A module whose model is
-- not imported yet is skipped, so the primitive arena always stands on its own (like PropDressing).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Arenas = require(Shared.Config.Arenas)
local KitModules = require(Shared.Config.KitModules)

local KitLayout = {}

-- Pieces players should walk around; everything else (ground patches, nets, hanging lanterns,
-- skyline) never collides.
local SOLID = {
	wall_2m = true,
	wall_4m = true,
	wall_corner = true,
	wall_arch = true,
	wall_window_grille = true,
	gate_lane = true,
	gate_rival = true,
	warehouse_door = true,
	warehouse_block = true,
	bakery_front = true,
	police_post = true,
	well = true,
	olive_press = true,
	orchard_wall_low = true,
}

local function template(module: string): Model?
	local folder = ReplicatedStorage:FindFirstChild("PropModels")
	local m = folder and folder:FindFirstChild("kit_" .. module)
	return if m and m:IsA("Model") then m else nil
end

local function layoutOf(kit: string): { any }?
	local folder = Shared.Config:FindFirstChild("ArenaLayouts")
	local mod = folder and folder:FindFirstChild(kit)
	if not mod or not mod:IsA("ModuleScript") then
		return nil
	end
	return require(mod) :: any
end

-- One kit module, scaled to its true size × `scale` (Config/KitModules) and set where its Blender
-- origin goes (`ground`: on the ground, facing -Z at yaw 0). nil when the model is not imported.
-- Used by the arena layouts and the lobby zones (LP-D03).
function KitLayout.place(parent: Instance, module: string, ground: CFrame, scale: number?): Model?
	local t = template(module)
	local info = (KitModules :: any)[module]
	if not t or not info then
		return nil
	end
	local k = scale or 1
	local m = t:Clone()
	-- With a PrimaryPart the bottom-centre WorldPivot below doesn't take and the piece is
	-- placed by its mesh centre, half under the ground (owner report 2026-10-18, D-068).
	m.PrimaryPart = nil
	local _, size = m:GetBoundingBox()
	local want = info.size[2] * k
	if size.Y > 0 and want > 0 then
		m:ScaleTo(m:GetScale() * want / size.Y)
	end
	local cf, box = m:GetBoundingBox()
	m.WorldPivot = CFrame.new(cf.Position - Vector3.new(0, box.Y / 2, 0))
	local solid = SOLID[module] == true
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = solid
			d.CanQuery = solid
			d.CanTouch = false
		end
	end
	local o = info.offset
	m:PivotTo(ground * CFrame.new(o[1] * k, o[2] * k, o[3] * k))
	m:SetAttribute("Kit", module)
	m.Parent = parent
	return m
end

-- Builds the arena's kit under `parent` (the arena model). Returns how many modules were placed.
function KitLayout.dress(parent: Instance, arenaId: string, origin: CFrame): number
	local def = (Arenas :: any)[arenaId]
	local layout = def and def.kit and layoutOf(def.kit)
	if not layout then
		return 0
	end
	local folder = Instance.new("Folder")
	folder.Name = "Kit"
	local placed = 0
	for _, p in layout do
		local ground = origin * CFrame.new(p.x, 0, p.z) * CFrame.Angles(0, math.rad(p.yaw), 0)
		if KitLayout.place(folder, p.module, ground, p.scale) then
			placed += 1
		end
	end
	folder.Parent = parent
	return placed
end

return KitLayout
