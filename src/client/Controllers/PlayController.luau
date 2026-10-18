--!strict
-- The Play panel (docs/research/ANIME_VANGUARDS_STUDY.md §1): opens when the player walks into
-- the Play arch in the square or taps Play on the lobby rail. Tabs down the left (Story · Endless ·
-- Event), the modes of the tab in the middle, and the selected mode on the right: description,
-- difficulty, waves, rewards, an enemy and boss preview, Create party, and the open parties of
-- that mode to join. Everything shown is a preview; the server re-checks unlocks and sizes.
--
-- The Story tab (STORY_PLAN §10.3, S1-C01) lists the nine episodes of Config/Story (Logic/StoryCards):
-- the ones not built yet show as "Coming soon". Each card carries the icons of the mechanics the
-- episode introduces; the detail tells the Hakawati's intro, the first-clear gifts still to earn and,
-- on Episode 9, the secret unit's odds (TD.SECRET_DROP).

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local TD = require(Shared.Config.TD)
local Modes = require(Shared.Config.Modes)
local Waves = require(Shared.Config.Waves)
local Enemies = require(Shared.Config.Enemies)
local Units = require(Shared.Config.Units)
local Beads = require(Shared.Config.Beads)
local Story = require(Shared.Config.Story)
local IconIds = require(Shared.Config.Icons)
local MatchRewards = require(Shared.Logic.MatchRewards)
local PartyLogic = require(Shared.Logic.PartyLogic)
local StoryCards = require(Shared.Logic.StoryCards)
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
local INTRO_COLOR = Color3.fromHex("#5A3E22") -- the Hakawati's voice: warm brown on the plaster panel
local SECRET_COLOR = Color3.fromHex("#7A3FA0")
local CARD_ICON = 18 -- px, mechanic icons on a card
local PARTY_ROW = 37 -- px per open party row (34 + gap); the box under the detail grows with them
local PARTIES_MIN = 48 -- px, at least the Create button's height (it sits beside the box)

local modal: Modal.Modal
local tabButtons: { [string]: TextButton } = {}
local list: ScrollingFrame
local detail: Frame
local info: ScrollingFrame
local infoHolder: Frame
local dName: TextLabel
local dMech: Frame
local dDesc: TextLabel
local dInfo: TextLabel
local dInfoRow: Frame
local dGift: Frame
local dSecret: TextLabel
local dEnemies: TextLabel
local diffRow: Frame
local diffButtons: { [string]: TextButton } = {}
local createButton: TextButton
local partiesBox: Frame
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

-- The story cards (Config/Story order), by id, rebuilt each render (Modes never change at runtime).
local function storyCards(): ({ string }, { [string]: StoryCards.Card })
	local ids, byId = {}, {}
	for _, c in StoryCards.cards(Story, Modes :: any) do
		table.insert(ids, c.id)
		byId[c.id] = c
	end
	return ids, byId
end

-- Ids listed under a tab, and whether `id` belongs to it.
local function idsOf(kind: string): { string }
	if kind == "story" then
		return (storyCards())
	end
	return modesOf(kind)
end

local function belongs(id: string?, kind: string): boolean
	if id == nil then
		return false
	end
	if kind == "story" then
		return (Story.episodes :: any)[id] ~= nil
	end
	local m = (Modes :: any)[id]
	return m ~= nil and m.kind == kind
end

-- Arabic-Indic digits in Arabic (the episode names in Strings use them).
local AR_DIGITS = { "٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩" }
local function digits(n: number): string
	local s = tostring(n)
	if not LocaleController.isRtl() then
		return s
	end
	return (string.gsub(s, "%d", function(d)
		return AR_DIGITS[tonumber(d) :: number + 1]
	end))
end

-- A card's title: the mode's name, or "Episode N · Title" for an episode not built yet.
local function titleOf(id: string, number: number?): string
	local t = LocaleController.t
	local mode = (Modes :: any)[id]
	if mode then
		return t(mode.nameKey)
	end
	local ep = (Story.episodes :: any)[id]
	return t("play.soon_name", { n = digits(number or 0), title = if ep then t(ep.titleKey) else id })
end

local function mechanicsOf(id: string): { string }
	local ep = (Story.episodes :: any)[id]
	return if ep then ep.mechanics else {}
end

local function canPlay(modeId: string, diff: string): (boolean, string?)
	local snapshot = StateController.get()
	if not snapshot or (Modes :: any)[modeId] == nil then
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

-- "First Hard clear: [bead] 1" for every first-clear gift still ahead of the player.
local function giftEntries(mode: any, modeId: string): { Amount.Entry }
	local t = LocaleController.t
	local snapshot = StateController.get()
	local cleared = snapshot and (snapshot.td.cleared :: any)[modeId]
	local out: { Amount.Entry } = {}
	for _, g in StoryCards.gifts(mode, TD, Beads, cleared) do
		table.insert(out, { text = t("play.first_gift", { d = t("difficulty." .. g.difficulty) }) })
		if g.traitStones > 0 then
			table.insert(out, { icon = IconIds.reward.traitStones, text = "+" .. tostring(g.traitStones) })
		end
		if g.beads > 0 then
			table.insert(out, { icon = IconIds.reward.beads, text = "+" .. tostring(g.beads) })
		end
		local unit = g.unit and (Units :: any)[g.unit]
		if unit then
			table.insert(out, { text = t(unit.nameKey) })
		end
	end
	return out
end

local function secretText(id: string): string
	local t = LocaleController.t
	local odds = StoryCards.secretOdds(TD, id, difficulty)
	if not odds then
		return ""
	end
	local unit = (Units :: any)[odds.unit]
	return t("play.secret", { pct = StoryCards.percent(odds.chance), unit = if unit then t(unit.nameKey) else odds.unit })
		.. "\n"
		.. t("play.secret_pity", { n = odds.pity })
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

local function card(id: string, i: number, number: number?): TextButton
	local t = LocaleController.t
	local rtl = LocaleController.isRtl()
	local mode = (Modes :: any)[id]
	local soon = mode == nil
	local unlocked = not soon and canPlay(id, "normal")
	local on = selected == id
	local b = Theme.button({
		Name = id,
		LayoutOrder = i,
		Text = "",
		Size = UDim2.new(1, -8, 0, 64),
		BackgroundColor3 = if not unlocked then Theme.colors.buttonDisabled else TAB_COLORS[mode.kind] or Theme.colors.button,
		ZIndex = 12,
		Parent = list,
	})
	-- The mode's painted banner (PV-C06) behind the text, dimmed so the outlined labels read on it.
	local art = IconIds.modes[id]
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
	local name = Theme.display({ Text = titleOf(id, number), TextSize = 14, Position = UDim2.fromOffset(0, 6), Size = UDim2.new(1, 0, 0, 34), ZIndex = 13, Parent = b })
	name.TextYAlignment = Enum.TextYAlignment.Top
	local snapshot = StateController.get()
	local cleared = snapshot and (snapshot.td.cleared :: any)[id]
	local sub = if soon then t("play.soon") elseif not unlocked then t("play.locked") elseif cleared then t("play.cleared", { d = t("difficulty." .. cleared) }) else wavesText(mode)
	-- The sub line on the leading side, the mechanic icons on the trailing side of the bottom edge.
	local mechs = mechanicsOf(id)
	local iconsWidth = #mechs * (CARD_ICON + 2)
	local subLabel = Theme.display({
		Text = sub,
		TextSize = 12,
		TextColor3 = Color3.fromHex("#FFD970"),
		AnchorPoint = Vector2.new(if rtl then 1 else 0, 1),
		Position = UDim2.new(if rtl then 1 else 0, 0, 1, -6),
		Size = UDim2.new(1, -iconsWidth - 4, 0, 14),
		ZIndex = 13,
		Parent = b,
	})
	Theme.align(subLabel, rtl)
	Theme.align(name, rtl)
	if #mechs > 0 then
		local row = Create("Frame", {
			Name = "Mechanics",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(if rtl then 0 else 1, 1),
			Position = UDim2.new(if rtl then 0 else 1, 0, 1, -4),
			Size = UDim2.fromOffset(iconsWidth, CARD_ICON),
			ZIndex = 13,
			Parent = b,
		})
		Create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = if rtl then Enum.HorizontalAlignment.Left else Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, 2),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = row,
		})
		for k, key in mechs do
			local holder = Create("Frame", { LayoutOrder = k, BackgroundTransparency = 1, Size = UDim2.fromOffset(CARD_ICON, CARD_ICON), ZIndex = 13, Parent = row })
			Icons.draw(IconIds.mechanics[key] or key, holder)
		end
	end
	b.Activated:Connect(function()
		pick(id)
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
	local ids = idsOf(tab)
	if not belongs(selected, tab) then
		selected = ids[1]
	end
	local numbers = {}
	if tab == "story" then
		local _, byId = storyCards()
		for id, c in byId do
			numbers[id] = c.number
		end
	end
	for i, id in ids do
		card(id, i, numbers[id])
	end
	emptyLabel.Visible = #ids == 0
	emptyLabel.Text = if tab == "event" then t("play.event_none") else ""
	detail.Visible = selected ~= nil
	local id = selected
	if not id then
		return
	end
	local mode = (Modes :: any)[id]
	local soon = mode == nil

	-- Title, the mechanics this episode brings, then the Hakawati's intro (story) or the blurb.
	dName.Text = titleOf(id, numbers[id])
	local mechs = mechanicsOf(id)
	local mechEntries: { Amount.Entry } = {}
	if #mechs > 0 then
		table.insert(mechEntries, { text = t("play.mechanics") })
		for _, key in mechs do
			table.insert(mechEntries, { icon = IconIds.mechanics[key] or key, text = t("mech." .. key) })
		end
	end
	dMech.Visible = #mechEntries > 0
	Amount.fill(dMech, mechEntries, { iconSize = 22, textSize = 12, bold = true, align = Enum.HorizontalAlignment.Left, rtl = rtl })
	local ep = (Story.episodes :: any)[id]
	if ep then
		local lines = {}
		for _, key in ep.intro do
			table.insert(lines, t(key))
		end
		dDesc.Text = t("play.hakawati") .. " “" .. table.concat(lines, " ") .. "”"
		dDesc.TextColor3 = INTRO_COLOR
	else
		dDesc.Text = t(mode.descKey)
		dDesc.TextColor3 = Theme.colors.textMuted
	end

	-- Difficulty, rewards, gifts, the secret odds and the enemies (playable modes only).
	diffRow.Visible = not soon and mode.kind ~= "event"
	for d, b in diffButtons do
		b.Text = t("difficulty." .. d)
		local ok = not soon and canPlay(id, d)
		b.BackgroundColor3 = if d == difficulty then Theme.colors.accent elseif ok then Theme.colors.button else Theme.colors.buttonDisabled
	end
	local entries = if soon then nil else rewardEntries(id, mode)
	dInfo.Visible = not soon and entries == nil
	dInfo.Text = if soon or entries then "" else wavesText(mode) .. "   ·   " .. rewardText(id, mode)
	dInfoRow.Visible = entries ~= nil
	Amount.fill(dInfoRow, entries or {}, { iconSize = 24, textSize = 12, bold = true, align = Enum.HorizontalAlignment.Left, rtl = rtl })
	local gifts = if soon then {} else giftEntries(mode, id)
	dGift.Visible = #gifts > 0
	Amount.fill(dGift, gifts, { iconSize = 22, textSize = 12, bold = true, align = Enum.HorizontalAlignment.Left, rtl = rtl })
	dSecret.Text = secretText(id)
	dSecret.Visible = dSecret.Text ~= ""
	dEnemies.Visible = not soon
	dEnemies.Text = if soon then "" else enemyText(mode)
	for _, l in { dName, dDesc, dInfo, dSecret, dEnemies } do
		Theme.align(l, rtl)
	end

	local unlocked = not soon and canPlay(id, difficulty)
	createButton.Text = if soon then t("play.soon") elseif unlocked then t("play.create") else t("play.locked")
	createButton.BackgroundColor3 = if unlocked and not inParty then Theme.colors.confirm else Theme.colors.buttonDisabled
	-- Open parties of this mode
	partiesBox.Visible = not soon
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
		if p.modeId == id and p.host ~= me and n < 3 then
			n += 1
			partyRow(p, n)
		end
	end
	if n == 0 then
		local none = Theme.label({ Text = t("play.no_parties"), TextSize = 12, TextColor3 = Theme.colors.textMuted, Size = UDim2.new(1, 0, 0, 18), ZIndex = 12, Parent = partiesList })
		Theme.align(none, rtl)
	end
	-- The parties box takes only the room its rows need; the detail stack gets the rest.
	local partiesHeight = math.max(PARTIES_MIN, 18 + n * PARTY_ROW)
	partiesBox.Size = UDim2.new(0.6, 0, 0, partiesHeight)
	infoHolder.Size = UDim2.new(1, 0, 1, -(partiesHeight + 4))
end

-- A wrapped label that grows with its text, for the detail stack.
local function stackLabel(order: number, props: { [string]: any }): TextLabel
	props.LayoutOrder = order
	props.Size = UDim2.new(1, -10, 0, 0)
	props.AutomaticSize = Enum.AutomaticSize.Y
	props.TextYAlignment = Enum.TextYAlignment.Top
	props.ZIndex = 12
	props.Parent = info
	return Theme.label(props)
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

	-- Detail: a scrolling stack above the Create button and the open parties.
	detail = Create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(330, 0), Size = UDim2.new(1, -330, 1, 0), ZIndex = 11, Parent = body })
	infoHolder = Create("Frame", { Name = "Info", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -(PARTIES_MIN + 4)), ZIndex = 11, Parent = detail })
	info = Modal.scroller(infoHolder)
	Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = info })
	dName = Theme.display({ LayoutOrder = 1, TextSize = 20, Size = UDim2.new(1, -10, 0, 24), ZIndex = 12, Parent = info })
	dMech = Amount.row({ Name = "Mechanics", LayoutOrder = 2, Size = UDim2.new(1, -10, 0, 24), ZIndex = 12, Parent = info }, {})
	dDesc = stackLabel(3, { TextSize = 13, TextColor3 = Theme.colors.textMuted })
	diffRow = Create("Frame", { LayoutOrder = 4, BackgroundTransparency = 1, Size = UDim2.new(1, -10, 0, 32), ZIndex = 12, Parent = info })
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
	dInfo = stackLabel(5, { TextSize = 12, FontFace = Theme.fontBold })
	dInfoRow = Amount.row({ Name = "Rewards", LayoutOrder = 6, Size = UDim2.new(1, -10, 0, 28), ZIndex = 12, Parent = info }, {})
	dGift = Amount.row({ Name = "Gifts", LayoutOrder = 7, Size = UDim2.new(1, -10, 0, 24), ZIndex = 12, Parent = info }, {})
	dSecret = stackLabel(8, { TextSize = 12, FontFace = Theme.fontBold, TextColor3 = SECRET_COLOR })
	dEnemies = stackLabel(9, { TextSize = 12, TextColor3 = Theme.colors.textMuted })

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
	partiesBox = Create("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1), Size = UDim2.new(0.6, 0, 0, PARTIES_MIN), ZIndex = 12, Parent = detail })
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

-- Studio harness (DebugKeysController): open a tab with a given card selected.
function PlayController.openAt(tabKey: string, id: string?)
	tab = tabKey
	selected = id
	modal.setVisible(true)
	render()
	if info then
		info.CanvasPosition = Vector2.zero
	end
	-- Bring the selected card into view (cards are 64 px with a 6 px gap).
	local c = if id then list:FindFirstChild(id) else nil
	if c and c:IsA("GuiObject") then
		list.CanvasPosition = Vector2.new(0, math.max(0, (c.LayoutOrder - 1) * 70 - 6))
	end
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
