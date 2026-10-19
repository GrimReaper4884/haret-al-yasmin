--!strict
-- Small UI motion helpers ("juice"), timings from docs/research/ROBLOX_TD_UI_PATTERNS.md:
-- press 0.06 s down / 0.18 s Back up, pop-in 0.25 s Back Out, count-up ~0.5 s, shake ±8 px.
-- Everything respects the player's Reduced Motion setting.

local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Fx = require(script.Parent.Fx)
local Motion = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").Logic.Motion)
local UserInputService = game:GetService("UserInputService")

local Juice = {}

local function reduced(): boolean
	local ok, v = pcall(function()
		return (GuiService :: any).ReducedMotionEnabled
	end)
	return ok and v == true
end

-- May this kind of motion play now? (Logic/Motion: Reduced Motion, the Effects setting, mouse.)
function Juice.allowed(kind: Motion.Kind): boolean
	return Motion.allowed(kind, Fx.level(), reduced(), UserInputService.MouseEnabled)
end

-- The UIScale every helper animates (created on demand, one per object).
function Juice.scaleOf(gui: GuiObject): UIScale
	local s = gui:FindFirstChild("JuiceScale")
	if s and s:IsA("UIScale") then
		return s
	end
	local n = Instance.new("UIScale")
	n.Name = "JuiceScale"
	n.Parent = gui
	return n
end

-- Press feedback for a button: squash on press, springy release, slight grow on hover.
function Juice.press(button: GuiButton)
	local scale = Juice.scaleOf(button)
	local hovering = false
	local function to(v: number, t: number, style: Enum.EasingStyle)
		if not Juice.allowed("press") then
			scale.Scale = 1
			return
		end
		TweenService:Create(scale, TweenInfo.new(t, style, Enum.EasingDirection.Out), { Scale = v }):Play()
	end
	button.InputBegan:Connect(function(input: InputObject)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
			to(0.92, 0.06, Enum.EasingStyle.Quad)
		elseif kind == Enum.UserInputType.MouseMovement then
			hovering = true
			to(1.04, 0.12, Enum.EasingStyle.Quad)
		end
	end)
	button.InputEnded:Connect(function(input: InputObject)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
			to(if hovering then 1.04 else 1, 0.18, Enum.EasingStyle.Back)
		elseif kind == Enum.UserInputType.MouseMovement then
			hovering = false
			to(1, 0.15, Enum.EasingStyle.Quad)
		end
	end)
end

-- Pops a panel in (0.8 → 1, Back Out).
function Juice.pop(gui: GuiObject, from: number?)
	local scale = Juice.scaleOf(gui)
	if reduced() then
		scale.Scale = 1
		return
	end
	scale.Scale = from or 0.8
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

-- A quick punch (1 → 1.15 → 1) to draw the eye to a changed number.
function Juice.punch(gui: GuiObject, amount: number?)
	if reduced() then
		return
	end
	local scale = Juice.scaleOf(gui)
	scale.Scale = 1 + (amount or 0.15)
	TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

-- Horizontal shake (errors, can't afford).
function Juice.shake(gui: GuiObject)
	if reduced() then
		return
	end
	local base = gui.Position
	task.spawn(function()
		for _, dx in { 8, -8, 6, -6, 3, 0 } do
			gui.Position = base + UDim2.fromOffset(dx, 0)
			task.wait(0.04)
		end
		gui.Position = base
	end)
end

-- Counts a label up/down from `from` to `to` over ~0.45 s using `format(n)` for the text.
local counting: { [TextLabel]: number } = {}
function Juice.count(label: TextLabel, from: number, to: number, format: (number) -> string)
	if reduced() or from == to then
		label.Text = format(to)
		return
	end
	local token = (counting[label] or 0) + 1
	counting[label] = token
	local start = os.clock()
	local dur = 0.45
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		if counting[label] ~= token or not label.Parent then
			conn:Disconnect()
			return
		end
		local k = math.min(1, (os.clock() - start) / dur)
		local e = 1 - (1 - k) ^ 3
		label.Text = format(math.floor(from + (to - from) * e + 0.5))
		if k >= 1 then
			conn:Disconnect()
		end
	end)
end

-- A narrow white band sweeping across `frame` every few seconds (Legendary+ cards, premium
-- buttons). Animates only the gradient Offset, the cheap path.
function Juice.shine(frame: GuiObject, period: number?)
	local holder = Instance.new("Frame")
	holder.Name = "Shine"
	holder.BackgroundColor3 = Color3.new(1, 1, 1)
	holder.BackgroundTransparency = 0
	holder.BorderSizePixel = 0
	holder.Size = UDim2.fromScale(1, 1)
	holder.ZIndex = frame.ZIndex + 1
	holder.Active = false
	holder.Parent = frame
	local corner = frame:FindFirstChildOfClass("UICorner")
	if corner then
		corner:Clone().Parent = holder
	end
	local g = Instance.new("UIGradient")
	g.Rotation = 20
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.42, 1),
		NumberSequenceKeypoint.new(0.5, 0.55),
		NumberSequenceKeypoint.new(0.58, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	g.Offset = Vector2.new(-1, 0)
	g.Parent = holder
	if reduced() or not Fx.full() then
		holder.Visible = false
		return
	end
	task.spawn(function()
		while holder.Parent and Fx.full() do
			g.Offset = Vector2.new(-1, 0)
			local tw = TweenService:Create(g, TweenInfo.new(0.8, Enum.EasingStyle.Linear), { Offset = Vector2.new(1, 0) })
			tw:Play()
			tw.Completed:Wait()
			task.wait(period or 2.2)
		end
	end)
end

-- Theme v2 (LP-C01) ----------------------------------------------------------------------------

-- A primary button's slow breath (scale 1 → 1 + amount → 1 every `period` s) until `stop()` or the
-- object leaves the game. Decorative: off under Reduced Motion and with Effects below full.
function Juice.breathe(gui: GuiObject, amount: number?, period: number?): () -> ()
	local running = true
	if not Juice.allowed("breathe") then
		return function() end
	end
	local scale = Juice.scaleOf(gui)
	local half = (period or 2.4) / 2
	task.spawn(function()
		while running and gui.Parent do
			local up = TweenService:Create(scale, TweenInfo.new(half, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Scale = 1 + (amount or 0.03) })
			up:Play()
			up.Completed:Wait()
			if not running then
				break
			end
			local down = TweenService:Create(scale, TweenInfo.new(half, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Scale = 1 })
			down:Play()
			down.Completed:Wait()
		end
		scale.Scale = 1
	end)
	return function()
		running = false
	end
end

-- Lists arrive one after another: each item pops `gap` s after the previous, at most `cap` items
-- animated (the rest appear at once). Follows `pop` (none under Reduced Motion).
function Juice.stagger(items: { GuiObject }, gap: number?, cap: number?)
	local animate = Juice.allowed("stagger")
	for i, item in items do
		local scale = Juice.scaleOf(item)
		if not animate or i > (cap or 12) then
			scale.Scale = 1
		else
			scale.Scale = 0.6
			task.delay((i - 1) * (gap or 0.03), function()
				TweenService:Create(scale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
			end)
		end
	end
end

-- The notification dot on a control's top-right corner (a claimable Daily, a ready Diary tier):
-- shown while `on`, removed otherwise. Static (it is information, not motion).
function Juice.dot(parent: GuiObject, on: boolean, color: Color3?): Frame?
	local dot = parent:FindFirstChild("Dot")
	if not on then
		if dot then
			dot:Destroy()
		end
		return nil
	end
	if dot and dot:IsA("Frame") then
		return dot
	end
	local f = Instance.new("Frame")
	f.Name = "Dot"
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.new(1, -4, 0, 4)
	f.Size = UDim2.fromOffset(14, 14)
	f.BackgroundColor3 = color or Color3.fromHex("#D9483B")
	f.BorderSizePixel = 0
	f.ZIndex = parent.ZIndex + 3
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = f
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Thickness = 2
	stroke.Parent = f
	f.Parent = parent
	return f
end

-- A currency pill's glow when it gains (Theme v2, LP-C02): its edge flashes gold and fades back.
function Juice.glow(gui: GuiObject)
	local stroke = gui:FindFirstChild("Border")
	if not (stroke and stroke:IsA("UIStroke")) then
		return
	end
	local color = stroke:GetAttribute("BaseColor")
	if typeof(color) ~= "Color3" then
		color = stroke.Color
		stroke:SetAttribute("BaseColor", color)
	end
	stroke.Color = Color3.fromHex("#F2C14E")
	if reduced() then
		task.delay(0.4, function()
			stroke.Color = color :: Color3
		end)
		return
	end
	TweenService:Create(stroke, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Color = color :: Color3 }):Play()
end

-- PV-B07 ------------------------------------------------------------------------------------

-- Desktop hover tilt for a card: a slight turn and lift while the mouse is over `hit`.
function Juice.tilt(card: GuiObject, hit: GuiObject)
	local base = card.Rotation
	hit.MouseEnter:Connect(function()
		if Juice.allowed("tilt") then
			TweenService:Create(card, TweenInfo.new(0.15, Enum.EasingStyle.Quad), { Rotation = base - 3 }):Play()
			TweenService:Create(Juice.scaleOf(card), TweenInfo.new(0.15, Enum.EasingStyle.Quad), { Scale = 1.04 }):Play()
		end
	end)
	hit.MouseLeave:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { Rotation = base }):Play()
		TweenService:Create(Juice.scaleOf(card), TweenInfo.new(0.2, Enum.EasingStyle.Quad), { Scale = 1 }):Play()
	end)
end

-- A card flips face up: a card back covering it narrows to nothing, then the face punches in.
function Juice.flip(card: GuiObject, backColor: Color3?, seconds: number?)
	if not Juice.allowed("flip") then
		return
	end
	local t = seconds or 0.22
	local back = Instance.new("Frame")
	back.Name = "FlipBack"
	back.AnchorPoint = Vector2.new(0.5, 0.5)
	back.Position = UDim2.fromScale(0.5, 0.5)
	back.Size = UDim2.fromScale(1.02, 1.02)
	back.BackgroundColor3 = backColor or Color3.fromHex("#4A2E18")
	back.BorderSizePixel = 0
	back.ZIndex = card.ZIndex + 10
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = back
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromHex("#F2C14E")
	stroke.Thickness = 2
	stroke.Parent = back
	back.Parent = card
	local tw = TweenService:Create(back, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Size = UDim2.fromScale(0, 1.02) })
	tw:Play()
	tw.Completed:Once(function()
		back:Destroy()
		Juice.punch(card, 0.08)
	end)
end

-- A gentle wobble that repeats while `active()` holds (a claimable daily chest).
function Juice.wobble(gui: GuiObject, active: () -> boolean)
	task.spawn(function()
		local base = gui.Rotation
		while gui.Parent do
			if active() and Juice.allowed("wobble") then
				for _, r in { 8, -7, 5, -3, 0 } do
					TweenService:Create(gui, TweenInfo.new(0.07), { Rotation = base + r }):Play()
					task.wait(0.07)
				end
				gui.Rotation = base
				task.wait(1.6)
			else
				task.wait(0.5)
			end
		end
	end)
end

-- One shine sweep across `frame` (a bar that just grew).
function Juice.shineOnce(frame: GuiObject)
	if not Juice.allowed("shine") then
		return
	end
	local holder = Instance.new("Frame")
	holder.Name = "ShineOnce"
	holder.BackgroundColor3 = Color3.new(1, 1, 1)
	holder.BorderSizePixel = 0
	holder.Size = UDim2.fromScale(1, 1)
	holder.ZIndex = frame.ZIndex + 1
	holder.Active = false
	local corner = frame:FindFirstChildOfClass("UICorner")
	if corner then
		corner:Clone().Parent = holder
	end
	local g = Instance.new("UIGradient")
	g.Rotation = 20
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.4, 1),
		NumberSequenceKeypoint.new(0.5, 0.35),
		NumberSequenceKeypoint.new(0.6, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	g.Offset = Vector2.new(-1, 0)
	g.Parent = holder
	holder.Parent = frame
	local tw = TweenService:Create(g, TweenInfo.new(0.7, Enum.EasingStyle.Sine), { Offset = Vector2.new(1, 0) })
	tw:Play()
	tw.Completed:Once(function()
		holder:Destroy()
	end)
end

-- Slides `inner` in from `dy` px above its place while fading it in (toasts).
function Juice.slideIn(inner: GuiObject, dy: number)
	if not Juice.allowed("slide") then
		return
	end
	local final = inner.Position
	inner.Position = final - UDim2.fromOffset(0, dy)
	TweenService:Create(inner, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = final }):Play()
end

return Juice
