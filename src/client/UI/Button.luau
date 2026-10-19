--!strict
-- One button factory for every screen (Theme v2, LP-C01, LOOK_AND_PLAY_PLAN §5.2). Every button
-- has four states: idle, hover / focus (Theme.hover: a brass edge), pressed (Juice.press: a squash,
-- the lip turns on touch) and disabled (Button.setEnabled: desaturated, no bevel, no input); where it
-- matters, a fifth: ready (Button.setReady: a slow brass shimmer and a notification dot).
--   Button.new(props, variant?) -- a visible button; variant "wood" (default) | "primary" (gold leaf)
--                                  | "danger" (diwan red) | "confirm" | "quiet" (muted)
--   Button.hit(props)            -- an invisible hit area over a card, a row or a backdrop
-- Theme.button is the implementation underneath and stays valid for the older call sites.

local Create = require(script.Parent.Create)
local Theme = require(script.Parent.Theme)
local Juice = require(script.Parent.Juice)

local Button = {}

export type Variant = "wood" | "primary" | "danger" | "confirm" | "quiet"

local function variantColor(variant: Variant?): Color3
	if variant == "primary" then
		return Theme.v2.goldLeaf
	elseif variant == "danger" then
		return Theme.v2.diwanRed
	elseif variant == "confirm" then
		return Theme.colors.confirm
	elseif variant == "quiet" then
		return Theme.colors.textMuted
	end
	return Theme.v2.wood
end

function Button.new(props: { [string]: any }, variant: Variant?): TextButton
	if props.BackgroundColor3 == nil then
		props.BackgroundColor3 = variantColor(variant)
	end
	local b = Theme.button(props)
	b:SetAttribute("Variant", variant or "wood")
	b:SetAttribute("Base", b.BackgroundColor3:ToHex())
	if variant == "primary" then
		Theme.chrome(b, "primary")
	else
		Theme.chrome(b, "button")
	end
	return b
end

-- An invisible, text-less hit area (no colour change, no squash of its own: the card it covers
-- usually presses or tilts instead).
function Button.hit(props: { [string]: any }): TextButton
	props.Text = props.Text or ""
	props.BackgroundTransparency = 1
	local b = Create("TextButton", props) :: TextButton
	b.AutoButtonColor = false
	b.BorderSizePixel = 0
	return b
end

-- Disabled: desaturated colour, no bevel shade, no input. Enabled again restores the colour it had.
function Button.setEnabled(b: TextButton, on: boolean)
	if (b:GetAttribute("Disabled") == true) == not on then
		return
	end
	local shade = b:FindFirstChild("Shade")
	if on then
		local base = b:GetAttribute("Base")
		if type(base) == "string" then
			b.BackgroundColor3 = Color3.fromHex(base)
		end
		b.TextColor3 = Theme.colors.buttonText
		if shade and shade:IsA("UIGradient") then
			shade.Enabled = true
		end
	else
		b:SetAttribute("Base", b.BackgroundColor3:ToHex())
		b.BackgroundColor3 = Theme.colors.buttonDisabled
		b.TextColor3 = Theme.v2.disabledText
		if shade and shade:IsA("UIGradient") then
			shade.Enabled = false
		end
	end
	b.Active = on
	b.AutoButtonColor = false
	b:SetAttribute("Disabled", not on)
end

-- Ready (a claimable Daily, a Diary tier, an affordable summon): a shimmer every 4 s while motion is
-- allowed, and the notification dot always.
function Button.setReady(b: GuiObject, on: boolean)
	Juice.dot(b, on)
	local shine = b:FindFirstChild("Shine")
	if on and not shine and Juice.allowed("ready") then
		Juice.shine(b, 4)
	elseif not on and shine then
		shine:Destroy()
	end
end

return Button
