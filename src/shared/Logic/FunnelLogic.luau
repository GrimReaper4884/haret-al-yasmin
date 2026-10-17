--!strict
-- Onboarding funnel (BUILD_PLAN P2-16): the first time a player reaches each step is stamped in
-- profile.funnel so the steps are reported once per player lifetime (not once per session), and
-- the join → wave 1 time can be read back in Studio. Pure.

export type Step = { step: number, name: string }

local FunnelLogic = {}

-- Ordered steps. `step` is the number sent to AnalyticsService:LogOnboardingFunnelStepEvent.
local ORDER: { string } = { "join", "prompt", "summon", "portal", "wave1", "wave5", "clear" }
local STEPS: { [string]: Step } = {}
for i, name in ORDER do
	STEPS[name] = { step = i, name = name }
end
-- The wave number that completes each wave step.
local WAVE_STEPS: { [number]: string } = { [1] = "wave1", [5] = "wave5" }

FunnelLogic.ORDER = ORDER
FunnelLogic.STEPS = STEPS
FunnelLogic.WAVE_STEPS = WAVE_STEPS

local function isFinite(v: any): boolean
	return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

-- Stamps `step` at `now` the first time it is reached. Returns true when it was newly reached
-- (the caller then logs the analytics event), false when it was already stamped or is unknown.
function FunnelLogic.mark(profile: any, step: string, now: number): boolean
	if not FunnelLogic.STEPS[step] then
		return false
	end
	local funnel = profile.funnel
	if type(funnel) ~= "table" then
		funnel = {}
		profile.funnel = funnel
	end
	if isFinite(funnel[step]) then
		return false
	end
	funnel[step] = now
	return true
end

function FunnelLogic.reached(profile: any, step: string): boolean
	local funnel = profile.funnel
	return type(funnel) == "table" and isFinite(funnel[step])
end

-- Seconds from the join stamp to `step`, or nil when either is missing.
function FunnelLogic.sinceJoin(profile: any, step: string): number?
	local funnel = profile.funnel
	if type(funnel) ~= "table" or not isFinite(funnel.join) or not isFinite(funnel[step]) then
		return nil
	end
	return funnel[step] - funnel.join
end

-- One row per step in order: { step, name, at?, sinceJoin? }. For the Studio report.
function FunnelLogic.report(profile: any): { { step: number, name: string, at: number?, sinceJoin: number? } }
	local out = {}
	for i, name in FunnelLogic.ORDER do
		local funnel = profile.funnel
		local at = if type(funnel) == "table" and isFinite(funnel[name]) then funnel[name] else nil
		table.insert(out, { step = i, name = name, at = at, sinceJoin = FunnelLogic.sinceJoin(profile, name) })
	end
	return out
end

-- Keeps only known steps with finite stamps.
function FunnelLogic.sanitize(raw: any): { [string]: number }
	local out: { [string]: number } = {}
	if type(raw) ~= "table" then
		return out
	end
	for _, name in FunnelLogic.ORDER do
		if isFinite(raw[name]) then
			out[name] = raw[name]
		end
	end
	return out
end

return FunnelLogic
