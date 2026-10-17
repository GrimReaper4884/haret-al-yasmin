--!strict
-- Studio-only red-team harness (BUILD_PLAN P3-09, docs/review/REDTEAM_P3-09.md). The fuzzed calls
-- come from a Client-context execute_luau (every remote in Shared/Net, 1,000 calls each with hostile
-- arguments; the driver is quoted in the review doc). This module measures the server side of that
-- window: a checksum of the live profile before and after, how often the rate limiter tripped, every
-- [RemoteGuard] handler error and every other warning or error, and whether the player ended up in a
-- match or the AFK room. Only DebugService requires it, and only in Studio.
--   D:Invoke("fuzz", "begin")  -- snapshot the profile and start counting
--   D:Invoke("fuzz", "end")    -- close the window; report as JSON

local HttpService = game:GetService("HttpService")
local LogService = game:GetService("LogService")
local RunService = game:GetService("RunService")

local DataService = require(script.Parent.DataService)
local RemoteGuard = require(script.Parent.RemoteGuard)
local MatchService = require(script.Parent.MatchService)
local AfkService = require(script.Parent.AfkService)

local RemoteFuzz = {}

-- Throttle toasts let through during a window (the rest are counted only, so a 40,000-call flood
-- does not bury the Studio client in Notify events).
local TOAST_SAMPLE = 5

type Window = {
	player: Player,
	startedAt: number,
	before: string,
	ledgerBefore: number,
	position: Vector3?,
	throttles: number,
	handlerErrors: { string },
	other: { string },
	connection: RBXScriptConnection,
	prevThrottled: ((Player) -> ())?,
}

local window: Window? = nil

local function encode(player: Player): (string, number)
	local profile = DataService.getProfile(player)
	if not profile then
		return "", 0
	end
	return HttpService:JSONEncode(profile), #DataService.ledger(player)
end

local function rootPosition(player: Player): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return if root then root.Position else nil
end

function RemoteFuzz.begin(player: Player): string
	assert(RunService:IsStudio(), "RemoteFuzz is Studio-only")
	if window then
		RemoteFuzz.finish()
	end
	local before, ledgerBefore = encode(player)
	local w: Window = {
		player = player,
		startedAt = os.clock(),
		before = before,
		ledgerBefore = ledgerBefore,
		position = rootPosition(player),
		throttles = 0,
		handlerErrors = {},
		other = {},
		connection = nil :: any,
		prevThrottled = RemoteGuard.onThrottled,
	}
	w.connection = LogService.MessageOut:Connect(function(message: string, messageType: Enum.MessageType)
		if messageType == Enum.MessageType.MessageOutput then
			return
		end
		if string.find(message, "[RemoteGuard]", 1, true) then
			table.insert(w.handlerErrors, message)
		else
			table.insert(w.other, message)
		end
	end)
	RemoteGuard.onThrottled = function(p: Player)
		w.throttles += 1
		if w.throttles <= TOAST_SAMPLE and w.prevThrottled then
			w.prevThrottled(p)
		end
	end
	window = w
	return string.format("fuzz window open: profile %d bytes, ledger %d entries", #before, ledgerBefore)
end

function RemoteFuzz.finish(): string
	local w = window
	if not w then
		return HttpService:JSONEncode({ error = "no fuzz window open" })
	end
	window = nil
	w.connection:Disconnect()
	RemoteGuard.onThrottled = w.prevThrottled
	local after, ledgerAfter = encode(w.player)
	local changed = {}
	if after ~= w.before then
		local a = HttpService:JSONDecode(w.before)
		local b = HttpService:JSONDecode(after)
		for k, v in a do
			if HttpService:JSONEncode(v) ~= HttpService:JSONEncode(b[k]) then
				table.insert(changed, k)
			end
		end
		for k in b do
			if a[k] == nil then
				table.insert(changed, k)
			end
		end
		table.sort(changed)
	end
	local pos = rootPosition(w.player)
	return HttpService:JSONEncode({
		seconds = math.floor((os.clock() - w.startedAt) * 10 + 0.5) / 10,
		profileUnchanged = after == w.before,
		profileBytes = #after,
		changedKeys = changed,
		ledgerBefore = w.ledgerBefore,
		ledgerAfter = ledgerAfter,
		throttles = w.throttles,
		handlerErrors = w.handlerErrors,
		otherMessages = w.other,
		inMatch = MatchService.matchOf(w.player) ~= nil,
		matches = MatchService.count(),
		inAfk = AfkService.isInside(w.player),
		movedStuds = if w.position and pos then math.floor((pos - w.position).Magnitude * 10 + 0.5) / 10 else -1,
	})
end

return RemoteFuzz
