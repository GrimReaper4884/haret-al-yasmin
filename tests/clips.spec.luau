--!nocheck
-- Baked bone clips (src/shared/Anim/Clips/<id>.luau, tools/anim/bake.py; POLISH_PLAN PV-A03): every
-- attacker with a baked file has walk, hit and death; bosses add intro and stagger; every slot is
-- well-formed. Attackers still waiting for their Meshy model (PV-A02) are listed explicitly so a
-- missing file anywhere else fails.

local fs = require("@lune/fs")

-- Attackers still waiting for their Meshy model: the Season Story 1 attackers of S1-S03 and S1-S08,
-- until S1-A02 / S1-A04 import and bake them.
local AWAITING_MODEL: { [string]: boolean } = {
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
				if AWAITING_MODEL[id] then
					t.eq(clips, nil, id .. " is listed as awaiting its model but has clips: update AWAITING_MODEL")
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
			t.truthy(checked >= 11, "all eleven imported attackers are covered")
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
end
