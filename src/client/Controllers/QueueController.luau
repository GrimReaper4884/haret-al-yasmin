--!strict
-- The party bar while the player is in a lobby party (made from the Play panel): mode, players,
-- countdown, the host's difficulty picker and Start now, and Leave.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local TD = require(Shared.Config.TD)
local Modes = require(Shared.Config.Modes)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Root = require(UI.Root)
local LocaleController = require(script.Parent.LocaleController)

local QueueController = {}

local panel: Frame
local title: TextLabel
local players: TextLabel
local countdown: TextLabel
local diffRow: Frame
local diffButtons: { [string]: TextButton } = {}
local hostNote: TextLabel
local leaveButton: TextButton
local startButton: TextButton
local current: any = nil

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
	local actions = Create("Frame", { LayoutOrder = 6, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, Theme.TOUCH - 8), ZIndex = 5, Parent = panel })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = actions })
	startButton = Theme.button({ LayoutOrder = 1, TextSize = 14, Size = UDim2.new(0.5, -3, 1, 0), BackgroundColor3 = Theme.colors.confirm, ZIndex = 5, Parent = actions })
	startButton.Activated:Connect(function()
		Net.event(Net.Events.PartyStart):FireServer()
	end)
	leaveButton = Theme.button({ LayoutOrder = 2, TextSize = 14, Size = UDim2.new(0.5, -3, 1, 0), BackgroundColor3 = Theme.colors.danger, ZIndex = 5, Parent = actions })
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
	startButton.Text = t("play.start_now")
	startButton.Visible = isHost
	leaveButton.Size = if isHost then UDim2.new(0.5, -3, 1, 0) else UDim2.fromScale(1, 1)
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
	LocaleController.Changed:Connect(render)
end

return QueueController
