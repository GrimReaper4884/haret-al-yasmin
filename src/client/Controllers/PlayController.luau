--!strict
-- The Play panel (docs/research/ANIME_VANGUARDS_STUDY.md §1): opens when the player walks into
-- the Play arch in the square or taps Play on the lobby rail. Tabs down the left (Story · Endless ·
-- Event), the modes of the tab in the middle, and the selected mode on the right: description,
-- difficulty, waves, rewards, an enemy and boss preview, Create party, and the open parties of
-- that mode to join. Everything shown is a preview; the server re-checks unlocks and sizes.

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local TD = require(Shared.Config.TD)
local Modes = require(Shared.Config.Modes)
local Waves = require(Shared.Config.Waves)
local Enemies = require(Shared.Config.Enemies)
local IconIds = require(Shared.Config.Icons)
local MatchRewards = require(Shared.Logic.MatchRewards)
local PartyLogic = require(Shared.Logic.PartyLogic)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Amount = require(UI.Amount)
local Modal = require(UI.Modal)
local Juice = require(UI.Juice)
local Icons = require(UI.Icons)
local StateController = require(script.Parent.StateController)
local LocaleController = require(script.Parent.LocaleController)
local LobbyMenuController = require(script.Parent.LobbyMenuController)
local ToastController = require(script.Parent.ToastController)

local PlayController = {}

local TABS = { "story", "infinite", "event" }
local TAB_COLORS = { story = Theme.colors.danger, infinite = Color3.fromHex("#3B3F7A"), event = Color3.fromHex("#2F7D6B") }

local modal: Modal.Modal
local tabButtons: { [string]: TextButton } = {}
local list: ScrollingFrame
local detail: Frame
local dName: TextLabel
local dDesc: TextLabel
local dInfo: TextLabel
local dInfoRow: Frame
local dEnemies: TextLabel
local diffRow: Frame
local diffButtons: { [string]: TextButton } = {}
local createButton: TextButton
local partiesLabel: TextLabel
local partiesList: Frame
local emptyLabel: TextLabel

local tab = "story"
local selected: string? = nil
local difficulty = "normal"
local parties: { any } = {}
local inParty = false
local busy = false

-- Modes shown under a tab, in order (event modes only while their event runs; see EventController).
local eventFilter: ((string) -> boolean)? = nil
function PlayController.setEventFilter(fn: (string) -> boolean)
	eventFilter = fn
end

local function modesOf(kind: string): { string }
	local out = {}
	for id, m in Modes :: { [string]: any } do
		if m.kind == kind and (kind ~= "event" or (eventFilter ~= nil and eventFilter(id))) then
			table.insert(out, id)
		end
	end
	table.sort(out, function(a, b)
		return (Modes :: any)[a].order < (Modes :: any)[b].order
	end)
	return out
end

local function canPlay(modeId: string, diff: string): (boolean, string?)
	local snapshot = StateController.get()
	if not snapshot then
		return false, "no_state"
	end
	return MatchRewards.canPlay(snapshot, modeId, Modes :: any, diff, TD)
end

local function wavesText(mode: any): string
	local t = LocaleController.t
	if mode.kind == "story" then
		return t("play.waves", { n = Waves.episodes[mode.episode].waves })
	elseif mode.kind == "event" and mode.waves then
		return t("play.waves", { n = mode.waves })
	end
	return t("play.waves_endless")
end

-- Story rewards as icon entries (UI/Amount); other modes describe their reward in text (nil here).
local function rewardEntries(modeId: string, mode: any): { Amount.Entry }?
	local t = LocaleController.t
	local diff = TD.DIFFICULTIES[difficulty]
	local base = (TD.STORY_REWARDS :: any)[modeId]
	if mode.kind == "story" and base then
		local mul = diff.reward
		return {
			{ text = wavesText(mode) .. "  ·  " .. t("play.rewards") .. ":" },
			{ icon = "lira", text = tostring(math.floor(base.lira * mul)) },
			{ icon = "qirsh", text = tostring(math.floor(base.qirsh * mul)) },
			{ icon = "xp", text = tostring(math.floor(base.xp * mul)) },
			{ text = "(" .. t("play.first_clear") .. ")" },
		}
	end
	return nil
end

local function rewardText(modeId: string, mode: any): string
	local t = LocaleController.t
	if mode.kind == "story" and (TD.STORY_REWARDS :: any)[modeId] then
		return ""
	elseif mode.kind == "event" and mode.rewardKey then
		return t("play.rewards") .. ": " .. t(mode.rewardKey)
	end
	return t("play.rewards") .. ": " .. t(mode.descKey)
end

local function enemyText(mode: any): string
	local t = LocaleController.t
	local pool, bosses = PartyLogic.enemiesOf(mode, Waves)
	local function names(ids: { string }): string
		local out = {}
		for _, id in ids do
			local def = (Enemies :: any)[id]
			table.insert(out, if def then t(def.nameKey) else id)
		end
		return table.concat(out, " · ")
	end
	local lines = { t("play.enemies") .. ": " .. names(pool) }
	if #bosses > 0 then
		table.insert(lines, t("play.bosses") .. ": " .. names(bosses))
	end
	return table.concat(lines, "\n")
end

local render: () -> ()

local function pick(modeId: string?)
	selected = modeId
	difficulty = "normal"
	render()
end

local function card(modeId: string, i: number): TextButton
	local t = LocaleController.t
	local mode = (Modes :: any)[modeId]
	local unlocked = canPlay(modeId, "normal")
	local on = selected == modeId
	local b = Theme.button({
		Name = modeId,
		LayoutOrder = i,
		Text = "",
		Size = UDim2.new(1, -8, 0, 64),
		BackgroundColor3 = if not unlocked then Theme.colors.buttonDisabled else TAB_COLORS[mode.kind] or Theme.colors.button,
		ZIndex = 12,
		Parent = list,
	})
	-- The mode's painted banner (PV-C06) behind the text, dimmed so the outlined labels read on it.
	local art = IconIds.modes[modeId]
	if art and art.id > 0 then
		local banner = Create("ImageLabel", {
			Name = "Banner",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Image = "rbxassetid://" .. tostring(art.id),
			ScaleType = Enum.ScaleType.Crop,
			ImageColor3 = if unlocked then Color3.fromRGB(175, 170, 165) else Color3.fromRGB(80, 80, 80),
			ZIndex = 12,
			Parent = b,
		}, { Create("UICorner", { CornerRadius = UDim.new(0, 10) }) })
		Create("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.25), NumberSequenceKeypoint.new(1, 0) }),
			Parent = banner,
		})
	end
	if on then
		local border = b:FindFirstChild("Border") :: UIStroke?
		if border then
			border.Color = Theme.colors.gold
			border.Thickness = 3.5
		end
	end
	local name = Theme.display({ Text = t(mode.nameKey), TextSize = 14, Position = UDim2.fromOffset(0, 6), Size = UDim2.new(1, 0, 0, 34), ZIndex = 13, Parent = b })
	name.TextYAlignment = Enum.TextYAlignment.Top
	local snapshot = StateController.get()
	local cleared = snapshot and (snapshot.td.cleared :: any)[modeId]
	local sub = if not unlocked then t("play.locked") elseif cleared then t("play.cleared", { d = t("difficulty." .. cleared) }) else wavesText(mode)
	Theme.display({ Text = sub, TextSize = 12, TextColor3 = Color3.fromHex("#FFD970"), AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, -6), Size = UDim2.new(1, 0, 0, 14), ZIndex = 13, Parent = b })
	Theme.align(name, LocaleController.isRtl())
	b.Activated:Connect(function()
		pick(modeId)
	end)
	return b
end

local function partyRow(p: any, i: number)
	local t = LocaleController.t
	local row = Create("Frame", { LayoutOrder = i, BackgroundColor3 = Theme.colors.panelStroke, BackgroundTransparency = 0.85, Size = UDim2.new(1, 0, 0, 34), ZIndex = 12, Parent = partiesList }, { Create("UICorner", { CornerRadius = UDim.new(0, 8) }) })
	local label = Theme.label({
		Text = string.format("%s  ·  %s  ·  %d/%d  ·  %ds", t("play.party_of", { name = p.host }), t("difficulty." .. p.difficulty), p.count, p.max, p.countdown),
		TextSize = 13,
		Position = UDim2.fromOffset(8, 0),
		Size = UDim2.new(1, -96, 1, 0),
		ZIndex = 13,
		Parent = row,
	})
	Theme.align(label, LocaleController.isRtl())
	local join = Theme.button({ Text = t("play.join"), TextSize = 13, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -3, 0.5, 0), Size = UDim2.fromOffset(84, 30), BackgroundColor3 = Theme.colors.confirm, ZIndex = 13, Parent = row })
	join.Activated:Connect(function()
		if busy then
			return
		end
		busy = true
		task.spawn(function()
			local ok, res = pcall(function()
				return Net.func(Net.Functions.PartyJoin):InvokeServer(p.id)
			end)
			busy = false
			if ok and type(res) == "table" and res.ok then
				modal.setVisible(false)
			elseif ok and type(res) == "table" and res.err == "full" then
				ToastController.show("notify.error")
			end
		end)
	end)
end

render = function()
	if not modal or not modal.isOpen() then
		return
	end
	local t = LocaleController.t
	local rtl = LocaleController.isRtl()
	modal.title.Text = t("play.title")
	Theme.align(modal.title, rtl)
	for key, b in tabButtons do
		b.Text = t("play.tab." .. key)
		b.BackgroundColor3 = if key == tab then TAB_COLORS[key] else Theme.colors.buttonDisabled
	end
	-- Mode list
	for _, c in list:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local ids = modesOf(tab)
	if selected == nil or (Modes :: any)[selected] == nil or (Modes :: any)[selected].kind ~= tab then
		selected = ids[1]
	end
	for i, id in ids do
		card(id, i)
	end
	emptyLabel.Visible = #ids == 0
	emptyLabel.Text = if tab == "event" then t("play.event_none") else ""
	detail.Visible = selected ~= nil
	local modeId = selected
	if not modeId then
		return
	end
	local mode = (Modes :: any)[modeId]
	dName.Text = t(mode.nameKey)
	dDesc.Text = t(mode.descKey)
	local entries = rewardEntries(modeId, mode)
	dInfo.Text = if entries then "" else wavesText(mode) .. "   ·   " .. rewardText(modeId, mode)
	Amount.fill(dInfoRow, entries or {}, { iconSize = 24, textSize = 12, bold = true, align = Enum.HorizontalAlignment.Left, rtl = rtl })
	dEnemies.Text = enemyText(mode)
	for _, l in { dName, dDesc, dInfo, dEnemies } do
		Theme.align(l, rtl)
	end
	diffRow.Visible = mode.kind ~= "event"
	for d, b in diffButtons do
		b.Text = t("difficulty." .. d)
		local ok = canPlay(modeId, d)
		b.BackgroundColor3 = if d == difficulty then Theme.colors.accent elseif ok then Theme.colors.button else Theme.colors.buttonDisabled
	end
	local unlocked = canPlay(modeId, difficulty)
	createButton.Text = if unlocked then t("play.create") else t("play.locked")
	createButton.BackgroundColor3 = if unlocked and not inParty then Theme.colors.confirm else Theme.colors.buttonDisabled
	-- Open parties of this mode
	partiesLabel.Text = t("play.parties")
	Theme.align(partiesLabel, rtl)
	for _, c in partiesList:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local n = 0
	local me = Players.LocalPlayer.Name
	for _, p in parties do
		if p.modeId == modeId and p.host ~= me and n < 3 then
			n += 1
			partyRow(p, n)
		end
	end
	if n == 0 then
		local none = Theme.label({ Text = t("play.no_parties"), TextSize = 12, TextColor3 = Theme.colors.textMuted, Size = UDim2.new(1, 0, 0, 18), ZIndex = 12, Parent = partiesList })
		Theme.align(none, rtl)
	end
end

local function build()
	modal = Modal.create("Play", 780, 252)
	local body = modal.body

	-- Tabs
	local tabs = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0, 104, 1, 0), ZIndex = 11, Parent = body })
	Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = tabs })
	for i, key in TABS do
		local b = Theme.button({ LayoutOrder = i, TextSize = 15, Size = UDim2.new(1, 0, 0, 52), ZIndex = 12, Parent = tabs })
		tabButtons[key] = b
		b.Activated:Connect(function()
			tab = key
			selected = nil
			render()
		end)
	end

	-- Mode list
	local listHolder = Create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(112, 0), Size = UDim2.new(0, 210, 1, 0), ZIndex = 11, Parent = body })
	list = Modal.scroller(listHolder)
	Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	emptyLabel = Theme.label({ TextSize = 13, TextColor3 = Theme.colors.textMuted, Size = UDim2.new(1, -8, 0, 60), ZIndex = 12, Visible = false, Parent = listHolder })

	-- Detail
	detail = Create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(330, 0), Size = UDim2.new(1, -330, 1, 0), ZIndex = 11, Parent = body })
	dName = Theme.display({ TextSize = 20, Size = UDim2.new(1, 0, 0, 24), ZIndex = 12, Parent = detail })
	dDesc = Theme.label({ TextSize = 13, TextColor3 = Theme.colors.textMuted, Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 30), TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 12, Parent = detail })
	diffRow = Create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 58), Size = UDim2.new(1, 0, 0, 32), ZIndex = 12, Parent = detail })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = diffRow })
	for i, d in TD.DIFFICULTY_ORDER do
		local b = Theme.button({ LayoutOrder = i, TextSize = 13, Size = UDim2.fromOffset(126, 32), ZIndex = 12, Parent = diffRow })
		diffButtons[d] = b
		-- Difficulty ribbon (PV-C06) at the leading edge, the label shifted past it.
		local ribbon = Create("Frame", { Name = "Ribbon", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 0), Size = UDim2.fromOffset(24, 24), ZIndex = 13, Parent = b })
		Icons.draw("diff_" .. d, ribbon)
		Create("UIPadding", { PaddingLeft = UDim.new(0, 26), PaddingRight = UDim.new(0, 2), Parent = b })
		b.Activated:Connect(function()
			if selected and canPlay(selected, d) then
				difficulty = d
				render()
			else
				Juice.shake(b)
				ToastController.show("mode.locked_difficulty")
			end
		end)
	end
	dInfo = Theme.label({ TextSize = 12, FontFace = Theme.fontBold, Position = UDim2.fromOffset(0, 94), Size = UDim2.new(1, 0, 0, 30), TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 12, Parent = detail })
	dInfoRow = Amount.row({ Name = "Rewards", Position = UDim2.fromOffset(0, 92), Size = UDim2.new(1, 0, 0, 30), ZIndex = 12, Parent = detail }, {})
	dEnemies = Theme.label({ TextSize = 12, TextColor3 = Theme.colors.textMuted, Position = UDim2.fromOffset(0, 124), Size = UDim2.new(1, 0, 0, 30), TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 12, Parent = detail })

	createButton = Theme.button({ TextSize = 16, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(0.38, 0, 0, 44), BackgroundColor3 = Theme.colors.confirm, ZIndex = 12, Parent = detail })
	createButton.Activated:Connect(function()
		local modeId = selected
		if busy or inParty or not modeId then
			return
		end
		if not canPlay(modeId, difficulty) then
			Juice.shake(createButton)
			return
		end
		busy = true
		task.spawn(function()
			local ok, res = pcall(function()
				return Net.func(Net.Functions.PartyCreate):InvokeServer(modeId, difficulty)
			end)
			busy = false
			if ok and type(res) == "table" and res.ok then
				modal.setVisible(false)
			end
		end)
	end)
	local partiesBox = Create("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1), Size = UDim2.new(0.6, 0, 0, 92), ZIndex = 12, Parent = detail })
	partiesLabel = Theme.label({ TextSize = 12, FontFace = Theme.fontBold, Size = UDim2.new(1, 0, 0, 16), ZIndex = 12, Parent = partiesBox })
	partiesList = Create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 1, -18), ZIndex = 12, Parent = partiesBox })
	Create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = partiesList })
end

function PlayController.open(tabKey: string?)
	if tabKey then
		tab = tabKey
		selected = nil
	end
	modal.setVisible(true)
	render()
end

-- Opens the panel once each time the player walks into a PlayGate pad (not during a match or
-- while already in a party).
local function watchGates()
	local inside = false
	while true do
		task.wait(0.3)
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local now = false
		if root then
			for _, pad in CollectionService:GetTagged("PlayGate") do
				if pad:IsA("BasePart") then
					local l = pad.CFrame:PointToObjectSpace(root.Position)
					if math.abs(l.X) <= pad.Size.X / 2 and math.abs(l.Z) <= pad.Size.Z / 2 and l.Y < 10 then
						now = true
						local kind = pad:GetAttribute("Tab")
						if now and not inside and not inParty and not modal.isOpen() and root.Position.Y < 200 then
							PlayController.open(if type(kind) == "string" then kind else "story")
						end
					end
				end
			end
		end
		inside = now
	end
end

function PlayController.start()
	build()
	LobbyMenuController.register("play", function()
		PlayController.open()
	end)
	Net.event(Net.Events.PartyList).OnClientEvent:Connect(function(payload: any)
		if type(payload) == "table" then
			parties = payload
			render()
		end
	end)
	Net.event(Net.Events.QueueState).OnClientEvent:Connect(function(payload: any)
		inParty = payload ~= nil
		render()
	end)
	StateController.Changed:Connect(render)
	LocaleController.Changed:Connect(render)
	task.spawn(watchGates)
end

return PlayController
