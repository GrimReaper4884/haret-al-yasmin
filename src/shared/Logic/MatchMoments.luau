--!strict
-- Which presentation moment a match event triggers (POLISH_PLAN PV-B06), so MatchFxController only
-- draws. Pure: the caller passes the match's total waves and the player's presentation settings.
--
-- Moments: waveStart (a plain wave), bossIntro (camera push only with cutscenes on, effects not
-- off and no Reduced Motion), finalWave (the warm last-wave lighting; also on a boss final wave),
-- waveClear (not after the last wave: victory covers it), victory (ribbons and petals only with
-- full effects), defeat (the desaturation with any effects).

export type Ctx = { totalWaves: number?, cutscenes: boolean, effects: string, reducedMotion: boolean }
export type Moment = {
	kind: "waveStart" | "bossIntro" | "finalWave" | "waveClear" | "victory" | "defeat",
	wave: number?,
	boss: string?,
	bonus: number?,
	camera: boolean?, -- bossIntro: push the camera toward the spawn gate
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
	end
	return out
end

return MatchMoments
