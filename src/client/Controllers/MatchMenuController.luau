--!strict
-- The match menu (docs/MOBILE_HUD_PLAN.md B2, MH-04): one `≡` button at the top of the rail's edge
-- opens this sheet with everything the thumbs rarely need mid-match: Leave (two steps, since a
-- mid-match leave forfeits the run), Codes (match-cash codes work only here), Settings, Music and the
-- language. Skip, Speed and View stay on the rail. The same sheet on every profile.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Modal = require(UI.Modal)
local Icons = require(UI.Icons)
local LocaleController = require(script.Parent.LocaleController)
local LobbyMenuController = require(script.Parent.LobbyMenuController)
local SettingsController = require(script.Parent.SettingsController)

local MatchMenuController = {}

local modal: Modal.Modal
local leaveRow: Frame
local confirmRow: Frame
local confirmLabel: TextLabel
local leaveButton: TextButton
local confirmButton: TextButton
local backButton: TextButton
local codesButton: TextButton
local settingsButton: TextButton
local musicButton: TextButton
local languageButton: TextButton
local leaving = false

-- A half-width 48 px button with an icon at its leading edge, in a two-button row.
local function halfButton(row: Frame, order: number, color: Color3, iconName: string?): TextButton
	local b = Theme.button({ LayoutOrder = order, TextSize = 16, Size = UDim2.new(0.5, -3, 1, 0), BackgroundColor3 = color, ZIndex = 11, Parent = row })
	if iconName then
		local holder = Create("Frame", { Name = "Icon", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(30, 30), BackgroundTransparency = 1, ZIndex = 12, Parent = b })
		Icons.draw(iconName, holder)
		for _, d in holder:GetDescendants() do
			if d:IsA("GuiObject") then
				d.ZIndex = 12
			end
		end
	end
	return b
end

local function showConfirm(on: boolean)
	leaveRow.Visible = not on
	confirmRow.Visible = on
end

local function render()
	if not modal then
		return
	end
	local t = LocaleController.t
	local rtl = LocaleController.isRtl()
	modal.title.Text = t("match.menu")
	Theme.align(modal.title, rtl)
	leaveButton.Text = t("match.leave")
	confirmLabel.Text = t("match.leave_confirm")
	Theme.align(confirmLabel, rtl)
	confirmButton.Text = t("match.leave")
	backButton.Text = t("match.leave_back")
	codesButton.Text = t("codes.title")
	settingsButton.Text = t("settings.title")
	local on = SettingsController.get("music") ~= false
	musicButton.Text = t(if on then "settings.on" else "settings.off")
	local icon = musicButton:FindFirstChild("Icon")
	if icon and icon:IsA("Frame") then
		icon:ClearAllChildren()
		Icons.draw(if on then "ui_music" else "ui_music_off", icon)
		for _, d in icon:GetDescendants() do
			if d:IsA("GuiObject") then
				d.ZIndex = 12
			end
		end
	end
	languageButton.Text = t("hud.language")
end

local function build()
	-- Three 48 px rows (Leave; Codes · Settings; Music · Language) fit a 282 px phone canvas.
	modal = Modal.create("MatchMenu", 380, 3 * Theme.TOUCH + 2 * 6)
	Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = modal.body })

	-- Leave, then "Leave the match?" with Leave / Stay in its place.
	leaveRow = Create("Frame", { LayoutOrder = 1, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, Theme.TOUCH), ZIndex = 11, Parent = modal.body })
	leaveButton = Theme.button({ TextSize = 17, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.colors.danger, ZIndex = 11, Parent = leaveRow })
	confirmRow = Create("Frame", { LayoutOrder = 1, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, Theme.TOUCH), Visible = false, ZIndex = 11, Parent = modal.body })
	confirmLabel = Theme.label({ TextSize = 15, FontFace = Theme.fontBold, Size = UDim2.new(1, -2 * (96 + 6), 1, 0), ZIndex = 11, Parent = confirmRow })
	confirmButton = Theme.button({ Name = "LeaveConfirm", TextSize = 16, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -(96 + 6), 0, 0), Size = UDim2.fromOffset(96, Theme.TOUCH), BackgroundColor3 = Theme.colors.danger, ZIndex = 11, Parent = confirmRow })
	backButton = Theme.button({ Name = "LeaveBack", TextSize = 16, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(96, Theme.TOUCH), ZIndex = 11, Parent = confirmRow })

	local function pairRow(order: number): Frame
		local row = Create("Frame", { LayoutOrder = order, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, Theme.TOUCH), ZIndex = 11, Parent = modal.body })
		Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })
		return row
	end
	local second, third = pairRow(2), pairRow(3)
	codesButton = halfButton(second, 1, Color3.fromHex("#5E6F7D"), "ui_codes")
	settingsButton = halfButton(second, 2, Color3.fromHex("#6E5E50"), "ui_settings")
	musicButton = halfButton(third, 1, Color3.fromHex("#6E5E50"), "ui_music")
	languageButton = halfButton(third, 2, Theme.colors.button, nil)

	leaveButton.Activated:Connect(function()
		showConfirm(true)
	end)
	backButton.Activated:Connect(function()
		showConfirm(false)
	end)
	confirmButton.Activated:Connect(function()
		if leaving then
			return
		end
		leaving = true
		Net.event(Net.Events.LeaveMatch):FireServer()
		modal.setVisible(false)
	end)
	codesButton.Activated:Connect(function()
		local open = LobbyMenuController.opener("codes")
		if open then
			open()
		end
	end)
	settingsButton.Activated:Connect(function()
		local open = LobbyMenuController.opener("settings")
		if open then
			open()
		end
	end)
	musicButton.Activated:Connect(function()
		SettingsController.set("music", SettingsController.get("music") == false)
	end)
	languageButton.Activated:Connect(LocaleController.toggle)
	modal.onClose = function()
		showConfirm(false)
	end
end

function MatchMenuController.open()
	leaving = false
	showConfirm(false)
	render()
	modal.setVisible(true)
end

function MatchMenuController.close()
	modal.setVisible(false)
end

function MatchMenuController.start()
	build()
	SettingsController.Changed:Connect(function(key: string)
		if key == "music" then
			render()
		end
	end)
	LocaleController.Changed:Connect(render)
end

return MatchMenuController
