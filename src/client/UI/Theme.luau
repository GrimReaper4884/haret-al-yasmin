--!strict
-- UI tokens (docs/ART_BIBLE.md §6) and the styling helpers every controller builds with.
--
-- The look follows the genre conventions in docs/research/ROBLOX_TD_UI_PATTERNS.md, in the lane's
-- own warm palette: chunky display numbers with dark outlines, thick dark panel strokes,
-- two-stop vertical gradients on buttons (lighter top), press feedback on every button.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Palette = require(ReplicatedStorage:WaitForChild("Shared").Config.Palette)
local Create = require(script.Parent.Create)
local Juice = require(script.Parent.Juice)

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
	confirm = Color3.fromHex("#4E9A3E"), -- upgrade / claim / buy
	gold = Color3.fromHex("#E0A82E"), -- premium, currency
	outline = Color3.fromHex("#22180F"), -- text and stroke outline
	hpHigh = Color3.fromHex("#5DBB4A"),
	hpMid = Color3.fromHex("#E8B23A"),
	hpLow = Color3.fromHex("#D9483B"),
}

Theme.rarity = {
	rare = Color3.fromHex("#3A8FD6"),
	epic = Color3.fromHex("#9B4FD1"),
	legendary = Color3.fromHex("#E8B23A"),
	mythic = Color3.fromHex("#E0433A"),
	secret = Color3.fromHex("#2A2A2A"),
}
Theme.lira = Color3.fromHex("#E0A82E")

function Theme.rarityColor(rarity: string): Color3
	return Theme.rarity[rarity] or Theme.colors.textMuted
end

Theme.font = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium)
Theme.fontBold = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
-- Chunky display face for titles, numbers and buttons (Arabic falls back automatically).
Theme.fontDisplay = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Regular)

Theme.TOUCH = 48 -- minimum touch target, px at UIScale 1
Theme.RADIUS = UDim.new(0, 12)

-- Dark glyph outline on a text object (the "sticker" look that reads on any background).
function Theme.outline(text: GuiObject, thickness: number?, color: Color3?): UIStroke
	local existing = text:FindFirstChild("TextOutline")
	local s = if existing and existing:IsA("UIStroke") then existing else Instance.new("UIStroke")
	s.Name = "TextOutline"
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Thickness = thickness or 2
	s.Color = color or Theme.colors.outline
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = text
	return s
end

-- Lighter-top vertical shading that works on any BackgroundColor3.
function Theme.shade(gui: GuiObject, strength: number?): UIGradient
	local k = strength or 0.22
	local g = Instance.new("UIGradient")
	g.Name = "Shade"
	g.Rotation = 90
	g.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1 - k, 1 - k, 1 - k))
	g.Parent = gui
	return g
end

local function border(gui: GuiObject, thickness: number, color: Color3?, transparency: number?): UIStroke
	local s = Instance.new("UIStroke")
	s.Name = "Border"
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Thickness = thickness
	s.Color = color or Theme.colors.outline
	s.Transparency = transparency or 0
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = gui
	return s
end
Theme.border = border

function Theme.panel(props: { [string]: any }): Frame
	local f = Create("Frame", props, {
		Create("UICorner", { CornerRadius = Theme.RADIUS }),
		Create("UIStroke", { Color = Theme.colors.panelStroke, Thickness = 3, Transparency = 0, LineJoinMode = Enum.LineJoinMode.Round }),
	})
	f.BackgroundColor3 = props.BackgroundColor3 or Theme.colors.panel
	f.BackgroundTransparency = if props.ZIndex and props.ZIndex >= 10 then 0 else 0.04
	f.BorderSizePixel = 0
	Theme.shade(f, 0.08)
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

-- A big outlined label for numbers and titles (white text, dark outline by default).
function Theme.display(props: { [string]: any }): TextLabel
	local l = Theme.label(props)
	l.FontFace = props.FontFace or Theme.fontDisplay
	l.TextColor3 = props.TextColor3 or Color3.new(1, 1, 1)
	Theme.outline(l, props.TextSize and props.TextSize >= 20 and 2.5 or 2)
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
	b.AutoButtonColor = false
	b.BackgroundColor3 = props.BackgroundColor3 or Theme.colors.button
	b.TextColor3 = props.TextColor3 or Theme.colors.buttonText
	b.FontFace = props.FontFace or Theme.fontDisplay
	b.BorderSizePixel = 0
	Theme.shade(b)
	border(b, 2.5)
	Theme.outline(b, 1.6)
	Juice.press(b)
	return b
end

-- A currency / counter pill: coloured disc icon on the left edge, outlined number.
function Theme.pill(props: { [string]: any }, iconColor: Color3): (Frame, TextLabel)
	local pill = Create("Frame", props, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	pill.BackgroundColor3 = Color3.fromHex("#2A1E14")
	pill.BackgroundTransparency = 0.25
	pill.BorderSizePixel = 0
	border(pill, 2.5)
	local disc = Create("Frame", {
		Name = "Icon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 4, 0.5, 0),
		Size = UDim2.fromOffset(30, 30),
		BackgroundColor3 = iconColor,
		ZIndex = (props.ZIndex or 1) + 1,
		Parent = pill,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	Theme.shade(disc, 0.3)
	border(disc, 2.5)
	Create("Frame", { -- inner ring so it reads as a coin
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.55, 0.55),
		BackgroundTransparency = 1,
		ZIndex = (props.ZIndex or 1) + 2,
		Parent = disc,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }), Create("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2, Transparency = 0.35 }) })
	local amount = Theme.display({
		Name = "Amount",
		Text = "",
		TextSize = 20,
		Position = UDim2.fromOffset(24, 0),
		Size = UDim2.new(1, -30, 1, 0),
		ZIndex = (props.ZIndex or 1) + 1,
		Parent = pill,
	})
	amount.TextXAlignment = Enum.TextXAlignment.Center
	return pill, amount
end

-- A horizontal meter (HP, progress) with a lagging "ghost" fill and a centred outlined label.
export type Meter = { frame: Frame, fill: Frame, ghost: Frame, label: TextLabel, set: (number, string?) -> () }
function Theme.meter(props: { [string]: any }, color: Color3?): Meter
	local TweenService = game:GetService("TweenService")
	local z = props.ZIndex or 1
	local frame = Create("Frame", props, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	frame.BackgroundColor3 = Color3.new(0, 0, 0)
	frame.BackgroundTransparency = 0.45
	frame.BorderSizePixel = 0
	border(frame, 2.5)
	local ghost = Create("Frame", { Name = "Ghost", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.15, BorderSizePixel = 0, ZIndex = z + 1, Parent = frame }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	local fill = Create("Frame", { Name = "Fill", Size = UDim2.fromScale(1, 1), BackgroundColor3 = color or Theme.colors.hpHigh, BorderSizePixel = 0, ZIndex = z + 2, Parent = frame }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	Theme.shade(fill, 0.3)
	local label = Theme.display({ Text = "", TextSize = 13, Size = UDim2.fromScale(1, 1), ZIndex = z + 3, Parent = frame })
	label.TextXAlignment = Enum.TextXAlignment.Center
	local last = 1
	local function set(frac: number, text: string?)
		frac = math.clamp(frac, 0, 1)
		TweenService:Create(fill, TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), { Size = UDim2.fromScale(frac, 1) }):Play()
		if frac < last then
			task.delay(0.3, function()
				TweenService:Create(ghost, TweenInfo.new(0.45, Enum.EasingStyle.Quad), { Size = UDim2.fromScale(frac, 1) }):Play()
			end)
		else
			ghost.Size = UDim2.fromScale(frac, 1)
		end
		last = frac
		if text then
			label.Text = text
		end
	end
	return { frame = frame, fill = fill, ghost = ghost, label = label, set = set }
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
