--!strict
-- Every client→server remote is connected through here: per-player rate limiting, error
-- isolation (a handler error never reaches the client), and cleanup on leave.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local RateLimiter = require(Shared.Logic.RateLimiter)

export type Limit = { capacity: number, perSecond: number }

local RemoteGuard = {}

RemoteGuard.DEFAULT = { capacity = 8, perSecond = 4 } :: Limit
RemoteGuard.STRICT = { capacity = 3, perSecond = 1 } :: Limit

local limiters: { RateLimiter.Limiter } = {}

Players.PlayerRemoving:Connect(function(player)
	for _, l in limiters do
		RateLimiter.forget(l, player)
	end
end)

local function makeLimiter(limit: Limit): RateLimiter.Limiter
	local l = RateLimiter.new(limit.capacity, limit.perSecond)
	table.insert(limiters, l)
	return l
end

-- Callback when a player is throttled (set by PlayerStateService to show a toast).
RemoteGuard.onThrottled = nil :: ((Player) -> ())?

function RemoteGuard.event(name: string, limit: Limit, handler: (Player, ...any) -> ())
	local limiter = makeLimiter(limit)
	Net.event(name).OnServerEvent:Connect(function(player: Player, ...)
		if not RateLimiter.allow(limiter, player, os.clock()) then
			if RemoteGuard.onThrottled then
				RemoteGuard.onThrottled(player)
			end
			return
		end
		local ok, err = pcall(handler :: (Player, ...any) -> any, player, ...)
		if not ok then
			warn(string.format("[RemoteGuard] %s handler error for %s: %s", name, player.Name, tostring(err)))
		end
	end)
end

-- Handlers return a result table { ok: boolean, err: string? }; errors become { ok = false, err = "error" }.
function RemoteGuard.func(name: string, limit: Limit, handler: (Player, ...any) -> { [string]: any })
	local limiter = makeLimiter(limit)
	Net.func(name).OnServerInvoke = function(player: Player, ...)
		if not RateLimiter.allow(limiter, player, os.clock()) then
			if RemoteGuard.onThrottled then
				RemoteGuard.onThrottled(player)
			end
			return { ok = false, err = "rate_limited" }
		end
		local ok, result = pcall(handler, player, ...)
		if not ok then
			warn(string.format("[RemoteGuard] %s handler error for %s: %s", name, player.Name, tostring(result)))
			return { ok = false, err = "error" }
		end
		return result
	end
end

return RemoteGuard
