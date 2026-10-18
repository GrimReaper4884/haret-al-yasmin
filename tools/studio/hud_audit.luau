--!nocheck
-- HUD touch audit (docs/MOBILE_HUD_PLAN.md MH-00 / MH-03). Paste the whole file into `execute_luau`
-- with datamodel_type "Client" during a Play session; it returns a report string. Never make it a
-- script instance (CLAUDE.md: no scripts through MCP).
--
-- It walks PlayerGui.HaretHud and reports every *effectively visible* GuiButton (it and every
-- ancestor Visible, on screen, not clipped out by a ScrollingFrame) that is
--   * under MIN px on either axis (AbsoluteSize, i.e. after the UIScale), unless the button carries a
--     transparent hit pad (`TouchPad`, MH-03) that is at least MIN on both axes, and
--   * intersecting the bottom-left LEFT or bottom-right RIGHT corner of the safe area (the Roblox
--     thumbstick and jump zones), while those touch controls would be shown.
-- Corners default to MOBILE_HUD_PLAN B1's numbers; when PlayerGui.TouchGui.TouchControlFrame exists
-- the measured thumbstick / jump frames are reported too.
-- Pass condition from MH-03 on: "undersized 0" on the phone presets for every screen an MH task has
-- moved to the touch layout (screens still marked TouchLegacy are MH-13's), and from MH-18 "corner
-- collisions 0" while the touch controls show.

local MIN = 48
local LEFT = { 160, 160 }
local RIGHT = { 140, 140 }

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
local screen = pg and pg:FindFirstChild("HaretHud")
if not screen then
	return "no PlayerGui.HaretHud"
end

local origin = screen.AbsolutePosition
local size = screen.AbsoluteSize
local leftRect = { x0 = 0, y0 = size.Y - LEFT[2], x1 = LEFT[1], y1 = size.Y }
local rightRect = { x0 = size.X - RIGHT[1], y0 = size.Y - RIGHT[2], x1 = size.X, y1 = size.Y }

local function overlaps(a, b)
	return a.x0 < b.x1 and b.x0 < a.x1 and a.y0 < b.y1 and b.y0 < a.y1
end

local function rectOf(gui)
	local p = gui.AbsolutePosition - origin
	local s = gui.AbsoluteSize
	return { x0 = p.X, y0 = p.Y, x1 = p.X + s.X, y1 = p.Y + s.Y }
end

-- Visible all the way up, and inside every clipping ScrollingFrame / ClipsDescendants ancestor.
local function effectivelyVisible(gui)
	local r = rectOf(gui)
	local node = gui
	while node and node ~= screen do
		if node:IsA("GuiObject") then
			if not node.Visible then
				return false
			end
			if node ~= gui and (node:IsA("ScrollingFrame") or node.ClipsDescendants) then
				if not overlaps(r, rectOf(node)) then
					return false
				end
			end
		end
		node = node.Parent
	end
	if not screen.Enabled then
		return false
	end
	return overlaps(r, { x0 = 0, y0 = 0, x1 = size.X, y1 = size.Y })
end

local function path(gui)
	local parts = {}
	local node = gui
	while node and node ~= screen do
		table.insert(parts, 1, node.Name)
		node = node.Parent
	end
	return table.concat(parts, ".")
end

local function padOk(button)
	local pad = button:FindFirstChild("TouchPad")
	return pad ~= nil and pad:IsA("GuiObject") and pad.AbsoluteSize.X >= MIN and pad.AbsoluteSize.Y >= MIN
end

local small, corner = {}, {}
local total = 0
for _, d in screen:GetDescendants() do
	if d:IsA("GuiButton") and d.Name ~= "TouchPad" and effectivelyVisible(d) then
		total += 1
		local s = d.AbsoluteSize
		if (s.X < MIN - 0.5 or s.Y < MIN - 0.5) and not padOk(d) then
			table.insert(small, string.format("%s %dx%d", path(d), math.floor(s.X + 0.5), math.floor(s.Y + 0.5)))
		end
		local r = rectOf(d)
		if overlaps(r, leftRect) or overlaps(r, rightRect) then
			table.insert(corner, string.format("%s [%d,%d..%d,%d]%s", path(d), r.x0, r.y0, r.x1, r.y1, if overlaps(r, leftRect) then " L" else " R"))
		end
	end
end
table.sort(small)
table.sort(corner)

local scale = screen:FindFirstChildOfClass("UIScale")
local measured = {}
local touchGui = pg:FindFirstChild("TouchGui")
local frame = touchGui and touchGui:FindFirstChild("TouchControlFrame")
if frame then
	for _, c in frame:GetChildren() do
		if c:IsA("GuiObject") and c.Visible then
			local r = rectOf(c)
			table.insert(measured, string.format("%s [%d,%d..%d,%d]", c.Name, r.x0, r.y0, r.x1, r.y1))
		end
	end
end

local lines = {
	string.format(
		"HUD audit · safe area %dx%d · viewport %s · UIScale %.3f · PreferredInput %s · TouchControls %s · TopbarInset %s",
		size.X,
		size.Y,
		tostring(workspace.CurrentCamera.ViewportSize),
		scale and scale.Scale or 1,
		tostring(UserInputService.PreferredInput),
		tostring(GuiService.TouchControlsEnabled),
		tostring(GuiService.TopbarInset)
	),
	string.format("visible buttons %d · undersized (<%d px) %d · corner collisions %d", total, MIN, #small, #corner),
}
if #measured > 0 then
	table.insert(lines, "TouchControlFrame: " .. table.concat(measured, "; "))
end
for _, s in small do
	table.insert(lines, "  SMALL  " .. s)
end
for _, c in corner do
	table.insert(lines, "  CORNER " .. c)
end
return table.concat(lines, "\n")
