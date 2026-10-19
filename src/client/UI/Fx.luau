--!strict
-- The client's effects budget and a few shared pools, so every controller draws effects the same
-- cheap way.
--
-- Fx.level() is the player's Effects setting (Logic/Settings): "full", "reduced" (no particles,
-- camera moves, screen shake or card shine) or "off" (plain beams only). SettingsController sets
-- it. Pools hand out anchored, non-colliding Neon parts and return them instead of destroying
-- them, so a busy wave does not churn Instance.new / Destroy every hit.

local Players = game:GetService("Players")
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

-- The lobby's Lane life setting (LP-D09): "full", "lite" or "off" (Logic/LobbyLife.tier reads it).
-- SettingsController sets it; LobbyLifeController, LaneClockController and the rooftop calls follow it.
local lane = "full"
Fx.LaneChanged = Signal.new()

function Fx.laneLife(): string
	-- Studio harness (LP-D10): "HarnessLaneLife" on the LocalPlayer overrides the saved setting, so a
	-- test run can show the still lane without writing the owner's live settings.
	if RunService:IsStudio() then
		local h = Players.LocalPlayer and Players.LocalPlayer:GetAttribute("HarnessLaneLife")
		if type(h) == "string" then
			return h
		end
	end
	return lane
end

function Fx.setLaneLife(v: string)
	if v ~= lane then
		lane = v
		Fx.LaneChanged:Fire(v)
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
local budget = VfxBudget.new(Vfx.MAX_LIVE, Vfx.MAX_PER_FRAME, Vfx.INFO_RESERVE)
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
function Fx.part(shape: Enum.PartType?, info: boolean?): BasePart?
	if not (if info then VfxBudget.takeInfo(budget) else VfxBudget.take(budget)) then
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

---------------------------------------------------------------- Particle emitters (PV-B01)

local emitterAnchor: Part? = nil
local emitters: { [string]: { ParticleEmitter } } = {}
local emitterCount = 0

-- A pooled ParticleEmitter of sprite `kind` on an Attachment of one invisible anchored part, or nil
-- when the sprite is not uploaded yet (Config/Vfx.TEXTURES id 0), effects are below "full", or
-- the pool is at MAX_EMITTERS. Emitters stay disabled (Rate 0) and are used with Emit(n).
function Fx.emitter(kind: string): ParticleEmitter?
	local tex = (Vfx.TEXTURES :: any)[kind]
	if not tex or tex.id == 0 or level ~= "full" then
		return nil
	end
	local list = emitters[kind]
	if list and #list > 0 then
		return list[1]
	end
	if emitterCount >= Vfx.MAX_EMITTERS then
		return nil
	end
	local anchor = emitterAnchor
	if not anchor or not anchor.Parent then
		local p = Instance.new("Part")
		p.Name = "EmitterAnchor"
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Transparency = 1
		p.Size = Vector3.one * 0.2
		p.Parent = fxFolder()
		emitterAnchor = p
		anchor = p
	end
	local att = Instance.new("Attachment")
	att.Name = kind
	att.Parent = anchor
	local e = Instance.new("ParticleEmitter")
	e.Name = kind
	e.Texture = "rbxassetid://" .. tostring(tex.id)
	e.Rate = 0
	e.Enabled = true
	e.Lifetime = NumberRange.new(tex.life * 0.8, tex.life)
	e.Speed = NumberRange.new(tex.speed * 0.5, tex.speed)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, tex.size), NumberSequenceKeypoint.new(1, tex.size * 0.4) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.7, 0.2), NumberSequenceKeypoint.new(1, 1) })
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-120, 120)
	e.LightEmission = tex.light
	e.Parent = att
	emitters[kind] = { e }
	emitterCount += 1
	return e
end

-- Emits `n` particles of sprite `kind` at `at` (optionally tinted). False when there is no
-- emitter (not uploaded, effects reduced/off, pool full): the caller draws its part fallback.
function Fx.emit(kind: string, at: Vector3, n: number, color: Color3?): boolean
	local e = Fx.emitter(kind)
	if not e then
		return false
	end
	local att = e.Parent :: Attachment
	att.WorldPosition = at
	if color then
		e.Color = ColorSequence.new(color)
	end
	e:Emit(n)
	return true
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
