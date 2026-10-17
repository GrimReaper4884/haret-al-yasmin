--!strict
-- Reward pop (POLISH_PLAN PV-B03): a cash coin arcs from a defeated enemy to the cash pill, then the
-- pill punches. A small fixed pool (Config/Vfx.COIN_FLIGHT.max); when every coin is in flight the
-- next one is skipped. The coin is UI/Icons "cash" (painted once uploaded, primitive until then).

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local HitFx = require(Shared.Logic.HitFx)
local Vfx = require(Shared.Config.Vfx)
local Create = require(script.Parent.Create)
local Icons = require(script.Parent.Icons)
local Juice = require(script.Parent.Juice)

local CoinFlight = {}

type Coin = { frame: Frame, busy: boolean, x0: number, y0: number, target: GuiObject?, at: number }

local cfg = Vfx.COIN_FLIGHT
local coins: { Coin } = {}
local gui: ScreenGui? = nil

local function build()
	local g = Create("ScreenGui", {
		Name = "HaretCoins",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ScreenInsets = Enum.ScreenInsets.None,
		DisplayOrder = 6,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	}) :: ScreenGui
	for i = 1, cfg.max do
		local f = Create("Frame", {
			Name = "Coin" .. i,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(cfg.size, cfg.size),
			Visible = false,
			Parent = g,
		}) :: Frame
		Icons.draw("cash", f)
		coins[i] = { frame = f, busy = false, x0 = 0, y0 = 0, target = nil, at = 0 }
	end
	gui = g
end

-- Flies a coin from world point `from` to `target` (a GUI object, e.g. the cash pill). False when
-- the pool is full or the point is off screen.
function CoinFlight.fly(from: Vector3, target: GuiObject): boolean
	if not gui then
		build()
	end
	local camera = Workspace.CurrentCamera
	if not camera then
		return false
	end
	local p, onScreen = camera:WorldToViewportPoint(from)
	if not onScreen then
		return false
	end
	for _, c in coins do
		if not c.busy then
			c.busy = true
			c.x0, c.y0 = p.X, p.Y
			c.target = target
			c.at = os.clock()
			c.frame.Position = UDim2.fromOffset(p.X, p.Y)
			c.frame.Visible = true
			return true
		end
	end
	return false
end

function CoinFlight.inFlight(): number
	local n = 0
	for _, c in coins do
		if c.busy then
			n += 1
		end
	end
	return n
end

function CoinFlight.start()
	RunService.RenderStepped:Connect(function()
		local now = os.clock()
		for _, c in coins do
			if c.busy then
				local t = c.target
				local k = (now - c.at) / cfg.life
				if not t or not t.Parent or k >= 1 then
					c.busy = false
					c.frame.Visible = false
					if t and t.Parent and k >= 1 then
						Juice.punch(t, 0.1)
					end
				else
					-- HUD positions exclude the top-bar inset; this ScreenGui and the viewport include it.
					local tp = t.AbsolutePosition + t.AbsoluteSize / 2 + GuiService:GetGuiInset()
					local x, y = HitFx.arc(k, c.x0, c.y0, tp.X, tp.Y, cfg.lift)
					c.frame.Position = UDim2.fromOffset(x, y)
				end
			end
		end
	end)
end

return CoinFlight
