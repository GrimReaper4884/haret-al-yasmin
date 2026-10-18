--!strict
-- Which presentation moment a match event triggers (POLISH_PLAN PV-B06), so MatchFxController only
-- draws. Pure: the caller passes the match's total waves and the player's presentation settings.
--
-- Moments: waveStart (a plain wave), bossIntro (camera push only with cutscenes on, effects not
-- off and no Reduced Motion), finalWave (the warm last-wave lighting; also on a boss final wave),
-- waveClear (not after the last wave: victory covers it), victory (ribbons and petals only with
-- full effects), defeat (the desaturation with any effects), allyTurn (S1-C05: a story ally joins
-- in an episode whose story has an `ally_turn` beat, the Hakawati's line `line`; the camera push
-- follows the boss rule).

export type Ctx = { totalWaves: number?, cutscenes: boolean, effects: string, reducedMotion: boolean, allyLine: string? }
export type Moment = {
	kind: "waveStart" | "bossIntro" | "finalWave" | "waveClear" | "victory" | "defeat" | "allyTurn",
	wave: number?,
	boss: string?,
	bonus: number?,
	camera: boolean?, -- bossIntro: push the camera toward the spawn gate; allyTurn: toward the ally
	id: number?, -- allyTurn: the ally tower
	unit: string?, -- allyTurn: its unit id
	line: string?, -- allyTurn: the Hakawati's line (a Strings key)
	fx: boolean?, -- victory / defeat / finalWave: draw the world effects
}

local MatchMoments = {}

function MatchMoments.fromEvent(e: { [string]: any }, ctx: Ctx): { Moment }
	local out: { Moment } = {}
	local t = e.type
	local final = ctx.totalWaves ~= nil and type(e.wave) == "number" and e.wave == ctx.totalWaves
	if t == "waveStart" then
		if type(e.boss) == "string" then
			local camera = ctx.cutscenes and ctx.effects ~= "off" and not ctx.reducedMotion
			table.insert(out, { kind = "bossIntro", wave = e.wave, boss = e.boss, camera = camera })
		else
			table.insert(out, { kind = "waveStart", wave = e.wave })
		end
		if final then
			table.insert(out, { kind = "finalWave", wave = e.wave, fx = ctx.effects ~= "off" })
		end
	elseif t == "waveEnd" then
		if type(e.wave) == "number" and not final then
			table.insert(out, { kind = "waveClear", wave = e.wave, bonus = if type(e.bonus) == "number" then e.bonus else nil })
		end
	elseif t == "won" then
		table.insert(out, { kind = "victory", fx = ctx.effects == "full" })
	elseif t == "lost" then
		table.insert(out, { kind = "defeat", fx = ctx.effects ~= "off" })
	elseif t == "ally" and ctx.allyLine then
		local camera = ctx.cutscenes and ctx.effects ~= "off" and not ctx.reducedMotion
		table.insert(out, { kind = "allyTurn", id = e.id, unit = e.unitId, line = ctx.allyLine, camera = camera })
	end
	return out
end

-- How far an episode that opens at dusk has fallen into night at `wave`: 0 at the first wave, 1 from
-- `nightByWave` on, linear between (Config/Lighting.dusk, S1-C05).
function MatchMoments.nightFraction(wave: number, nightByWave: number): number
	if nightByWave <= 1 then
		return 1
	end
	return math.clamp((wave - 1) / (nightByWave - 1), 0, 1)
end

return MatchMoments
