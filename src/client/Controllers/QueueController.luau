--!strict
-- Portals: localized billboards over the mode pads (name, lock state, party count) and the party
-- panel while the player stands on one (players, countdown, difficulty picker for the host, Leave).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local TD = require(Shared.Config.TD)
local Modes = require(Shared.Config.Modes)
local MatchRewards = require(Shared.Logic.MatchRewards)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Root = require(UI.Root)
local StateController = require(script.Parent.StateController)
local LocaleController = require(script.Parent.LocaleController)

local QueueController = {}

type Label = { pad: BasePart, modeId: string, name: TextLabel, sub: TextLabel }
local labels: { [BasePart]: Label } = {}

local panel: Frame
local title: TextLabel
local players: TextLabel
local countdown: TextLabel
local diffRow: Frame
local diffButtons: { [string]: TextButton } = {}
local hostNote: TextLabel
local leaveButton: TextButton
local current: any = nil

local function updateLabel(l: Label)
	local t = LocaleController.t
	local mode = (Modes :: any)[l.modeId]
	local snapshot = StateController.get()
	l.name.Text = t(mode.nameKey)
	local count = l.pad:GetAttribute("Count") or 0
	local locked = false
	if snapshot then
		local ok = MatchRewards.canPlay(snapshot, l.modeId, Modes :: any, "normal", TD)
		locked = not ok
	end
	if locked and mode.requires then
		l.sub.Text = t("mode.locked", { mode = t((Modes :: any)[mode.requires].nameKey) })
		l.sub.TextColor3 = Theme.colors.danger
	else
		l.sub.Text = t("queue.players", { n = count, max = TD.MAX_PLAYERS }) .. "\n" .. t(mode.descKey)
		l.sub.TextColor3 = Theme.colors.buttonText
	end
end

local function attach(pad: Instance)
	if not pad:IsA("BasePart") or labels[pad] then
		return
	end
	local modeId = pad:GetAttribute("ModeId")
	if type(modeId) ~= "string" then
		return
	end
	local gui = Create("BillboardGui", {
		Name = "PortalLabel",
		Adornee = pad,
		Size = UDim2.fromOffset(240, 90),
		StudsOffset = Vector3.new(0, 12, 0),
		MaxDistance = 80,
		LightInfluence = 0,
		Parent = pad,
	})
	local name = Theme.label({ TextSize = 18, FontFace = Theme.fontBold, TextColor3 = Theme.colors.buttonText, TextStrokeTransparency = 0.3, Size = UDim2.new(1, 0, 0, 24), Parent = gui })
	name.TextXAlignment = Enum.TextXAlignment.Center
	local sub = Theme.label({ TextSize = 13, TextColor3 = Theme.colors.buttonText, TextStrokeTransparency = 0.3, Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 60), TextYAlignment = Enum.TextYAlignment.Top, Parent = gui })
	sub.TextXAlignment = Enum.TextXAlignment.Center
	local l: Label = { pad = pad, modeId = modeId, name = name, sub = sub }
	labels[pad] = l
	updateLabel(l)
	pad:GetAttributeChangedSignal("Count"):Connect(function()
		updateLabel(l)
	end)
end

local function updateAll()
	for _, l in labels do
		updateLabel(l)
	end
end

local function build()
	panel = Theme.panel({
		Name = "Queue",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, Theme.TOUCH + 14),
		Size = UDim2.fromOffset(360, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 5,
		Visible = false,
		Parent = Root.get(),
	})
	Create("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = panel })
	Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = panel })
	title = Theme.label({ LayoutOrder = 1, TextSize = 16, FontFace = Theme.fontBold, Size = UDim2.new(1, 0, 0, 20), ZIndex = 5, Parent = panel })
	players = Theme.label({ LayoutOrder = 2, TextSize = 13, TextColor3 = Theme.colors.textMuted, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 5, Parent = panel })
	countdown = Theme.label({ LayoutOrder = 3, TextSize = 15, FontFace = Theme.fontBold, TextColor3 = Theme.colors.accent, Size = UDim2.new(1, 0, 0, 18), ZIndex = 5, Parent = panel })
	diffRow = Create("Frame", { LayoutOrder = 4, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 36), ZIndex = 5, Parent = panel })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = diffRow })
	for i, d in TD.DIFFICULTY_ORDER do
		local b = Theme.button({ LayoutOrder = i, TextSize = 13, Size = UDim2.fromOffset(106, 36), ZIndex = 5, Parent = diffRow })
		diffButtons[d] = b
		b.Activated:Connect(function()
			Net.event(Net.Events.QueueSetDifficulty):FireServer(d)
		end)
	end
	hostNote = Theme.label({ LayoutOrder = 5, TextSize = 12, TextColor3 = Theme.colors.textMuted, Size = UDim2.new(1, 0, 0, 16), ZIndex = 5, Parent = panel })
	leaveButton = Theme.button({ LayoutOrder = 6, TextSize = 14, Size = UDim2.new(1, 0, 0, Theme.TOUCH - 8), BackgroundColor3 = Theme.colors.danger, ZIndex = 5, Parent = panel })
	leaveButton.Activated:Connect(function()
		Net.event(Net.Events.QueueLeave):FireServer()
	end)
end

local function render()
	if not current then
		panel.Visible = false
		return
	end
	local t = LocaleController.t
	local rtl = LocaleController.isRtl()
	local mode = (Modes :: any)[current.modeId]
	local me = game:GetService("Players").LocalPlayer.Name
	local isHost = current.host == me
	title.Text = t(mode.nameKey)
	players.Text = t("queue.players", { n = #current.players, max = current.max or TD.MAX_PLAYERS }) .. "\n" .. table.concat(current.players, ", ")
	countdown.Text = t("queue.starting", { n = math.ceil(current.countdown or 0) })
	for d, b in diffButtons do
		b.Text = t("difficulty." .. d)
		local chosen = current.difficulty == d
		b.BackgroundColor3 = if chosen then Theme.colors.accent else (if isHost then Theme.colors.button else Theme.colors.buttonDisabled)
		b.AutoButtonColor = isHost
	end
	hostNote.Text = if isHost then "" else t("queue.host")
	leaveButton.Text = t("queue.leave")
	for _, l in { title, players, countdown, hostNote } do
		Theme.align(l, rtl)
	end
	panel.Visible = true
end

function QueueController.start()
	build()
	Net.event(Net.Events.QueueState).OnClientEvent:Connect(function(payload: any)
		current = payload
		render()
	end)
	for _, pad in CollectionService:GetTagged("Portal") do
		task.spawn(attach, pad)
	end
	CollectionService:GetInstanceAddedSignal("Portal"):Connect(function(pad)
		task.spawn(attach, pad)
	end)
	CollectionService:GetInstanceRemovedSignal("Portal"):Connect(function(pad)
		labels[pad :: BasePart] = nil
	end)
	StateController.Changed:Connect(updateAll)
	LocaleController.Changed:Connect(function()
		updateAll()
		render()
	end)
end

return QueueController
