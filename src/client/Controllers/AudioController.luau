--!strict
-- Plays cues from Config/Audio: one looping music track at a time (crossfaded) and one-shot
-- stings. A cue whose id is 0 is silent, so the game runs without any uploaded audio.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Audio = require(ReplicatedStorage:WaitForChild("Shared").Config.Audio)

local AudioController = {}

local group: SoundGroup
local music: Sound? = nil
local musicCue: string? = nil
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

function AudioController.sting(cueId: string)
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

function AudioController.music(cueId: string?)
	if cueId == musicCue then
		return
	end
	local old = music
	if old then
		local t = TweenService:Create(old, TweenInfo.new(1.2), { Volume = 0 })
		t:Play()
		t.Completed:Connect(function()
			old:Destroy()
		end)
	end
	music = nil
	musicCue = cueId
	local cue = if cueId then (Audio :: any)[cueId] else nil
	if not cue or cue.id == 0 then
		return
	end
	local s = make(cueId :: string, cue)
	s.Volume = 0
	s:Play()
	TweenService:Create(s, TweenInfo.new(1.5), { Volume = cue.volume }):Play()
	music = s
end

function AudioController.start()
	group = Instance.new("SoundGroup")
	group.Name = "HaretAudio"
	group.Volume = 1
	group.Parent = SoundService
	AudioController.music("lobby")
end

return AudioController
