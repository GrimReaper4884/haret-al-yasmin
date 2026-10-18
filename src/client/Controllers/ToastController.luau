--!strict
-- Short notifications from the server. Args ending in "Key" are string keys and get localized
-- (e.g. { itemKey = "item.x.name" } fills the {item} placeholder).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Juice = require(UI.Juice)
local Root = require(UI.Root)
local Device = require(UI.Device)
local Hud = require(Shared.Config.Hud)
local LocaleController = require(script.Parent.LocaleController)

local ToastController = {}

local LIFETIME = 3

local stack: Frame
local order = 0
local top = Hud.TOAST.lobbyTop

-- How many toasts fit between the stack's top and the bottom band (always at least one).
local function maxVisible(): number
	local T = Hud.TOAST
	local room = Device.designSize().y - T.keepBottom - top + (T.step - 40)
	return math.clamp(math.floor(room / T.step), 1, T.max)
end

-- The match HUD moves the stack under its wave / gate block (MatchController); nil = lobby.
function ToastController.setTop(y: number?)
	top = y or Hud.TOAST.lobbyTop
	if stack then
		stack.Position = UDim2.new(0.5, 0, 0, top)
	end
end

local function resolveArgs(args: { [string]: any }?): { [string]: any }?
	if not args then
		return nil
	end
	local out = {}
	for k, v in args do
		local base = string.match(k, "^(.-)Key$")
		if base and type(v) == "string" then
			out[base] = LocaleController.t(v)
		else
			out[k] = v
		end
	end
	return out
end

function ToastController.show(key: string, args: { [string]: any }?)
	order += 1
	-- The list layout places the holder; the panel inside it slides down into place (PV-B07).
	local holder = Create("Frame", {
		LayoutOrder = order,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(0, 40),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = stack,
	})
	local toast = Theme.panel({
		Size = UDim2.fromOffset(0, 40),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = holder,
	})
	Juice.slideIn(toast, 18)
	Create("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), Parent = toast })
	local label = Theme.label({
		Text = LocaleController.t(key, resolveArgs(args)),
		TextSize = 16,
		FontFace = Theme.fontBold,
		TextWrapped = false,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromScale(0, 1),
		Parent = toast,
	})

	local frames = {}
	for _, c in stack:GetChildren() do
		if c:IsA("Frame") then
			table.insert(frames, c)
		end
	end
	local cap = maxVisible()
	if #frames > cap then
		table.sort(frames, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		for i = 1, #frames - cap do
			frames[i]:Destroy()
		end
	end

	task.delay(LIFETIME, function()
		if holder.Parent then
			local tween = TweenService:Create(label, TweenInfo.new(0.3), { TextTransparency = 1 })
			TweenService:Create(toast, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
			tween:Play()
			tween.Completed:Wait()
			holder:Destroy()
		end
	end)
end

function ToastController.start()
	stack = Create("Frame", {
		Name = "Toasts",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, top),
		Size = UDim2.fromScale(0.6, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		-- Above every screen (modals and the store are 10, the summon flash 30), so a toast fired as
		-- a screen opens (e.g. "Not enough lira" opening the store) is never hidden; the Studio log
		-- overlay stays on top at 50.
		ZIndex = 40,
		Parent = Root.get(),
	})
	Create("UIListLayout", {
		Padding = UDim.new(0, 6),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = stack,
	})
	Net.event(Net.Events.Notify).OnClientEvent:Connect(function(payload: { key: string, args: { [string]: any }? })
		if type(payload) == "table" and type(payload.key) == "string" then
			ToastController.show(payload.key, payload.args)
		end
	end)
end

return ToastController
