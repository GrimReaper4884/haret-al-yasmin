--!strict
-- Codes screen: a text box and a Redeem button. The server validates everything.
-- On touch (MOBILE_HUD_PLAN B7) typing anchors the panel to the top of the safe area and ends it
-- above the on-screen keyboard, the box row scrolled to the top, so the box and Redeem stay visible.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local Hud = require(Shared.Config.Hud)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Modal = require(UI.Modal)
local Amount = require(UI.Amount)
local Juice = require(UI.Juice)
local Device = require(UI.Device)
local Root = require(UI.Root)
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
local lastRedeem = -math.huge

local ERRORS = {
	unknown_code = "codes.unknown",
	bad_code = "codes.unknown",
	expired = "codes.expired",
	already_redeemed = "codes.already",
	match_only = "codes.match_only",
}

local sendCode: (code: string) -> ()

-- Asks, then sends the code (Redeem, or Return in the box); the server validates everything.
local function redeemCode()
	if busy or os.clock() - lastRedeem < Hud.KEYBOARD.redeemDebounceS then
		return
	end
	local code = box.Text
	if #code == 0 then
		return
	end
	-- Ask once before the code is spent (LP-C03, Modal.confirm).
	local t0 = LocaleController.t
	Modal.confirm("redeem", t0("confirm.redeem", { code = code }), t0("codes.redeem"), t0("confirm.no"), LocaleController.isRtl(), function()
		sendCode(code)
	end)
end

sendCode = function(code: string)
	if busy then
		return
	end
	busy = true
	lastRedeem = os.clock()
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
			Juice.shake(box)
		end
	end)
end

local function build()
	modal = Modal.create("Codes", 440, 170)
	modal.onClose = function()
		box:ReleaseFocus()
		modal.setKeyboard(false)
	end
	local body = modal.body
	hint = Theme.label({ TextSize = 13, TextColor3 = Theme.colors.textMuted, Size = UDim2.new(1, 0, 0, 36), ZIndex = 11, Parent = body })
	box = Create("TextBox", {
		Position = UDim2.fromOffset(0, 44),
		Size = UDim2.new(1, -130, 0, Theme.TOUCH),
		BackgroundColor3 = Color3.fromHex("#FBF8F1"),
		TextColor3 = Theme.colors.text,
		PlaceholderColor3 = Theme.colors.textMuted,
		TextSize = 20,
		FontFace = Theme.fontBold,
		ClearTextOnFocus = false,
		Text = "",
		ZIndex = 11,
		Parent = body,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 10) }),
		-- Border mode: a Contextual stroke on a TextBox outlines the letters, not the box.
		Create("UIStroke", { Color = Theme.colors.panelStroke, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		Create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }),
	})
	redeem = Theme.button({ TextSize = 15, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 44), Size = UDim2.fromOffset(120, Theme.TOUCH), BackgroundColor3 = Theme.colors.quest, ZIndex = 11, Parent = body })
	result = Theme.label({ TextSize = 14, FontFace = Theme.fontBold, TextColor3 = Theme.colors.accent, Position = UDim2.fromOffset(0, 104), Size = UDim2.new(1, 0, 0, 22), ZIndex = 11, Parent = body })
	granted = Amount.row({ Name = "Granted", Position = UDim2.fromOffset(0, 126), Size = UDim2.new(1, 0, 0, 28), ZIndex = 11, Parent = body }, {})
	redeem.Activated:Connect(redeemCode)
end

-- Where the keyboard's top edge sits, in design px from the top of the safe area (nil: none
-- reported). OnScreenKeyboardPosition is in viewport px, which start above the top bar inset.
local function keyboardTop(): number?
	if not UserInputService.OnScreenKeyboardVisible then
		return nil
	end
	local inset = GuiService:GetGuiInset()
	local y = UserInputService.OnScreenKeyboardPosition.Y - inset.Y - Root.get().AbsolutePosition.Y
	return y / math.max(Device.scale(), 0.01)
end

local function fitKeyboard()
	local typing = Device.isTouch() and box:IsFocused() and modal.isOpen()
	modal.setKeyboard(typing, if typing then keyboardTop() else nil, if typing then box else nil)
end

-- The tap that ends typing is usually on Redeem: keep the layout until that tap has landed, or the
-- button moves out from under the finger before its release.
local function keyboardGone()
	task.delay(Hud.KEYBOARD.restoreS, fitKeyboard)
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
	box.Focused:Connect(fitKeyboard)
	-- Return redeems; so does the tap that ends typing when it lands on Redeem (on touch that tap
	-- only dismisses the keyboard and never reaches the button).
	box.FocusLost:Connect(function(enterPressed: boolean, cause: InputObject?)
		keyboardGone()
		local onRedeem = false
		if cause and (cause.UserInputType == Enum.UserInputType.Touch or cause.UserInputType == Enum.UserInputType.MouseButton1) then
			local p, a, sz = cause.Position, redeem.AbsolutePosition, redeem.AbsoluteSize
			onRedeem = p.X >= a.X and p.X <= a.X + sz.X and p.Y >= a.Y and p.Y <= a.Y + sz.Y
		end
		if enterPressed or onRedeem then
			redeemCode()
		end
	end)
	UserInputService:GetPropertyChangedSignal("OnScreenKeyboardVisible"):Connect(function()
		if UserInputService.OnScreenKeyboardVisible then
			fitKeyboard()
		else
			keyboardGone()
		end
	end)
	UserInputService:GetPropertyChangedSignal("OnScreenKeyboardPosition"):Connect(fitKeyboard)
	Device.Changed:Connect(fitKeyboard)
end

return CodesController
