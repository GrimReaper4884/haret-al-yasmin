--!strict
-- Plays cues from Config/Audio: one looping music track at a time (crossfaded) and one-shot
-- stings. A cue whose id is 0 is silent, so the game runs without any uploaded audio.
-- The `music` and `sfx` settings (Logic/Settings, saved in the profile) mute either half: muting
-- music fades the loop out and remembers which cue should be playing (lobby / match / boss), so
-- turning it back on resumes the right one; muting sfx skips every sting.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Audio = require(ReplicatedStorage:WaitForChild("Shared").Config.Audio)
local StateController = require(script.Parent.StateController)
local SettingsController = require(script.Parent.SettingsController)

local AudioController = {}

local FADE_IN = 1.5 -- s, a new or resumed loop
local CROSSFADE_OUT = 1.2 -- s, the old loop when the cue changes
local MUTE_FADE = 0.4 -- s, the loop when music is switched off
local SETTINGS_WAIT = 5 -- s, longest wait for the first snapshot before music starts anyway

local group: SoundGroup
local music: Sound? = nil
local playingCue: string? = nil -- the cue `music` is playing
local wantedCue: string? = nil -- the cue that should be playing (kept while muted)
local ready = false -- the saved settings are known (or we gave up waiting)
local stings: { [string]: Sound } = {}

local function make(cueId: string, cue: any): Sound
	local s = Instance.new("Sound")
	s.Name = cueId
	s.SoundId = "rbxassetid://" .. tostring(cue.id)
	s.Volume = cue.volume
	s.Looped = cue.loop == true
	s.SoundGroup = group
	s.Parent = SoundService
	return s
end

local function fadeOut(s: Sound, seconds: number)
	local t = TweenService:Create(s, TweenInfo.new(seconds), { Volume = 0 })
	t:Play()
	t.Completed:Connect(function()
		s:Stop()
		s:Destroy()
	end)
end

function AudioController.sting(cueId: string)
	if SettingsController.get("sfx") == false then
		return
	end
	local cue = (Audio :: any)[cueId]
	if not cue or cue.id == 0 then
		return
	end
	local s = stings[cueId]
	if not s then
		s = make(cueId, cue)
		stings[cueId] = s
	end
	s.TimePosition = 0
	s:Play()
end

-- Brings the playing loop in line with the wanted cue and the music setting.
local function refresh(outSeconds: number)
	local target = if ready and SettingsController.get("music") ~= false then wantedCue else nil
	if target == playingCue and (target == nil or music ~= nil) then
		return
	end
	local old = music
	if old then
		fadeOut(old, outSeconds)
	end
	music = nil
	playingCue = target
	local cue = if target then (Audio :: any)[target] else nil
	if not cue or cue.id == 0 then
		return
	end
	local s = make(target :: string, cue)
	s.Volume = 0
	s:Play()
	TweenService:Create(s, TweenInfo.new(FADE_IN), { Volume = cue.volume }):Play()
	music = s
end

-- Sets the cue that should be playing (nil = silence). Muted music only remembers it.
function AudioController.music(cueId: string?)
	wantedCue = cueId
	refresh(CROSSFADE_OUT)
end

local function markReady()
	if ready then
		return
	end
	ready = true
	refresh(CROSSFADE_OUT)
end

function AudioController.start()
	group = Instance.new("SoundGroup")
	group.Name = "HaretAudio"
	group.Volume = 1
	group.Parent = SoundService
	SettingsController.Changed:Connect(function(key: string)
		if key == "music" then
			refresh(MUTE_FADE)
		end
	end)
	-- Wait for the saved settings so a muted player never hears the first seconds of the lobby loop.
	if StateController.get() then
		ready = true
	else
		local conn
		conn = StateController.Changed:Connect(function()
			conn:Disconnect()
			-- SettingsController adopts the snapshot on the same signal; let it run first.
			task.defer(markReady)
		end)
		task.delay(SETTINGS_WAIT, markReady)
	end
	AudioController.music("lobby")
end

return AudioController
