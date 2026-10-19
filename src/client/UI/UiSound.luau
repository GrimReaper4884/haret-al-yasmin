--!strict
-- The UI layer's sound hook (LP-C07): UI modules (Theme, Modal, Button) call UiSound.play(kind) without
-- requiring a controller; AudioController.start installs the player. Before that, nothing plays.

local UiSound = {}

local player: ((string) -> ())? = nil

function UiSound.set(fn: (string) -> ())
	player = fn
end

function UiSound.play(kind: string)
	local fn = player
	if fn then
		fn(kind)
	end
end

return UiSound
