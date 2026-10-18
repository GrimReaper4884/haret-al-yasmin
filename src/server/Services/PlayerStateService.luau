--!strict
-- Sends each player a snapshot of their own state whenever it changes (coalesced per frame),
-- handles the language preference, and delivers notifications. Other services can add fields to
-- the snapshot with PlayerStateService.addExtra (perks, region policy…).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local Validate = require(Shared.Logic.Validate)
local Settings = require(Shared.Logic.Settings)
local DeviceTelemetry = require(Shared.Logic.DeviceTelemetry)
local Hud = require(Shared.Config.Hud)
local DataService = require(script.Parent.DataService)
local RemoteGuard = require(script.Parent.RemoteGuard)
local Analytics = require(script.Parent.AnalyticsService)

local PlayerStateService = {}

local pending: { [Player]: boolean } = {}
local stateSync: RemoteEvent
local notify: RemoteEvent
local extras: { (Player, { [string]: any }) -> () } = {}
-- The HUD profile each client reported this session (player state, not the profile: MH-17).
local devices: { [Player]: DeviceTelemetry.Session } = {}

-- The device session of a player (created on first use; dropped when they leave).
function PlayerStateService.device(player: Player): DeviceTelemetry.Session
	local s = devices[player]
	if not s then
		s = DeviceTelemetry.newSession()
		devices[player] = s
	end
	return s
end

local function eventsSnapshot(events: { [string]: any }): { [string]: any }
	local out = {}
	for id, rec in events do
		out[id] = { currency = rec.currency, bought = table.clone(rec.bought) }
	end
	return out
end

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
		units[id] = { copies = rec.copies, trait = rec.trait, trait2 = rec.trait2, beads = if rec.beads then table.clone(rec.beads) else nil, at = rec.at }
	end
	local s = {
		qirsh = profile.qirsh,
		lira = profile.lira,
		traitStones = profile.traitStones,
		beads = profile.beads or 0,
		inventory = table.clone(profile.inventory),
		equipped = table.clone(profile.equipped),
		quests = quests,
		language = profile.settings.language,
		settings = Settings.resolve(profile.settings),
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
		events = eventsSnapshot(profile.events),
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
	end)
	DataService.ProfileChanged:Connect(PlayerStateService.schedule)

	RemoteGuard.onThrottled = function(player: Player)
		PlayerStateService.notify(player, "notify.slow_down")
	end

	-- The client's HUD profile, once per session (DeviceTelemetry.report drops the rest).
	RemoteGuard.event(Net.Events.ClientProfile, RemoteGuard.STRICT, function(player: Player, profile: any)
		local session = PlayerStateService.device(player)
		local ok, why = DeviceTelemetry.report(Hud, session, profile)
		if not ok then
			print(string.format("[Telemetry] ClientProfile from %s dropped: %s", player.Name, tostring(why)))
			return
		end
		Analytics.custom(player, "ui_device", DeviceTelemetry.index(Hud, profile), profile)
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		devices[player] = nil
	end)

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

	RemoteGuard.event(Net.Events.SetSetting, RemoteGuard.DEFAULT, function(player: Player, key: any, value: any)
		if not Settings.accept(key, value) then
			return
		end
		DataService.mutate(player, function(profile)
			if profile.settings[key] == value then
				return false
			end
			profile.settings[key] = value
			return true
		end)
	end)
end

return PlayerStateService
