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
local Icons = require(UI.Icons)
local Button = require(UI.Button)
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

-- What a toast reports (Theme v2, LP-C03): a refusal (red mark), a gain (a lira coin) or news.
local function kindOf(key: string): "deny" | "gain" | "info"
	if string.find(key, "err") or string.find(key, "locked") or string.find(key, "needs") then
		return "deny"
	end
	if string.find(key, "%.ok$") or string.find(key, "claim") or string.find(key, "unlocked") or string.find(key, "reward") then
		return "gain"
	end
	return "info"
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
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = toast })
	local kind = kindOf(key)
	if kind ~= "info" then
		local mark = Create("Frame", { Name = "Kind", LayoutOrder = 0, Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 1, Parent = toast })
		if kind == "gain" then
			Icons.draw("lira", mark)
		else
			mark.BackgroundColor3 = Theme.v2.diwanRed
			mark.BackgroundTransparency = 0
			Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = mark })
			local bang = Theme.display({ Text = "!", TextSize = 16, Size = UDim2.fromScale(1, 1), Parent = mark })
			bang.TextXAlignment = Enum.TextXAlignment.Center
		end
	end
	-- A tap or a sideways swipe dismisses it.
	local function dismiss()
		if holder.Parent then
			holder:Destroy()
		end
	end
	local hit = Button.hit({ Name = "Dismiss", Size = UDim2.fromScale(1, 1), ZIndex = toast.ZIndex + 5, Parent = holder })
	hit.Activated:Connect(dismiss)
	local swipeX: number? = nil
	hit.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.Touch then
			swipeX = input.Position.X
		end
	end)
	hit.InputEnded:Connect(function(input: InputObject)
		local x0 = swipeX
		if x0 and input.UserInputType == Enum.UserInputType.Touch and math.abs(input.Position.X - x0) > 30 then
			dismiss()
		end
		swipeX = nil
	end)
	local label = Theme.label({
		LayoutOrder = 1,
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
