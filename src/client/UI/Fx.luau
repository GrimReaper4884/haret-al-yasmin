--!strict
-- The client's effects budget and a few shared pools, so every controller draws effects the same
-- cheap way.
--
-- Fx.level() is the player's Effects setting (Logic/Settings): "full", "reduced" (no particles,
-- camera moves, screen shake or card shine) or "off" (plain beams only). SettingsController sets
-- it. Pools hand out anchored, non-colliding Neon parts and return them instead of destroying
-- them, so a busy wave does not churn Instance.new / Destroy every hit.

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Signal = require(Shared.Util.Signal)
local VfxBudget = require(Shared.Logic.VfxBudget)
local Vfx = require(Shared.Config.Vfx)

local Fx = {}

Fx.Changed = Signal.new()

local level = "full"

function Fx.level(): string
	return level
end

function Fx.set(v: string)
	if v ~= level then
		level = v
		Fx.Changed:Fire(v)
	end
end

-- Convenience checks.
function Fx.full(): boolean
	return level == "full"
end

function Fx.any(): boolean
	return level ~= "off"
end

---------------------------------------------------------------- Part pool

local folder: Folder? = nil
local free: { BasePart } = {}
-- Caps (Config/Vfx): MAX_LIVE parts out at once, MAX_PER_FRAME handed out per frame. An effect that
-- misses the budget is skipped, never queued, so a busy wave degrades instead of stalling.
local budget = VfxBudget.new(Vfx.MAX_LIVE, Vfx.MAX_PER_FRAME)
RunService.Heartbeat:Connect(function()
	VfxBudget.newFrame(budget)
end)

-- How many of `wanted` parts fit in this frame's budget (multi-part effects shrink to fit).
function Fx.allow(wanted: number): number
	return VfxBudget.allow(budget, wanted)
end

-- Live / per-frame counters for the debug overlay.
function Fx.stats(): (number, number, number)
	return budget.live, budget.frame, budget.skipped
end

local function fxFolder(): Folder
	local f = folder
	if f and f.Parent then
		return f
	end
	local n = Instance.new("Folder")
	n.Name = "ClientFx"
	n.Parent = Workspace
	folder = n
	return n
end

-- A pooled effect part (Block, Ball or Cylinder), or nil when the budget is spent.
function Fx.part(shape: Enum.PartType?): BasePart?
	if not VfxBudget.take(budget) then
		return nil
	end
	local p: BasePart? = nil
	for i = #free, 1, -1 do
		local c = free[i]
		if (c :: Part).Shape == (shape or Enum.PartType.Block) then
			table.remove(free, i)
			p = c
			break
		end
	end
	if not p then
		local n = Instance.new("Part")
		n.Shape = shape or Enum.PartType.Block
		n.Anchored = true
		n.CanCollide = false
		n.CanQuery = false
		n.CanTouch = false
		n.CastShadow = false
		n.Material = Enum.Material.Neon
		n.TopSurface = Enum.SurfaceType.Smooth
		n.BottomSurface = Enum.SurfaceType.Smooth
		p = n
	end
	local part = p :: BasePart
	part.Transparency = 0
	part.Material = Enum.Material.Neon -- a borrower may have changed it
	part.Parent = fxFolder()
	return part
end

function Fx.release(p: BasePart)
	VfxBudget.release(budget)
	p.Parent = nil
	if #free < Vfx.MAX_LIVE then
		table.insert(free, p)
	else
		p:Destroy()
	end
end

-- Tweens `props` on a pooled part over `t` seconds, then returns it to the pool.
function Fx.fade(p: BasePart, t: number, props: { [string]: any }, style: Enum.EasingStyle?)
	local tw = TweenService:Create(p, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	tw.Completed:Once(function()
		Fx.release(p)
	end)
	tw:Play()
end

return Fx
