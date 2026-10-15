--!strict
-- Audio cues. Every id is 0 (silent) until an ORIGINAL recording is approved and uploaded
-- (docs/AUDIO_BIBLE.md has the composition brief per cue; docs/COPYRIGHT_REGISTER.md the rule:
-- no TV theme, no sound-alikes). Pure data.
--
-- kind "music" loops and crossfades; "sting" plays once. volume 0..1.

export type Cue = { id: number, kind: "music" | "sting", volume: number, loop: boolean? }

local Audio: { [string]: Cue } = {
	-- Lobby: oud and qanun, slow Bayati, daytime lane
	lobby = { id = 0, kind = "music", volume = 0.35, loop = true },
	-- Match: driving riqq/darbuka groove with a low oud ostinato, Hijaz
	match = { id = 0, kind = "music", volume = 0.4, loop = true },
	-- Boss wave: the "patriot" cue, brass-like nay and strings, half tempo, heavy percussion
	boss = { id = 0, kind = "music", volume = 0.45, loop = true },
	-- Stings
	gate_close = { id = 0, kind = "sting", volume = 0.8 }, -- wooden bar dropping into its hooks, iron rattle
	wave_start = { id = 0, kind = "sting", volume = 0.6 }, -- darbuka roll + zaghareet-like rise
	shabriyeh = { id = 0, kind = "sting", volume = 0.9 }, -- blade drawn: metal shing + single qanun hit
	gate_hit = { id = 0, kind = "sting", volume = 0.7 }, -- thud on wood
	victory = { id = 0, kind = "sting", volume = 0.8 }, -- 'arada-style sword-and-shield rhythm, 6 s
	defeat = { id = 0, kind = "sting", volume = 0.8 }, -- the sad oud phrase, 5 s
	summon_reveal = { id = 0, kind = "sting", volume = 0.6 }, -- short oud strum
	summon_legendary = { id = 0, kind = "sting", volume = 0.9 }, -- shabriyeh sting + choir hit
	ui_click = { id = 0, kind = "sting", volume = 0.4 },
	coin = { id = 0, kind = "sting", volume = 0.5 },
}

return Audio
