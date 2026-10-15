--!strict
-- Studio-only keyboard harness so play-tests can be driven without the mouse:
--   1 Units · 2 Summon · 3 Diary · 4 Codes · 5 Daily · 6 Store · 7 Summon ×1 · 8 Summon ×10
--   9 teleport to the Episode 1 portal · 0 teleport to the square · L fill the loadout with the
--   best owned units · X close every screen
--   In a match: P place the next loadout unit at your feet · B place it at a road-side spot · U upgrade the last tower you placed
--   · K vote skip · J sell the last tower · T set speed 2x · C +5000 match cash · H leave · G set the gate to 1 HP.
-- Never created outside Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local Units = require(Shared.Config.Units)
local TD = require(Shared.Config.TD)
local StateController = require(script.Parent.StateController)
local ShopController = require(script.Parent.ShopController)
local SummonController = require(script.Parent.SummonController)
local UnitsController = require(script.Parent.UnitsController)
local PassController = require(script.Parent.PassController)
local CodesController = require(script.Parent.CodesController)
local DailyController = require(script.Parent.DailyController)
local MatchController = require(script.Parent.MatchController)
local Modal = require(script.Parent.Parent.UI.Modal)

local DebugKeysController = {}

local lastTower: number? = nil
local placeIndex = 1
local spotIndex = 1
-- Road-side spots in the orchard arena (local coords), for the B key
local SPOTS = { { 18, 0 }, { 18, 10 }, { 6, -10 }, { -22, 0 }, { -34, 4 }, { 44, 12 }, { 56, 0 }, { -58, -10 } }

local function placeAtFeet()
	local snapshot = StateController.get()
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not snapshot or not root or #snapshot.loadout == 0 then
		return
	end
	local unitId = snapshot.loadout[((placeIndex - 1) % #snapshot.loadout) + 1]
	placeIndex += 1
	-- Slightly in front of the character so towers don't stack on the player
	local pos = root.Position + root.CFrame.LookVector * 3
	task.spawn(function()
		local ok, r = pcall(function()
			return Net.func(Net.Functions.PlaceTower):InvokeServer(unitId, pos.X, pos.Z)
		end)
		if ok and type(r) == "table" then
			print("[DebugKeys] place", unitId, r.ok, r.err, r.towerId)
			if r.ok then
				lastTower = r.towerId
			end
		end
	end)
end

function DebugKeysController.start()
	if not RunService:IsStudio() then
		return
	end
	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed or input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end
		local k = input.KeyCode
		if MatchController.active() then
			if k == Enum.KeyCode.P then
				placeAtFeet()
			elseif k == Enum.KeyCode.B then
				local snapshot = StateController.get()
				if snapshot and #snapshot.loadout > 0 then
					local unitId = snapshot.loadout[((placeIndex - 1) % #snapshot.loadout) + 1]
					local spot = SPOTS[((spotIndex - 1) % #SPOTS) + 1]
					placeIndex += 1
					spotIndex += 1
					Net.event(Net.Events.DebugCommand):FireServer("place", unitId .. "," .. spot[1] .. "," .. spot[2])
				end
			elseif k == Enum.KeyCode.U and lastTower then
				task.spawn(function()
					local ok, r = pcall(function()
						return Net.func(Net.Functions.UpgradeTower):InvokeServer(lastTower)
					end)
					print("[DebugKeys] upgrade", ok, r and r.ok, r and r.err)
				end)
			elseif k == Enum.KeyCode.J and lastTower then
				task.spawn(function()
					pcall(function()
						return Net.func(Net.Functions.SellTower):InvokeServer(lastTower)
					end)
				end)
			elseif k == Enum.KeyCode.K then
				Net.event(Net.Events.VoteSkip):FireServer()
			elseif k == Enum.KeyCode.T then
				Net.event(Net.Events.SetSpeed):FireServer(2)
			elseif k == Enum.KeyCode.C then
				Net.event(Net.Events.DebugCommand):FireServer("cash", 5000)
			elseif k == Enum.KeyCode.H then
				Net.event(Net.Events.LeaveMatch):FireServer()
			elseif k == Enum.KeyCode.G then
				Net.event(Net.Events.DebugCommand):FireServer("gate", 1)
			end
			return
		end
		if k == Enum.KeyCode.X then
			Modal.closeAll()
		elseif k == Enum.KeyCode.One then
			UnitsController.open()
		elseif k == Enum.KeyCode.Two then
			SummonController.open()
		elseif k == Enum.KeyCode.Three then
			PassController.open()
		elseif k == Enum.KeyCode.Four then
			CodesController.open()
		elseif k == Enum.KeyCode.Five then
			DailyController.open()
		elseif k == Enum.KeyCode.Six then
			ShopController.openStore()
		elseif k == Enum.KeyCode.Nine then
			Net.event(Net.Events.DebugCommand):FireServer("tp", "ep1")
		elseif k == Enum.KeyCode.Zero then
			Net.event(Net.Events.DebugCommand):FireServer("tp", "0,-5")
		elseif k == Enum.KeyCode.L then
			local snapshot = StateController.get()
			if snapshot then
				local rank = { secret = 6, mythic = 5, legendary = 4, epic = 3, rare = 2 }
				local ids = {}
				for id in snapshot.units do
					if (Units :: any)[id] then
						table.insert(ids, id)
					end
				end
				table.sort(ids, function(a, b)
					local ra, rb = rank[(Units :: any)[a].rarity] or 0, rank[(Units :: any)[b].rarity] or 0
					if ra ~= rb then
						return ra > rb
					end
					return a < b
				end)
				local list = {}
				for i = 1, math.min(#ids, snapshot.loadoutSlots or TD.LOADOUT_SLOTS) do
					list[i] = ids[i]
				end
				task.spawn(function()
					local ok, r = pcall(function()
						return Net.func(Net.Functions.SetLoadout):InvokeServer(list)
					end)
					print("[DebugKeys] loadout", ok, r and r.ok, r and r.err, table.concat(list, ","))
				end)
			end
		elseif k == Enum.KeyCode.Seven or k == Enum.KeyCode.Eight then
			local n = if k == Enum.KeyCode.Seven then 1 else 10
			task.spawn(function()
				local ok, r = pcall(function()
					return Net.func(Net.Functions.Summon):InvokeServer(n)
				end)
				print("[DebugKeys] summon", n, ok, r and r.ok, r and r.err)
				if ok and type(r) == "table" and r.ok then
					SummonController.showResults(r.results)
				end
			end)
		end
	end)
end

return DebugKeysController
