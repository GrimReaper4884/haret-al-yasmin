--!nocheck
-- Icon registry (Config/Icons, POLISH_PLAN PV-C02): every icon name the UI asks for resolves, and
-- every name still at id 0 has a primitive drawer in client UI/Icons to fall back to.

local fs = require("@lune/fs")

return function(t)
	local Icons = t.config("Icons")
	local Items = t.config("Items")
	local SeasonPass = t.config("SeasonPass")
	local Daily = t.config("Daily")
	local Codes = t.config("Codes")
	local Events = t.config("Events")
	local Products = t.config("Products")
	local Units = t.config("Units")
	local Enemies = t.config("Enemies")
	local Modes = t.config("Modes")
	local TD = t.config("TD")
	local Looks = t.config("CharacterLooks")

	-- Drawer names in the client module (`\tname = function(`), read as text: it needs Roblox globals.
	local drawers = {}
	for name in string.gmatch(fs.readFile("src/client/UI/Icons.luau"), "\n\t([%w_]+) = function%(") do
		drawers[name] = true
	end
	-- Rail keys in LobbyMenuController (`{ key = "play", color = ... }`), drawn as "ui_" .. key.
	local railKeys = {}
	for key in string.gmatch(fs.readFile("src/client/Controllers/LobbyMenuController.luau"), "{ key = \"([%w_]+)\", color =") do
		table.insert(railKeys, key)
	end

	local function known(name, where)
		t.truthy(Icons.images[name], (where or "") .. " icon '" .. tostring(name) .. "' is not in Config/Icons")
	end

	local function rewardKeys(reward, where)
		for key in reward do
			local icon = Icons.reward[key]
			t.truthy(icon, where .. ": reward kind '" .. key .. "' has no Icons.reward entry")
			if string.sub(icon, 1, 1) ~= "@" then
				known(icon, where)
			end
		end
	end

	t.describe("Icons", function()
		t.it("every entry is a whole non-negative id with an optional hex tint", function()
			local n = 0
			for name, def in Icons.images do
				n += 1
				t.truthy(type(def.id) == "number" and def.id >= 0 and def.id == math.floor(def.id), name .. " id")
				t.truthy(def.tint == nil or string.match(def.tint, "^#%x%x%x%x%x%x$"), name .. " tint")
				t.truthy(string.match(name, "^[a-z][a-z0-9_]*$"), name .. " is lower_snake")
			end
			t.truthy(n >= 30, "registry looks complete")
		end)

		t.it("names without an uploaded image have a primitive drawer (no text fallback)", function()
			t.truthy(drawers.ui_settings and drawers.tarboosh, "drawer scan found the client module")
			for name, def in Icons.images do
				if def.id == 0 then
					t.truthy(drawers[name], name .. " has id 0 and no drawer in UI/Icons")
				end
			end
		end)

		t.it("every rail button, HUD button and item icon resolves", function()
			t.truthy(#railKeys >= 9, "rail scan found the menu items")
			for _, key in railKeys do
				known("ui_" .. key, "rail")
			end
			for _, name in { "ui_settings", "ui_music", "ui_music_off" } do
				known(name, "HUD")
			end
			for id, def in Items do
				known(def.icon, "Items." .. id)
			end
		end)

		t.it("every currency and reward kind has an icon", function()
			for _, name in { "lira", "qirsh", "cash", "stone", "xp", "pass", "ticket" } do
				known(name, "currency")
			end
			for level, tier in SeasonPass.tiers or SeasonPass do
				if type(tier) == "table" and tier.free then
					rewardKeys(tier.free, "SeasonPass " .. level .. " free")
					rewardKeys(tier.premium, "SeasonPass " .. level .. " premium")
				end
			end
			for day, reward in Daily do
				rewardKeys(reward, "Daily " .. day)
			end
			for code, def in Codes do
				local reward = {}
				for key, v in def do
					if key ~= "expiresAt" and key ~= "onlyUserIds" then
						reward[key] = v
					end
				end
				rewardKeys(reward, "Codes." .. code)
			end
			for eventId, ev in Events do
				for _, entry in ev.shop do
					rewardKeys(entry.reward, "Events." .. eventId .. "." .. entry.key)
				end
			end
		end)

		t.it("every developer product kind and item reward has a store icon", function()
			for key, p in Products.devProducts do
				local icon = Icons.product[p.kind]
				t.truthy(icon, "Products." .. key .. ": kind '" .. tostring(p.kind) .. "' has no Icons.product entry")
				if icon == "@item" then
					t.truthy(p.item and Items[p.item], "Products." .. key .. " names an item")
				else
					known(icon, "Products." .. key)
				end
			end
		end)

		t.it("every mode has a banner and every difficulty a ribbon", function()
			for id in Modes do
				local def = Icons.modes[id]
				t.truthy(def and def.id > 0, "Modes." .. id .. " has no banner in Icons.modes")
			end
			for _, d in TD.DIFFICULTY_ORDER do
				known("diff_" .. d, "difficulty")
			end
		end)

		t.it("every defender and attacker has a portrait of its current model", function()
			-- Season Story 1 attackers (S1-S03, S1-S08) are primitive figures until S1-A02/A04; their boss bar
			-- uses the live viewport. Listed so a portrait missing anywhere else still fails.
			local AWAITING = {
				pickpocket = true,
				drummer = true,
				torchbearer = true,
				porter = true,
				disguised = true,
				beggar = true,
				corporal = true,
				abu_jawdan = true,
				abu_shatour = true,
				lateef = true,
				rifleman = true,
				cart = true,
				hakim_rival = true,
				snake = true,
				brute = true,
				fakhr = true,
				abu_zira = true,
			}
			local function check(id)
				if AWAITING[id] then
					local look = Looks[id]
					t.truthy(not (look and look.model), id .. " has a model now: render its portrait and drop it from AWAITING")
					return
				end
				local p = Icons.portraits[id]
				t.truthy(p and p.id > 0, id .. " has no portrait in Icons.portraits")
				local look = Looks[id]
				local model = if look and look.model then look.model else ""
				-- A stale portrait would only fall back to the live viewport, but say so: re-render it
				-- (tools/icons/portrait_render.luau + portraits.py) or set its id to 0.
				t.eq(p.model, model, id .. " portrait was rendered from '" .. p.model .. "', the model is now '" .. model .. "'")
			end
			for id in Units do
				check(id)
			end
			for id in Enemies do
				check(id)
			end
		end)
	end)
end
