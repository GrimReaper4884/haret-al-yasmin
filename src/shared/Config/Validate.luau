--!strict
--[[
	Validate: structural and sum checks for every Config module.
	Runs at server start (src/server/Main.server.luau) and from tests. Returns a list of error
	strings; assertAll() raises if the list is non-empty. Keep this free of gameplay logic.
]]

local Types = require(script.Parent.Types)
local SummonConfig = require(script.Parent.SummonConfig)
local TraitConfig = require(script.Parent.TraitConfig)
local StatGradeConfig = require(script.Parent.StatGradeConfig)
local EnemyConfig = require(script.Parent.EnemyConfig)
local UnitConfig = require(script.Parent.UnitConfig)
local WaveConfig = require(script.Parent.WaveConfig)

local PPM = Types.PPM_TOTAL

local Validate = {}

local function rarityOf(unitId: string): Types.Rarity?
	local unit = UnitConfig.Units[unitId]
	return if unit then unit.rarity else nil
end

function Validate.run(): { string }
	local errors: { string } = {}
	local function check(condition: boolean, message: string)
		if not condition then
			table.insert(errors, message)
		end
	end

	-- Summons ------------------------------------------------------------------------------
	for name, t in SummonConfig.RarityPpm do
		local sum = t.Rare + t.Epic + t.Legendary + t.Mythic + t.Secret
		check(sum == PPM, `SummonConfig.RarityPpm.{name} sums to {sum} ppm, expected {PPM}`)
	end
	check(SummonConfig.RarityPpm.Standard.Secret == 0, "Standard banner must not contain Secret")
	check(
		SummonConfig.Featured.featuredShareOfMythicPpm >= 0 and SummonConfig.Featured.featuredShareOfMythicPpm <= PPM,
		"Featured.featuredShareOfMythicPpm out of range"
	)
	for id, banner in SummonConfig.Banners do
		check(banner.id == id, `Banner key {id} ~= id {banner.id}`)
		check(SummonConfig.RarityPpm[banner.rarityTable] ~= nil, `Banner {id}: unknown rarityTable`)
		if banner.slot10Table then
			local slot10 = SummonConfig.RarityPpm[banner.slot10Table]
			check(slot10 ~= nil and slot10.Rare == 0, `Banner {id}: slot10Table must exist and exclude Rare`)
		end
		if banner.fixedPoolPpm then
			local sum = 0
			for unitId, ppm in banner.fixedPoolPpm do
				sum += ppm
				check(UnitConfig.Units[unitId] ~= nil, `Banner {id}: unknown unit {unitId}`)
			end
			check(sum == PPM, `Banner {id}: fixedPoolPpm sums to {sum}`)
		end
		for _, unitId in banner.featuredMythics or {} do
			check(rarityOf(unitId) == "Mythic", `Banner {id}: featured {unitId} is not a Mythic`)
		end
		if banner.featuredSecret then
			check(rarityOf(banner.featuredSecret) == "Secret", `Banner {id}: featuredSecret is not a Secret`)
			check(banner.sparkEnabled, `Banner {id}: limited banners must award spark currency`)
		end
	end

	-- Traits -------------------------------------------------------------------------------
	local traitSum = 0
	for _, trait in TraitConfig.Traits do
		traitSum += trait.ppm
		check(trait.ppm > 0, `Trait {trait.id}: ppm must be > 0`)
		if trait.pity then
			local expected = math.round(TraitConfig.PITY_MULTIPLIER * PPM / trait.ppm)
			check(trait.pity == expected, `Trait {trait.id}: pity {trait.pity} ~= round(1.2 x expected) {expected}`)
		end
	end
	check(#TraitConfig.Traits == 17, `TraitConfig must have 17 traits, has {#TraitConfig.Traits}`)
	check(traitSum == PPM, `TraitConfig sums to {traitSum} ppm, expected {PPM}`)

	-- Stat grades --------------------------------------------------------------------------
	local baseSum, fullSum = 0, 0
	for _, grade in StatGradeConfig.Grades do
		baseSum += grade.basePpm
		fullSum += grade.fullPotentialPpm
		check(grade.damage.min <= grade.damage.max, `Grade {grade.id}: damage range inverted`)
		check(grade.spaRange.min <= grade.spaRange.max, `Grade {grade.id}: spaRange inverted`)
	end
	check(baseSum == PPM, `StatGrade base odds sum to {baseSum} ppm`)
	check(fullSum == PPM, `StatGrade full-potential odds sum to {fullSum} ppm`)

	-- Units --------------------------------------------------------------------------------
	for id, unit in UnitConfig.Units do
		check(unit.id == id, `Unit key {id} ~= id {unit.id}`)
		check(unit.placementCap >= 1, `Unit {id}: placementCap < 1`)
		local first = unit.levels[1]
		check(first ~= nil and first.cost > 0, `Unit {id}: missing Lv0 cost`)
		if unit.role == "Merchant" then
			check(unit.branches == nil, `Unit {id}: Merchants do not fork`)
			for i, level in unit.levels do
				check(level.income ~= nil, `Unit {id}: Merchant level {i} missing income`)
			end
		else
			check(#unit.levels == 4, `Unit {id}: needs Lv0..U3 (4 levels), has {#unit.levels}`)
			check(
				first ~= nil and first.damage ~= nil and first.spa ~= nil and first.range ~= nil,
				`Unit {id}: Lv0 needs damage, spa, range`
			)
			local branches = unit.branches
			check(branches ~= nil and #branches == 2, `Unit {id}: needs exactly 2 branches`)
			for _, branch in branches or {} do
				check(#branch.levels == 2, `Unit {id} branch {branch.id}: needs U4 and U5`)
			end
		end
		local hasUltimate = unit.ultimate ~= nil
		local wantsUltimate = unit.rarity == "Mythic" or unit.rarity == "Secret"
		check(hasUltimate == wantsUltimate, `Unit {id}: only Mythic/Secret units have ultimates`)
		check((unit.evolution ~= nil) == wantsUltimate, `Unit {id}: only Mythic/Secret units evolve`)
		if unit.rarity == "Legendary" or wantsUltimate then
			check(unit.active ~= nil, `Unit {id}: Legendary+ units need an active`)
		end
		if unit.active then
			check(
				unit.active.cooldown >= 30 and unit.active.cooldown <= 90,
				`Unit {id}: active cooldown must be 30-90 s`
			)
		end
	end
	for _, unitId in UnitConfig.StarterUnits do
		check(UnitConfig.Units[unitId] ~= nil, `StarterUnits: unknown unit {unitId}`)
	end

	-- Waves --------------------------------------------------------------------------------
	for worldId, world in WaveConfig.Worlds do
		for waveIndex, wave in world.template do
			for _, group in wave.groups do
				check(
					EnemyConfig.Enemies[group.enemy] ~= nil,
					`{worldId} wave {waveIndex}: unknown enemy {group.enemy}`
				)
				check(group.count > 0, `{worldId} wave {waveIndex}: count must be > 0`)
			end
		end
		local finaleHasBoss = false
		for _, group in world.finale.groups do
			local enemy = EnemyConfig.Enemies[group.enemy]
			if enemy and enemy.tier == "Boss" then
				finaleHasBoss = true
			end
		end
		check(finaleHasBoss, `{worldId}: finale must contain a Boss`)
		check(world.finale.timed == false and world.finale.skippable == false, `{worldId}: finale must be untimed`)
		for _, act in world.acts do
			check(act.waveCount <= #world.template, `{worldId} act {act.act}: longer than template`)
		end
	end

	return errors
end

function Validate.assertAll()
	local errors = Validate.run()
	if #errors > 0 then
		error(`[HY][Config] {#errors} error(s):\n` .. table.concat(errors, "\n"), 2)
	end
end

return Validate
