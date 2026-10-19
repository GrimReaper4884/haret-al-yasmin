--!strict
-- Audio cues. An id of 0 is silent. Non-zero ids are approved licensed Creator Store assets (v1) or original recordings
-- (docs/AUDIO_BIBLE.md has the composition brief per cue; docs/COPYRIGHT_REGISTER.md the rule:
-- no TV theme, no sound-alikes). Sourcing route per cue and the owner's upload steps: AUDIO_BIBLE §4.
-- v1 ids are licensed Creator Store assets (AUDIO_BIBLE §4.4, register C-101..C-113): Roblox-only, never in off-platform video.
-- Paste only the numeric asset id; AudioController adds the rbxassetid:// prefix. Pure data.
--
-- kind "music" loops and crossfades; "sting" plays once. volume 0..1.

export type Cue = { id: number, kind: "music" | "sting", volume: number, loop: boolean? }

local Audio: { [string]: Cue } = {
	-- Lobby: oud and qanun, slow Bayati, daytime lane
	lobby = { id = 1838890709, kind = "music", volume = 0.35, loop = true }, -- licensed, approved by owner 2026-10-16 (C-101)
	-- Match: driving riqq/darbuka groove with a low oud ostinato, Hijaz
	match = { id = 1838901247, kind = "music", volume = 0.4, loop = true }, -- licensed, approved by owner 2026-10-16 (C-102)
	-- Boss wave: the "patriot" cue, brass-like nay and strings, half tempo, heavy percussion
	boss = { id = 9040299375, kind = "music", volume = 0.45, loop = true }, -- licensed, approved by owner 2026-10-16 (C-103)
	-- Stings
	gate_close = { id = 9114129501, kind = "sting", volume = 0.8 }, -- wooden bar dropping into its hooks, iron rattle; licensed, approved by owner 2026-10-16 (C-104)
	wave_start = { id = 1841116360, kind = "sting", volume = 0.6 }, -- darbuka roll + zaghareet-like rise; licensed, approved by owner 2026-10-16 (C-105)
	wave_clear = { id = 125614866791240, kind = "sting", volume = 0.6 }, -- short darbuka flourish; synthesised (tools/audio/synth_cues.py, C-280)
	shabriyeh = { id = 9119742466, kind = "sting", volume = 0.9 }, -- blade drawn: metal shing + single qanun hit; licensed, approved by owner 2026-10-16 (C-106)
	gate_hit = { id = 9114129572, kind = "sting", volume = 0.7 }, -- thud on wood; licensed, approved by owner 2026-10-16 (C-107)
	victory = { id = 9040297291, kind = "sting", volume = 0.8 }, -- 'arada-style sword-and-shield rhythm, 6 s; licensed, approved by owner 2026-10-16 (C-108)
	defeat = { id = 1843261009, kind = "sting", volume = 0.8 }, -- the sad oud phrase, 5 s; licensed, approved by owner 2026-10-16 (C-109)
	summon_reveal = { id = 104871389478468, kind = "sting", volume = 0.6 }, -- short oud strum; synthesised (tools/audio/synth_cues.py, C-280)
	summon_legendary = { id = 1841822723, kind = "sting", volume = 0.9 }, -- shabriyeh sting + choir hit; licensed, approved by owner 2026-10-16 (C-111)
	ui_click = { id = 9119975775, kind = "sting", volume = 0.4 }, -- licensed, approved by owner 2026-10-16 (C-112)
	coin = { id = 9113848780, kind = "sting", volume = 0.5 }, -- licensed, approved by owner 2026-10-16 (C-113)
	coin_jingle = { id = 100885293697028, kind = "sting", volume = 0.45 }, -- Abu Brahim's coins clinking into a heap (Vfx.FARM.unitSting); synthesised (C-280)
	-- Theme v2 UI sounds (LP-C07, Config/UiSounds), synthesised for LP-F02 (AUDIO_COMMISSION Batches 3-4)
	ui_open = { id = 138106125164918, kind = "sting", volume = 0.35 }, -- a soft cloth swish, a screen opening; synthesised (tools/audio/synth_cues.py, C-280)
	ui_close = { id = 109587391430040, kind = "sting", volume = 0.3 }, -- the swish reversed, shorter; synthesised (tools/audio/synth_cues.py, C-280)
	ui_confirm = { id = 73988615945448, kind = "sting", volume = 0.45 }, -- a brass bell tap; synthesised (tools/audio/synth_cues.py, C-280)
	ui_deny = { id = 77730571662941, kind = "sting", volume = 0.4 }, -- a dull wooden knock, two beats; synthesised (tools/audio/synth_cues.py, C-280)
	ui_ready = { id = 119912670684164, kind = "sting", volume = 0.35 }, -- a small finger-cymbal (sagat) chime; synthesised (tools/audio/synth_cues.py, C-280)
	rooster = { id = 114975753420688, kind = "sting", volume = 0.4 }, -- a rooster at dawn, distant (LP-D10); synthesised (tools/audio/synth_cues.py, C-280)
	arada_drums = { id = 72375252792165, kind = "sting", volume = 0.5 }, -- the 'arada passing by: tabl, daff, swords on shields, ~75 s, no voices (LP-D11); synthesised (tools/audio/synth_cues.py, C-280)
}

return Audio
