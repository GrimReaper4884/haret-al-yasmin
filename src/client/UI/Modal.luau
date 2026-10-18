--!strict
-- A modal panel with a title and a close button (the shape used by every screen). Content goes into
-- `body`, a fixed-height frame, inside `content`, the panel's scroll area (extra rows such as the
-- result banner go into `content` too, ordered by LayoutOrder; the body is 2).
--   Tablet / desktop: a centred panel at most `maxWidth` wide, as tall as its content.
--   Phone (MOBILE_HUD_PLAN B7): a sheet filling the safe area minus Hud.SHEET_MARGIN; the content
--   scrolls when it is taller than the sheet, the close button is 48 px and a swipe down on the
--   header closes it. The mode follows UI/Device live.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hud = require(ReplicatedStorage:WaitForChild("Shared").Config.Hud)
local HudLayout = require(ReplicatedStorage.Shared.Logic.HudLayout)
local Create = require(script.Parent.Create)
local Theme = require(script.Parent.Theme)
local Root = require(script.Parent.Root)
local Juice = require(script.Parent.Juice)
local Device = require(script.Parent.Device)

local Modal = {}

export type Modal = {
	panel: Frame,
	title: TextLabel,
	content: ScrollingFrame,
	body: Frame,
	setVisible: (boolean) -> (),
	isOpen: () -> boolean,
	onClose: (() -> ())?,
	-- Touch text entry: keep the panel above the on-screen keyboard (`kbTop` in design px from the
	-- safe area's top, nil = no keyboard reported) and scroll `focus` into view; `on` false restores.
	setKeyboard: (on: boolean, kbTop: number?, focus: GuiObject?) -> (),
}

Modal.BODY_HEIGHT = 236 -- px at UIScale 1

local PAD_TOP, PAD_BOTTOM, GAP = 10, 12, 8
local SWIPE_PX = 50
local SCROLL_BAR = 10 -- px, the content's scroll bar while it can scroll

local openModals: { [Frame]: boolean } = {}
local overlays: { GuiObject } = {}
local closers: { [Frame]: () -> () } = {}
type Shape = {
	panel: Frame,
	header: Frame,
	content: ScrollingFrame,
	list: UIListLayout,
	body: Frame,
	limit: UISizeConstraint,
	maxWidth: number,
	bodyHeight: number,
	fill: boolean,
	keyboard: { on: boolean, kbTop: number? }?,
}
local shapes: { Shape } = {}

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

-- Sheet on a phone, centred panel elsewhere.
local function applyShape(s: Shape)
	if Device.isPhone() then
		local m = Hud.SHEET_MARGIN
		s.limit.MaxSize = Vector2.new(math.huge, math.huge)
		s.panel.AutomaticSize = Enum.AutomaticSize.None
		s.panel.Size = UDim2.new(1, -2 * m, 1, -2 * m)
		s.content.AutomaticSize = Enum.AutomaticSize.None
		s.content.Size = UDim2.new(1, 0, 1, -(Theme.TOUCH + GAP))
		s.content.ScrollingEnabled = true
		s.content.ScrollBarThickness = SCROLL_BAR
		-- A body built around its own scroller fills the sheet; any other keeps its height and the
		-- sheet scrolls it (room left for the bar).
		local window = s.content.AbsoluteSize.Y / math.max(Device.scale(), 0.01)
		local h = if s.fill and window > 0 then math.max(window, Theme.TOUCH) else s.bodyHeight
		s.body.Size = UDim2.new(1, if s.fill then 0 else -12, 0, h)
	else
		s.limit.MaxSize = Vector2.new(s.maxWidth, math.huge)
		s.panel.Size = UDim2.fromScale(0.94, 0)
		s.panel.AutomaticSize = Enum.AutomaticSize.Y
		-- As tall as its rows (a plain height: a parent's AutomaticSize does not count its padding
		-- around an auto-sized ScrollingFrame), rounded up so no sub-pixel remainder shows a bar.
		s.content.AutomaticSize = Enum.AutomaticSize.None
		s.content.Size = UDim2.new(1, 0, 0, math.ceil(s.list.AbsoluteContentSize.Y / math.max(Device.scale(), 0.01)))
		s.content.ScrollingEnabled = false
		s.content.ScrollBarThickness = 0
		s.content.CanvasPosition = Vector2.zero
		s.body.Size = UDim2.new(1, 0, 0, s.bodyHeight)
	end
	-- Typing on touch: anchored to the top of the safe area, ending above the keyboard.
	local kb = s.keyboard
	local fit = if kb then HudLayout.keyboardFit(Hud, Device.designSize().y, kb.kbTop, PAD_TOP + PAD_BOTTOM, Theme.TOUCH + GAP) else nil
	s.panel.AnchorPoint = Vector2.new(0.5, if kb then 0 else 0.5)
	s.panel.Position = if kb then UDim2.new(0.5, 0, 0, Hud.SHEET_MARGIN) else UDim2.fromScale(0.5, 0.5)
	s.header.Visible = fit == nil or fit.header
	if fit then
		s.panel.AutomaticSize = Enum.AutomaticSize.None
		s.panel.Size = if Device.isPhone() then UDim2.new(1, -2 * Hud.SHEET_MARGIN, 0, fit.height) else UDim2.new(0.94, 0, 0, fit.height)
		s.content.AutomaticSize = Enum.AutomaticSize.None
		s.content.Size = UDim2.new(1, 0, 1, if fit.header then -(Theme.TOUCH + GAP) else 0)
		s.content.ScrollingEnabled = true
		s.content.ScrollBarThickness = SCROLL_BAR
	end
end

-- opts.fill: on a phone the body takes the sheet's whole height (bodies whose content is a scroller).
function Modal.create(name: string, maxWidth: number, bodyHeight: number?, opts: { fill: boolean? }?): Modal
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
	local limit = Create("UISizeConstraint", { MaxSize = Vector2.new(maxWidth, math.huge), Parent = panel })
	Create("UIPadding", {
		PaddingTop = UDim.new(0, PAD_TOP),
		PaddingBottom = UDim.new(0, PAD_BOTTOM),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		Parent = panel,
	})
	Create("UIListLayout", { Padding = UDim.new(0, GAP), SortOrder = Enum.SortOrder.LayoutOrder, Parent = panel })

	local header = Create("Frame", {
		Name = "Header",
		LayoutOrder = 1,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, Theme.TOUCH),
		ZIndex = 11,
		Parent = panel,
	})
	local title = Theme.label({
		TextSize = 22,
		FontFace = Theme.fontDisplay,
		Size = UDim2.new(1, -(Theme.TOUCH + 8), 1, 0),
		ZIndex = 11,
		Parent = header,
	})
	local close = Theme.button({
		Text = "X",
		TextSize = 18,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(Theme.TOUCH, Theme.TOUCH),
		BackgroundColor3 = Theme.colors.danger,
		ZIndex = 11,
		Parent = header,
	})
	local content = Create("ScrollingFrame", {
		Name = "Content",
		LayoutOrder = 2,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = SCROLL_BAR,
		ScrollBarImageColor3 = Theme.colors.panelStroke,
		ElasticBehavior = Enum.ElasticBehavior.Always,
		ScrollingEnabled = false,
		ZIndex = 11,
		Parent = panel,
	})
	local contentList = Create("UIListLayout", { Padding = UDim.new(0, GAP), SortOrder = Enum.SortOrder.LayoutOrder, Parent = content })
	local body = Create("Frame", {
		Name = "Body",
		LayoutOrder = 2,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, bodyHeight or Modal.BODY_HEIGHT),
		ZIndex = 11,
		Parent = content,
	})

	local self: Modal = {
		panel = panel,
		title = title,
		content = content,
		body = body,
		setVisible = function() end,
		isOpen = function()
			return panel.Visible
		end,
		onClose = nil,
		setKeyboard = function() end,
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
			content.CanvasPosition = Vector2.zero
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
	-- A swipe down on the header closes the sheet (phones).
	local swipe: { input: InputObject, y: number }? = nil
	header.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.Touch then
			swipe = { input = input, y = input.Position.Y }
		end
	end)
	header.InputEnded:Connect(function(input: InputObject)
		local s = swipe
		if s and s.input == input then
			swipe = nil
			if Device.isPhone() and input.Position.Y - s.y > SWIPE_PX then
				self.setVisible(false)
			end
		end
	end)
	Modal.track(panel)
	local shape: Shape = {
		panel = panel,
		header = header,
		content = content,
		list = contentList,
		body = body,
		limit = limit,
		maxWidth = maxWidth,
		bodyHeight = bodyHeight or Modal.BODY_HEIGHT,
		fill = opts ~= nil and opts.fill == true,
		keyboard = nil,
	}
	table.insert(shapes, shape)
	applyShape(shape)
	self.setKeyboard = function(on: boolean, kbTop: number?, focus: GuiObject?)
		shape.keyboard = if on then { on = true, kbTop = kbTop } else nil
		applyShape(shape)
		if on and focus then
			-- Scroll the focused row to the top of the content window.
			task.defer(function()
				local dy = (focus.AbsolutePosition.Y - content.AbsolutePosition.Y) / math.max(Device.scale(), 0.01)
				content.CanvasPosition = Vector2.new(0, math.max(0, content.CanvasPosition.Y + dy))
			end)
		end
	end
	content:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if shape.fill and Device.isPhone() then
			applyShape(shape)
		end
	end)
	contentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		if not Device.isPhone() then
			applyShape(shape)
		end
	end)
	return self
end

-- Roblox's thumbstick and jump draw above every ScreenGui: hide them while a sheet (or another full
-- panel registered here) is open on a phone.
local tracked: { GuiObject } = {}
local function syncSheetBlock()
	local open = false
	if Device.isPhone() then
		for _, p in tracked do
			if p.Visible then
				open = true
				break
			end
		end
	end
	Device.blockTouchControls("sheet", open)
end

function Modal.track(panel: GuiObject)
	table.insert(tracked, panel)
	panel:GetPropertyChangedSignal("Visible"):Connect(syncSheetBlock)
end

Device.Changed:Connect(function()
	for _, s in shapes do
		applyShape(s)
	end
	syncSheetBlock()
end)

-- Standard scrolling list inside a modal body (thick bar and an elastic edge for thumbs, B7).
function Modal.scroller(parent: Instance, horizontal: boolean?): ScrollingFrame
	local sf = Create("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = if horizontal then Enum.AutomaticSize.X else Enum.AutomaticSize.Y,
		ScrollingDirection = if horizontal then Enum.ScrollingDirection.X else Enum.ScrollingDirection.Y,
		ScrollBarThickness = if Device.isTouch() then 10 else 6,
		ScrollBarImageColor3 = Theme.colors.panelStroke,
		ElasticBehavior = Enum.ElasticBehavior.Always,
		ZIndex = 11,
		Parent = parent,
	})
	return sf
end

return Modal
