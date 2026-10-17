--!strict
-- Which UI motion may play (POLISH_PLAN PV-B07). One gate for every Juice helper, so Reduced
-- Motion and the Effects setting are respected everywhere. Pure.
--
-- Reduced Motion (Roblox accessibility setting) stops all of it. Effects "off" keeps only the
-- press squash (feedback that a tap registered). Effects "reduced" drops the decorative extras:
-- shine sweeps and petal bursts. Hover tilt needs a mouse.

export type Kind = "press" | "pop" | "tilt" | "flip" | "petals" | "shine" | "wobble" | "slide"

local Motion = {}

Motion.kinds = { "press", "pop", "tilt", "flip", "petals", "shine", "wobble", "slide" } :: { Kind }

local DECORATIVE = { shine = true, petals = true }

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
