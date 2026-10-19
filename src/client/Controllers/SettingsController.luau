--!strict
-- Player settings (Logic/Settings): effects level, music, sound effects, summon animation, match
-- camera, auto ultimate, auto skip. Values follow the server snapshot; a change applies at once on this client and is
-- sent to the server to be saved (the server validates it). The Settings screen opens from the
-- lobby rail and the match HUD gear.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local Settings = require(Shared.Logic.Settings)
local Version = require(Shared.Config.Version)
local Signal = require(Shared.Util.Signal)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Haptics = require(UI.Haptics)
local Modal = require(UI.Modal)
local Fx = require(UI.Fx)
local Icons = require(UI.Icons)
local Device = require(UI.Device)
local StateController = require(script.Parent.StateController)
local LocaleController = require(script.Parent.LocaleController)
local LobbyMenuController = require(script.Parent.LobbyMenuController)

local SettingsController = {}

SettingsController.Changed = Signal.new() -- (key, value)

local values: { [string]: any } = Settings.resolve(nil)
-- Local changes not yet echoed by a snapshot (so a stale snapshot does not flip them back).
local pending: { [string]: any } = {}

function SettingsController.get(key: string): any
	return values[key]
end

local function apply(key: string, value: any)
	if values[key] == value then
		return
	end
	values[key] = value
	if key == "effects" then
		Fx.set(value)
	elseif key == "uiScale" then
		Device.setPreset(value)
	elseif key == "sfx" then
		Haptics.setEnabled(value ~= false)
	end
	SettingsController.Changed:Fire(key, value)
	if key == "music" then
		LobbyMenuController.refresh()
	end
end

function SettingsController.set(key: string, value: any)
	if not Settings.accept(key, value) then
		return
	end
	pending[key] = value
	apply(key, value)
	Net.event(Net.Events.SetSetting):FireServer(key, value)
end

local function adopt(snapshot: any)
	local s = snapshot and snapshot.settings
	if type(s) ~= "table" then
		return
	end
	for key in Settings.defs do
		local v = s[key]
		if pending[key] ~= nil then
			if pending[key] == v then
				pending[key] = nil
			end
		elseif v ~= nil and Settings.accept(key, v) then
			apply(key, v)
		end
	end
end

---------------------------------------------------------------- Screen

type Row = { key: string, labelKey: string, options: { { value: any, textKey: string } } }

-- Theme v2 (LP-C05): the rows in four groups, each under an icon and a title.
local GROUPS: { { titleKey: string, icon: string, keys: { string } } } = {
	{ titleKey = "settings.group.look", icon = "ui_music", keys = { "effects", "cutscenes", "music", "sfx", "skipSummon" } },
	{ titleKey = "settings.group.match", icon = "act_speed", keys = { "camera", "autoUlt", "autoSkip", "autoAfk" } },
	{ titleKey = "settings.group.controls", icon = "ui_settings", keys = { "uiScale", "panelSide", "quickPlace", "railSide" } },
	{ titleKey = "settings.group.language", icon = "ui_codes", keys = { "language" } },
}
local groupLabels: { TextLabel } = {}

local ROWS: { Row } = {
	{
		key = "effects",
		labelKey = "settings.effects",
		options = {
			{ value = "full", textKey = "settings.effects.full" },
			{ value = "reduced", textKey = "settings.effects.reduced" },
			{ value = "off", textKey = "settings.effects.off" },
		},
	},
	{
		key = "cutscenes",
		labelKey = "settings.cutscenes",
		options = { { value = true, textKey = "settings.on" }, { value = false, textKey = "settings.off" } },
	},
	{
		key = "music",
		labelKey = "settings.music",
		options = { { value = true, textKey = "settings.on" }, { value = false, textKey = "settings.off" } },
	},
	{
		key = "sfx",
		labelKey = "settings.sfx",
		options = { { value = true, textKey = "settings.on" }, { value = false, textKey = "settings.off" } },
	},
	{
		key = "skipSummon",
		labelKey = "settings.skipSummon",
		options = { { value = false, textKey = "settings.show" }, { value = true, textKey = "settings.skip" } },
	},
	{
		key = "camera",
		labelKey = "settings.camera",
		options = { { value = "walk", textKey = "settings.camera.walk" }, { value = "overhead", textKey = "settings.camera.overhead" } },
	},
	{
		key = "autoUlt",
		labelKey = "settings.autoUlt",
		options = { { value = true, textKey = "settings.on" }, { value = false, textKey = "settings.off" } },
	},
	{
		key = "autoSkip",
		labelKey = "settings.autoSkip",
		options = { { value = true, textKey = "settings.on" }, { value = false, textKey = "settings.off" } },
	},
	{
		key = "autoAfk",
		labelKey = "settings.autoAfk",
		options = { { value = true, textKey = "settings.on" }, { value = false, textKey = "settings.off" } },
	},
	-- Touch HUD (MOBILE_HUD_PLAN B7): UI size, where the defender panel opens, tap-to-place on touch,
	-- which edge holds the match rail and Place; and the language (its own remote, not a setting).
	{
		key = "uiScale",
		labelKey = "settings.uiScale",
		options = {
			{ value = "small", textKey = "settings.uiScale.small" },
			{ value = "default", textKey = "settings.uiScale.default" },
			{ value = "large", textKey = "settings.uiScale.large" },
			{ value = "huge", textKey = "settings.uiScale.huge" },
		},
	},
	{
		key = "panelSide",
		labelKey = "settings.panelSide",
		options = {
			{ value = "auto", textKey = "settings.panelSide.auto" },
			{ value = "side", textKey = "settings.panelSide.side" },
			{ value = "bottom", textKey = "settings.panelSide.bottom" },
		},
	},
	{
		key = "quickPlace",
		labelKey = "settings.quickPlace",
		options = { { value = true, textKey = "settings.on" }, { value = false, textKey = "settings.off" } },
	},
	{
		key = "railSide",
		labelKey = "settings.railSide",
		options = { { value = "right", textKey = "settings.railSide.right" }, { value = "left", textKey = "settings.railSide.left" } },
	},
	{
		key = "language",
		labelKey = "settings.language",
		options = { { value = "en", textKey = "settings.language.en" }, { value = "ar", textKey = "settings.language.ar" } },
	},
}

-- The value a row shows as selected (the language lives in LocaleController, not in Settings).
local function rowValue(key: string): any
	if key == "language" then
		return LocaleController.lang()
	end
	return values[key]
end

local MAX_BODY = 300 -- px
local modal: Modal.Modal
local rowLabels: { [string]: TextLabel } = {}
local optionButtons: { [string]: { { b: TextButton, value: any, textKey: string } } } = {}
local hint: TextLabel

local function render()
	if not modal then
		return
	end
	local t = LocaleController.t
	local rtl = LocaleController.isRtl()
	modal.title.Text = t("settings.title")
	Theme.align(modal.title, rtl)
	for _, row in ROWS do
		local l = rowLabels[row.key]
		l.Text = t(row.labelKey)
		Theme.align(l, rtl)
		for _, o in optionButtons[row.key] do
			o.b.Text = t(o.textKey)
			local on = rowValue(row.key) == o.value
			o.b.BackgroundColor3 = if on then Theme.colors.confirm else Theme.colors.buttonDisabled
		end
	end
	hint.Text = t("settings.effects.hint")
	for g, group in GROUPS do
		local l = groupLabels[g]
		if l then
			l.Text = t(group.titleKey)
			Theme.align(l, rtl)
		end
	end
	Theme.align(hint, rtl)
end

local function build()
	-- The rows scroll once they outgrow the body (a sheet on phones).
	modal = Modal.create("Settings", 560, math.min(#ROWS * (Theme.TOUCH + 6) + #GROUPS * 36 + 48, MAX_BODY), { fill = true })
	local body = Modal.scroller(modal.body)
	Create("UIPadding", { PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3), PaddingRight = UDim.new(0, 12), Parent = body })
	Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = body })
	-- Each row's place: its group's header, then the group's rows in order.
	local orderOf: { [string]: number } = {}
	for g, group in GROUPS do
		local head = Create("Frame", { Name = "Group" .. g, LayoutOrder = g * 100, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), ZIndex = 11, Parent = body })
		local icon = Create("Frame", { Size = UDim2.fromOffset(24, 24), Position = UDim2.fromOffset(0, 3), BackgroundTransparency = 1, ZIndex = 12, Parent = head })
		Icons.draw(group.icon, icon)
		for _, d in icon:GetDescendants() do
			if d:IsA("GuiObject") then
				d.ZIndex = 12
			end
		end
		local label = Theme.display({ TextSize = 17, TextColor3 = Theme.v2.woodDark, Position = UDim2.fromOffset(30, 0), Size = UDim2.new(1, -30, 1, 0), ZIndex = 12, Parent = head })
		groupLabels[g] = label
		Create("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Theme.v2.brass, BorderSizePixel = 0, ZIndex = 11, Parent = head })
		for k, key in group.keys do
			orderOf[key] = g * 100 + k
		end
	end
	for i, row in ROWS do
		local line = Create("Frame", { LayoutOrder = orderOf[row.key] or (1000 + i), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, Theme.TOUCH), ZIndex = 11, Parent = body })
		rowLabels[row.key] = Theme.label({ TextSize = 15, FontFace = Theme.fontBold, Size = UDim2.fromScale(0.38, 1), ZIndex = 11, Parent = line })
		local opts = Create("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromScale(0.62, 1), ZIndex = 11, Parent = line })
		Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = opts })
		optionButtons[row.key] = {}
		local w = if #row.options >= 4 then 74 elseif #row.options == 3 then 96 else 120
		for j, o in row.options do
			local b = Theme.button({ LayoutOrder = j, TextSize = 14, Size = UDim2.fromOffset(w, Theme.TOUCH), ZIndex = 11, Parent = opts })
			local pad = b:FindFirstChildOfClass("UIPadding")
			if pad then
				pad.PaddingLeft = UDim.new(0, 4)
				pad.PaddingRight = UDim.new(0, 4)
			end
			table.insert(optionButtons[row.key], { b = b, value = o.value, textKey = o.textKey })
			b.Activated:Connect(function()
				if row.key == "language" then
					if LocaleController.lang() ~= o.value then
						LocaleController.toggle()
					end
				else
					SettingsController.set(row.key, o.value)
				end
			end)
		end
	end
	hint = Theme.label({ LayoutOrder = 2000, TextSize = 12, TextColor3 = Theme.colors.textMuted, Size = UDim2.new(1, 0, 0, 18), ZIndex = 11, Parent = body })
	Theme.label({
		LayoutOrder = 2001,
		Text = "v" .. Version.VERSION,
		TextSize = 12,
		TextColor3 = Theme.colors.textMuted,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 16),
		ZIndex = 11,
		Parent = body,
	})
end

-- A one-tap speaker that toggles `music` (lobby HUD and match HUD). The icon and the hover hint
-- follow the setting; the hint sits below the button, or to its left when `tipLeft` (match column).
function SettingsController.muteButton(props: { [string]: any }, tipLeft: boolean?): TextButton
	local b = Theme.button(props)
	b.Text = ""
	local pad = b:FindFirstChildOfClass("UIPadding")
	if pad then
		pad:Destroy()
	end
	local icon = Create("Frame", {
		Name = "Icon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.62, 0.62),
		BackgroundTransparency = 1,
		ZIndex = (props.ZIndex or 1) + 1,
		Parent = b,
	})
	local tip = Theme.label({
		Name = "Tip",
		AnchorPoint = if tipLeft then Vector2.new(1, 0.5) else Vector2.new(0.5, 0),
		Position = if tipLeft then UDim2.new(0, -6, 0.5, 0) else UDim2.new(0.5, 0, 1, 4),
		Size = UDim2.fromOffset(200, 18),
		TextXAlignment = if tipLeft then Enum.TextXAlignment.Right else Enum.TextXAlignment.Center,
		TextSize = 12,
		FontFace = Theme.fontBold,
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0.3,
		Visible = false,
		ZIndex = (props.ZIndex or 1) + 2,
		Parent = b,
	})
	local shown: boolean? = nil
	local function paint()
		local on = values.music ~= false
		tip.Text = LocaleController.t(if on then "hud.music_on" else "hud.music_off")
		if shown == on then
			return
		end
		shown = on
		icon:ClearAllChildren()
		Icons.draw(if on then "ui_music" else "ui_music_off", icon)
		for _, d in icon:GetDescendants() do
			if d:IsA("GuiObject") then
				d.ZIndex = icon.ZIndex
			end
		end
	end
	b.Activated:Connect(function()
		SettingsController.set("music", values.music == false)
	end)
	b.MouseEnter:Connect(function()
		-- Hover hint for the mouse only: a tap on a phone also fires MouseEnter.
		tip.Visible = not Device.isTouch()
	end)
	b.MouseLeave:Connect(function()
		tip.Visible = false
	end)
	SettingsController.Changed:Connect(function(key: string)
		if key == "music" then
			paint()
		end
	end)
	LocaleController.Changed:Connect(paint)
	paint()
	return b
end

function SettingsController.open()
	modal.setVisible(true)
	render()
end

function SettingsController.start()
	build()
	adopt(StateController.get())
	StateController.Changed:Connect(adopt)
	SettingsController.Changed:Connect(render)
	LocaleController.Changed:Connect(render)
	LobbyMenuController.register("settings", SettingsController.open)
	-- The lobby's More sheet on a phone (MOBILE_HUD_PLAN B6): Music with its state.
	LobbyMenuController.register("music", function()
		SettingsController.set("music", values.music == false)
	end)
	LobbyMenuController.registerLabel("music", function()
		return LocaleController.t("settings.music") .. ": " .. LocaleController.t(if values.music == false then "settings.off" else "settings.on")
	end)
end

return SettingsController
