--!strict
-- Currency amounts drawn as an icon next to the number (POLISH_PLAN PV-C03): reward cells, costs on
-- buttons, result lines. An entry is { icon, text }: the icon sits left of the number, right of it in
-- Arabic, and entries flow in reading order. Icons come from UI/Icons (painted image when
-- Config/Icons has an id, else the primitive drawer).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared.Config.Items)
local Units = require(Shared.Config.Units)
local IconIds = require(Shared.Config.Icons)
local Create = require(script.Parent.Create)
local Theme = require(script.Parent.Theme)
local Icons = require(script.Parent.Icons)

local Amount = {}

export type Entry = { icon: string?, iconColor: string?, text: string }
-- align: where the row sits (default centre; Left is mirrored to Right in Arabic).
export type Opts = { iconSize: number?, textSize: number?, color: Color3?, rtl: boolean?, zIndex: number?, display: boolean?, align: Enum.HorizontalAlignment?, bold: boolean? }

-- The entries for a reward bundle ({ lira, qirsh, traitStones, cash, xp, item, unit, units }),
-- in the same order as UI/RewardText. Numbers carry a "+".
function Amount.reward(t: (string, { [string]: any }?) -> string, reward: any): { Entry }
	local out: { Entry } = {}
	local function num(key: string, n: any)
		if type(n) == "number" and n > 0 then
			table.insert(out, { icon = IconIds.reward[key], text = "+" .. tostring(n) })
		end
	end
	num("lira", reward.lira)
	num("qirsh", reward.qirsh)
	num("traitStones", reward.traitStones)
	num("matchCash", reward.cash)
	num("xp", reward.xp)
	local item = reward.item and (Items :: any)[reward.item]
	if item then
		table.insert(out, { icon = item.icon, iconColor = item.iconColor, text = t(item.nameKey) })
	end
	if reward.unit and (Units :: any)[reward.unit] then
		table.insert(out, { text = t("pass.reward.unit", { unit = t((Units :: any)[reward.unit].nameKey) }) })
	end
	if type(reward.units) == "table" then
		table.insert(out, { text = t("reward.units", { n = #reward.units }) })
	end
	return out
end

-- Fills `row` (a Frame) with the entries, replacing what it held. The row gets a centred,
-- wrapping horizontal layout; each entry is an icon + label pair.
function Amount.fill(row: GuiObject, entries: { Entry }, opts: Opts?)
	local o: Opts = opts or {}
	local iconSize = o.iconSize or 24
	local textSize = o.textSize or 14
	local z = o.zIndex or row.ZIndex
	for _, c in row:GetChildren() do
		if c.Name == "AmountLayout" or c.Name == "AmountEntry" then
			c:Destroy()
		end
	end
	Create("UIListLayout", {
		Name = "AmountLayout",
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = if o.align == Enum.HorizontalAlignment.Left and o.rtl then Enum.HorizontalAlignment.Right else o.align or Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Wraps = true,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = row,
	})
	local n = #entries
	for i, e in entries do
		local pair = Create("Frame", {
			Name = "AmountEntry",
			LayoutOrder = if o.rtl then n - i else i,
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, math.max(iconSize, textSize + 4)),
			ZIndex = z,
			Parent = row,
		})
		Create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 3),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = pair,
		})
		if e.icon then
			local holder = Create("Frame", {
				Name = "Icon",
				LayoutOrder = if o.rtl then 2 else 1,
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(iconSize, iconSize),
				ZIndex = z,
				Parent = pair,
			})
			Icons.draw(e.icon, holder, e.iconColor)
			for _, d in holder:GetDescendants() do
				if d:IsA("GuiObject") then
					d.ZIndex = z
				end
			end
		end
		local props = {
			Name = "Text",
			LayoutOrder = if o.rtl then 1 else 2,
			Text = e.text,
			TextSize = textSize,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, textSize + 4),
			ZIndex = z,
			Parent = pair,
		}
		local label = if o.display then Theme.display(props) else Theme.label(props)
		label.TextWrapped = false
		if o.color then
			label.TextColor3 = o.color
		end
		if o.bold and not o.display then
			label.FontFace = Theme.fontBold
		end
	end
end

-- A transparent row frame filled with the entries.
function Amount.row(props: { [string]: any }, entries: { Entry }, opts: Opts?): Frame
	local row = Create("Frame", props)
	row.BackgroundTransparency = 1
	Amount.fill(row, entries, opts)
	return row
end

-- Replaces a button's text with entries (e.g. "Summon ×1 ·" then the lira icon and "50"),
-- in the button's own outlined display style.
function Amount.button(button: TextButton, entries: { Entry }, opts: Opts?)
	button.Text = ""
	local holder = button:FindFirstChild("AmountRow") :: Frame?
	if not holder then
		holder = Create("Frame", {
			Name = "AmountRow",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ZIndex = button.ZIndex + 1,
			Parent = button,
		})
	end
	local o: Opts = table.clone(opts or {})
	o.display = true
	o.textSize = o.textSize or button.TextSize
	o.iconSize = o.iconSize or math.floor(button.TextSize * 1.5)
	o.zIndex = button.ZIndex + 1
	Amount.fill(holder :: Frame, entries, o)
end

return Amount
