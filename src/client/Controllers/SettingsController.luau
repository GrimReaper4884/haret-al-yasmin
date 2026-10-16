--!strict
-- Player settings (Logic/Settings): effects level, summon animation, match camera, auto
-- ultimate, auto skip. Values follow the server snapshot; a change applies at once on this client and is
-- sent to the server to be saved (the server validates it). The Settings screen opens from the
-- lobby rail and the match HUD gear.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local Settings = require(Shared.Logic.Settings)
local Signal = require(Shared.Util.Signal)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Modal = require(UI.Modal)
local Fx = require(UI.Fx)
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
	end
	SettingsController.Changed:Fire(key, value)
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
	},	{
		key = "autoAfk",
		labelKey = "settings.autoAfk",
		options = { { value = true, textKey = "settings.on" }, { value = false, textKey = "settings.off" } },
	},
}

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
			local on = values[row.key] == o.value
			o.b.BackgroundColor3 = if on then Theme.colors.confirm else Theme.colors.buttonDisabled
		end
	end
	hint.Text = t("settings.effects.hint")
	Theme.align(hint, rtl)
end

local function build()
	modal = Modal.create("Settings", 520, #ROWS * 46 + 26)
	local body = modal.body
	Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = body })
	for i, row in ROWS do
		local line = Create("Frame", { LayoutOrder = i, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), ZIndex = 11, Parent = body })
		rowLabels[row.key] = Theme.label({ TextSize = 15, FontFace = Theme.fontBold, Size = UDim2.fromScale(0.38, 1), ZIndex = 11, Parent = line })
		local opts = Create("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromScale(0.62, 1), ZIndex = 11, Parent = line })
		Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = opts })
		optionButtons[row.key] = {}
		local w = if #row.options == 3 then 96 else 120
		for j, o in row.options do
			local b = Theme.button({ LayoutOrder = j, TextSize = 14, Size = UDim2.fromOffset(w, 40), ZIndex = 11, Parent = opts })
			table.insert(optionButtons[row.key], { b = b, value = o.value, textKey = o.textKey })
			b.Activated:Connect(function()
				SettingsController.set(row.key, o.value)
			end)
		end
	end
	hint = Theme.label({ LayoutOrder = #ROWS + 1, TextSize = 12, TextColor3 = Theme.colors.textMuted, Size = UDim2.new(1, 0, 0, 18), ZIndex = 11, Parent = body })
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
end

return SettingsController
