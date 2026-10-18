--!strict
-- The loading screen (POLISH_PLAN PV-D05). Runs from ReplicatedFirst before anything else: a
-- limestone backdrop with ablaq bands, the mark fading in (the drawn arch until the owner's logo is
-- uploaded, LoadingLook.images), jasmine petals drifting down, the wordmark, a thin ablaq progress
-- bar driven by ContentProvider.RequestQueueSize and bilingual lines, then a short crossfade into the
-- lobby once the game is loaded, the queue is empty and our character exists (LoadingLogic.done).
-- Roblox's Reduced Motion setting keeps it static (no petals, no fades).

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Look = require(script.Parent:WaitForChild("LoadingLook"))
local LoadingLogic = require(script.Parent:WaitForChild("LoadingLogic"))

local player = Players.LocalPlayer
local started = os.clock()

local reducedMotion = false
pcall(function()
	reducedMotion = (UserSettings():GetService("UserGameSettings") :: any).ReducedMotion == true
end)

local function hex(s: string): Color3
	return Color3.fromHex(s)
end
local C = Look.colors

local function frame(props: { [string]: any }, parent: Instance): Frame
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	for k, v in props do
		(f :: any)[k] = v
	end
	f.Parent = parent
	return f
end

local function corner(parent: Instance, scale: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(scale, 0)
	c.Parent = parent
end

-- Alternating basalt / honey stripes (the ablaq) along a frame (rotation 0: along X, 90: along Y).
-- A ColorSequence holds at most 20 keypoints, so long runs are split into segments of 10 stripes.
local MAX_BANDS = 10
local function stripes(parent: GuiObject, bands: number, rotation: number, startIndex: number)
	local g = Instance.new("UIGradient")
	local keys = {}
	for _, stop in LoadingLogic.stripeStops(bands) do
		local c = if (startIndex + stop[2]) % 2 == 0 then hex(C.basalt) else hex(C.honey)
		table.insert(keys, ColorSequenceKeypoint.new(stop[1], c))
	end
	g.Color = ColorSequence.new(keys)
	g.Rotation = rotation
	g.Parent = parent
end

local function ablaq(parent: GuiObject, bands: number, rotation: number)
	if bands <= MAX_BANDS then
		stripes(parent, bands, rotation, 0)
		return
	end
	parent.BackgroundTransparency = 1
	local segments = math.ceil(bands / MAX_BANDS)
	for k = 0, segments - 1 do
		local n = math.min(MAX_BANDS, bands - k * MAX_BANDS)
		local share = n / bands
		local seg = Instance.new("Frame")
		seg.Name = "Stripes"
		seg.BorderSizePixel = 0
		seg.BackgroundColor3 = Color3.new(1, 1, 1)
		if rotation == 90 then
			seg.Position = UDim2.fromScale(0, k * MAX_BANDS / bands)
			seg.Size = UDim2.fromScale(1, share)
		else
			seg.Position = UDim2.fromScale(k * MAX_BANDS / bands, 0)
			seg.Size = UDim2.fromScale(share, 1)
		end
		stripes(seg, n, rotation, k * MAX_BANDS)
		seg.Parent = parent
	end
end

---------------------------------------------------------------- build

local gui = Instance.new("ScreenGui")
gui.Name = "HaretLoading"
gui.IgnoreGuiInset = true
gui.ScreenInsets = Enum.ScreenInsets.None -- full bleed: no world showing round a phone's notch / safe area
gui.ResetOnSpawn = false
gui.DisplayOrder = 1000
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local root = Instance.new("CanvasGroup")
root.Name = "Root"
root.Size = UDim2.fromScale(1, 1)
root.BackgroundColor3 = hex(C.backdrop)
root.BorderSizePixel = 0
root.Parent = gui

-- Ablaq bands along the top and bottom edges
for _, y in { 0, 1 } do
	local band = frame({
		Name = "Band",
		AnchorPoint = Vector2.new(0, y),
		Position = UDim2.fromScale(0, y),
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundColor3 = Color3.new(1, 1, 1),
	}, root)
	ablaq(band, 40, 0)
end

-- Centre column: mark, wordmark, bar, line
local column = frame({
	Name = "Column",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.47),
	Size = UDim2.fromScale(0.8, 0.8),
	BackgroundTransparency = 1,
}, root)
local ratio = Instance.new("UIAspectRatioConstraint")
ratio.AspectRatio = 0.9
ratio.Parent = column

local mark: GuiObject
do
	-- The drawn arch: ablaq frame, wooden door, jasmine over the top-left
	local m = Instance.new("Frame")
	m.BackgroundTransparency = 1
	local arch = frame({
		Name = "Arch",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.fromScale(0.62, 0.92),
		BackgroundColor3 = Color3.new(1, 1, 1),
	}, m)
	corner(arch, 0.5)
	ablaq(arch, 9, 90)
	local door = frame({
		Name = "Door",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.fromScale(0.62, 0.8),
		BackgroundColor3 = hex(C.door),
	}, arch)
	corner(door, 0.5)
	frame({
		Name = "Seam",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.new(0, 2, 0.7, 0),
		BackgroundColor3 = hex(C.basalt),
	}, door)
	for i, p in
		{
			{ 0.18, 0.12, 0.22 },
			{ 0.3, 0.02, 0.2 },
			{ 0.08, 0.3, 0.2 },
			{ 0.44, 0.0, 0.16 },
			{ 0.12, 0.5, 0.16 },
		}
	do
		local leaf = frame({
			Name = "Leaf",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(p[1], p[2] + 0.06),
			Size = UDim2.fromScale(p[3], p[3] * 0.9),
			BackgroundColor3 = hex(C.leaf),
		}, m)
		corner(leaf, 0.5)
		local flower = frame({
			Name = "Flower",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(p[1] + 0.03 * (i % 2), p[2] + 0.04),
			Size = UDim2.fromScale(p[3] * 0.45, p[3] * 0.42),
			BackgroundColor3 = hex(C.jasmine),
		}, m)
		corner(flower, 0.5)
	end
	mark = m
end
mark.Name = "Mark"
mark.AnchorPoint = Vector2.new(0.5, 0)
mark.Position = UDim2.fromScale(0.5, 0)
mark.Size = UDim2.fromScale(0.5, 0.45)
mark.Parent = column

local function label(
	name: string,
	text: string,
	y: number,
	h: number,
	color: string,
	stroke: boolean
): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.AnchorPoint = Vector2.new(0.5, 0)
	l.Position = UDim2.fromScale(0.5, y)
	l.Size = UDim2.fromScale(1, h)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextScaled = true
	l.FontFace = Font.fromEnum(Enum.Font.FredokaOne)
	l.TextColor3 = hex(color)
	if stroke then
		local s = Instance.new("UIStroke")
		s.Color = hex(C.text)
		s.Thickness = 3
		s.Parent = l
	end
	l.Parent = column
	return l
end

local wordAr = label("WordmarkAr", Look.wordmark.ar, 0.47, 0.14, C.gold, true)
local wordEn = label("WordmarkEn", Look.wordmark.en, 0.61, 0.09, C.gold, true)

-- The owner's logo images (PV-D01) replace the drawn mark and the text wordmark, but only once they
-- have actually loaded: an image still in moderation or failing to load leaves the fallbacks up.
local function swapIn(id: number, name: string, pos: UDim2, size: UDim2, fallbacks: { GuiObject })
	if id == 0 then
		return
	end
	local img = Instance.new("ImageLabel")
	img.Name = name
	img.Image = "rbxassetid://" .. tostring(id)
	img.BackgroundTransparency = 1
	img.ImageTransparency = 1
	img.ScaleType = Enum.ScaleType.Fit
	img.AnchorPoint = Vector2.new(0.5, 0)
	img.Position = pos
	img.Size = size
	img.Parent = column
	task.spawn(function()
		local ok = false
		pcall(function()
			ContentProvider:PreloadAsync({ img }, function(_, status: Enum.AssetFetchStatus)
				ok = status == Enum.AssetFetchStatus.Success
			end)
		end)
		if ok and img.Parent then
			img.ImageTransparency = 0
			for _, f in fallbacks do
				f.Visible = false
			end
		end
	end)
end
swapIn(Look.images.mark, "MarkImage", UDim2.fromScale(0.5, 0), UDim2.fromScale(0.5, 0.45), { mark })
swapIn(
	Look.images.wordmark,
	"WordmarkImage",
	UDim2.fromScale(0.5, 0.47),
	UDim2.fromScale(1, 0.24),
	{ wordAr, wordEn }
)

-- The progress bar: a basalt track with an ablaq fill
local track = frame({
	Name = "Track",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.76),
	Size = UDim2.new(0.7, 0, 0, 10),
	BackgroundColor3 = hex(C.basalt),
	BackgroundTransparency = 0.6,
}, column)
corner(track, 0.5)
local fill =
	frame({ Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1) }, track)
corner(fill, 0.5)
ablaq(fill, 16, 0)

local lineEn = label("LineEn", "", 0.81, 0.06, C.text, false)
local lineAr = label("LineAr", "", 0.875, 0.06, C.text, false)

-- Jasmine petals drifting down (static under Reduced Motion)
local petals: { ImageLabel } = {}
if Look.images.petal ~= 0 then
	local P = Look.petals
	for i = 1, P.count do
		local p = Instance.new("ImageLabel")
		p.Name = "Petal"
		p.BackgroundTransparency = 1
		p.Image = "rbxassetid://" .. tostring(Look.images.petal)
		p.ImageColor3 = hex(C.jasmine)
		local s = math.random(P.minSize, P.maxSize)
		p.Size = UDim2.fromOffset(s, s)
		p.Position = UDim2.fromScale((i - 0.5) / P.count + (math.random() - 0.5) * 0.05, math.random())
		p.Rotation = math.random(0, 360)
		p.ImageTransparency = 0.15
		p.Parent = root
		table.insert(petals, p)
	end
end

-- Failsafe: whatever goes wrong below, the screen never outlives maxTime by more than a moment.
task.delay(Look.maxTime + 2, function()
	if gui.Parent then
		gui:Destroy()
	end
end)
gui.Parent = player:WaitForChild("PlayerGui")
ReplicatedFirst:RemoveDefaultLoadingScreen()

---------------------------------------------------------------- animate

if not reducedMotion then
	root.GroupTransparency = 0
	mark.Position = UDim2.fromScale(0.5, 0.03)
	local markTween = TweenService:Create(
		mark,
		TweenInfo.new(Look.markFade, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = UDim2.fromScale(0.5, 0) }
	)
	markTween:Play()
	for _, p in petals do
		local fallFor = Look.petals.minFall + math.random() * (Look.petals.maxFall - Look.petals.minFall)
		task.spawn(function()
			while p.Parent do
				local startX = p.Position.X.Scale
				p.Position = UDim2.fromScale(startX, -0.05)
				local tw = TweenService:Create(p, TweenInfo.new(fallFor, Enum.EasingStyle.Linear), {
					Position = UDim2.fromScale(startX + (math.random() - 0.5) * 0.12, 1.05),
					Rotation = p.Rotation + math.random(-180, 180),
				})
				tw:Play()
				tw.Completed:Wait()
			end
		end)
	end
end

local maxQueue = 0
local shown = 0
local lastLine = 0
local finished = false
local conn: RBXScriptConnection? = nil

local function finish()
	if finished then
		return
	end
	finished = true
	if conn then
		conn:Disconnect()
	end
	local total = os.clock() - started
	player:SetAttribute("LoadingDoneAt", total)
	print(string.format("[Loading] done in %.2f s", total))
	if reducedMotion then
		gui:Destroy()
		return
	end
	local tw = TweenService:Create(
		root,
		TweenInfo.new(Look.fade, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ GroupTransparency = 1 }
	)
	tw.Completed:Once(function()
		gui:Destroy()
	end)
	tw:Play()
end

conn = RunService.RenderStepped:Connect(function(dt: number)
	local elapsed = os.clock() - started
	local queue = ContentProvider.RequestQueueSize
	maxQueue = math.max(maxQueue, queue)
	shown = LoadingLogic.ease(shown, LoadingLogic.progress(maxQueue, queue), dt, 6)
	fill.Size = UDim2.fromScale(shown, 1)
	local n = LoadingLogic.line(elapsed, Look.lineEvery, #Look.lines)
	if n ~= lastLine then
		lastLine = n
		lineEn.Text = Look.lines[n].en
		lineAr.Text = Look.lines[n].ar
	end
	local state = {
		elapsed = elapsed,
		loaded = game:IsLoaded(),
		queue = queue,
		ready = player.Character ~= nil,
	}
	-- Studio only: Workspace attribute DebugHoldLoading (seconds, set in Edit before Play) holds the
	-- screen longer for screenshots; ignored in live servers.
	local hold = if RunService:IsStudio()
		then tonumber(workspace:GetAttribute("DebugHoldLoading")) or 0
		else 0
	if LoadingLogic.done(state, Look.minTime + hold, Look.maxTime) then
		fill.Size = UDim2.fromScale(1, 1)
		finish()
	end
end)
