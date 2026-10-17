--!strict
-- Lobby chrome for the tower-defense update: the lira pill next to the coins, and the left
-- menu grid (Play, Units, Summon, Diary, Daily, Codes, Settings, and Event while one runs). Hides the whole lobby HUD while a match is on
-- or a dialogue is open, so the phone screen stays clear.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Daily = require(Shared.Config.Daily)
local DailyLogic = require(Shared.Logic.DailyLogic)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Root = require(UI.Root)
local Icons = require(UI.Icons)
local Juice = require(UI.Juice)
local StateController = require(script.Parent.StateController)
local LocaleController = require(script.Parent.LocaleController)

local LobbyMenuController = {}

local LOBBY_WIDGETS = { "Coins", "Errand", "Language", "Wardrobe", "Music", "Lira", "Menu", "TestMode" }

local liraLabel: TextLabel
local bar: Frame
local buttons: { [string]: TextButton } = {}
local badges: { [string]: Frame } = {}
local inMatch = false
local inAfk = false -- sitting in the Hakawati's room (AfkController): the lobby HUD is hidden too
local openers: { [string]: () -> () } = {}
local lastLira: number? = nil

-- Other controllers register what their button opens (avoids require cycles).
function LobbyMenuController.register(key: string, open: () -> ())
	openers[key] = open
end

function LobbyMenuController.opener(key: string): (() -> ())?
	return openers[key]
end

-- Shows or hides one entry (the Event button exists only while an event runs).
local hidden: { [string]: boolean } = { event = true }
function LobbyMenuController.setVisibleEntry(key: string, visible: boolean)
	hidden[key] = not visible
	local b = buttons[key]
	if b then
		b.Visible = visible
	end
end

local function build()
	local root = Root.get()
	local _pill
	_pill, liraLabel = Theme.pill({
		Name = "Lira",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(0.5, -204, 0, 10),
		Size = UDim2.fromOffset(132, 36),
		Parent = root,
	}, Color3.fromHex("#7B3FA0"), "lira")
	liraLabel.TextColor3 = Color3.fromHex("#FFE08A")

	-- Left rail of big icon buttons with red notification badges (the genre's lobby pattern,
	-- docs/research/ROBLOX_TD_UI_PATTERNS.md §2). Leaves the bottom free for dialogue.
	-- A 3 × 3 grid of square buttons (the genre's left grid). It starts just below the middle of
	-- the screen so the PC chat window (top-left) never covers it, and stays clear of the phone's
	-- thumbstick corner.
	local CELL, GAP, COLS = 54, 6, 3
	local items = {
		{ key = "play", color = Theme.colors.danger },
		{ key = "event", color = Color3.fromHex("#2F7D6B") },
		{ key = "units", color = Color3.fromHex("#4C7FC0") },
		{ key = "summon", color = Color3.fromHex("#9B4FD1") },
		{ key = "pass", color = Theme.colors.quest },
		{ key = "daily", color = Theme.colors.confirm },
		{ key = "codes", color = Color3.fromHex("#5E6F7D") },
		{ key = "afk", color = Color3.fromHex("#8A5A2B") },
		{ key = "settings", color = Color3.fromHex("#6E5E50") },
	}
	local rows = math.ceil(#items / COLS)
	bar = Create("Frame", {
		Name = "Menu",
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.new(0, 10, 0.45, 0),
		Size = UDim2.fromOffset(COLS * CELL + (COLS - 1) * GAP, rows * CELL + (rows - 1) * GAP),
		BackgroundTransparency = 1,
		Parent = root,
	})
	Create("UIGridLayout", {
		CellSize = UDim2.fromOffset(CELL, CELL),
		CellPadding = UDim2.fromOffset(GAP, GAP),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = bar,
	})
	for i, it in items do
		local b = Theme.button({
			Name = it.key,
			LayoutOrder = i,
			Text = "",
			Size = UDim2.fromOffset(CELL, CELL),
			BackgroundColor3 = it.color,
			Parent = bar,
		})
		local pad = b:FindFirstChildOfClass("UIPadding")
		if pad then
			pad:Destroy()
		end
		local icon = Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 4),
			Size = UDim2.fromOffset(30, 30),
			BackgroundTransparency = 1,
			Parent = b,
		})
		Icons.draw("ui_" .. it.key, icon)
		if it.key == "daily" then
			Juice.wobble(icon, function()
				local badge: Frame? = badges.daily
				return if badge then badge.Visible else false
			end)
		end
		local caption = Theme.display({
			Name = "Caption",
			TextSize = 11,
			Size = UDim2.new(1, 0, 0, 15),
			Position = UDim2.fromOffset(0, 36),
			Parent = b,
		})
		caption.TextXAlignment = Enum.TextXAlignment.Center
		local badge = Create("Frame", {
			Name = "Badge",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(1, -4, 0, 4),
			Size = UDim2.fromOffset(20, 20),
			BackgroundColor3 = Color3.fromHex("#E0433A"),
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 3,
			Parent = b,
		}, {
			Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
			Create("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		})
		local bang = Theme.display({ Text = "!", TextSize = 14, Size = UDim2.fromScale(1, 1), ZIndex = 4, Parent = badge })
		bang.TextXAlignment = Enum.TextXAlignment.Center
		badges[it.key] = badge
		buttons[it.key] = b
		b.Visible = not hidden[it.key]
		b.Activated:Connect(function()
			local open = openers[it.key]
			if open then
				open()
			end
		end)
	end
end

local function applyVisibility()
	local root = Root.get()
	local dialogue = root:FindFirstChild("Dialogue")
	local dialogueOpen = dialogue ~= nil and (dialogue :: Frame).Visible
	local away = inMatch or inAfk
	for _, name in LOBBY_WIDGETS do
		local w = root:FindFirstChild(name)
		if w and w:IsA("GuiObject") then
			if name == "Menu" then
				w.Visible = not away and not dialogueOpen
			elseif name == "TestMode" then
				local snapshot = StateController.get()
				w.Visible = not away and snapshot ~= nil and not snapshot.persistent
			else
				w.Visible = not away
			end
		end
	end
end

function LobbyMenuController.setInMatch(v: boolean)
	inMatch = v
	applyVisibility()
end

function LobbyMenuController.setInAfk(v: boolean)
	inAfk = v
	applyVisibility()
end

local function render()
	local t = LocaleController.t
	local snapshot = StateController.get()
	if snapshot then
		-- The lira icon carries the unit; the pill shows the number only.
		local function fmt(n: number): string
			return tostring(n)
		end
		if lastLira and lastLira ~= snapshot.lira then
			Juice.count(liraLabel, lastLira, snapshot.lira, fmt)
		else
			liraLabel.Text = fmt(snapshot.lira)
		end
		lastLira = snapshot.lira
		local status = DailyLogic.status(snapshot, os.time(), Daily :: any)
		badges.daily.Visible = status.canClaim
		local pending = false
		if snapshot.pass then
			-- a claimable free tier waiting?
			local PassLogic = require(Shared.Logic.PassLogic)
			local SeasonPass = require(Shared.Config.SeasonPass)
			local level = PassLogic.level(snapshot.pass.xp, SeasonPass.tiers)
			for tier = 1, level do
				if not snapshot.pass.claimedFree[tostring(tier)] then
					pending = true
					break
				end
			end
		end
		badges.pass.Visible = pending
	end
	for key, b in buttons do
		local caption = b:FindFirstChild("Caption") :: TextLabel?
		if caption then
			caption.Text = t("hud." .. key)
		end
	end
	applyVisibility()
end

function LobbyMenuController.start()
	build()
	render()
	StateController.Changed:Connect(render)
	LocaleController.Changed:Connect(render)
	task.defer(function()
		local dialogue = Root.get():WaitForChild("Dialogue", 10)
		if dialogue and dialogue:IsA("GuiObject") then
			dialogue:GetPropertyChangedSignal("Visible"):Connect(applyVisibility)
		end
	end)
end

return LobbyMenuController
