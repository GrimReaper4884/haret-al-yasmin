--!strict
-- UI tokens (docs/ART_BIBLE.md §6) and small styling helpers shared by all UI controllers.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Palette = require(ReplicatedStorage:WaitForChild("Shared").Config.Palette)
local Create = require(script.Parent.Create)

local Theme = {}

Theme.colors = {
	panel = Palette.plaster,
	panelStroke = Palette.woodDark,
	text = Palette.ink,
	textMuted = Color3.fromHex("#6E5E50"),
	accent = Palette.copper,
	quest = Palette.tile,
	button = Palette.wood,
	buttonText = Palette.jasmine,
	buttonDisabled = Color3.fromHex("#A89A8C"),
	danger = Palette.fabricRed,
}

Theme.font = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium)
Theme.fontBold = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)

Theme.TOUCH = 48 -- minimum touch target, px at UIScale 1
Theme.RADIUS = UDim.new(0, 12)

function Theme.panel(props: { [string]: any }): Frame
	local f = Create("Frame", props, {
		Create("UICorner", { CornerRadius = Theme.RADIUS }),
		Create("UIStroke", { Color = Theme.colors.panelStroke, Thickness = 2, Transparency = 0.2 }),
	})
	f.BackgroundColor3 = Theme.colors.panel
	f.BackgroundTransparency = if props.ZIndex and props.ZIndex >= 10 then 0 else 0.06
	f.BorderSizePixel = 0
	return f
end

function Theme.label(props: { [string]: any }): TextLabel
	local l = Create("TextLabel", props)
	l.BackgroundTransparency = 1
	l.FontFace = props.FontFace or Theme.font
	l.TextColor3 = props.TextColor3 or Theme.colors.text
	l.TextWrapped = true
	return l
end

function Theme.button(props: { [string]: any }): TextButton
	local b = Create("TextButton", props, {
		Create("UICorner", { CornerRadius = UDim.new(0, 10) }),
		Create("UIPadding", {
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
		}),
	})
	b.AutoButtonColor = true
	b.BackgroundColor3 = props.BackgroundColor3 or Theme.colors.button
	b.TextColor3 = props.TextColor3 or Theme.colors.buttonText
	b.FontFace = Theme.fontBold
	b.BorderSizePixel = 0
	return b
end

-- Applies right-to-left alignment to a label for Arabic.
function Theme.align(label: any, rtl: boolean, centered: boolean?)
	if centered then
		label.TextXAlignment = Enum.TextXAlignment.Center
	else
		label.TextXAlignment = if rtl then Enum.TextXAlignment.Right else Enum.TextXAlignment.Left
	end
end

return Theme
