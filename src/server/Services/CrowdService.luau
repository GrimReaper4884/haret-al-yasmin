--!strict
-- Ambient neighbours: a handful of humanoid walkers that stroll between the gate, the shops and
-- the square, pausing to chat, so the lane feels lived in. They pass through players (same
-- collision group) and never block anything. Pure set dressing: no prompts, no state.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local PhysicsService = game:GetService("PhysicsService")
local PathfindingService = game:GetService("PathfindingService")

local AvatarService = require(script.Parent.AvatarService)

local CrowdService = {}

local COUNT = 8
local GROUP = "Players"

-- Stroll points around the lobby (ground level)
local POINTS = {
	Vector3.new(0, 0, 76),
	Vector3.new(-4, 0, 62),
	Vector3.new(4, 0, 54),
	Vector3.new(-2, 0, 40),
	Vector3.new(3, 0, 30),
	Vector3.new(-12, 0, 14),
	Vector3.new(12, 0, 12),
	Vector3.new(-14, 0, -4),
	Vector3.new(14, 0, -6),
	Vector3.new(0, 0, -18),
	Vector3.new(-26, 0, -10),
	Vector3.new(11, 0, 38),
	Vector3.new(-18, 0, 20),
}

local LOOKS = {
	{ skin = "#C68E64", robe = "#EADFC8", accent = "#2F3E6B", hat = "tarboosh" },
	{ skin = "#B97F5A", robe = "#4A2E18", accent = "#C9A13B", hat = "cap" },
	{ skin = "#D2A07A", robe = "#2F3E6B", accent = "#FBF8F1", hat = "scarf" },
	{ skin = "#C08A62", robe = "#5E7D3A", accent = "#A4302A", hat = "tarboosh" },
	{ skin = "#B97F5A", robe = "#1F1B18", accent = "#C9A13B", hat = "tarboosh" },
	{ skin = "#C68E64", robe = "#F1E9DA", accent = "#6B4423", hat = "cap" },
	{ skin = "#D2A07A", robe = "#A4302A", accent = "#1F1B18", hat = "scarf" },
	{ skin = "#C08A62", robe = "#2E8B87", accent = "#EADFC8", hat = "tarboosh" },
}

local function describe(look: any): HumanoidDescription
	local d = Instance.new("HumanoidDescription")
	local skin = Color3.fromHex(look.skin)
	local robe = Color3.fromHex(look.robe)
	local accent = Color3.fromHex(look.accent)
	d.HeadColor = skin
	d.LeftArmColor = robe
	d.RightArmColor = robe
	d.TorsoColor = accent
	d.LeftLegColor = robe
	d.RightLegColor = robe
	return d
end

local function setGroup(inst: Instance)
	if inst:IsA("BasePart") then
		inst.CollisionGroup = GROUP
	end
end

local function walker(folder: Instance, i: number)
	local look = LOOKS[(i - 1) % #LOOKS + 1]
	local ok, rig = pcall(function()
		return Players:CreateHumanoidModelFromDescription(describe(look), Enum.HumanoidRigType.R15)
	end)
	if not ok or not rig then
		return
	end
	local m = rig :: Model
	m.Name = "Walker" .. i
	local humanoid = m:FindFirstChildOfClass("Humanoid")
	local root = m:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not root then
		m:Destroy()
		return
	end
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.WalkSpeed = 7 + (i % 3) * 1.5
	humanoid.BreakJointsOnDeath = false
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	for _, d in m:GetDescendants() do
		setGroup(d)
	end
	m.DescendantAdded:Connect(setGroup)
	local start = POINTS[(i * 3) % #POINTS + 1]
	m:PivotTo(CFrame.new(start + Vector3.new(0, 3.5, 0)))
	m.Parent = folder
	AvatarService.attach(m, look.hat, "head")

	-- Walk a waypoint: returns true when reached before the deadline.
	local function walkTo(point: Vector3, timeout: number): boolean
		humanoid:MoveTo(point)
		local reached = false
		local conn = humanoid.MoveToFinished:Connect(function(arrivedOk: boolean)
			reached = arrivedOk
		end)
		local deadline = os.clock() + timeout
		while not reached and os.clock() < deadline and m.Parent do
			task.wait(0.2)
		end
		conn:Disconnect()
		return reached
	end

	task.spawn(function()
		local rng = Random.new(i * 7919)
		local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = false })
		while m.Parent do
			local target = POINTS[rng:NextInteger(1, #POINTS)] + Vector3.new(rng:NextNumber(-2, 2), 0, rng:NextNumber(-2, 2))
			local computed = pcall(function()
				path:ComputeAsync(root.Position, target)
			end)
			local arrived = false
			if computed and path.Status == Enum.PathStatus.Success then
				arrived = true
				for _, wp in path:GetWaypoints() do
					if not walkTo(wp.Position, 6) then
						arrived = false
						break
					end
				end
			else
				arrived = walkTo(target, 10)
			end
			if not arrived and m.Parent then
				-- Stuck behind something: hop to the point and carry on
				m:PivotTo(CFrame.new(target + Vector3.new(0, 3.5, 0)))
			end
			task.wait(rng:NextNumber(1.5, 6))
		end
	end)
end

function CrowdService.start()
	-- The group normally exists already (PlayerCollisionService); registering twice errors.
	pcall(function()
		PhysicsService:RegisterCollisionGroup(GROUP)
	end)
	local folder = Instance.new("Folder")
	folder.Name = "Crowd"
	folder.Parent = Workspace
	for i = 1, COUNT do
		task.spawn(walker, folder, i)
		task.wait(0.1)
	end
end

return CrowdService
