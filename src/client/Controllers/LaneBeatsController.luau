--!strict
-- The lane's beats (LOOK_AND_PLAY_PLAN §4.3, LP-D10), drawn by this client on the lane clock
-- (Logic/LobbyLife.beatAt / inPhase / gateAngle, Config/LobbyLife `beats`), so every player sees the
-- same lane at the same moment and the server builds and simulates nothing:
--   * the gate: Abu Hares swings the leaves half shut at night (a gap stays open) and open at dawn,
--     when a rooster calls; he calls out twice in the night;
--   * the patrol: by day Corporal Houri and two gendarmes march from the gate round the fountain and
--     back (the corporal at the post steps out of sight while they march);
--   * the dispute: by day two neighbours quarrel before the liwan, the za'im raises his hand, they
--     shake on it; players close by see the (cosmetic) lane fund grow;
--   * the coffee-house evening: six neighbours on the benches and the Hakawati on his stool telling a
--     tale in three lines (a different tale each evening);
--   * the cameo: one night in each, Al-Adashari slips up the souq to Abu Brahim's shutter and is gone.
-- Lane life "off" stops all of it (the gate stays open). Figures exist only while their beat plays and
-- animate only within LobbyLife `radius` of the camera, at most `hz` times a second.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Cfg = require(Shared.Config.LobbyLife)
local Enemies = require(Shared.Config.Enemies)
local Units = require(Shared.Config.Units)
local LobbyLife = require(Shared.Logic.LobbyLife)
local RigBuilder = require(Shared.Util.RigBuilder)
local BoneAnim = require(Shared.Anim.BoneAnim)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Fx = require(UI.Fx)
local LocaleController = require(script.Parent.LocaleController)
local MatchController = require(script.Parent.MatchController)
local RigAnimController = require(script.Parent.RigAnimController)
local ToastController = require(script.Parent.ToastController)
local AudioController = require(script.Parent.AudioController)

local LaneBeatsController = {}

local B = Cfg.beats
local C = Cfg.CLOCK
local folder: Folder

local function now(): number
	local t = Workspace:GetServerTimeNow()
	if RunService:IsStudio() then
		local off = Players.LocalPlayer:GetAttribute("HarnessClockOffset") -- LaneClockController's harness
		if type(off) == "number" then
			t += off
		end
	end
	return t
end

---------------------------------------------------------------- bubbles

type Bubble = { gui: BillboardGui, label: TextLabel, key: string? }

local function bubble(part: BasePart, over: number): Bubble
	local g = Create("BillboardGui", {
		Name = "BeatLine",
		Adornee = part,
		Size = UDim2.fromOffset(230, 58),
		StudsOffset = Vector3.new(0, over, 0),
		MaxDistance = 70,
		AlwaysOnTop = false,
		LightInfluence = 0,
		Enabled = false,
		Parent = folder,
	}) :: BillboardGui
	local panel = Create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.colors.panel, BackgroundTransparency = 0.05, Parent = g })
	Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = panel })
	Create("UIStroke", { Color = Theme.colors.panelStroke, Thickness = 2, Parent = panel })
	Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = panel })
	local label = Theme.label({ Size = UDim2.fromScale(1, 1), TextSize = 14, TextWrapped = true, Parent = panel })
	return { gui = g, label = label, key = nil }
end

local function say(b: Bubble, key: string?)
	if b.key == key then
		return
	end
	b.key = key
	if key then
		b.label.Text = LocaleController.t(key)
		b.label.TextXAlignment = if LocaleController.isRtl() then Enum.TextXAlignment.Right else Enum.TextXAlignment.Left
	end
	b.gui.Enabled = key ~= nil
end

local function npcRoot(id: string): BasePart?
	local npcs = Workspace:FindFirstChild("Npcs")
	local m = npcs and npcs:FindFirstChild(id)
	return if m and m:IsA("Model") then m.PrimaryPart else nil
end

---------------------------------------------------------------- figures

local CROWD = {
	{ skin = "#C68E64", robe = "#EADFC8", accent = "#2F3E6B", hat = "tarboosh", hatColor = "#A4302A" },
	{ skin = "#B97F5A", robe = "#4A2E18", accent = "#C9A13B", hat = "cap", hatColor = "#FBF8F1" },
	{ skin = "#D2A07A", robe = "#2F3E6B", accent = "#FBF8F1", hat = "hatta", hatColor = "#EFE6D2" },
	{ skin = "#C08A62", robe = "#5E7D3A", accent = "#A4302A", hat = "tarboosh", hatColor = "#A4302A" },
	{ skin = "#B97F5A", robe = "#1F1B18", accent = "#C9A13B", hat = "tarboosh", hatColor = "#7A1E1A" },
	{ skin = "#C68E64", robe = "#A4302A", accent = "#1F1B18", hat = "cap", hatColor = "#EADFC8" },
}
local HAKAWATI = { skin = "#B5835E", robe = "#2F3E6B", accent = "#C9A13B", hat = "tarboosh", hatColor = "#A4302A" }

-- A neighbour (the stylized primitive figure: these extras have no character of their own).
local function neighbour(name: string, look: { [string]: string }): Model
	return RigBuilder.build(folder, name, {
		robe = look.robe,
		accent = look.accent,
		skin = look.skin,
		hat = look.hat,
		hatColor = look.hatColor,
		weapon = "none",
	}, nil)
end

-- Seats a primitive figure: hips on the seat at `seat` (top surface), legs out in front.
local function sit(m: Model, x: number, seatY: number, z: number, yaw: number)
	local root = m.PrimaryPart :: BasePart
	local hip = 0
	for _, d in m:GetDescendants() do
		if d:IsA("Motor6D") and (d.Name == "LeftHip" or d.Name == "RightHip") then
			hip = (root.CFrame * d.C0).Position.Y - m:GetPivot().Position.Y
			d.Transform = CFrame.Angles(math.rad(90), 0, 0)
		end
	end
	m:PivotTo(CFrame.new(x, seatY - hip + 0.05, z) * CFrame.Angles(0, math.rad(yaw), 0))
end

local function place(m: Model, x: number, z: number, yaw: number)
	m:PivotTo(CFrame.new(x, 0, z) * CFrame.Angles(0, yaw, 0))
end

-- A walking figure in a character's own model, with its baked walk (borrowed when it has none).
type Walker = { model: Model, bone: BoneAnim.Player? }
local function walker(name: string, lookId: string, visual: any, walkFrom: string?): Walker
	local m = RigBuilder.build(folder, name, visual, lookId)
	for _, d in m:GetDescendants() do
		if d:IsA("AnimationController") then
			d:Destroy() -- the bones are written here, like RigAnimController does
		end
	end
	local p = BoneAnim.new(m, lookId)
	if p and walkFrom then
		BoneAnim.borrow(p, walkFrom, "walk")
	end
	return { model = m, bone = p }
end

local function stride(w: Walker, moving: boolean, speed: number, dt: number)
	local p = w.bone
	if not p then
		return
	end
	if not moving and not p.clips.idle then
		return -- a figure with no idle of its own holds its stride while it waits
	end
	local authored = BoneAnim.walkSpeed(p)
	BoneAnim.loop(p, if moving then "walk" else "idle", if moving and authored > 0 then speed / authored else 1)
	BoneAnim.step(p, dt, true)
end

local function near(pos: Vector3, cam: Vector3): boolean
	return (pos - cam).Magnitude <= Cfg.radius
end

---------------------------------------------------------------- the gate

type Leaf = { leaf: BasePart, side: number, open: CFrame, hinge: CFrame, lw: number, h: number, parts: { { p: BasePart, rel: CFrame } } }
local leaves: { Leaf }? = nil
local gateAngle = 100

local function findLeaves(): { Leaf }?
	local map = Workspace:FindFirstChild("Map")
	local jg = map and map:FindFirstChild("JasmineGate")
	local gate = jg and jg:FindFirstChild("Gate")
	if not gate then
		return nil
	end
	local out: { Leaf } = {}
	for _, name in { "LeafW", "LeafE" } do
		local leaf = gate:FindFirstChild(name)
		if not leaf or not leaf:IsA("BasePart") then
			return nil
		end
		local side: number = if name == "LeafW" then -1 else 1
		local lw = leaf.Size.X + 0.1
		local h = leaf.Size.Y
		-- Built open at 100°: leafFrame = hinge * R(side*100) * T(-side*lw/2, h/2, 0)
		local hinge = leaf.CFrame * CFrame.new(side * lw / 2, -h / 2, 0) * CFrame.Angles(0, -math.rad(side * 100), 0)
		table.insert(out, { leaf = leaf, side = side, open = leaf.CFrame, hinge = hinge, lw = lw, h = h, parts = {} })
	end
	-- The straps, studs, knockers and the wicket ride with the leaf on their side of the lane
	for _, d in gate:GetChildren() do
		if d:IsA("BasePart") and not string.match(d.Name, "^Leaf") and d.Name ~= "Hook" and d.Name ~= "Bar" and d.Name ~= "BarLeaning" then
			local l = if d.Position.X < 0 then out[1] else out[2]
			table.insert(l.parts, { p = d, rel = l.leaf.CFrame:ToObjectSpace(d.CFrame) })
		end
	end
	return out
end

local function setGate(angle: number)
	if math.abs(angle - gateAngle) < 0.05 then
		return
	end
	local ls = leaves
	if not ls or not ls[1].leaf.Parent then
		ls = findLeaves()
		leaves = ls
	end
	if not ls then
		return
	end
	gateAngle = angle
	for _, l in ls do
		local cf = l.hinge * CFrame.Angles(0, math.rad(l.side * angle), 0) * CFrame.new(-l.side * l.lw / 2, l.h / 2, 0)
		l.leaf.CFrame = cf
		for _, q in l.parts do
			q.p.CFrame = cf * q.rel
		end
	end
end

---------------------------------------------------------------- the beats

local watchBubble: Bubble? = nil
local zaimBubble: Bubble? = nil
local lastPhase: string? = nil

-- Patrol
local patrol: { Walker }? = nil
local function hidePostCorporal(hidden: boolean)
	local npcs = Workspace:FindFirstChild("Npcs")
	local m = npcs and npcs:FindFirstChild("corporal_npc")
	if not m then
		return
	end
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.LocalTransparencyModifier = if hidden then 1 else 0
		elseif d:IsA("BillboardGui") then
			d.Enabled = not hidden
		end
	end
end

local function runPatrol(t: number, cam: Vector3, dt: number)
	local p = B.patrol
	local into = LobbyLife.beatAt(t, C, p)
	if not into then
		if patrol then
			for _, w in patrol do
				w.model:Destroy()
			end
			patrol = nil
			hidePostCorporal(false)
		end
		return
	end
	if not patrol then
		patrol = {
			walker("PatrolCorporal", "corporal", (Enemies :: any).corporal.visual, nil),
			walker("PatrolGendarme1", "gendarme", (Enemies :: any).gendarme.visual, nil),
			walker("PatrolGendarme2", "gendarme", (Enemies :: any).gendarme.visual, nil),
		}
		hidePostCorporal(true)
	end
	local cycle = LobbyLife.routeCycle(p.route, p.speed, 0)
	for i, w in patrol :: { Walker } do
		local s = into - (i - 1) * p.gap
		local x, z, yaw, moving
		if s <= 0 then
			x, z, yaw = LobbyLife.route(p.route, p.speed, 0, 0)
			moving = false
		elseif s >= cycle then
			x, z, yaw = LobbyLife.route(p.route, p.speed, 0, cycle - 0.01)
			moving = false
		else
			x, z, yaw, moving = LobbyLife.route(p.route, p.speed, 0, s)
		end
		-- the two gendarmes walk a stride to either side behind the corporal
		local off = if i == 1 then 0 elseif i == 2 then -1.3 else 1.3
		local cf = CFrame.new(x, 0, z) * CFrame.Angles(0, yaw, 0) * CFrame.new(off, 0, 0)
		w.model:PivotTo(cf)
		if near(cf.Position, cam) then
			stride(w, moving, p.speed, dt)
		end
	end
end

-- Dispute
local dispute: { model: { Model }, bubbles: { Bubble }, period: number }? = nil
local fundPeriod = -1
local function runDispute(t: number)
	local d = B.dispute
	local into = LobbyLife.beatAt(t, C, d)
	local zb = zaimBubble
	if not into then
		if dispute then
			for _, m in dispute.model do
				m:Destroy()
			end
			for _, b in dispute.bubbles do
				b.gui:Destroy()
			end
			dispute = nil
		end
		if zb then
			say(zb, nil)
		end
		return
	end
	local period = math.floor((t - d.offset) / d.every)
	if not dispute then
		local a, b = neighbour("Disputant1", CROWD[2]), neighbour("Disputant2", CROWD[4])
		place(a, d.at[1] - 1.6, d.at[2], math.rad(-90)) -- faces +X
		place(b, d.at[1] + 1.6, d.at[2], math.rad(90)) -- faces -X
		dispute = {
			model = { a, b },
			bubbles = { bubble(a.PrimaryPart :: BasePart, 4.6), bubble(b.PrimaryPart :: BasePart, 4.6) },
			period = period,
		}
	end
	local dd = dispute :: any
	local line = math.floor(into / d.lineSeconds) + 1
	say(dd.bubbles[1], if line == 1 then d.lines[1] elseif line == 4 then d.lines[4] else nil)
	say(dd.bubbles[2], if line == 2 then d.lines[2] elseif line == 4 then d.lines[4] else nil)
	local root = npcRoot("zaim_npc")
	if root and not zb then
		zb = bubble(root, root.Size.Y / 2 + 2.6)
		zaimBubble = zb
	end
	if zb then
		say(zb, if line == 3 then d.lines[3] else nil)
	end
	if line == 3 and dd.raised ~= period then
		if RigAnimController.npcPlay("zaim_npc", "ability") then
			dd.raised = period
		end
	end
	if line == 4 and fundPeriod ~= period then
		fundPeriod = period
		local char = Players.LocalPlayer.Character
		local pos = char and char:GetPivot().Position
		if pos and (pos - Vector3.new(d.at[1], pos.Y, d.at[2])).Magnitude <= d.fundRange then
			ToastController.show("beat.fund", { n = 5 + (period % 4) * 5 })
		end
	end
end

-- Coffee-house evening
local coffee: { sitters: { Model }, hakawati: Model, stool: Model, bubble: Bubble }? = nil
local function runCoffee(t: number)
	local c = B.coffee
	local id, into = LobbyLife.clock(t, C)
	if id ~= c.phase then
		if coffee then
			for _, m in coffee.sitters do
				m:Destroy()
			end
			coffee.hakawati:Destroy()
			coffee.stool:Destroy()
			coffee.bubble.gui:Destroy()
			coffee = nil
		end
		return
	end
	if not coffee then
		local sitters = {}
		for i, s in c.seats do
			local m = neighbour("Patron" .. i, CROWD[(i - 1) % #CROWD + 1])
			sit(m, s[1], 2.0, s[2], s[3]) -- the dikkeh cushions top out at 2.0
			table.insert(sitters, m)
		end
		local h = c.hakawati
		local stool = Instance.new("Model")
		stool.Name = "HakawatiStool"
		local seat = Instance.new("Part")
		seat.Anchored = true
		seat.CanCollide = false
		seat.CanQuery = false
		seat.Size = Vector3.new(1.6, 1.4, 1.6)
		seat.CFrame = CFrame.new(h[1], 0.3 + 0.7, h[2])
		seat.Color = Color3.fromHex("#6B4423")
		seat.Material = Enum.Material.WoodPlanks
		seat.Parent = stool
		stool.Parent = folder
		local hk = neighbour("Hakawati", HAKAWATI)
		sit(hk, h[1], 1.7, h[2], h[3])
		coffee = { sitters = sitters, hakawati = hk, stool = stool, bubble = bubble(hk.PrimaryPart :: BasePart, 3.8) }
	end
	local cc = coffee :: any
	local tale = c.tales[math.floor(t / C.cycle) % #c.tales + 1]
	local key: string? = nil
	for i, at in c.lineAt do
		if into >= at and into < at + c.lineSeconds then
			key = "afk.line." .. tale .. "." .. i
		end
	end
	say(cc.bubble, key)
end

-- Night watch: Abu Hares calls; the cameo
local cameo: Walker? = nil
local function runWatch(t: number, cam: Vector3, dt: number)
	local w = B.watch
	local key: string? = nil
	for _, call in w.calls do
		if LobbyLife.inPhase(t, C, w.phase, call.at, call.at + w.callSeconds) then
			key = call.key
		end
	end
	local root = npcRoot("natour")
	if root and not watchBubble then
		watchBubble = bubble(root, root.Size.Y / 2 + 2.6)
	end
	local wb = watchBubble
	if wb then
		say(wb, key)
	end
	local cm = w.cameo
	local s = LobbyLife.inPhase(t, C, w.phase, cm.from, cm.from + cm.length)
	if not s then
		if cameo then
			cameo.model:Destroy()
			cameo = nil
		end
		return
	end
	if not cameo then
		cameo = walker("Adashari", "adashari", (Units :: any).adashari.visual, "beggar")
	end
	local legT = LobbyLife.routeCycle(cm.route, cm.speed, 0) / 2
	local pause = (cm.length - 2 * legT) / 2
	local x, z, yaw, moving = LobbyLife.route(cm.route, cm.speed, pause, s)
	local cw = cameo :: Walker
	local cf = CFrame.new(x, 0, z) * CFrame.Angles(0, yaw, 0)
	cw.model:PivotTo(cf)
	if near(cf.Position, cam) then
		stride(cw, moving, cm.speed, dt)
	end
end

local function clearAll()
	setGate(100)
	if patrol then
		hidePostCorporal(false)
	end
	folder:ClearAllChildren() -- every beat figure and bubble lives here
	dispute, coffee, cameo, patrol = nil, nil, nil, nil
	watchBubble, zaimBubble = nil, nil
end

local acc = 0
local function step(dt: number)
	acc += dt
	if acc < 1 / Cfg.hz then
		return
	end
	local span = acc
	acc = 0
	if Fx.laneLife() == "off" or MatchController.state() then
		if lastPhase ~= nil then
			clearAll()
			lastPhase = nil
		end
		return
	end
	local t = now()
	local camera = Workspace.CurrentCamera
	local cam = if camera then camera.CFrame.Position else Vector3.zero
	local phase = LobbyLife.clock(t, C)
	if lastPhase == "night" and phase == "dawn" then
		AudioController.sting("rooster")
	end
	lastPhase = phase
	setGate(LobbyLife.gateAngle(t, C, B.gate))
	runPatrol(t, cam, span)
	runDispute(t)
	runCoffee(t)
	runWatch(t, cam, span)
end

function LaneBeatsController.start()
	folder = Instance.new("Folder")
	folder.Name = "LaneBeats"
	folder.Parent = Workspace
	RunService.Heartbeat:Connect(step)
	LocaleController.Changed:Connect(function()
		for _, b in { watchBubble, zaimBubble } do
			if b then
				b.key = nil -- redrawn in the new language on the next step
			end
		end
		local d, c = dispute, coffee
		if d then
			for _, b in d.bubbles do
				b.key = nil
			end
		end
		if c then
			c.bubble.key = nil
		end
	end)
end

return LaneBeatsController
