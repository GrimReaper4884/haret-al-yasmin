--!nocheck
-- Config integrity: every cross-reference resolves and every string exists in every language.

return function(t)
	local Items = t.config("Items")
	local Quests = t.config("Quests")
	local Shops = t.config("Shops")
	local Npcs = t.config("Npcs")
	local Dialogue = t.config("Dialogue")
	local Strings = t.config("Strings")
	local Clues = t.config("Clues")

	local function hasString(key)
		for _, lang in Strings.languages do
			if Strings[lang][key] == nil then
				return false, lang
			end
		end
		return true
	end

	local function checkKey(key, where)
		local ok, lang = hasString(key)
		t.truthy(ok, "missing string '" .. tostring(key) .. "' (" .. tostring(lang) .. ") used by " .. where)
	end

	t.describe("Strings", function()
		t.it("every language has exactly the same keys", function()
			for _, a in Strings.languages do
				for _, b in Strings.languages do
					for key in Strings[a] do
						t.truthy(Strings[b][key] ~= nil, key .. " is in " .. a .. " but not " .. b)
					end
				end
			end
		end)
		t.it("placeholders match across languages", function()
			for key, en in Strings.en do
				for _, lang in Strings.languages do
					local other = Strings[lang][key]
					for ph in string.gmatch(en, "{(%w+)}") do
						t.truthy(string.find(other, "{" .. ph .. "}", 1, true), key .. " in " .. lang .. " lacks {" .. ph .. "}")
					end
				end
			end
		end)
	end)

	t.describe("Items", function()
		t.it("have valid fields and strings", function()
			for id, def in Items do
				checkKey(def.nameKey, id)
				checkKey(def.descKey, id)
				t.truthy(def.stackMax >= 1, id .. " stackMax")
				if def.kind == "cosmetic" then
					if def.price ~= nil then
						t.truthy(type(def.price) == "number" and def.price >= 0 and def.price % 1 == 0, id .. " price")
					else
						t.truthy(type(def.product) == "string", id .. " has a qirsh price or a Robux product")
					end
					t.truthy(type(def.slot) == "string", id .. " slot")
					t.eq(def.stackMax, 1, id .. " cosmetics are unique")
				end
			end
		end)
	end)

	t.describe("Quests", function()
		t.it("reference existing NPCs, items and strings", function()
			for id, q in Quests do
				t.truthy(Npcs[q.giver], id .. " giver")
				t.truthy(Npcs[q.target], id .. " target")
				if (q.kind or "delivery") == "delivery" then
					t.truthy(Items[q.item] and Items[q.item].kind == "quest", id .. " item")
				end
				if q.objectiveKeys.ready then
					checkKey(q.objectiveKeys.ready, id)
				end
				t.truthy(q.reward.qirsh >= 0 and q.reward.qirsh % 1 == 0, id .. " reward")
				checkKey(q.titleKey, id)
				checkKey(q.objectiveKeys.active, id)
				checkKey(q.objectiveKeys.completed, id)
			end
		end)
	end)

	t.describe("Clues", function()
		t.it("have strings", function()
			for id, c in Clues do
				checkKey(c.nameKey, id)
				checkKey(c.textKey, id)
			end
		end)
	end)

	t.describe("Shops", function()
		t.it("are run by NPCs and sell priced items", function()
			for id, s in Shops do
				t.truthy(Npcs[s.npc], id .. " npc")
				checkKey(s.titleKey, id)
				for _, itemId in s.items do
					t.truthy(Items[itemId] and (Items[itemId].price or Items[itemId].product), id .. " sells " .. itemId)
				end
			end
		end)
	end)

	t.describe("NPCs and dialogue", function()
		t.it("every NPC has dialogue and strings (ambient ones have none)", function()
			for id, n in Npcs do
				if n.talk == false then
					t.eq(Dialogue[id], nil, id .. " is ambient: no prompt, no dialogue")
				else
					t.truthy(Dialogue[id], id .. " dialogue")
				end
				checkKey(n.nameKey, id)
				checkKey(n.roleKey, id)
			end
		end)
		t.it("dialogue graphs resolve", function()
			for npcId, tree in Dialogue do
				t.truthy(Npcs[npcId], "dialogue for unknown npc " .. npcId)
				t.truthy(#tree.entries > 0, npcId .. " has entries")
				for _, e in tree.entries do
					t.truthy(tree.nodes[e.node], npcId .. " entry → " .. e.node)
					if e.condition then
						t.truthy(Quests[e.condition.quest], npcId .. " condition quest")
						local valid = { none = true, active = true, ready = true, completed = true }
						t.truthy(valid[e.condition.state], npcId .. " condition state " .. tostring(e.condition.state))
					end
				end
				for nodeId, node in tree.nodes do
					checkKey(node.textKey, npcId .. "/" .. nodeId)
					t.truthy(#node.choices > 0, npcId .. "/" .. nodeId .. " has choices")
					for i, c in node.choices do
						local where = npcId .. "/" .. nodeId .. "#" .. i
						checkKey(c.textKey, where)
						if c.next then
							t.truthy(tree.nodes[c.next], where .. " next")
						end
						local a = c.action
						if a then
							if a.type == "acceptQuest" then
								t.eq(Quests[a.quest].giver, npcId, where .. " only the giver can hand out")
							elseif a.type == "deliverQuest" then
								t.eq(Quests[a.quest].target, npcId, where .. " only the target can receive")
							elseif a.type == "openShop" then
								t.eq(Shops[a.shop].npc, npcId, where .. " shop belongs to npc")
							elseif a.type == "afk" then
								t.eq(npcId, "qahwaji", where .. " only the coffee-house keeper sends players upstairs")
							elseif a.type == "screen" then
								local Hud = t.config("Hud")
								t.truthy(table.find(Hud.DIALOGUE.screens, a.screen), where .. " opens a listed screen")
							else
								t.eq(a.type, "close", where .. " action type")
							end
						end
					end
				end
			end
		end)
	end)

	-- Defender abilities: a known kind; the mark (S1-S06) is capped at ×1.4 (STORY_PLAN §7.6, D-045).
	t.describe("Unit abilities", function()
		local Units = t.config("Units")
		t.it("every ability has a known kind, a cooldown and a capped mark", function()
			for id, u in Units do
				local ab = u.ability
				if ab then
					t.truthy(ab.kind == "shabriyeh" or ab.kind == "sweep" or ab.kind == "mark", id .. " ability kind")
					t.truthy(type(ab.cooldown) == "number" and ab.cooldown >= 3, id .. " ability cooldown")
					if ab.kind == "mark" then
						t.truthy(ab.multiplier > 1 and ab.multiplier <= 1.4, id .. " mark ≤ ×1.4")
						t.truthy(type(ab.duration) == "number" and ab.duration > 0 and ab.duration < ab.cooldown, id .. " mark duration")
					end
				end
			end
		end)
	end)

	-- Season Story 1 (Config/Story, STORY_PLAN §5, S1-N02): every line resolves in every language.
	t.describe("Story", function()
		local Story = t.config("Story")
		local Waves = t.config("Waves")
		t.it("nine episodes, three intro and three outro lines each, every key in EN and AR", function()
			checkKey(Story.titleKey, "Story.titleKey")
			t.eq(#Story.order, 9)
			local seen = {}
			for i, id in Story.order do
				t.eq(id, "ep" .. i, "episodes in order")
				local ep = Story.episodes[id]
				t.truthy(ep, id .. " has an entry")
				seen[id] = true
				checkKey(ep.titleKey, id .. ".title")
				t.eq(#ep.intro, 3, id .. " intro lines")
				t.eq(#ep.outro, 3, id .. " outro lines")
				for _, key in ep.intro do
					checkKey(key, id .. ".intro")
				end
				for _, key in ep.outro do
					checkKey(key, id .. ".outro")
				end
				for enemy, key in ep.boss do
					checkKey(key, id .. ".boss." .. enemy)
				end
				for name, key in ep.moments or {} do
					checkKey(key, id .. ".moment." .. name)
				end
			end
			for id in Story.episodes do
				t.truthy(seen[id], id .. " is in Story.order")
			end
		end)
		t.it("13 boss lines; the built episodes have a line for every boss they spawn", function()
			local keys = {}
			for _, ep in Story.episodes do
				for _, key in ep.boss do
					keys[key] = true
				end
				for _, key in ep.moments or {} do
					keys[key] = true
				end
			end
			local n = 0
			for _ in keys do
				n += 1
			end
			t.eq(n, 13, "boss and moment lines")
			for id, wave in Waves.episodes do
				local ep = Story.episodes[id]
				if ep then
					for _, boss in wave.bosses do
						t.truthy(ep.boss[boss], id .. " has a Hakawati line for " .. boss)
					end
				end
			end
		end)
		t.it("no story line names a character (names wait for the S1-N01 table)", function()
			local banned = { "Abu ", "Issam", "Shehab", "Idaashari", "Adashari", "أبو ", "الإدعشري", "العدشري" }
			for key, text in Strings.en do
				if string.sub(key, 1, 6) == "story." then
					for _, lang in Strings.languages do
						local s = Strings[lang][key]
						for _, word in banned do
							t.truthy(not string.find(s, word, 1, true), key .. " (" .. lang .. ") names " .. word)
						end
					end
				end
				t.truthy(text ~= "", key)
			end
		end)
	end)

	-- Attackers (Config/Enemies): every name resolves and every story flag (STORY_PLAN §10.1) is typed
	-- and inside its cap, so a typo in S1-S03/S1-S08 data fails here, not in a live match.
	t.describe("Enemies", function()
		local Enemies = t.config("Enemies")
		local Looks = t.config("CharacterLooks")
		local TD = t.config("TD")
		local WaveLogic = t.logic("WaveLogic")
		local function num(v, lo, hi)
			return type(v) == "number" and v == v and v >= lo and v <= hi
		end
		local KNOWN = {
			nameKey = true, hp = true, speed = true, reward = true, gateDamage = true, armor = true, stealth = true,
			boss = true, swarm = true, aura = true, shield = true, burn = true, disguised = true, visual = true,
			summon = true, teleport = true, sabotage = true, split = true, enrage = true, healAura = true, small = true,
		}
		t.it("names resolve, numbers are sane, every flag is known and typed, every attacker has a look", function()
			for id, def in Enemies do
				checkKey(def.nameKey, "enemy " .. id)
				t.truthy(num(def.hp, 1, 1e6) and num(def.speed, 0.5, 20), id .. " hp/speed")
				t.truthy(num(def.reward, 0, 1e5) and def.reward % 1 == 0, id .. " reward")
				t.truthy(num(def.gateDamage, 0, 200) and def.gateDamage % 1 == 0, id .. " gateDamage")
				for k in def do
					t.truthy(KNOWN[k], id .. " has an unknown field '" .. tostring(k) .. "' (typo, or a flag the sim doesn't run yet)")
				end
				if def.armor ~= nil then
					t.truthy(num(def.armor, 0, 0.6), id .. " armor")
				end
				for _, flag in { "stealth", "boss", "swarm", "disguised", "small" } do
					t.truthy(def[flag] == nil or type(def[flag]) == "boolean", id .. "." .. flag .. " is a boolean")
				end
				if def.aura then
					t.truthy(num(def.aura.speed, 1.01, WaveLogic.MAX_SPEED_MUL) and num(def.aura.radius, 1, 20), id .. " aura")
				end
				if def.shield then
					t.truthy(num(def.shield.reduce, 0.01, 0.5) and num(def.shield.radius, 1, 20), id .. " shield")
				end
				if def.burn ~= nil then
					t.truthy(num(def.burn, 1, TD.BURN_MAX_STACKS) and def.burn % 1 == 0, id .. " burn stacks")
				end
				t.truthy(not (def.swarm and def.boss), id .. " a boss is never a swarm")
				if def.summon then
					local child = Enemies[def.summon.enemy]
					t.truthy(def.boss, id .. " only bosses summon")
					t.truthy(child and not child.boss and not child.summon, id .. " summons a plain attacker")
					t.truthy(num(def.summon.count, 1, 8) and def.summon.count % 1 == 0, id .. " summon count")
					t.truthy(num(def.summon.every, 5, 120), id .. " summon interval")
				end
				if def.teleport then
					t.truthy(def.boss, id .. " only bosses teleport")
					t.truthy(num(def.teleport.atHp, 0.05, 0.95), id .. " teleport atHp")
					t.truthy(num(def.teleport.fraction, 0.01, 0.5), id .. " teleport fraction")
					t.truthy(num(def.teleport.telegraph, 0.5, 10), id .. " teleport telegraph")
				end
				if def.sabotage then
					local sb = def.sabotage
					t.truthy(num(sb.range, 2, 30) and num(sb.duration, 0.5, 5) and num(sb.cooldown, sb.duration, 60), id .. " sabotage")
				end
				if def.split then
					local child = Enemies[def.split.enemy]
					t.truthy(child and not child.boss and not child.split, id .. " splits into a plain attacker")
					t.truthy(num(def.split.count, 1, 8) and def.split.count % 1 == 0, id .. " split count")
				end
				if def.enrage then
					t.truthy(num(def.enrage.belowHp, 0.05, 0.95) and num(def.enrage.speed, 1.01, WaveLogic.MAX_SPEED_MUL), id .. " enrage")
				end
				if def.healAura then
					t.truthy(num(def.healAura.radius, 1, 20) and num(def.healAura.pct, 0.001, 0.05), id .. " heal aura")
				end
				local look = Looks[id]
				if look and look.clips then
					t.truthy(Enemies[look.clips] or Looks[look.clips], id .. " borrows the clips of a real figure")
				end
				t.truthy(Looks[id] ~= nil, id .. " has a CharacterLooks entry (the primitive fallback)")
			end
		end)
	end)

	-- The hara kit and the Blender-authored arenas (STORY_PLAN §8, S1-M01..M03): every placed module is
	-- a real kit module, inside the arena, and no tree canopy or solid piece sits on the road.
	t.describe("Kit layouts", function()
		local Arenas = t.config("Arenas")
		local KitModules = t.config("KitModules")
		local TD = t.config("TD")
		local Path = t.logic("Path")
		-- Pieces that may cross or touch the road: overhead wires, the gates at its ends.
		local ON_ROAD = { lantern_wire_span = true, gate_rival = true, gate_lane = true, warehouse_door = true }
		-- World/Arena.gate builds the lane gate's wall just past the road's end: 0–4 studs further on,
		-- 6–40 studs to either side of the opening. No road may run under it (player report 2026-10-18:
		-- "there is a wall in the middle of the road" on the warehouse yard).
		t.it("twin_gates: two roads from gates 40 studs apart that merge and end at one gate (S1-M05)", function()
			local def = Arenas.twin_gates
			t.eq(#def.paths, 2)
			local a, b = def.paths[1], def.paths[2]
			t.eq(math.abs(a[1][2] - b[1][2]), 40, "spawn gates 40 studs apart")
			t.eq(a[#a][1], b[#b][1])
			t.eq(a[#a][2], b[#b][2])
			t.truthy(def.allySpot, "an ally spot for Episodes 8 and 9")
			local pa, pb = Path.build(a), Path.build(b)
			t.truthy(Path.distanceToAll({ pa, pb }, def.allySpot[1], def.allySpot[2]) >= TD.PATH_HALF_WIDTH, "the ally stands off the road")
			t.truthy(Arenas.post_road and Arenas.post_road.kit == "post_road", "the police-post road is a kit arena")
		end)
		t.it("the gate wall stands clear of every road", function()
			local bad = {}
			for id, def in Arenas do
				local last, prev = def.path[#def.path], def.path[#def.path - 1]
				local ux, uz = last[1] - prev[1], last[2] - prev[2]
				local len = math.sqrt(ux * ux + uz * uz)
				ux, uz = ux / len, uz / len
				for r, road in def.paths or { def.path } do
					for i = 1, #road - 1 do
						local a, b = road[i], road[i + 1]
						local seg = math.sqrt((b[1] - a[1]) ^ 2 + (b[2] - a[2]) ^ 2)
						for step = 0, math.ceil(seg * 2) do
							local f = if seg > 0 then math.min(1, step / (seg * 2)) else 0
							local x, z = a[1] + (b[1] - a[1]) * f - last[1], a[2] + (b[2] - a[2]) * f - last[2]
							local along, across = x * ux + z * uz, math.abs(x * uz - z * ux)
							local dt = math.max(-along, 0, along - 4)
							local ds = math.max(6 - across, 0, across - 40)
							if math.sqrt(dt * dt + ds * ds) < TD.PATH_HALF_WIDTH then
								bad[string.format("%s road %d leg %d", id, r, i)] = true
							end
						end
					end
				end
			end
			local list = {}
			for k in bad do
				table.insert(list, k)
			end
			table.sort(list)
			t.eq(#list, 0, "road under the gate wall: " .. table.concat(list, ", "))
		end)
		t.it("every kit module has a size and a triangle count within budget", function()
			local n = 0
			for id, m in KitModules do
				n += 1
				t.eq(#m.size, 3, id .. " size")
				t.eq(#m.offset, 3, id .. " offset")
				t.truthy(m.tris > 0 and m.tris <= 6000, id .. " tris")
			end
			t.truthy(n >= 37, "the procedural and organic halves")
		end)
		t.it("each kit arena's layout uses real modules, stays in bounds and keeps the road clear", function()
			local checked = 0
			for id, def in Arenas do
				if def.kit then
					checked += 1
					local layout = t.config("ArenaLayouts/" .. def.kit)
					t.truthy(#layout > 0, id .. " has modules")
					local roads = Path.buildAll(def)
					local b = def.bounds
					for i, p in layout do
						local m = KitModules[p.module]
						local where = id .. " #" .. i .. " " .. p.module
						t.truthy(m, where .. " is a kit module")
						t.truthy(p.scale > 0 and p.scale <= 2, where .. " scale")
						-- skyline pieces stand far outside on purpose (distant scenery)
						if not string.find(p.module, "^skyline_") then
							t.truthy(p.x >= b[1] - 4 and p.x <= b[3] + 4 and p.z >= b[2] - 4 and p.z <= b[4] + 4, where .. " in bounds")
						end
						if m and not ON_ROAD[p.module] then
							-- the footprint radius of the piece (half its larger side, scaled)
							local r = math.max(m.size[1], m.size[3]) / 2 * p.scale
							if string.find(p.module, "olive_tree") then
								t.truthy(Path.distanceToAll(roads, p.x, p.z) >= TD.PATH_HALF_WIDTH + r * 0.8, where .. " canopy clear of the road")
							elseif m.size[2] > 1 then
								t.truthy(Path.distanceToAll(roads, p.x, p.z) >= TD.PATH_HALF_WIDTH, where .. " off the road")
							end
						end
					end
				end
			end
			t.truthy(checked >= 1, "at least the Olive Press")
		end)
	end)
end
