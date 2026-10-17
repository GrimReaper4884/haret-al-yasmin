--!strict
-- Places imported Meshy props (ReplicatedStorage.PropModels) into the lobby lane and the arenas,
-- per Config/PropPlacements. Each prop is scaled to its target height, anchored, and set on the
-- ground at its spot. Missing models are skipped silently: the primitive world stays complete.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Placements = require(Shared.Config.PropPlacements)

local PropDressing = {}

local function template(name: string): Model?
	local folder = ReplicatedStorage:FindFirstChild("PropModels")
	local m = folder and folder:FindFirstChild(name)
	return if m and m:IsA("Model") then m else nil
end

-- Clones `name`, scales it to `height` studs and puts its bottom-centre on `ground`.
local function spawnProp(
	parent: Instance,
	name: string,
	ground: CFrame,
	height: number,
	solid: boolean
): Model?
	local t = template(name)
	if not t then
		return nil
	end
	local m = t:Clone()
	for _, junk in { "InitialPoses", "AnimSaves", "AnimationController" } do
		local j = m:FindFirstChild(junk)
		if j then
			j:Destroy()
		end
	end
	local _, size = m:GetBoundingBox()
	if size.Y > 0 then
		m:ScaleTo(m:GetScale() * height / size.Y)
	end
	local cf, box = m:GetBoundingBox()
	-- Pivot at the bottom centre of the bounding box so ground placement is exact.
	m.WorldPivot = CFrame.new(cf.Position - Vector3.new(0, box.Y / 2, 0))
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = solid
			d.CanQuery = solid
			d.CanTouch = false
		end
	end
	m:PivotTo(ground)
	m:SetAttribute("Prop", name)
	m.Parent = parent
	return m
end

local function place(parent: Instance, origin: CFrame, p: Placements.Placement, startFrame: CFrame?)
	local base = if p.anchor == "start" and startFrame then startFrame else origin
	local ground = base * CFrame.new(p.at[1], 0, p.at[2]) * CFrame.Angles(0, math.rad(p.yaw or 0), 0)
	spawnProp(parent, p.prop, ground, p.height, p.solid == true)
end

-- Lobby dressing in world coordinates.
function PropDressing.dressLobby(parent: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "Props"
	folder.Parent = parent
	for _, p in Placements.lobby do
		place(folder, CFrame.new(), p, nil)
	end
end

-- Arena dressing: `origin` is the arena's world frame, `path` its road points (arena-local).
function PropDressing.dressArena(parent: Instance, arenaId: string, origin: CFrame, path: { { number } })
	local list = Placements.arenas[arenaId]
	if not list then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "Props"
	folder.Parent = parent
	-- Road start, looking along the road: -Z points down the road, +Z back out of the arena.
	local a, b = path[1], path[2]
	local startFrame = origin * CFrame.lookAt(Vector3.new(a[1], 0, a[2]), Vector3.new(b[1], 0, b[2]))
	for _, p in list do
		place(folder, origin, p, startFrame)
	end
end

return PropDressing
