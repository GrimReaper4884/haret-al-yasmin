--!strict
-- Codes screen: a text box and a Redeem button. The server validates everything.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Modal = require(UI.Modal)
local Amount = require(UI.Amount)
local LocaleController = require(script.Parent.LocaleController)
local LobbyMenuController = require(script.Parent.LobbyMenuController)
local ToastController = require(script.Parent.ToastController)

local CodesController = {}

local modal: Modal.Modal
local box: TextBox
local redeem: TextButton
local hint: TextLabel
local result: TextLabel
local granted: Frame
local busy = false

local ERRORS = {
	unknown_code = "codes.unknown",
	bad_code = "codes.unknown",
	expired = "codes.expired",
	already_redeemed = "codes.already",
	match_only = "codes.match_only",
}

local function build()
	modal = Modal.create("Codes", 440, 170)
	local body = modal.body
	hint = Theme.label({ TextSize = 13, TextColor3 = Theme.colors.textMuted, Size = UDim2.new(1, 0, 0, 36), ZIndex = 11, Parent = body })
	box = Create("TextBox", {
		Position = UDim2.fromOffset(0, 44),
		Size = UDim2.new(1, -130, 0, Theme.TOUCH),
		BackgroundColor3 = Color3.fromHex("#FBF8F1"),
		TextColor3 = Theme.colors.text,
		TextSize = 20,
		FontFace = Theme.fontBold,
		ClearTextOnFocus = false,
		Text = "",
		ZIndex = 11,
		Parent = body,
	}, { Create("UICorner", { CornerRadius = UDim.new(0, 10) }), Create("UIStroke", { Color = Theme.colors.panelStroke, Thickness = 2 }) })
	redeem = Theme.button({ TextSize = 15, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 44), Size = UDim2.fromOffset(120, Theme.TOUCH), BackgroundColor3 = Theme.colors.quest, ZIndex = 11, Parent = body })
	result = Theme.label({ TextSize = 14, FontFace = Theme.fontBold, TextColor3 = Theme.colors.accent, Position = UDim2.fromOffset(0, 104), Size = UDim2.new(1, 0, 0, 22), ZIndex = 11, Parent = body })
	granted = Amount.row({ Name = "Granted", Position = UDim2.fromOffset(0, 126), Size = UDim2.new(1, 0, 0, 28), ZIndex = 11, Parent = body }, {})
	redeem.Activated:Connect(function()
		if busy then
			return
		end
		local code = box.Text
		if #code == 0 then
			return
		end
		busy = true
		task.spawn(function()
			local ok, r = pcall(function()
				return Net.func(Net.Functions.RedeemCode):InvokeServer(code)
			end)
			busy = false
			local t = LocaleController.t
			if ok and type(r) == "table" and r.ok then
				result.Text = t("codes.ok")
				Amount.fill(granted, Amount.reward(t, r.granted or {}), { iconSize = 24, textSize = 15, rtl = LocaleController.isRtl() })
				box.Text = ""
				ToastController.show("codes.ok")
			else
				local err = if ok and type(r) == "table" then r.err else "error"
				result.Text = t(ERRORS[err] or "notify.error")
				Amount.fill(granted, {})
			end
		end)
	end)
end

local function render()
	if not modal.isOpen() then
		return
	end
	local t = LocaleController.t
	modal.title.Text = t("codes.title")
	hint.Text = t("codes.hint")
	box.PlaceholderText = t("codes.placeholder")
	redeem.Text = t("codes.redeem")
	Theme.align(hint, LocaleController.isRtl())
	Theme.align(modal.title, LocaleController.isRtl())
end

function CodesController.open()
	result.Text = ""
	modal.setVisible(true)
	render()
end

function CodesController.start()
	build()
	LocaleController.Changed:Connect(render)
	LobbyMenuController.register("codes", CodesController.open)
end

return CodesController
