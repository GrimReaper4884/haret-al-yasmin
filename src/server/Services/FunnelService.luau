--!strict
-- Onboarding funnel (BUILD_PLAN P2-16): join → first prompt → first summon → portal → wave 1 →
-- wave 5 → first clear. Each step is stamped once per player in profile.funnel (Logic/FunnelLogic)
-- inside a DataService.mutate, and logged to AnalyticsService the first time only. In Studio the
-- join → wave 1 time is printed as soon as it is known; HaretDebug:Invoke("funnel") dumps the rows.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FunnelLogic = require(Shared.Logic.FunnelLogic)
local DataService = require(script.Parent.DataService)
local Analytics = require(script.Parent.AnalyticsService)

local FunnelService = {}

-- Marks `step` for the player if this is the first time. Safe to call often; no-op when the step
-- was already reached or the profile is not loaded.
function FunnelService.reach(player: Player, step: string)
	local def = FunnelLogic.STEPS[step]
	if not def then
		warn("[Funnel] unknown step " .. tostring(step))
		return
	end
	local now = os.time()
	local fresh = DataService.mutate(player, function(profile)
		return FunnelLogic.mark(profile, step, now)
	end)
	if fresh ~= true then
		return
	end
	Analytics.funnel(player, def)
	if RunService:IsStudio() then
		local profile = DataService.getProfile(player)
		local since = if profile then FunnelLogic.sinceJoin(profile, step) else nil
		print(string.format("[Funnel] %s reached %s (step %d)%s", player.Name, step, def.step, if since then string.format(" %d s after join", since) else ""))
	end
end

-- A cleared wave number → its funnel step, if any.
function FunnelService.waveCleared(player: Player, wave: number)
	local step = FunnelLogic.WAVE_STEPS[wave]
	if step then
		FunnelService.reach(player, step)
	end
end

function FunnelService.report(player: Player): { any }
	local profile = DataService.getProfile(player)
	return if profile then FunnelLogic.report(profile) else {}
end

function FunnelService.start()
	DataService.ProfileLoaded:Connect(function(player: Player)
		FunnelService.reach(player, "join")
	end)
end

return FunnelService
