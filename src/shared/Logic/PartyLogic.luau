--!strict
-- Lobby parties for the Play panel: membership (join / leave / host hand-over), the countdown
-- rules, which mode "Next" leads to, and the enemy preview of a mode. Members are opaque ids
-- (the server passes Player objects). Pure.

export type Party<P> = {
	id: number,
	modeId: string,
	difficulty: string,
	players: { P },
	host: P?,
	startAt: number, -- os.clock() when it launches; math.huge = not counting down
}

local PartyLogic = {}

function PartyLogic.new<P>(id: number, modeId: string, difficulty: string, host: P, now: number, queueSeconds: number): Party<P>
	return { id = id, modeId = modeId, difficulty = difficulty, players = { host }, host = host, startAt = now + queueSeconds }
end

function PartyLogic.has<P>(party: Party<P>, member: P): boolean
	return table.find(party.players, member) ~= nil
end

-- Adds a member. Returns ok, err ("full" | "already"). A full party starts soon.
function PartyLogic.join<P>(party: Party<P>, member: P, max: number, now: number, fullSeconds: number): (boolean, string?)
	if PartyLogic.has(party, member) then
		return false, "already"
	end
	if #party.players >= max then
		return false, "full"
	end
	table.insert(party.players, member)
	if #party.players >= max then
		party.startAt = math.min(party.startAt, now + fullSeconds)
	end
	return true, nil
end

-- Removes a member; the next member in join order becomes host. Returns true when the party is
-- now empty (the caller drops it).
function PartyLogic.leave<P>(party: Party<P>, member: P): boolean
	local i = table.find(party.players, member)
	if i then
		table.remove(party.players, i)
	end
	if party.host == member then
		party.host = party.players[1]
	end
	return #party.players == 0
end

-- The host's "Start now": launch within `seconds` (never later than already planned).
function PartyLogic.startSoon<P>(party: Party<P>, member: P, now: number, seconds: number): boolean
	if party.host ~= member then
		return false
	end
	party.startAt = math.min(party.startAt, now + seconds)
	return true
end

-- The story mode that follows `modeId` (the one that requires it, lowest order), or nil.
function PartyLogic.nextMode(modes: { [string]: any }, modeId: string): string?
	local best, bestOrder = nil, math.huge
	for id, m in modes do
		if m.requires == modeId and m.kind == "story" and m.order < bestOrder then
			best, bestOrder = id, m.order
		end
	end
	return best
end

-- Enemies of a mode for the preview: regular enemies in order of first appearance, then bosses
-- by wave. `waves` is Config/Waves.
function PartyLogic.enemiesOf(mode: any, waves: any): ({ string }, { string })
	local pool, bosses = {}, {}
	local def = if mode.kind == "story" then waves.episodes[mode.episode] elseif mode.kind == "event" then waves.events and waves.events[mode.event] else waves.infinite
	if not def then
		return pool, bosses
	end
	local entries = table.clone(def.pool)
	table.sort(entries, function(a: any, b: any)
		return a.from < b.from
	end)
	for _, e in entries do
		if not table.find(pool, e.enemy) then
			table.insert(pool, e.enemy)
		end
	end
	if def.bosses then
		local waveNums = {}
		for w in def.bosses do
			table.insert(waveNums, w)
		end
		table.sort(waveNums)
		for _, w in waveNums do
			local b = def.bosses[w]
			if not table.find(bosses, b) then
				table.insert(bosses, b)
			end
		end
	elseif def.bossCycle then
		for _, b in def.bossCycle do
			table.insert(bosses, b)
		end
	end
	return pool, bosses
end

return PartyLogic
