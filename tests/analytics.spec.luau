--!nocheck
-- Analytics events (BUILD_PLAN P3-07): custom event names come from a closed list (Roblox caps how many
-- distinct names an experience may log), ids travel in custom fields, matches are progression events.

return function(t)
	local AnalyticsEvents = _G.LogicRequire("AnalyticsEvents")
	local Modes = t.config("Modes")
	local Units = t.config("Units")
	local fs = require("@lune/fs")

	local names = {}
	for _, n in AnalyticsEvents.NAMES do
		names[n] = true
	end

	t.describe("Analytics events", function()
		t.it("every constructor returns a listed name, a number and at most three short fields", function()
			local samples = {
				AnalyticsEvents.summonPull(10),
				AnalyticsEvents.summonResult("mythic", "zaim_akbar"),
				AnalyticsEvents.traitReroll(),
				AnalyticsEvents.codeRedeem("YASMIN"),
				AnalyticsEvents.clueFound("fountain"),
				AnalyticsEvents.passClaim("premium", 20),
				AnalyticsEvents.eventBuy("ramadan", "fanous"),
				AnalyticsEvents.dailyClaim(7),
				AnalyticsEvents.shopOpened(),
				AnalyticsEvents.languageSet("ar"),
				AnalyticsEvents.afkEnter("idle"),
				AnalyticsEvents.afkHop(),
				AnalyticsEvents.afkMinutes(12),
				AnalyticsEvents.matchEnd("ep1", "normal", true, 20),
				AnalyticsEvents.codeRedeem(string.rep("X", 200)),
			}
			for _, ev in samples do
				t.truthy(names[ev.name], ev.name .. " is listed")
				t.truthy(type(ev.value) == "number", ev.name .. " value")
				t.truthy(#ev.fields <= 3, ev.name .. " fields")
				for _, f in ev.fields do
					t.truthy(type(f) == "string" and #f <= 50, ev.name .. " field length")
				end
			end
			local r = AnalyticsEvents.summonResult("epic", "tajir")
			t.eq(r.fields[1], "epic")
			t.eq(r.fields[2], "tajir")
			t.eq(AnalyticsEvents.matchEnd("ep1", "hard", false, 7).fields[3], "lost")
		end)

		t.it("the placement telemetry names (DeviceTelemetry.events) are listed", function()
			local DeviceTelemetry = _G.LogicRequire("DeviceTelemetry")
			local counts = DeviceTelemetry.newCounts()
			for k in counts do
				counts[k] = 1
			end
			for _, e in DeviceTelemetry.events(counts, nil) do
				t.truthy(names[e.name], e.name)
			end
		end)

		t.it("the summon-result name stays one name whatever the unit (no per-unit names)", function()
			local seen = {}
			for id in Units do
				seen[AnalyticsEvents.summonResult("rare", id).name] = true
			end
			local n = 0
			for _ in seen do
				n += 1
			end
			t.eq(n, 1)
		end)

		t.it("every mode maps to a valid progression (path without , \" ' or newline; story levels are episode numbers)", function()
			for modeId, mode in Modes do
				for _, status in { "Start", "Complete", "Fail" } do
					local p = AnalyticsEvents.progression(status, mode, modeId, "normal")
					t.eq(p.status, status)
					t.truthy(#p.path > 0 and not string.find(p.path, "[,\"'\n]"), modeId .. " path " .. p.path)
					t.truthy(p.level >= 1 and p.level == math.floor(p.level), modeId .. " level")
					t.eq(p.levelName, modeId)
					t.eq(p.fields[1], "normal")
				end
				if mode.kind == "story" then
					local p = AnalyticsEvents.progression("Start", mode, modeId, "hard")
					t.eq(p.path, "Story")
					t.eq(p.level, tonumber(string.match(modeId, "(%d+)$")), modeId)
				end
			end
		end)

		t.it("server code logs custom events only by listed literal names or the Events shapes", function()
			local function walk(dir, out)
				for _, name in fs.readDir(dir) do
					local path = dir .. "/" .. name
					if fs.isDir(path) then
						walk(path, out)
					elseif string.sub(name, -5) == ".luau" then
						table.insert(out, path)
					end
				end
				return out
			end
			for _, path in walk("src/server", {}) do
				if string.find(path, "AnalyticsService.luau", 1, true) then
					continue -- the wrapper itself
				end
				local src = fs.readFile(path)
				for call in string.gmatch(src, "Analytics%.custom%(([^\n]*)") do
					local name = string.match(call, '^%s*[%w_]+%s*,%s*"([%w_]+)"%s*[,)]')
					local fromEvent = string.match(call, "^%s*[%w_]+%s*,%s*e%.name")
					t.truthy(name and names[name] or fromEvent, path .. ": Analytics.custom(" .. string.sub(call, 1, 60))
				end
			end
		end)
	end)
end
