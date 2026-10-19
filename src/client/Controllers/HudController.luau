--!strict
-- Always-on HUD: coin pill, language toggle and the music mute.

local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Icons = require(UI.Icons)
local Theme = require(UI.Theme)
local Root = require(UI.Root)
local Juice = require(UI.Juice)
local StateController = require(script.Parent.StateController)
local LocaleController = require(script.Parent.LocaleController)
local ShopController = require(script.Parent.ShopController)
local SettingsController = require(script.Parent.SettingsController)
local LobbyMenuController = require(script.Parent.LobbyMenuController)
local Device = require(UI.Device)

local HudController = {}

local coinLabel: TextLabel
local coinPill: Frame
local langButton: TextButton
local testBadge: TextLabel
local lastQirsh: number? = nil
local render: () -> ()

local function build()
	local root = Root.get()

	-- Layout: Roblox owns the top-left (menu + chat window) and top-right (player list), so the
	-- coin pill and language toggle sit top-centre.
	coinPill, coinLabel = Theme.pill({
		Name = "Coins",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(0.5, -6, 0, 10),
		Size = UDim2.fromOffset(170, 36),
		Parent = root,
	}, Theme.colors.gold, "qirsh")
	coinLabel.TextColor3 = Color3.fromHex("#F6C08A")
	coinLabel.Size = UDim2.new(1, -66, 1, 0)
	-- The brass coin purse opens the store (Robux purses and passes; Theme v2, LP-C02).
	local storeButton = Theme.button({
		Name = "Store",
		Text = "",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 8, 0.5, 0),
		Size = UDim2.fromOffset(Theme.TOUCH, Theme.TOUCH),
		BackgroundColor3 = Theme.v2.brass,
		Parent = coinPill,
	})
	local sp = storeButton:FindFirstChildOfClass("UIPadding")
	if sp then
		sp:Destroy()
	end
	local purse = Create("Frame", { Name = "Purse", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(32, 32), BackgroundTransparency = 1, Parent = storeButton })
	Icons.draw("qirsh_pouch", purse)
	storeButton.Activated:Connect(function()
		ShopController.openStore()
	end)

	langButton = Theme.button({
		Name = "Language",
		Position = UDim2.new(0.5, 10, 0, 4),
		Size = UDim2.fromOffset(96, Theme.TOUCH),
		TextSize = 18,
		Parent = root,
	})
	langButton.Activated:Connect(LocaleController.toggle)

	-- The lane store as a dialogue screen: Abu Marzouk's and Abu Brahim's prompts open it (LP-D08, LP-E03).
	LobbyMenuController.register("store", function()
		ShopController.openStore()
	end)

	-- One-tap music mute beside the pills (the match HUD has its own next to the gear).
	SettingsController.muteButton({
		Name = "Music",
		Position = UDim2.new(0.5, 112, 0, 4),
		Size = UDim2.fromOffset(Theme.TOUCH, Theme.TOUCH),
		BackgroundColor3 = Color3.fromHex("#6E5E50"),
		Parent = root,
	})

	-- Shown only when the server runs on the mock store (unpublished place / no API access).
	testBadge = Theme.label({
		Name = "TestMode",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, Theme.TOUCH + 10),
		Size = UDim2.fromOffset(320, 18),
		TextSize = 13,
		FontFace = Theme.fontBold,
		TextColor3 = Theme.colors.danger,
		TextStrokeColor3 = Theme.colors.panel,
		TextStrokeTransparency = 0.2,
		Visible = false,
		Parent = root,
	})
end

render = function()
	local t = LocaleController.t
	local rtl = LocaleController.isRtl()
	local snapshot = StateController.get()

	if snapshot then
		-- The qirsh icon carries the unit; the pill shows the number only.
		local function fmt(n: number): string
			return tostring(n)
		end
		if lastQirsh and snapshot.qirsh ~= lastQirsh then
			-- Count up and punch so earning/spending is noticed.
			Juice.count(coinLabel, lastQirsh, snapshot.qirsh, fmt)
			Juice.punch(coinPill, 0.1)
			if snapshot.qirsh > lastQirsh then
				Juice.glow(coinPill) -- Theme v2 (LP-C02)
			end
		else
			coinLabel.Text = fmt(snapshot.qirsh)
		end
		lastQirsh = snapshot.qirsh
	end

	langButton.Text = t("hud.language")
	-- The toggle names the other language: "عربي" in English mode. Fredoka One has no Arabic glyphs
	-- (a thin fallback under a heavy outline), so the Arabic label gets the bold UI face instead.
	langButton.FontFace = if rtl then Theme.fontDisplay else Theme.fontBold
	langButton.TextSize = if rtl then 17 else 21
	testBadge.Visible = snapshot ~= nil and not snapshot.persistent
	testBadge.Text = t("notify.persistence_disabled")
end

function HudController.start()
	build()
	render()
	StateController.Changed:Connect(render)
	LocaleController.Changed:Connect(render)
	Device.Changed:Connect(render)
end

return HudController
