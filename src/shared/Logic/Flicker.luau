--!strict
-- A lantern's brightness multiplier at time `t` (POLISH_PLAN PV-E01): two slow sines and a quick
-- one per lantern (seeded), mapped into [min, max]. Smooth, never a strobe. Pure.

local Flicker = {}

function Flicker.value(t: number, seed: number, min: number, max: number): number
	local a = math.sin(t * 2.1 + seed) * 0.5
	local b = math.sin(t * 3.7 + seed * 1.9) * 0.3
	local c = math.sin(t * 9.3 + seed * 3.1) * 0.2
	local n = (a + b + c + 1) / 2 -- 0..1
	return min + (max - min) * math.clamp(n, 0, 1)
end

return Flicker
