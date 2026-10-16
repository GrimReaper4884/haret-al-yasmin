--!strict
-- Turns a wave script (Config/Waves) into a concrete spawn list for one wave. Pure.

export type Spawn = { at: number, enemy: string, hpMul: number, speedMul: number, boss: boolean? }
export type Wave = { spawns: { Spawn }, boss: string?, count: number }

type PoolEntry = { enemy: string, from: number, to: number?, base: number, perWave: number, gap: number, delay: number? }

local WaveLogic = {}

local MAX_PER_GROUP = 40
local MAX_PER_WAVE = 90
local MAX_SPEED_MUL = 1.6

local function groupSpawns(out: { Spawn }, entry: PoolEntry, wave: number, hpMul: number, speedMul: number)
	if wave < entry.from or (entry.to ~= nil and wave > entry.to) then
		return
	end
	local count = math.clamp(math.floor(entry.base + entry.perWave * (wave - entry.from) + 0.5), 1, MAX_PER_GROUP)
	local delay = entry.delay or 0
	for k = 0, count - 1 do
		table.insert(out, { at = delay + k * entry.gap, enemy = entry.enemy, hpMul = hpMul, speedMul = speedMul })
	end
end

local function finish(spawns: { Spawn }, boss: string?, bossHpMul: number, speedMul: number): Wave
	table.sort(spawns, function(a, b)
		return a.at < b.at
	end)
	if #spawns > MAX_PER_WAVE then
		local trimmed = table.move(spawns, 1, MAX_PER_WAVE, 1, {})
		spawns = trimmed
	end
	if boss then
		local last = if #spawns > 0 then spawns[#spawns].at else 0
		table.insert(spawns, { at = last + 4, enemy = boss, hpMul = bossHpMul, speedMul = speedMul, boss = true })
	end
	return { spawns = spawns, boss = boss, count = #spawns }
end

export type Difficulty = { hp: number, speed: number, growth: number?, endless: number?, boss: number? }

-- Story episode wave. difficulty = { hp, speed } multipliers; growth (default 1) scales the
-- per-wave HP growth, so harder difficulties stay playable early and bite late; boss (default 1)
-- multiplies the boss's HP on top.
function WaveLogic.story(episode: any, wave: number, difficulty: Difficulty): Wave
	local hpMul = difficulty.hp * (1 + episode.hpPerWave * (difficulty.growth or 1) * (wave - 1))
	local speedMul = math.min(difficulty.speed, MAX_SPEED_MUL)
	local spawns: { Spawn } = {}
	for _, entry in episode.pool do
		groupSpawns(spawns, entry, wave, hpMul, speedMul)
	end
	return finish(spawns, episode.bosses[wave], hpMul * (difficulty.boss or 1), speedMul)
end

-- Endless wave. The curve is already quadratic, so difficulty uses its own (milder) growth
-- multiplier `endless` here (default 1).
function WaveLogic.infinite(cfg: any, wave: number, difficulty: Difficulty): Wave
	local hpMul = difficulty.hp * (1 + (difficulty.endless or 1) * (cfg.hpPerWave * wave + cfg.hpPerWaveSq * wave * wave))
	-- Past `lateFrom` HP also compounds, so even a maxed team meets a wall (≈ wave 100 on Normal).
	if cfg.lateFrom and cfg.lateGrowth and wave > cfg.lateFrom then
		hpMul *= (1 + cfg.lateGrowth) ^ (wave - cfg.lateFrom)
	end
	local speedMul = math.min(difficulty.speed * (1 + cfg.speedPerWave * wave), MAX_SPEED_MUL)
	local spawns: { Spawn } = {}
	for _, entry in cfg.pool do
		groupSpawns(spawns, entry, wave, hpMul, speedMul)
	end
	local boss: string? = nil
	if wave % cfg.bossEvery == 0 then
		local idx = (wave // cfg.bossEvery - 1) % #cfg.bossCycle + 1
		boss = cfg.bossCycle[idx]
	end
	return finish(spawns, boss, hpMul * (difficulty.boss or 1), speedMul)
end

return WaveLogic
