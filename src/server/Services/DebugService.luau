--!strict
-- Studio-only test hook. The Studio command bar runs in a separate Lua VM, so `require` there
-- returns fresh module copies; this BindableFunction reaches the live server state instead.
-- Never created outside Studio.
--   local D = game.ServerStorage.HaretDebug
--   print(D:Invoke("state"))         -- live profile as JSON (first player)
--   print(D:Invoke("peek"))          -- what the (mock) store holds
--   print(D:Invoke("reload"))        -- save + release + load again
--   print(D:Invoke("failNext", 3))   -- next 3 store calls fail (mock only)
--   print(D:Invoke("qirsh", 500))    -- grant test qirsh (Studio only)
--   print(D:Invoke("lira", 5000))    -- grant test lira and 5 trait stones (Studio only)

local HttpService = game:GetService("HttpService")
local Net = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").Net)
local LogService = game:GetService("LogService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local MatchService = require(script.Parent.MatchService)
local AfkService = require(script.Parent.AfkService)
local Wallet = require(ReplicatedStorage:WaitForChild("Shared").Logic.Wallet)
local Economy = require(ReplicatedStorage:WaitForChild("Shared").Config.Economy)
local TD = require(ReplicatedStorage:WaitForChild("Shared").Config.TD)

local DebugService = {}

function DebugService.start()
	if not RunService:IsStudio() then
		return
	end
	-- Mirror warnings and errors into ServerStorage.HaretLog so they can be read from the
	-- Explorer (Server view) when the Output window isn't available.
	local log = Instance.new("StringValue")
	log.Name = "HaretLog"
	log.Parent = ReplicatedStorage -- replicated so the client's Studio overlay can show it
	local lines = {}
	LogService.MessageOut:Connect(function(message: string, messageType: Enum.MessageType)
		if messageType ~= Enum.MessageType.MessageOutput then
			table.insert(lines, message)
			if #lines > 40 then
				table.remove(lines, 1)
			end
			log.Value = table.concat(lines, "\n")
		end
	end)
	local fn = Instance.new("BindableFunction")
	fn.Name = "HaretDebug"
	local function run(player: Player, cmd: string, arg: any): any
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
		elseif cmd == "qirsh" then
			local amount = math.clamp(math.floor(tonumber(arg) or 0), 0, 100000)
			return DataService.mutate(player, function(profile)
				return Wallet.add(profile, amount, Economy.MAX_QIRSH)
			end)
		elseif cmd == "lira" then
			local amount = math.clamp(math.floor(tonumber(arg) or 0), 0, 100000)
			return DataService.mutate(player, function(profile)
				profile.lira = math.min(profile.lira + amount, TD.MAX_LIRA)
				profile.traitStones += 5
				return true
			end)
		elseif cmd == "cash" then
			MatchService.debugAddCash(player, math.clamp(math.floor(tonumber(arg) or 5000), 0, 100000))
			return true
		elseif cmd == "place" then
			local unitId, x, z = string.match(tostring(arg), "^([%w_]+),(-?[%d%.]+),(-?[%d%.]+)$")
			if not unitId then
				return "bad arg"
			end
			return MatchService.debugPlace(player, unitId, tonumber(x) :: number, tonumber(z) :: number)
		elseif cmd == "gate" then
			MatchService.debugSetGate(player, tonumber(arg) or 1)
			return true
		elseif cmd == "tp" then
			-- teleport to x,z given as "x,z" or to a mode portal by id
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not root then
				return "no character"
			end
			local Modes = require(ReplicatedStorage:WaitForChild("Shared").Config.Modes)
			local mode = (Modes :: any)[tostring(arg)]
			if mode then
				root.CFrame = CFrame.new(mode.portal[1], 4, mode.portal[2])
				return true
			end
			local x, z = string.match(tostring(arg), "^(-?[%d%.]+),(-?[%d%.]+)$")
			if x and z then
				root.CFrame = CFrame.new(tonumber(x) :: number, 4, tonumber(z) :: number)
				return true
			end
			return "bad target"
		elseif cmd == "afk" then
			-- "enter" / "leave", or a number of seconds to add to the current visit
			if arg == "enter" then
				return AfkService.enter(player, "debug")
			elseif arg == "leave" then
				AfkService.leave(player, "debug", true)
				return true
			end
			return AfkService.debugAdvance(player, tonumber(arg) or 300)
		elseif cmd == "failNext" then
			DataService.debug.store():failNext(tonumber(arg) or 1)
			return true
		end
		return "unknown command"
	end
	fn.OnInvoke = function(cmd: string, arg: any): any
		local player = Players:GetPlayers()[1]
		if not player then
			return "no player"
		end
		return run(player, cmd, arg)
	end
	fn.Parent = ServerStorage
	-- Same commands from the client's Studio debug keys (DebugKeysController). Studio only.
	Net.event(Net.Events.DebugCommand).OnServerEvent:Connect(function(player: Player, cmd: any, arg: any)
		if type(cmd) == "string" then
			print("[HaretDebug]", cmd, arg, run(player, cmd, arg))
		end
	end)

	-- Test mode (mock store, nothing persists): seed lira and trait stones so summons, traits and
	-- the store can be exercised without Robux or grinding.
	DataService.ProfileLoaded:Connect(function(player: Player)
		if DataService.isPersistent() then
			return
		end
		DataService.mutate(player, function(profile)
			profile.lira = math.max(profile.lira, 5000)
			profile.traitStones = math.max(profile.traitStones, 5)
			return true
		end)
	end)
end

return DebugService
