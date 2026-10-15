--!strict
-- Studio-only test hook. The Studio command bar runs in a separate Lua VM, so `require` there
-- returns fresh module copies; this BindableFunction reaches the live server state instead.
-- Never created outside Studio.
--   local D = game.ServerStorage.HaretDebug
--   print(D:Invoke("state"))         -- live profile as JSON (first player)
--   print(D:Invoke("peek"))          -- what the (mock) store holds
--   print(D:Invoke("reload"))        -- save + release + load again
--   print(D:Invoke("failNext", 3))   -- next 3 store calls fail (mock only)

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local DataService = require(script.Parent.DataService)

local DebugService = {}

function DebugService.start()
	if not RunService:IsStudio() then
		return
	end
	local fn = Instance.new("BindableFunction")
	fn.Name = "HaretDebug"
	fn.OnInvoke = function(cmd: string, arg: any): any
		local player = Players:GetPlayers()[1]
		if not player then
			return "no player"
		end
		if cmd == "state" then
			local p = DataService.getProfile(player)
			return if p then HttpService:JSONEncode(p) else "not loaded"
		elseif cmd == "peek" then
			return HttpService:JSONEncode(DataService.debug.store():peek("u_" .. player.UserId))
		elseif cmd == "reload" then
			return DataService.debug.reload(player)
		elseif cmd == "save" then
			DataService.debug.saveNow(player)
			return true
		elseif cmd == "failNext" then
			DataService.debug.store():failNext(tonumber(arg) or 1)
			return true
		end
		return "unknown command"
	end
	fn.Parent = ServerStorage
end

return DebugService
