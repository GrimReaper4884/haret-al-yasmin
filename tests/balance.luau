--!nocheck
-- Balance report: plays every mode × difficulty × loadout with the auto-battler (tests/autobattle)
-- and prints the outcome. Run from the repo root:
--   lune run tests/balance                    -- summary matrix for everything
--   lune run tests/balance ep1 normal re6up   -- one run, wave by wave ("all" works for any field)
--   lune run tests/balance all all all --waves   -- every run wave by wave
--   lune run tests/balance --md               -- the summary as a Markdown table (docs)
--   lune run tests/balance --party 4          -- a 4-player party, every player on the loadout
--                                                (scaled by TD.PARTY_*; default 1)

local process = require("@lune/process")

local cache = {}
_G.LogicRequire = function(name)
	if cache[name] == nil then
		cache[name] = require("../src/shared/Logic/" .. name)
	end
	return cache[name]
end

local AutoBattle = require("./autobattle")
local TD = require("../src/shared/Config/TD")

local MODES = { "ep1", "ep2", "ep3", "infinite" }

local VALUE_FLAGS = { party = true } -- flags that take a value: --party 4 or --party=4
local positional, flags = {}, {}
local i = 1
while i <= #process.args do
	local a = process.args[i]
	if string.sub(a, 1, 2) == "--" then
		local name, value = string.match(a, "^%-%-([%w_]+)=(.*)$")
		if name then
			flags[name] = value
		elseif VALUE_FLAGS[string.sub(a, 3)] then
			flags[string.sub(a, 3)] = process.args[i + 1]
			i += 1
		else
			flags[string.sub(a, 3)] = true
		end
	else
		table.insert(positional, a)
	end
	i += 1
end
local party = tonumber(flags.party) or 1
assert(party >= 1 and party <= TD.MAX_PLAYERS and party % 1 == 0, "--party must be 1.." .. TD.MAX_PLAYERS)
local function pick(list, want)
	if want == nil or want == "all" then
		return list
	end
	return { want }
end
local modes = pick(MODES, positional[1])
local diffs = pick(TD.DIFFICULTY_ORDER, positional[2])
local policies = pick(AutoBattle.POLICY_ORDER, positional[3])
local single = #modes == 1 and #diffs == 1 and #policies == 1
local showWaves = flags.waves or single

local function outcome(r)
	if r.won then
		return string.format("WIN %d/%d", r.gateHp, r.gateMax)
	end
	if r.totalWaves then
		return string.format("lost w%d", r.wavesCleared + 1)
	end
	if not r.lost then
		return string.format("alive w%d", r.wavesCleared) -- hit the --max cap
	end
	return string.format("died w%d", r.wavesCleared + 1)
end

local function printWaves(r)
	print("  wave  enemies  boss               leaked  gateLost  gateHp   cash  towers  levels  result leaked by")
	for _, w in r.waves do
		local boss = if w.boss then w.boss .. (if w.bossLeaked then string.format("!%d%%", w.bossHpLeft * 100) else "") else "-"
		local by = {}
		for kind, n in w.leakedBy do
			table.insert(by, kind .. "×" .. n)
		end
		table.sort(by)
		print(string.format("  %4d  %7d  %-17s  %6d  %8d  %6d  %5d  %6d  %6d  %-6s %s", w.wave, w.count, boss, w.leaked, w.gateLost, w.gateHp, w.cash, w.towers, w.levels, w.result, table.concat(by, " ")))
	end
end

local results = {}
local t0 = os.clock()
for _, m in modes do
	for _, d in diffs do
		for _, pid in policies do
			local r = AutoBattle.play(m, d, pid, { maxWaves = 150, party = party })
			results[m .. "/" .. d .. "/" .. pid] = r
			if showWaves then
				print(string.format("\n%s · %s · %s (%s) → %s   (boss!N%% = the boss reached the gate with N%% HP)", m, d, pid, AutoBattle.POLICIES[pid].label, outcome(r)))
				printWaves(r)
			end
		end
	end
end

-- Summary matrix: rows = mode/difficulty, columns = loadouts
if flags.md then
	local head = "| Mode | Diff. |"
	local sep = "|------|-------|"
	for _, pid in policies do
		head ..= " " .. pid .. " |"
		sep ..= "------|"
	end
	print("\n" .. head .. "\n" .. sep)
	for _, m in modes do
		for _, d in diffs do
			local line = "| " .. m .. " | " .. d .. " |"
			for _, pid in policies do
				line ..= " " .. outcome(results[m .. "/" .. d .. "/" .. pid]) .. " |"
			end
			print(line)
		end
	end
else
	local head = string.format("\n%-19s", "mode/difficulty")
	for _, pid in policies do
		head ..= string.format("%-14s", pid)
	end
	print(head)
	for _, m in modes do
		for _, d in diffs do
			local line = string.format("%-19s", m .. "/" .. d)
			for _, pid in policies do
				line ..= string.format("%-14s", outcome(results[m .. "/" .. d .. "/" .. pid]))
			end
			print(line)
		end
	end
end
local scale = AutoBattle.partyScale(party)
print(string.format("\n(%d runs in %.1f s; party of %d: enemy HP ×%.2f, boss HP ×%.2f, cash ×%.2f each; loadouts: %s)", #modes * #diffs * #policies, os.clock() - t0, party, scale.hp, scale.boss, scale.cash, table.concat(policies, ", ")))
