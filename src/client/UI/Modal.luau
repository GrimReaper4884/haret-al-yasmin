--!strict
-- A centred modal panel with a title and a close button (the shape used by the shop and the
-- wardrobe), sized for a landscape phone. Content goes into `body`, a fixed-height frame.

local Create = require(script.Parent.Create)
local Theme = require(script.Parent.Theme)
local Root = require(script.Parent.Root)
local Juice = require(script.Parent.Juice)

local Modal = {}

export type Modal = {
	panel: Frame,
	title: TextLabel,
	body: Frame,
	setVisible: (boolean) -> (),
	isOpen: () -> boolean,
	onClose: (() -> ())?,
}

Modal.BODY_HEIGHT = 236 -- px at UIScale 1

local openModals: { [Frame]: boolean } = {}
local overlays: { GuiObject } = {}
local closers: { [Frame]: () -> () } = {}

function Modal.closed(f: Frame)
	local fn = closers[f]
	if fn then
		fn()
	end
end

-- Full-screen overlays (e.g. the summon reveal) that must close whenever a modal opens.
function Modal.registerOverlay(frame: GuiObject)
	table.insert(overlays, frame)
end

-- Closes every modal and overlay (match start, teleports).
function Modal.closeAll()
	for f in openModals do
		if f.Visible then
			f.Visible = false
			Modal.closed(f)
		end
	end
	for _, o in overlays do
		o.Visible = false
	end
end

-- Closes every other modal (one screen at a time on a phone).
local function closeOthers(except: Frame)
	for f in openModals do
		if f ~= except and f.Visible then
			f.Visible = false
			local m = f:GetAttribute("ModalName")
			if m then
				Modal.closed(f)
			end
		end
	end
end


function Modal.create(name: string, maxWidth: number, bodyHeight: number?): Modal
	local panel = Theme.panel({
		Name = name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		ZIndex = 10,
		Size = UDim2.fromScale(0.94, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = Root.get(),
	})
	panel:SetAttribute("ModalName", name)
	Create("UISizeConstraint", { MaxSize = Vector2.new(maxWidth, math.huge), Parent = panel })
	Create("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		Parent = panel,
	})
	Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = panel })

	local header = Create("Frame", {
		LayoutOrder = 1,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, Theme.TOUCH - 8),
		ZIndex = 11,
		Parent = panel,
	})
	local title = Theme.label({
		TextSize = 22,
		FontFace = Theme.fontDisplay,
		Size = UDim2.new(1, -(Theme.TOUCH + 4), 1, 0),
		ZIndex = 11,
		Parent = header,
	})
	local close = Theme.button({
		Text = "X",
		TextSize = 18,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(Theme.TOUCH - 8, Theme.TOUCH - 8),
		BackgroundColor3 = Theme.colors.danger,
		ZIndex = 11,
		Parent = header,
	})
	local body = Create("Frame", {
		LayoutOrder = 2,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, bodyHeight or Modal.BODY_HEIGHT),
		ZIndex = 11,
		Parent = panel,
	})

	local self: Modal = {
		panel = panel,
		title = title,
		body = body,
		setVisible = function() end,
		isOpen = function()
			return panel.Visible
		end,
		onClose = nil,
	}
	self.setVisible = function(v: boolean)
		if v then
			closeOthers(panel)
			for _, o in overlays do
				o.Visible = false
			end
		end
		if panel.Visible and not v and self.onClose then
			self.onClose()
		end
		local opening = v and not panel.Visible
		panel.Visible = v
		if opening then
			Juice.pop(panel)
		end
	end
	closers[panel] = function()
		if self.onClose then
			self.onClose()
		end
	end
	openModals[panel] = true
	close.Activated:Connect(function()
		self.setVisible(false)
	end)
	return self
end

-- Standard scrolling list inside a modal body.
function Modal.scroller(parent: Instance, horizontal: boolean?): ScrollingFrame
	local sf = Create("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = if horizontal then Enum.AutomaticSize.X else Enum.AutomaticSize.Y,
		ScrollingDirection = if horizontal then Enum.ScrollingDirection.X else Enum.ScrollingDirection.Y,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = Theme.colors.panelStroke,
		ZIndex = 11,
		Parent = parent,
	})
	return sf
end

return Modal
