--!strict
-- Auto Play and layout codes on the client (BUILD_PLAN P3-06). The match menu's fourth row: Auto Play on/off
-- (the server's Logic/AutoPlay builds and upgrades your loadout near where you stand, never firing an
-- ability) and Layout, a sheet with your current towers as a code to copy and a box to paste one. The code
-- is built here from your own towers (Logic/LayoutCode); an imported one is checked and played by the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local LayoutCode = require(Shared.Logic.LayoutCode)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Modal = require(UI.Modal)
local LocaleController = require(script.Parent.LocaleController)
local StateController = require(script.Parent.StateController)
local MatchController = require(script.Parent.MatchController)
local MatchMenuController = require(script.Parent.MatchMenuController)
local PlacementController = require(script.Parent.PlacementController)

local LayoutController = {}

local modal: Modal.Modal
local hint: TextLabel
local box: TextBox
local import: TextButton

local function autoOn(): boolean
	local s = MatchController.state()
	return s ~= nil and s.auto == true
end

-- Your towers in this match as a code: each one's loadout slot and arena-local spot, oldest first.
function LayoutController.exportCode(): string?
	local info = MatchController.info()
	local snapshot: any = StateController.get()
	if not info or not snapshot or not snapshot.loadout then
		return nil
	end
	local mine = {}
	for _, tw in PlacementController.list() do
		if tw.mine then
			table.insert(mine, tw)
		end
	end
	table.sort(mine, function(a, b)
		return a.id < b.id
	end)
	local entries = {}
	for _, tw in mine do
		local slot = table.find(snapshot.loadout, tw.unitId)
		if slot then
			table.insert(entries, { slot = slot, x = tw.x, z = tw.z })
		end
	end
	return LayoutCode.encode(info.arenaId, entries)
end

local function render()
	if not modal then
		return
	end
	local t = LocaleController.t
	modal.title.Text = t("layout.title")
	Theme.align(modal.title, LocaleController.isRtl())
	hint.Text = t("layout.hint")
	import.Text = t("layout.import")
	box.PlaceholderText = t("layout.paste")
end

local function build()
	modal = Modal.create("Layout", 460, 150)
	local body = modal.body
	hint = Theme.label({ TextSize = 13, TextWrapped = true, TextColor3 = Theme.colors.textMuted, Size = UDim2.new(1, 0, 0, 36), ZIndex = 11, Parent = body })
	box = Create("TextBox", {
		Name = "Code",
		Position = UDim2.fromOffset(0, 44),
		Size = UDim2.new(1, -130, 0, Theme.TOUCH),
		BackgroundColor3 = Color3.fromHex("#FBF8F1"),
		TextColor3 = Theme.colors.text,
		TextSize = 14,
		TextTruncate = Enum.TextTruncate.AtEnd,
		FontFace = Theme.fontBold,
		ClearTextOnFocus = false,
		Text = "",
		ZIndex = 11,
		Parent = body,
	}, { Create("UICorner", { CornerRadius = UDim.new(0, 10) }), Create("UIStroke", { Color = Theme.colors.panelStroke, Thickness = 2 }) })
	import = Theme.button({ Name = "Import", TextSize = 15, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 44), Size = UDim2.fromOffset(120, Theme.TOUCH), BackgroundColor3 = Theme.colors.quest, ZIndex = 11, Parent = body })
	import.Activated:Connect(function()
		local code = string.gsub(box.Text, "%s", "")
		if code ~= "" and #code <= LayoutCode.MAX_LEN then
			Net.event(Net.Events.ImportLayout):FireServer(code)
			modal.setVisible(false)
		end
	end)
	modal.onClose = function()
		box:ReleaseFocus()
	end
end

function LayoutController.open()
	MatchMenuController.close()
	render()
	box.Text = LayoutController.exportCode() or ""
	modal.setVisible(true)
end

function LayoutController.toggleAuto()
	Net.event(Net.Events.SetAutoPlay):FireServer(not autoOn())
end

function LayoutController.start()
	build()
	LocaleController.Changed:Connect(render)
	MatchMenuController.setAutoPlay({
		isOn = autoOn,
		toggle = LayoutController.toggleAuto,
		openLayout = LayoutController.open,
	})
	-- The menu's Auto Play label follows the server's state.
	Net.event(Net.Events.MatchState).OnClientEvent:Connect(function()
		task.defer(MatchMenuController.refresh)
	end)
end

return LayoutController
