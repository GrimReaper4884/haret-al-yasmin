--!strict
-- Lobby chrome for the tower-defense update: the lira pill next to the coins, and the lobby menu.
-- On a phone (MOBILE_HUD_PLAN B6) the menu is a bottom bar between Roblox's thumbstick and jump
-- (Play, Units, Summon, Diary, More); More opens a sheet with Daily, Codes, the Hakawati, Wardrobe,
-- the Event while one runs, Language, Music and Settings, and the top row keeps only the lira and
-- coin pills. Tablets and desktop get the Theme v2 rail (LP-C02): a wood panel with a large gold Play
-- that breathes, Units / Summon / Diary beside it and the smaller tiles (Event, Daily, Codes, AFK,
-- Settings) under them, its bottom edge above the thumbstick zone. Dots (the "!" badges) mark a
-- claimable Daily, a Diary tier and a running Event, and clear once that screen is opened until
-- something new waits. Hides the whole lobby HUD while a match is on or a dialogue is open.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Daily = require(Shared.Config.Daily)
local Hud = require(Shared.Config.Hud)
local DailyLogic = require(Shared.Logic.DailyLogic)
local HudLayout = require(Shared.Logic.HudLayout)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Root = require(UI.Root)
local Icons = require(UI.Icons)
local Juice = require(UI.Juice)
local Modal = require(UI.Modal)
local Device = require(UI.Device)
local CoinFlight = require(UI.CoinFlight)
local Vfx = require(Shared.Config.Vfx)
local StateController = require(script.Parent.StateController)
local LocaleController = require(script.Parent.LocaleController)

local LobbyMenuController = {}

local LOBBY_WIDGETS = { "Coins", "Errand", "Language", "Wardrobe", "Music", "Lira", "Menu", "LobbyBar", "TestMode" }
-- Top-row buttons that live in the More sheet on a phone (B6).
local PHONE_HIDDEN = { Language = true, Wardrobe = true, Music = true }

local RAIL_TOP = { "units", "summon", "pass" }
local RAIL_SMALL = { "event", "daily", "codes", "afk", "settings" }
local BAR = { "play", "units", "summon", "pass", "more" }
local MORE = { "daily", "codes", "afk", "wardrobe", "event", "language", "music", "settings" }
local COLORS: { [string]: Color3 } = {
	play = Theme.v2.goldLeaf,
	event = Color3.fromHex("#2F7D6B"),
	units = Color3.fromHex("#4C7FC0"),
	summon = Color3.fromHex("#9B4FD1"),
	pass = Theme.colors.quest,
	daily = Theme.colors.confirm,
	codes = Color3.fromHex("#5E6F7D"),
	afk = Color3.fromHex("#8A5A2B"),
	settings = Color3.fromHex("#6E5E50"),
	more = Color3.fromHex("#6E5E50"),
	wardrobe = Theme.colors.quest,
	language = Theme.colors.button,
	music = Color3.fromHex("#6E5E50"),
}
local ICONS: { [string]: string? } = { wardrobe = "tarboosh", language = nil, music = "ui_music" }

local liraLabel: TextLabel
local grid: Frame
local lobbyBar: Frame
local more: Modal.Modal
-- Every button per entry key (grid cell, bar button, More row) with its caption and badge.
type Entry = { button: TextButton, caption: TextLabel, badge: Frame }
local entries: { [string]: { Entry } } = {}
local inMatch = false
local inAfk = false -- sitting in the Hakawati's room (AfkController): the lobby HUD is hidden too
local phone = false
local openers: { [string]: () -> () } = {}
local labels: { [string]: () -> string } = {}
local lastLira: number? = nil
local railPlay: TextButton? = nil
local railTop: { TextButton } = {}
local railSmall: { [string]: TextButton } = {}
-- Dots clear when their screen is opened, until the reason changes (a new day, a new tier, …).
local dotReason: { [string]: string } = {}
local dotSeen: { [string]: string } = {}

-- Other controllers register what their button opens (avoids require cycles).
function LobbyMenuController.register(key: string, open: () -> ())
	openers[key] = open
end

function LobbyMenuController.opener(key: string): (() -> ())?
	return openers[key]
end

-- A caption that shows state (the More sheet's Music: On / Off), registered by its owner.
function LobbyMenuController.registerLabel(key: string, label: () -> string)
	labels[key] = label
end

local render: () -> ()
function LobbyMenuController.refresh()
	render()
end

-- Shows or hides one entry (the Event button exists only while an event runs).
local hidden: { [string]: boolean } = { event = true }
-- A claim's coins fly from its button to the currency pills (Theme v2, LP-C02); the pills then count
-- and glow from the state update.
function LobbyMenuController.rewardFlight(from: GuiObject)
	local root = Root.get()
	local lira = root:FindFirstChild("Lira")
	local coins = root:FindFirstChild("Coins")
	local n = Vfx.COIN_FLIGHT.lobbyCoins
	if lira and lira:IsA("GuiObject") then
		CoinFlight.flyFrom(from, lira, math.ceil(n / 2))
	end
	if coins and coins:IsA("GuiObject") then
		CoinFlight.flyFrom(from, coins, math.floor(n / 2))
	end
end

local relayout: (() -> ())? = nil
function LobbyMenuController.setVisibleEntry(key: string, visible: boolean)
	hidden[key] = not visible
	local list: { Entry } = entries[key] or {}
	for _, e in list do
		e.button.Visible = visible
	end
	if relayout then
		relayout()
	end
end

local function track(key: string, e: Entry)
	entries[key] = entries[key] or {}
	table.insert(entries[key], e)
end

-- A red "!" badge in a button's top-right corner.
local function badgeOn(b: GuiObject): Frame
	local badge = Create("Frame", {
		Name = "Badge",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -4, 0, 4),
		Size = UDim2.fromOffset(20, 20),
		BackgroundColor3 = Color3.fromHex("#E0433A"),
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = (b.ZIndex or 1) + 2,
		Parent = b,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Create("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
	})
	local bang = Theme.display({ Text = "!", TextSize = 14, Size = UDim2.fromScale(1, 1), ZIndex = (b.ZIndex or 1) + 3, Parent = badge })
	bang.TextXAlignment = Enum.TextXAlignment.Center
	return badge
end

local function activate(key: string)
	if key == "more" then
		render()
		more.setVisible(true)
		return
	end
	if key == "language" then
		LocaleController.toggle()
		return
	end
	if key == "music" then
		local open = openers.music
		if open then
			open()
		end
		render()
		return
	end
	local open = openers[key]
	if open then
		if more.isOpen() then
			more.setVisible(false)
		end
		if dotReason[key] then
			dotSeen[key] = dotReason[key]
			render()
		end
		open()
	end
end

-- A square icon button with a caption under the icon (grid cells and the phone bar).
local function iconButton(key: string, order: number, size: number, parent: Instance): Entry
	local b = Theme.button({ Name = key, LayoutOrder = order, Text = "", Size = UDim2.fromOffset(size, size), BackgroundColor3 = COLORS[key], Parent = parent })
	local pad = b:FindFirstChildOfClass("UIPadding")
	if pad then
		pad:Destroy()
	end
	local icon = Create("Frame", { Name = "Icon", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 5), Size = UDim2.fromOffset(32, 32), BackgroundTransparency = 1, Parent = b })
	Icons.draw("ui_" .. key, icon)
	local caption = Theme.display({ Name = "Caption", TextSize = 13, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -3), Size = UDim2.new(1, 0, 0, 16), Parent = b })
	caption.TextXAlignment = Enum.TextXAlignment.Center
	caption.TextWrapped = false
	local badge = badgeOn(b)
	if key == "daily" or key == "more" then
		Juice.wobble(icon, function()
			return badge.Visible
		end)
	end
	b.Activated:Connect(function()
		activate(key)
	end)
	local e = { button = b, caption = caption, badge = badge }
	track(key, e)
	return e
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

	-- Tablets and desktop: the Theme v2 rail (LP-C02), placed by layout() above the thumbstick zone.
	local R = Hud.LOBBY_RAIL
	grid = Theme.panel({ Name = "Menu", Position = UDim2.new(0, 10, 0.45, 0), Size = UDim2.fromOffset(100, 100), BackgroundColor3 = Theme.v2.woodDark, Parent = root })
	grid.BackgroundTransparency = 0.15
	Theme.chrome(grid, "panel")
	local play = iconButton("play", 1, R.tile, grid)
	railPlay = play.button
	play.caption.TextSize = 18
	local playIcon = play.button:FindFirstChild("Icon") :: Frame?
	if playIcon then
		playIcon.Size = UDim2.fromOffset(48, 48)
		playIcon.Position = UDim2.new(0.5, 0, 0, 10)
	end
	Juice.breathe(play.button, R.breathe, R.breatheS)
	for i, key in RAIL_TOP do
		table.insert(railTop, iconButton(key, 1 + i, R.tile, grid).button)
	end
	for i, key in RAIL_SMALL do
		local e = iconButton(key, 10 + i, R.small, grid)
		e.button.Visible = not hidden[key]
		railSmall[key] = e.button
	end

	-- Phones: the bottom bar between Roblox's corners (HudLayout.lobbyBar).
	lobbyBar = Create("Frame", { Name = "LobbyBar", BackgroundTransparency = 1, Visible = false, Parent = root })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, Hud.LOBBY_BAR.gap), SortOrder = Enum.SortOrder.LayoutOrder, Parent = lobbyBar })
	for i, key in BAR do
		iconButton(key, i, Hud.LOBBY_BAR.button, lobbyBar)
	end

	-- More: the rest of the lobby in three columns of 48 px buttons.
	more = Modal.create("More", 440, 3 * Theme.TOUCH + 2 * 6)
	local list = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 11, Parent = more.body })
	Create("UIGridLayout", { CellSize = UDim2.new(1 / 3, -4, 0, Theme.TOUCH), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	for i, key in MORE do
		local b = Theme.button({ Name = key, LayoutOrder = i, Text = "", TextSize = 15, Size = UDim2.fromOffset(Theme.TOUCH, Theme.TOUCH), BackgroundColor3 = COLORS[key], ZIndex = 11, Parent = list })
		local pad = b:FindFirstChildOfClass("UIPadding")
		if pad then
			pad.PaddingLeft = UDim.new(0, 4)
			pad.PaddingRight = UDim.new(0, 4)
		end
		local iconName = if ICONS[key] ~= nil or key == "language" then ICONS[key] else "ui_" .. key
		local captionX = 6
		if iconName then
			local icon = Create("Frame", { Name = "Icon", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(30, 30), BackgroundTransparency = 1, ZIndex = 12, Parent = b })
			Icons.draw(iconName, icon, if key == "wardrobe" then "#F2E6CF" else nil)
			for _, d in icon:GetDescendants() do
				if d:IsA("GuiObject") then
					d.ZIndex = 12
				end
			end
			captionX = 34
		end
		local caption = Theme.display({ Name = "Caption", TextSize = 15, Position = UDim2.fromOffset(captionX, 0), Size = UDim2.new(1, -captionX, 1, 0), ZIndex = 12, Parent = b })
		caption.TextXAlignment = Enum.TextXAlignment.Center
		local badge = badgeOn(b)
		b.Visible = not hidden[key]
		b.Activated:Connect(function()
			activate(key)
		end)
		track(key, { button = b, caption = caption, badge = badge })
	end
end

local function applyVisibility()
	local root = Root.get()
	local dialogue = root:FindFirstChild("Dialogue")
	local dialogueOpen = dialogue ~= nil and (dialogue :: Frame).Visible
	-- On a phone the party countdown panel needs the screen's middle; the bar waits under it.
	local queue = root:FindFirstChild("Queue")
	local queued = queue ~= nil and (queue :: Frame).Visible
	local away = inMatch or inAfk
	for _, name in LOBBY_WIDGETS do
		local w = root:FindFirstChild(name)
		if w and w:IsA("GuiObject") then
			if name == "Menu" then
				w.Visible = not away and not dialogueOpen and not phone
			elseif name == "LobbyBar" then
				w.Visible = not away and not dialogueOpen and not queued and phone
			elseif name == "TestMode" then
				local snapshot = StateController.get()
				w.Visible = not away and snapshot ~= nil and not snapshot.persistent
			elseif PHONE_HIDDEN[name] then
				w.Visible = not away and not phone
			elseif name == "Errand" then
				-- The tracker steps aside while someone talks (the dialogue takes the screen's bottom).
				w.Visible = not away and not dialogueOpen
			else
				w.Visible = not away
			end
		end
	end
end

-- Phone or not, and where everything goes (re-run on every Device change).
local function layout()
	local root = Root.get()
	phone = Device.isPhone()
	local d = Device.designSize()
	local scale = Device.scale()
	local reserved = Device.reserved()
	-- Rail: Play on the left as tall as both rows, the big row then the visible small tiles.
	local R = Hud.LOBBY_RAIL
	local x0 = R.pad + math.floor(R.tile * R.play + 0.5) + R.gap
	local n = 0
	for _, key in RAIL_SMALL do
		local b = railSmall[key]
		if b and b.Visible then
			b.Position = UDim2.fromOffset(x0 + n * (R.small + R.gap), R.pad + R.tile + R.gap)
			b.Size = UDim2.fromOffset(R.small, R.small)
			n += 1
		end
	end
	local rowW = math.max(#railTop * (R.tile + R.gap) - R.gap, n * (R.small + R.gap) - R.gap)
	-- The big tiles share the row's width (the small row sets it).
	local topW = math.floor((rowW - (#railTop - 1) * R.gap) / #railTop)
	for i, b in railTop do
		b.Position = UDim2.fromOffset(x0 + (i - 1) * (topW + R.gap), R.pad)
		b.Size = UDim2.fromOffset(topW, R.tile)
	end
	local height = R.tile + R.gap + R.small
	local p = railPlay
	if p then
		p.Position = UDim2.fromOffset(R.pad, R.pad)
		p.Size = UDim2.fromOffset(math.floor(R.tile * R.play + 0.5), height)
	end
	grid.Size = UDim2.fromOffset(x0 + rowW + R.pad, height + 2 * R.pad)
	-- Its bottom edge above the thumbstick zone, below the screen's middle when there is room.
	local bottomKeep = if reserved.left then (reserved.left.y1 - reserved.left.y0) / scale + 8 else 8
	local gridY = math.max(0, math.min(d.y * 0.45, d.y - bottomKeep - grid.Size.Y.Offset))
	grid.Position = UDim2.fromOffset(10, gridY)
	-- On a narrow tablet the rail reaches the errand card (right edge, centred at 45 % height): the
	-- card then rises to end above the rail.
	local errand = root:FindFirstChild("Errand")
	if errand and errand:IsA("GuiObject") and not phone then
		local h = errand.AbsoluteSize.Y / scale
		local left = d.x - 12 - errand.Size.X.Offset
		local cy = d.y * 0.45
		local overlaps = 10 + grid.Size.X.Offset + R.gap > left and cy + h / 2 > gridY - R.gap
		if overlaps then
			cy = math.max(Hud.TOP_CLEAR + 52 + h / 2, gridY - R.gap - h / 2)
		end
		errand.Position = UDim2.new(1, -12, 0, cy)
	end
	-- Phone bar: centred in the band between the corners.
	local bar = HudLayout.lobbyBar(Hud, Device.profile(), scale, Device.safeSize(), #BAR, reserved)
	lobbyBar.Position = UDim2.fromOffset(bar.x, bar.y)
	lobbyBar.Size = UDim2.fromOffset(bar.width, bar.size)
	for _, key in BAR do
		for _, e in entries[key] do
			if e.button.Parent == lobbyBar then
				e.button.Size = UDim2.fromOffset(bar.size, bar.size)
			end
		end
	end
	-- Top row: on a phone only the lira and coin pills, centred (the coins' store button sticks out 8 px).
	local lira = root:FindFirstChild("Lira") :: GuiObject?
	local coins = root:FindFirstChild("Coins") :: GuiObject?
	if lira and coins then
		if phone then
			local total = lira.Size.X.Offset + 8 + coins.Size.X.Offset + 8
			lira.Position = UDim2.new(0.5, -total / 2 + lira.Size.X.Offset, 0, 10)
			coins.Position = UDim2.new(0.5, total / 2 - 8, 0, 10)
		else
			lira.Position = UDim2.new(0.5, -204, 0, 10)
			coins.Position = UDim2.new(0.5, -6, 0, 10)
		end
	end
	applyVisibility()
end

function LobbyMenuController.setInMatch(v: boolean)
	inMatch = v
	applyVisibility()
end

function LobbyMenuController.setInAfk(v: boolean)
	inAfk = v
	applyVisibility()
end

local function setBadge(key: string, on: boolean)
	local list: { Entry } = entries[key] or {}
	for _, e in list do
		e.badge.Visible = on
	end
end

render = function()
	local t = LocaleController.t
	local snapshot = StateController.get()
	local dailyReady, passPending = false, false
	if snapshot then
		-- The lira icon carries the unit; the pill shows the number only.
		local function fmt(n: number): string
			return tostring(n)
		end
		if lastLira and lastLira ~= snapshot.lira then
			Juice.count(liraLabel, lastLira, snapshot.lira, fmt)
			if snapshot.lira > lastLira and liraLabel.Parent then
				Juice.glow(liraLabel.Parent :: GuiObject)
			end
		else
			liraLabel.Text = fmt(snapshot.lira)
		end
		lastLira = snapshot.lira
		dailyReady = DailyLogic.status(snapshot, os.time(), Daily :: any).canClaim
		if snapshot.pass then
			-- a claimable free tier waiting?
			local PassLogic = require(Shared.Logic.PassLogic)
			local SeasonPass = require(Shared.Config.SeasonPass)
			local level = PassLogic.level(snapshot.pass.xp, SeasonPass.tiers)
			for tier = 1, level do
				if not snapshot.pass.claimedFree[tostring(tier)] then
					passPending = true
					break
				end
			end
		end
	end
	-- The reason each dot shows (it clears once its screen is opened, until the reason changes).
	table.clear(dotReason)
	if dailyReady and snapshot then
		dotReason.daily = "day" .. tostring(snapshot.daily and snapshot.daily.lastDay or 0)
	end
	if passPending and snapshot then
		dotReason.pass = "xp" .. tostring(snapshot.pass.xp)
	end
	if not hidden.event then
		dotReason.event = "running"
	end
	local function dot(key: string): boolean
		local reason = dotReason[key]
		return reason ~= nil and dotSeen[key] ~= reason
	end
	setBadge("daily", dot("daily"))
	setBadge("pass", dot("pass"))
	setBadge("event", dot("event"))
	-- More carries the badges of what it holds.
	setBadge("more", dot("daily") or dot("event"))
	for key, list in entries do
		for _, e in list do
			if key == "language" then
				e.caption.Text = t("hud.language")
			elseif key == "wardrobe" then
				e.caption.Text = t("hud.wardrobe")
			elseif labels[key] then
				e.caption.Text = labels[key]()
			else
				e.caption.Text = t("hud." .. key)
			end
		end
	end
	more.title.Text = t("hud.more")
	Theme.align(more.title, LocaleController.isRtl())
	applyVisibility()
end

function LobbyMenuController.start()
	build()
	relayout = layout
	layout()
	render()
	StateController.Changed:Connect(render)
	LocaleController.Changed:Connect(render)
	Device.Changed:Connect(layout)
	if game:GetService("RunService"):IsStudio() then
		-- Studio test hook (LP-C02 evidence, no profile change): LocalPlayer.HaretUiDemo:Invoke("claim")
		-- flies a claim's coins from the Daily button and counts the lira pill up by 30 as a real
		-- claim would; the next state update puts the true number back.
		local hook = Instance.new("BindableFunction")
		hook.Name = "HaretUiDemo"
		hook.OnInvoke = function(cmd: string): any
			if cmd == "claim" then
				local list = entries.daily or {}
				local from = list[1] and list[1].button
				if from and lastLira then
					LobbyMenuController.rewardFlight(from)
					task.delay(Vfx.COIN_FLIGHT.life, function()
						Juice.count(liraLabel, lastLira :: number, (lastLira :: number) + 30, tostring)
						if liraLabel.Parent then
							Juice.glow(liraLabel.Parent :: GuiObject)
						end
					end)
					return true
				end
			end
			return false
		end
		hook.Parent = game:GetService("Players").LocalPlayer
	end
	task.defer(function()
		local dialogue = Root.get():WaitForChild("Dialogue", 10)
		if dialogue and dialogue:IsA("GuiObject") then
			dialogue:GetPropertyChangedSignal("Visible"):Connect(applyVisibility)
		end
		local errand = Root.get():WaitForChild("Errand", 10)
		if errand and errand:IsA("GuiObject") then
			errand:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
			layout()
		end
		local queue = Root.get():WaitForChild("Queue", 10)
		if queue and queue:IsA("GuiObject") then
			queue:GetPropertyChangedSignal("Visible"):Connect(applyVisibility)
		end
	end)
end

return LobbyMenuController
