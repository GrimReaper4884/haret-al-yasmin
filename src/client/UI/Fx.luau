--!strict
-- The client's effects budget and a few shared pools, so every controller draws effects the same
-- cheap way.
--
-- Fx.level() is the player's Effects setting (Logic/Settings): "full", "reduced" (no particles,
-- camera moves, screen shake or card shine) or "off" (plain beams only). SettingsController sets
-- it. Pools hand out anchored, non-colliding Neon parts and return them instead of destroying
-- them, so a busy wave does not churn Instance.new / Destroy every hit.

local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Signal = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").Util.Signal)

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
local live = 0
local MAX_LIVE = 80 -- hard cap on pooled effect parts on screen at once

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

-- A pooled effect part (Block or Ball), or nil when the budget is spent.
function Fx.part(shape: Enum.PartType?): BasePart?
	if live >= MAX_LIVE then
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
	live += 1
	return part
end

function Fx.release(p: BasePart)
	live = math.max(0, live - 1)
	p.Parent = nil
	if #free < MAX_LIVE then
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
