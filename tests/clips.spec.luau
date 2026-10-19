--!nocheck
-- Baked bone clips (src/shared/Anim/Clips/<id>.luau, tools/anim/bake.py; POLISH_PLAN PV-A03): every
-- attacker with a baked file has walk, hit and death; bosses add intro and stagger; every slot is
-- well-formed. Attackers still waiting for their Meshy model (PV-A02) are listed explicitly so a
-- missing file anywhere else fails.

local fs = require("@lune/fs")

-- Attackers still waiting for their Meshy model (none since S1-A04).
local AWAITING_MODEL: { [string]: boolean } = {}
-- Static meshes with no rig (Meshy's auto-rigger is biped-only): they slide along the road unanimated,
-- like the cat among the defenders (S1-A04).
local STATIC_MODEL: { [string]: boolean } = { cart = true, snake = true }

local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function decodedLength(s)
	local pad = if string.sub(s, -2) == "==" then 2 elseif string.sub(s, -1) == "=" then 1 else 0
	return #s // 4 * 3 - pad
end

return function(t)
	local Enemies = t.config("Enemies")
	local Looks = t.config("CharacterLooks")

	-- A re-skin (CharacterLooks[id].clips) plays the clips of the figure whose mesh it borrows.
	local function clipsOf(id)
		local look = Looks[id]
		id = if look and look.clips then look.clips else id
		local path = "src/shared/Anim/Clips/" .. id .. ".luau"
		if not fs.isFile(path) then
			return nil
		end
		return require("../src/shared/Anim/Clips/" .. id)
	end

	t.describe("Baked clips (PV-A03)", function()
		t.it("every attacker has walk, hit and death; bosses also intro and stagger", function()
			local checked = 0
			for id, def in Enemies do
				local clips = clipsOf(id)
				if AWAITING_MODEL[id] or STATIC_MODEL[id] then
					t.eq(clips, nil, id .. " is listed as awaiting its model (or static) but has clips: update the lists")
				else
					t.truthy(clips, id .. " has no baked clips")
					for _, slot in { "walk", "hit", "death" } do
						t.truthy(clips[slot], id .. "." .. slot)
					end
					if def.boss then
						t.truthy(clips.intro, id .. ".intro (boss)")
						t.truthy(clips.stagger, id .. ".stagger (boss)")
					end
					checked += 1
				end
			end
			t.truthy(checked >= 26, "all twenty-six rigged attackers are covered")
		end)

		t.it("each slot is well-formed: frames, fps, rotations for every bone, hips per frame", function()
			for id in Enemies do
				local clips = clipsOf(id)
				if clips then
					local nb = #clips.bones
					t.truthy(nb >= 10, id .. " bones")
					for slot, c in clips do
						if slot ~= "bones" then
							local where = id .. "." .. slot
							t.truthy(c.frames >= 2 and c.fps > 0, where .. " frames/fps")
							t.eq(decodedLength(c.rot), c.frames * nb * 6, where .. " rotations = frames x bones x 3 int16")
							t.truthy(string.match(c.rot, "^[" .. B64:gsub("%+", "%%+") .. "=]+$") ~= nil, where .. " base64")
							t.eq(#c.hips, c.frames, where .. " hips per frame")
							t.truthy(c.move >= 0, where .. " move")
						end
					end
				end
			end
		end)
	end)
	-- The lane's cast wears unit and enemy figures (LOOK_AND_PLAY_PLAN LP-D02).
	t.describe("Lane NPC figures (LP-D02)", function()
		local Npcs = t.config("Npcs")
		local LaneZones = t.config("LaneZones")
		t.it("every NPC look has an approved model and the clips its pose needs", function()
			local zones = {}
			for _, z in LaneZones.zones do
				zones[z.id] = true
			end
			local n = 0
			for id, def in Npcs do
				if def.zone then
					t.truthy(zones[def.zone], id .. " waits for a known zone")
				end
				if def.look then
					n += 1
					local look = Looks[def.look]
					t.truthy(look and look.model, id .. " look " .. def.look .. " names a model")
					t.truthy(fs.isFile("assets/production/CharacterModels/" .. look.model .. ".rbxm"), id .. " model is in production")
					local function has(slot)
						local from = def.clipsFrom and def.clipsFrom[slot]
						local c = clipsOf(from or def.look)
						return c ~= nil and c[slot] ~= nil and c[slot].rot ~= nil
					end
					t.truthy(has("idle"), id .. " has an idle (own or borrowed)")
					if def.pose == "walk" then
						t.truthy(has("walk"), id .. " walker has a walk")
					end
				end
				if def.pose == "walk" then
					t.truthy(def.route and #def.route >= 2, id .. " walker has a route")
					t.eq(def.position[1], def.route[1][1], id .. " starts on its route")
					t.eq(def.position[3], def.route[1][2], id .. " starts on its route")
				else
					t.eq(def.route, nil, id .. " only walkers have a route")
				end
				for slot, from in def.clipsFrom or {} do
					t.truthy(slot == "idle" or slot == "walk", id .. " borrows a loop slot")
					t.truthy(clipsOf(from) ~= nil, id .. " borrows from a baked figure")
				end
			end
			t.truthy(n >= 17, "the 13 model NPCs of §4.2 and the four Meshy looks of LP-D08 (" .. n .. ")")
		end)
	end)
end
