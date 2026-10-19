--!strict
-- Studio-only test hook. The Studio command bar runs in a separate Lua VM, so `require` there
-- returns fresh module copies; this BindableFunction reaches the live server state instead.
-- Never created outside Studio.
--   local D = game.ServerStorage.HaretDebug
--   print(D:Invoke("state"))         -- live profile as JSON (first player)
--   print(D:Invoke("match", "ep4,normal")) -- start a match past the requires chain (no unlock written)
--   print(D:Invoke("peek"))          -- what the (mock) store holds
--   print(D:Invoke("ledger"))        -- audit ledger (Logic/Ledger) as JSON, newest last
--   print(D:Invoke("funnel"))        -- onboarding funnel rows with seconds since join (P2-16)
--   print(D:Invoke("funnel", "reset")) -- forget the stamps and restart the join clock (Studio timing runs)
--   print(D:Invoke("reload"))        -- save + release + load again
--   print(D:Invoke("failNext", 3))   -- next 3 store calls fail (mock only)
--   print(D:Invoke("fuzz", "begin")) -- red-team window: snapshot the profile, count throttles (P3-09)
--   print(D:Invoke("fuzz", "end"))   -- close it: JSON report (profile unchanged?, throttles, errors)
--   print(D:Invoke("foreignLock"))   -- another server "holds" this profile's lock (then "reload" must refuse)
--   print(D:Invoke("foreignLock", "clear")) -- release it again ("clear <userId>" once the player is kicked)
--   print(D:Invoke("qirsh", 500))    -- grant test qirsh (Studio only)
--   print(D:Invoke("lira", 5000))    -- grant test lira and 5 trait stones (Studio only)
--   print(D:Invoke("spawn", "porter,drummer")) -- queue attackers into the running wave, 1 per second
--   print(D:Invoke("ally", "adashari,3"))  -- a story ally at your feet (no profile change)

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
local FunnelService = require(script.Parent.FunnelService)
local RemoteFuzz = require(script.Parent.RemoteFuzz)
local MonetizationService = require(script.Parent.MonetizationService)
local NpcService = require(script.Parent.NpcService)
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
	-- P3-09 session-lock test on one client: writes (or clears) a fresh lock owned by another job on
	-- the profile's record, nothing else. A following "reload" must then refuse to save (lock lost →
	-- kick) and refuse to load (locked), exactly as a second server would be. The kick removes the
	-- player, so the clear is also reachable without one: D:Invoke("foreignLock", "clear <userId>").
	local function foreignLock(userId: number, clear: boolean): any
		local key = Economy.KEY_PREFIX .. tostring(userId)
		local ok, err = pcall(function()
			DataService.debug.store():update(key, function(record: any)
				if type(record) ~= "table" then
					return nil
				end
				record.lock = if clear then nil else { jobId = "redteam-other-server", at = os.time() }
				return record, { userId }
			end)
		end)
		return if ok then true else "store error: " .. tostring(err)
	end
	local function run(player: Player, cmd: string, arg: any): any
		if cmd == "state" then
			local p = DataService.getProfile(player)
			return if p then HttpService:JSONEncode(p) else "not loaded"
		elseif cmd == "peek" then
			return HttpService:JSONEncode(DataService.debug.store():peek("u_" .. player.UserId))
		elseif cmd == "ledger" then
			return HttpService:JSONEncode(DataService.ledger(player))
		elseif cmd == "funnel" then
			-- "reset" re-stamps join at now so a harness run can be timed again (stamps are lifetime)
			if arg == "reset" then
				return DataService.mutate(player, function(profile)
					profile.funnel = { join = os.time() }
					return true
				end)
			end
			return HttpService:JSONEncode(FunnelService.report(player))
		elseif cmd == "reload" then
			return DataService.debug.reload(player)
		elseif cmd == "save" then
			DataService.debug.saveNow(player)
			return true
		elseif cmd == "qirsh" then
			local amount = math.clamp(math.floor(tonumber(arg) or 0), 0, 100000)
			return DataService.mutate(player, function(profile)
				return Wallet.add(profile, amount, Economy.MAX_QIRSH)
			end, { src = "debug" })
		elseif cmd == "lira" then
			local amount = math.clamp(math.floor(tonumber(arg) or 0), 0, 100000)
			return DataService.mutate(player, function(profile)
				profile.lira = math.min(profile.lira + amount, TD.MAX_LIRA)
				profile.traitStones += 5
				return true
			end, { src = "debug" })
		elseif cmd == "cash" then
			MatchService.debugAddCash(player, math.clamp(math.floor(tonumber(arg) or 5000), 0, 100000))
			return true
		elseif cmd == "place" then
			local unitId, x, z = string.match(tostring(arg), "^([%w_]+),(-?[%d%.]+),(-?[%d%.]+)$")
			if not unitId then
				return "bad arg"
			end
			return MatchService.debugPlace(player, unitId, tonumber(x) :: number, tonumber(z) :: number)
		elseif cmd == "placeAny" then
			-- "unitId": that unit at your feet in your match, no copy granted (LP-E01; no profile change)
			return MatchService.debugPlaceUnowned(player, tostring(arg))
		elseif cmd == "ally" then
			-- "unitId,level": a story ally at your feet (S1-S12 checks; no profile change)
			local unitId, lvl = string.match(tostring(arg), "^([%w_]+),(%d+)$")
			if not unitId then
				return "bad arg"
			end
			return MatchService.debugAlly(player, unitId, tonumber(lvl) :: number)
		elseif cmd == "match" then
			-- "mode,difficulty": start that match for you alone, past the requires chain (S1-S04 checks
			-- of episodes the profile has not unlocked; leave with H before the end to keep rewards out)
			local modeId, diff = string.match(tostring(arg), "^([%w_]+),(%a+)$")
			if not modeId then
				return "bad arg"
			end
			local match, err = MatchService.create(modeId, diff :: string, { player }, player)
			return if match then "ok" else tostring(err)
		elseif cmd == "spawn" then
			-- "id,id,…": queue these attackers into the running wave, one per second (S1-S03 checks)
			return MatchService.debugSpawn(player, string.split(tostring(arg), ","), 1)
		elseif cmd == "grant" then
			-- "id,id,…": own these units and make them the loadout (play-testing specific figures)
			local ids = string.split(tostring(arg), ",")
			return DataService.mutate(player, function(profile)
				for _, id in ids do
					if not profile.units[id] then
						profile.units[id] = { copies = 0, trait = "steady", at = os.time() }
					end
				end
				profile.loadout = ids
				return true
			end)
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
		elseif cmd == "fuzz" then
			if arg == "begin" then
				return RemoteFuzz.begin(player)
			end
			return RemoteFuzz.finish()
		elseif cmd == "foreignLock" then
			return foreignLock(player.UserId, arg == "clear")
		elseif cmd == "perk" then
			-- "vip" | "fast" | "slot", or "-fast" to drop it: this session's perk flag only (LP-A03 checks)
			local off, perk = string.match(tostring(arg), "^(%-?)([%a]+)$")
			if not perk then
				return "bad arg"
			end
			return MonetizationService.debugPerk(player, perk, off ~= "-")
		elseif cmd == "policy" then
			-- "restricted" | "open" | "clear": this session's paid-random-items policy (LP-F05 checks; no profile change)
			if arg == "restricted" or arg == "open" then
				MonetizationService.debugRestricted(player, arg == "restricted")
			elseif arg == "clear" then
				MonetizationService.debugRestricted(player, nil)
			else
				return "bad arg"
			end
			return MonetizationService.isRestricted(player)
		elseif cmd == "storyClear" then
			-- S1-A08 checks: show the figures gated on a story clear for this session ("off" hides them); no profile change
			player:SetAttribute("HarnessStoryClear", arg ~= "off")
			return true
		elseif cmd == "noAutoAfk" then
			-- Studio runs driven through MCP send no input: keep the idle walk to the AFK room off
			player:SetAttribute("HarnessNoAutoAfk", arg ~= "off")
			return true
		elseif cmd == "npcs" then
			-- LP-D02: show the NPCs still waiting for their zone at their provisional spots
			return NpcService.spawnWaiting()
		end
		return "unknown command"
	end
	fn.OnInvoke = function(cmd: string, arg: any): any
		local player = Players:GetPlayers()[1]
		if not player then
			local clearId = if cmd == "foreignLock" then tonumber(string.match(tostring(arg), "^clear%s+(%d+)$")) else nil
			if clearId then
				return foreignLock(clearId, true)
			end
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
		end, { src = "debug" })
	end)
end

return DebugService
