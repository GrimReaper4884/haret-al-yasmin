--!strict
-- Effects budget (BUILD_PLAN P2-17): how many pooled effect parts may be alive at once and how many
-- may be handed out in one frame. Pure, so the caps are unit-tested; UI/Fx owns the parts.

export type Budget = {
	maxLive: number,
	maxPerFrame: number,
	live: number, -- parts out of the pool right now
	frame: number, -- parts handed out since the last newFrame()
	skipped: number, -- requests refused since the last newFrame() (for the debug overlay)
}

local VfxBudget = {}

function VfxBudget.new(maxLive: number, maxPerFrame: number): Budget
	return { maxLive = maxLive, maxPerFrame = maxPerFrame, live = 0, frame = 0, skipped = 0 }
end

function VfxBudget.canTake(b: Budget): boolean
	return b.live < b.maxLive and b.frame < b.maxPerFrame
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
	return math.max(0, math.min(wanted, b.maxLive - b.live, b.maxPerFrame - b.frame))
end

return VfxBudget
