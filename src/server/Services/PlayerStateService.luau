--!strict
-- Sends each player a snapshot of their own state whenever it changes (coalesced per frame),
-- handles the language preference, and delivers notifications. Other services can add fields to
-- the snapshot with PlayerStateService.addExtra (perks, region policy…).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local Validate = require(Shared.Logic.Validate)
local DataService = require(script.Parent.DataService)
local RemoteGuard = require(script.Parent.RemoteGuard)
local Analytics = require(script.Parent.AnalyticsService)

local PlayerStateService = {}

local pending: { [Player]: boolean } = {}
local stateSync: RemoteEvent
local notify: RemoteEvent
local extras: { (Player, { [string]: any }) -> () } = {}

local function snapshot(player: Player, profile: any): { [string]: any }
	local quests = {}
	for id, rec in profile.quests do
		quests[id] = {
			state = rec.state,
			completions = rec.completions,
			progress = if rec.progress then table.clone(rec.progress) else nil,
		}
	end
	local units = {}
	for id, rec in profile.units do
		units[id] = { copies = rec.copies, trait = rec.trait, at = rec.at }
	end
	local s = {
		qirsh = profile.qirsh,
		lira = profile.lira,
		traitStones = profile.traitStones,
		inventory = table.clone(profile.inventory),
		equipped = table.clone(profile.equipped),
		quests = quests,
		language = profile.settings.language,
		persistent = DataService.isPersistent(),
		-- Tower defense
		units = units,
		loadout = table.clone(profile.loadout),
		summons = table.clone(profile.summons),
		pass = {
			season = profile.pass.season,
			xp = profile.pass.xp,
			premium = profile.pass.premium,
			claimedFree = table.clone(profile.pass.claimedFree),
			claimedPremium = table.clone(profile.pass.claimedPremium),
		},
		daily = table.clone(profile.daily),
		td = {
			matches = profile.td.matches,
			wins = profile.td.wins,
			kills = profile.td.kills,
			cleared = table.clone(profile.td.cleared),
			bestInfinite = profile.td.bestInfinite,
		},
		bundles = table.clone(profile.bundles),
	}
	for _, fn in extras do
		fn(player, s)
	end
	return s
end

local function push(player: Player)
	pending[player] = nil
	local profile = DataService.getProfile(player)
	if profile and player.Parent then
		stateSync:FireClient(player, snapshot(player, profile))
	end
end

function PlayerStateService.schedule(player: Player)
	if pending[player] then
		return
	end
	pending[player] = true
	task.defer(push, player)
end

function PlayerStateService.notify(player: Player, key: string, args: { [string]: any }?)
	if player.Parent then
		notify:FireClient(player, { key = key, args = args })
	end
end

-- Registers a function that adds fields to every snapshot of a player.
function PlayerStateService.addExtra(fn: (Player, { [string]: any }) -> ())
	table.insert(extras, fn)
end

function PlayerStateService.start()
	stateSync = Net.event(Net.Events.StateSync)
	notify = Net.event(Net.Events.Notify)

	DataService.ProfileLoaded:Connect(function(player: Player)
		PlayerStateService.schedule(player)
		Analytics.funnel(player, Analytics.Funnel.Spawned)
	end)
	DataService.ProfileChanged:Connect(PlayerStateService.schedule)

	RemoteGuard.onThrottled = function(player: Player)
		PlayerStateService.notify(player, "notify.slow_down")
	end

	RemoteGuard.event(Net.Events.SetLanguage, RemoteGuard.STRICT, function(player: Player, lang: any)
		if not Validate.isShortString(lang, 4) or (lang ~= "en" and lang ~= "ar") then
			return
		end
		DataService.mutate(player, function(profile)
			if profile.settings.language == lang then
				return false
			end
			profile.settings.language = lang
			return true
		end)
		Analytics.custom(player, "LanguageSet_" .. lang)
	end)
end

return PlayerStateService
