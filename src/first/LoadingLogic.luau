--!strict
-- Loading screen rules (POLISH_PLAN PV-D05): how full the progress bar is, when to hand over to the
-- lobby and which bilingual line is showing. Pure.

local LoadingLogic = {}

-- Bar target 0..1 from the asset queue: the largest queue seen so far is "empty bar".
function LoadingLogic.progress(maxQueue: number, queue: number): number
	if maxQueue <= 0 then
		return 1
	end
	return math.clamp(1 - queue / maxQueue, 0, 1)
end

-- The bar on screen eases toward `target` and never goes backwards.
function LoadingLogic.ease(shown: number, target: number, dt: number, rate: number): number
	if target <= shown then
		return shown
	end
	return math.min(target, shown + (target - shown) * math.clamp(dt * rate, 0, 1))
end

export type State = { elapsed: number, loaded: boolean, queue: number, ready: boolean }

-- Done when the game is loaded, nothing is queued and the lobby is ready, after `minTime`; or at
-- `maxTime` whatever happens.
function LoadingLogic.done(s: State, minTime: number, maxTime: number): boolean
	if s.elapsed >= maxTime then
		return true
	end
	return s.elapsed >= minTime and s.loaded and s.queue == 0 and s.ready
end

function LoadingLogic.line(elapsed: number, every: number, count: number): number
	if count <= 0 then
		return 0
	end
	return math.floor(elapsed / every) % count + 1
end

-- Keypoints for `bands` hard-edged stripes: { time, stripe index (0-based) } pairs, two per
-- stripe, from 0 to exactly 1 (Roblox's ColorSequence rule; at most 20 keypoints, so bands ≤ 10).
function LoadingLogic.stripeStops(bands: number): { { number } }
	local stops = {}
	for i = 0, bands - 1 do
		local a = i / bands
		local b = if i == bands - 1 then 1 else (i + 1) / bands - 0.0001
		table.insert(stops, { a, i })
		table.insert(stops, { b, i })
	end
	return stops
end

return LoadingLogic
