--!strict
-- Effects budget (BUILD_PLAN P2-17): how many pooled effect parts may be alive at once and how many
-- may be handed out in one frame. Pure, so the caps are unit-tested; UI/Fx owns the parts.
-- `reserve` live parts are kept for play information (S1-C02: a telegraph, the aura and shield
-- rings): takeInfo() may use them and is not held back by the per-frame cap, so a busy wave's hit
-- sparks can never crowd out a warning; decoration stops `reserve` short of maxLive.

export type Budget = {
	maxLive: number,
	maxPerFrame: number,
	reserve: number, -- live parts only takeInfo() may use
	live: number, -- parts out of the pool right now
	frame: number, -- parts handed out since the last newFrame()
	skipped: number, -- requests refused since the last newFrame() (for the debug overlay)
}

local VfxBudget = {}

function VfxBudget.new(maxLive: number, maxPerFrame: number, reserve: number?): Budget
	return { maxLive = maxLive, maxPerFrame = maxPerFrame, reserve = math.clamp(reserve or 0, 0, maxLive), live = 0, frame = 0, skipped = 0 }
end

function VfxBudget.canTake(b: Budget): boolean
	return b.live < b.maxLive - b.reserve and b.frame < b.maxPerFrame
end

-- Reserves one part. False when either cap is reached (the effect is skipped, never queued).
function VfxBudget.take(b: Budget): boolean
	if not VfxBudget.canTake(b) then
		b.skipped += 1
		return false
	end
	b.live += 1
	b.frame += 1
	return true
end

-- Reserves one part for play information: only the live cap applies (it still counts toward the
-- frame, so decoration drawn later in the same frame gets less).
function VfxBudget.takeInfo(b: Budget): boolean
	if b.live >= b.maxLive then
		b.skipped += 1
		return false
	end
	b.live += 1
	b.frame += 1
	return true
end

function VfxBudget.release(b: Budget)
	b.live = math.max(0, b.live - 1)
end

-- Call once per frame: the per-frame counter resets, the live count does not.
function VfxBudget.newFrame(b: Budget)
	b.frame = 0
	b.skipped = 0
end

-- How many of `wanted` parts an effect may draw this frame (so a petal poof shrinks instead of
-- vanishing when the frame is busy).
function VfxBudget.allow(b: Budget, wanted: number): number
	return math.max(0, math.min(wanted, b.maxLive - b.reserve - b.live, b.maxPerFrame - b.frame))
end

return VfxBudget
