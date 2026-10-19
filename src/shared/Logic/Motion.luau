--!strict
-- Which UI motion may play (POLISH_PLAN PV-B07). One gate for every Juice helper, so Reduced
-- Motion and the Effects setting are respected everywhere. Pure.
--
-- Reduced Motion (Roblox accessibility setting) stops all of it. Effects "off" keeps only the
-- press squash (feedback that a tap registered). Effects "reduced" drops the decorative extras:
-- shine sweeps and petal bursts. Hover tilt needs a mouse. Theme v2 (LP-C01): `breathe` (a primary
-- button's slow pulse) and `ready` (a claimable control's shimmer) are decorative; `stagger` (lists
-- arriving one after another) follows `pop`.

export type Kind = "press" | "pop" | "tilt" | "flip" | "petals" | "shine" | "wobble" | "slide" | "breathe" | "ready" | "stagger"

local Motion = {}

Motion.kinds = { "press", "pop", "tilt", "flip", "petals", "shine", "wobble", "slide", "breathe", "ready", "stagger" } :: { Kind }

local DECORATIVE = { shine = true, petals = true, breathe = true, ready = true }

function Motion.allowed(kind: Kind, effects: string, reducedMotion: boolean, hasMouse: boolean): boolean
	if reducedMotion then
		return false
	end
	if effects == "off" then
		return kind == "press"
	end
	if effects ~= "full" and DECORATIVE[kind] then
		return false
	end
	if kind == "tilt" then
		return hasMouse
	end
	return true
end

return Motion
