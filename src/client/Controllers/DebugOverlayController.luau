--!strict
-- Studio-only overlay: shows the last server warnings/errors (ReplicatedStorage.HaretLog, mirrored
-- by DebugService) and the client's own errors in the top-left corner, so a play-test screenshot
-- carries the log. Never created outside Studio.

local LogService = game:GetService("LogService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local UI = script.Parent.Parent.UI
local Theme = require(UI.Theme)
local Root = require(UI.Root)

local DebugOverlayController = {}

local MAX_LINES = 10
local NEWLINE = string.char(10)

function DebugOverlayController.start()
	if not RunService:IsStudio() then
		return
	end
	local label = Theme.label({
		Name = "DebugLog",
		TextSize = 11,
		TextColor3 = Color3.fromRGB(255, 230, 120),
		TextStrokeTransparency = 0.2,
		TextStrokeColor3 = Color3.new(0, 0, 0),
		Position = UDim2.fromOffset(8, 150),
		Size = UDim2.new(0.55, 0, 0, 160),
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 50,
		Parent = Root.get(),
	})
	label.TextXAlignment = Enum.TextXAlignment.Left
	local clientLines: { string } = {}
	local serverLines: { string } = {}
	local function render()
		local lines = {}
		for _, l in clientLines do
			table.insert(lines, "[C] " .. l)
		end
		for _, l in serverLines do
			table.insert(lines, "[S] " .. l)
		end
		label.Text = table.concat(lines, NEWLINE)
	end
	LogService.MessageOut:Connect(function(message: string, messageType: Enum.MessageType)
		local text: string = tostring(message)
		local isOurs = not string.find(text, "UIBlox", 1, true) and not string.find(text, "CoreScript", 1, true)
		if isOurs and (messageType == Enum.MessageType.MessageError or messageType == Enum.MessageType.MessageWarning) then
			table.insert(clientLines, string.sub(text, 1, 160))
			if #clientLines > MAX_LINES then
				table.remove(clientLines, 1)
			end
			render()
		end
	end)
	task.spawn(function()
		local v = ReplicatedStorage:WaitForChild("HaretLog", 30)
		if v and v:IsA("StringValue") then
			local function update()
				local all = string.split(v.Value, NEWLINE)
				serverLines = {}
				for i = math.max(1, #all - MAX_LINES + 1), #all do
					table.insert(serverLines, string.sub(all[i], 1, 160))
				end
				render()
			end
			update()
			v:GetPropertyChangedSignal("Value"):Connect(update)
		end
	end)
end

return DebugOverlayController
