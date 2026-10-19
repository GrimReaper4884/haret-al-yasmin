--!strict
-- The UI's sound kinds (Theme v2, LP-C07, LOOK_AND_PLAY_PLAN §5.2) → the Config/Audio cue each plays.
-- AudioController.ui(kind) plays it through the `sfx` setting; a cue at id 0 is silent until its file
-- is supplied (docs/AUDIO_COMMISSION.md §UI). Pure data.

export type Kind = "tap" | "open" | "close" | "confirm" | "deny" | "claim" | "ready"

local UiSounds: { [string]: string } = {
	tap = "ui_click", -- any button press
	open = "ui_open", -- a screen opens
	close = "ui_close", -- a screen closes
	confirm = "ui_confirm", -- the primary answer of a confirmation
	deny = "ui_deny", -- a refusal toast, an unaffordable tap
	claim = "coin", -- a reward flies to the pills
	ready = "ui_ready", -- a control becomes ready (a dot appears)
}

return UiSounds
