--!strict
-- Device and placement telemetry (MOBILE_HUD_PLAN B8, MH-17). Pure: the server keeps one Session
-- per player (the HUD profile its client reported; the first valid report wins, later ones are
-- dropped) and one Counts per player per match (placed / invalid / cancelled). When the match ends
-- for that player, `events` turns the counts into the custom events AnalyticsService logs, each
-- tagged with the device so Creator Hub can split the misplacement rate by device class.
-- Every function takes the Hud config first (Config/Hud.TELEMETRY).

local DeviceTelemetry = {}

export type Outcome = "placed" | "invalid" | "cancelled"
export type Session = { profile: string?, dropped: number }
export type Counts = { placed: number, invalid: number, cancelled: number }
export type Event = { name: string, value: number, profile: string }

local OUTCOMES: { Outcome } = { "placed", "invalid", "cancelled" }

-- 0 desktop, 1 touch-phone, 2 touch-tablet; nil for anything else.
function DeviceTelemetry.index(cfg: any, profile: any): number?
	if type(profile) ~= "string" then
		return nil
	end
	local i = table.find(cfg.TELEMETRY.profiles, profile)
	return if i then i - 1 else nil
end

function DeviceTelemetry.newSession(): Session
	return { profile = nil, dropped = 0 }
end

-- A ClientProfile report. Returns true when it was taken; false and why otherwise.
function DeviceTelemetry.report(cfg: any, session: Session, value: any): (boolean, string?)
	if session.profile ~= nil then
		session.dropped += 1
		return false, "already_reported"
	end
	if DeviceTelemetry.index(cfg, value) == nil then
		session.dropped += 1
		return false, "bad_profile"
	end
	session.profile = value
	return true, nil
end

function DeviceTelemetry.newCounts(): Counts
	return { placed = 0, invalid = 0, cancelled = 0 }
end

-- What a PlaceTower result means for the misplacement rate: a placement, a refused spot, or
-- nothing (a bad request, no match, a cap or an empty purse are not aiming mistakes).
function DeviceTelemetry.classify(cfg: any, ok: boolean, err: string?): Outcome?
	if ok then
		return "placed"
	end
	if err and table.find(cfg.TELEMETRY.invalidReasons, err) then
		return "invalid"
	end
	return nil
end

-- Counts one outcome, never past TELEMETRY.maxPerMatch.
function DeviceTelemetry.add(cfg: any, counts: Counts, outcome: Outcome)
	counts[outcome] = math.min(counts[outcome] + 1, cfg.TELEMETRY.maxPerMatch)
end

-- One `place_outcome_<outcome>` event per non-zero count; the profile is "unknown" when the
-- client never reported one.
function DeviceTelemetry.events(counts: Counts, session: Session?): { Event }
	local profile = if session and session.profile then session.profile else "unknown"
	local out: { Event } = {}
	for _, o in OUTCOMES do
		if counts[o] > 0 then
			table.insert(out, { name = "place_outcome_" .. o, value = counts[o], profile = profile })
		end
	end
	return out
end

return DeviceTelemetry
