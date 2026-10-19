--!strict
-- The single ScreenGui all controllers draw into. Layouts are authored in offsets for a landscape
-- phone's safe area at UIScale 1; UI/Device sets the one UIScale from the layout profile, the safe-area
-- size and the player's uiScale preset (Logic/HudLayout.scale).

local Players = game:GetService("Players")

local Create = require(script.Parent.Create)

local Root = {}

local gui: ScreenGui? = nil

function Root.get(): ScreenGui
	if gui then
		return gui
	end
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local screen = Create("ScreenGui", {
		Name = "HaretHud",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		Parent = playerGui,
	})
	Create("UIScale", { Parent = screen })
	gui = screen
	return screen
end

-- The ScreenGui sits inside the safe area and is clipped to it, so a full-screen dimmer leaves the
-- strip under Roblox's top bar (and a phone's notch side) bright. Root.bleed mirrors `frame` (its
-- colour, transparency and visibility, tweens included) onto four strips around the safe area in a
-- second, inset-free ScreenGui that holds nothing else.
local edge: ScreenGui? = nil

local function edgeGui(): ScreenGui
	if edge then
		return edge
	end
	local made = Create("ScreenGui", {
		Name = "HaretEdge",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ScreenInsets = Enum.ScreenInsets.None,
		ClipToDeviceSafeArea = false,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	})
	edge = made
	return made
end

function Root.bleed(frame: GuiObject)
	local outer = edgeGui()
	local strips: { Frame } = {}
	for i = 1, 4 do
		strips[i] = Create("Frame", { Name = frame.Name .. "Edge", BorderSizePixel = 0, Visible = false, Parent = outer })
	end
	local function layout()
		local inner = Root.get()
		local o, w, h = outer.AbsolutePosition, outer.AbsoluteSize.X, outer.AbsoluteSize.Y
		local x0, y0 = inner.AbsolutePosition.X - o.X, inner.AbsolutePosition.Y - o.Y
		local x1, y1 = x0 + inner.AbsoluteSize.X, y0 + inner.AbsoluteSize.Y
		local rects = { { 0, 0, w, y0 }, { 0, y1, w, h - y1 }, { 0, y0, x0, y1 - y0 }, { x1, y0, w - x1, y1 - y0 } }
		for i, r in rects do
			strips[i].Position = UDim2.fromOffset(r[1], r[2])
			strips[i].Size = UDim2.fromOffset(math.max(0, r[3]), math.max(0, r[4]))
		end
	end
	local function mirror()
		for _, st in strips do
			st.BackgroundColor3 = frame.BackgroundColor3
			st.BackgroundTransparency = frame.BackgroundTransparency
			st.Visible = frame.Visible
		end
	end
	for _, prop in { "Visible", "BackgroundTransparency", "BackgroundColor3" } do
		frame:GetPropertyChangedSignal(prop):Connect(mirror)
	end
	outer:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	Root.get():GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	Root.get():GetPropertyChangedSignal("AbsolutePosition"):Connect(layout)
	layout()
	mirror()
end

return Root
