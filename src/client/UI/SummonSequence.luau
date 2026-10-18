--!strict
-- The summon build-up, drawn from UI primitives (no uploaded images): a brass lantern drops in on
-- its chain and swings, glows in the colour of the best rarity in the pull (a Legendary or better
-- first glows blue, then shakes and turns: the "rarity tell"), and bursts open with a flash and
-- rays. Calls onBurst when the cards should appear. Tapping anywhere skips straight to the burst.
-- docs/research/ANIME_VANGUARDS_STUDY.md §3.

local TweenService = game:GetService("TweenService")

local Create = require(script.Parent.Create)
local Theme = require(script.Parent.Theme)
local Fx = require(script.Parent.Fx)
local Juice = require(script.Parent.Juice)

local SummonSequence = {}

local BRASS = Color3.fromHex("#B8862E")
local BRASS_DARK = Color3.fromHex("#6E4A16")

local RANK = { rare = 1, epic = 2, legendary = 3, mythic = 4, secret = 5 }

function SummonSequence.rank(rarity: string): number
	return RANK[rarity] or 1
end

local function tween(obj: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?): Tween
	local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function box(parent: Instance, color: Color3, x: number, y: number, w: number, h: number, radius: number, z: number): Frame
	return Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(x, y),
		Size = UDim2.fromScale(w, h),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		ZIndex = z,
		Parent = parent,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(radius, 0) }),
		Create("UIStroke", { Color = Theme.colors.outline, Thickness = 2.5 }),
	})
end

-- The lantern: cap, chain ring, body with glowing panes, base. Returns (holder, glowPanes).
local function lantern(parent: Instance, z: number): (Frame, { Frame })
	local holder = Create("Frame", {
		Name = "Lantern",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, -260),
		Size = UDim2.fromOffset(150, 230),
		BackgroundTransparency = 1,
		ZIndex = z,
		Parent = parent,
	})
	-- chain from above the screen
	Create("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.08), Size = UDim2.fromOffset(4, 400), BackgroundColor3 = BRASS_DARK, BorderSizePixel = 0, ZIndex = z, Parent = holder })
	box(holder, BRASS, 0.5, 0.06, 0.18, 0.08, 1, z + 1) -- ring
	box(holder, BRASS, 0.5, 0.17, 0.6, 0.1, 0.4, z + 1) -- cap
	box(holder, BRASS_DARK, 0.5, 0.12, 0.3, 0.06, 0.5, z + 2) -- finial
	local body = box(holder, BRASS, 0.5, 0.55, 0.72, 0.62, 0.18, z + 1)
	local panes = {}
	for i, x in { 0.27, 0.5, 0.73 } do
		local pane = box(body, Color3.fromHex("#FFF2B8"), x, 0.5, 0.2, 0.78, 0.4, z + 2)
		pane.Name = "Pane" .. i
		table.insert(panes, pane)
	end
	box(holder, BRASS, 0.5, 0.9, 0.5, 0.08, 0.4, z + 1) -- base
	box(holder, BRASS_DARK, 0.5, 0.96, 0.22, 0.05, 1, z + 1) -- drop
	return holder, panes
end

-- A soft radial glow (a round frame whose transparency fades outward).
local function glow(parent: Instance, z: number): Frame
	local g = Create("Frame", {
		Name = "Glow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromOffset(10, 10),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		ZIndex = z,
		Parent = parent,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	Create("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(0.5, 0.6),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = g,
	})
	return g
end

-- Rays spinning out from the burst point.
local function rays(parent: Instance, color: Color3, z: number): Frame
	local holder = Create("Frame", {
		Name = "Rays",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromOffset(40, 40),
		BackgroundTransparency = 1,
		ZIndex = z,
		Parent = parent,
	})
	for k = 0, 7 do
		local ray = Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.12, 6),
			Rotation = k * 22.5,
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			ZIndex = z,
			Parent = holder,
		})
		Create("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0.2),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Parent = ray,
		})
	end
	return holder
end

-- Small sparks flying outward (Legendary and better).
local function sparks(parent: Instance, color: Color3, z: number)
	for _ = 1, 18 do
		local a = math.random() * math.pi * 2
		local d = 180 + math.random() * 220
		local s = Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.42),
			Size = UDim2.fromOffset(10, 10),
			Rotation = 45,
			BackgroundColor3 = if math.random() < 0.5 then color else Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			ZIndex = z,
			Parent = parent,
		})
		local t = 0.6 + math.random() * 0.5
		tween(s, t, { Position = UDim2.new(0.5, math.cos(a) * d, 0.42, math.sin(a) * d), BackgroundTransparency = 1, Size = UDim2.fromOffset(4, 4) })
		task.delay(t, function()
			s:Destroy()
		end)
	end
end

-- Jasmine petals bursting from the lantern (Legendary and better, PV-B07). UI frames, freed after.
local function petals(parent: Instance, z: number)
	for i = 1, 14 do
		local a = (i / 14) * math.pi * 2 + math.random() * 0.4
		local d = 140 + math.random() * 160
		local p = Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.42),
			Size = UDim2.fromOffset(14, 9),
			Rotation = math.deg(a),
			BackgroundColor3 = if i % 3 == 0 then Color3.fromHex("#F6D4DC") else Color3.fromHex("#FFF6EA"),
			BorderSizePixel = 0,
			ZIndex = z,
			Parent = parent,
		}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		local t = 0.9 + math.random() * 0.6
		tween(p, t, { Position = UDim2.new(0.5, math.cos(a) * d, 0.42, math.sin(a) * d + 60), Rotation = math.deg(a) + 160, BackgroundTransparency = 1 }, Enum.EasingStyle.Sine)
		task.delay(t, function()
			p:Destroy()
		end)
	end
end

export type Handle = { skip: () -> () }

-- Plays the build-up inside `parent` (a full-screen frame). `best` is the best rarity rolled.
function SummonSequence.play(parent: GuiObject, best: string, onBurst: () -> (), sting: (string) -> ()): Handle
	local z = 22
	local color = Theme.rarityColor(best)
	local high = SummonSequence.rank(best) >= 3
	local stage = Create("Frame", { Name = "Sequence", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = z, Parent = parent })
	local skip = Create("TextButton", { Name = "Skip", Text = "", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = z + 20, Parent = stage })
	local light = glow(stage, z)
	local body, panes = lantern(stage, z + 2)
	local done = false

	local function burst()
		if done then
			return
		end
		done = true
		skip:Destroy()
		sting(if high then "summon_legendary" else "summon_reveal")
		body.Visible = false
		local flash = Create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.05, BorderSizePixel = 0, ZIndex = z + 10, Parent = stage })
		tween(flash, 0.5, { BackgroundTransparency = 1 })
		light.BackgroundColor3 = color
		tween(light, 0.6, { Size = UDim2.fromOffset(900, 900), BackgroundTransparency = 1 })
		if Fx.full() then
			local r = rays(stage, color, z + 1)
			tween(r, 1.4, { Rotation = 90, Size = UDim2.fromOffset(160, 160) })
			for _, ray in r:GetChildren() do
				if ray:IsA("Frame") then
					tween(ray, 1.4, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				end
			end
			if high then
				sparks(stage, color, z + 3)
				if Juice.allowed("petals") then
					petals(stage, z + 4)
				end
			end
		end
		onBurst()
		task.delay(1.6, function()
			stage:Destroy()
		end)
	end
	skip.Activated:Connect(burst)

	task.spawn(function()
		-- Drop in on the chain with a swing.
		sting("summon_reveal")
		tween(body, 0.55, { Position = UDim2.new(0.5, 0, 0.42, -115) }, Enum.EasingStyle.Back)
		for _, r in { 8, -6, 4, -2, 0 } do
			if done then
				return
			end
			tween(body, 0.16, { Rotation = r }, Enum.EasingStyle.Sine)
			task.wait(0.16)
		end
		-- First glow: blue for everyone (so a gold pull is a surprise), then the real colour.
		local first = if high then Theme.rarityColor("rare") else color
		light.BackgroundColor3 = first
		for _, pane in panes do
			pane.BackgroundColor3 = first
		end
		tween(light, 0.4, { Size = UDim2.fromOffset(320, 320) })
		task.wait(0.45)
		if done then
			return
		end
		if high then
			-- The tell: a shake, then the colour turns.
			for _, dx in { 10, -10, 8, -8, 5, -5, 0 } do
				if done then
					return
				end
				body.Position = UDim2.new(0.5, dx, 0.42, -115)
				task.wait(0.04)
			end
			sting("shabriyeh")
			for _, pane in panes do
				tween(pane, 0.25, { BackgroundColor3 = color })
			end
			tween(light, 0.3, { BackgroundColor3 = color, Size = UDim2.fromOffset(460, 460) })
			task.wait(0.5)
		end
		if done then
			return
		end
		tween(body, 0.18, { Size = UDim2.fromOffset(180, 270) }, Enum.EasingStyle.Back)
		task.wait(0.2)
		burst()
	end)

	return { skip = burst }
end

return SummonSequence
