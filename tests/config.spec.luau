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
		t.it("every NPC has dialogue and strings", function()
			for id, n in Npcs do
				t.truthy(Dialogue[id], id .. " dialogue")
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
							else
								t.eq(a.type, "close", where .. " action type")
							end
						end
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
				for _, flag in { "stealth", "boss", "swarm", "disguised" } do
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
				t.truthy(Looks[id] ~= nil, id .. " has a CharacterLooks entry (the primitive fallback)")
			end
		end)
	end)
end
