--!strict
-- Shop sessions, purchases and wearing cosmetics. The client names only an item id; the shop,
-- the price and ownership all come from server state and config.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local Items = require(Shared.Config.Items)
local Shops = require(Shared.Config.Shops)
local ShopLogic = require(Shared.Logic.ShopLogic)
local Validate = require(Shared.Logic.Validate)
local DataService = require(script.Parent.DataService)
local PlayerStateService = require(script.Parent.PlayerStateService)
local RemoteGuard = require(script.Parent.RemoteGuard)
local NpcService = require(script.Parent.NpcService)
local AvatarService = require(script.Parent.AvatarService)
local Analytics = require(script.Parent.AnalyticsService)

local ShopService = {}

type Session = { shopId: string, npcId: string }
local sessions: { [Player]: Session } = {}

local ERR_TO_NOTIFY: { [string]: string } = {
	insufficient_funds = "notify.cannot_afford",
	already_owned = "notify.already_owned",
}

function ShopService.open(player: Player, shopId: string, npcId: string): boolean
	local shop = (Shops :: any)[shopId]
	if not shop or shop.npc ~= npcId then
		return false
	end
	sessions[player] = { shopId = shopId, npcId = npcId }
	Net.event(Net.Events.ShopShow):FireClient(player, shopId)
	Analytics.custom(player, "ShopOpened")
	return true
end

function ShopService.close(player: Player)
	sessions[player] = nil
end

local function purchase(player: Player, itemId: any): { [string]: any }
	if not Validate.isIdentifier(itemId) then
		return { ok = false, err = "bad_request" }
	end
	local session = sessions[player]
	if not session then
		return { ok = false, err = "no_shop" }
	end
	if not NpcService.inRange(player, session.npcId) then
		sessions[player] = nil
		PlayerStateService.notify(player, "notify.too_far")
		return { ok = false, err = "too_far" }
	end
	local shop = (Shops :: any)[session.shopId]
	local ok, err, price = DataService.mutate(player, function(profile)
		return ShopLogic.purchase(profile, shop, itemId, Items :: any)
	end)
	if not ok then
		PlayerStateService.notify(player, ERR_TO_NOTIFY[err :: string] or "notify.error")
		return { ok = false, err = err }
	end
	local def = (Items :: any)[itemId]
	local profile = DataService.getProfile(player)
	PlayerStateService.notify(player, "notify.purchased", { itemKey = def.nameKey })
	Analytics.sink(player, price, if profile then profile.qirsh else 0, itemId)
	Analytics.funnel(player, Analytics.Funnel.FirstPurchase)
	return { ok = true }
end

local function setWorn(player: Player, itemId: any, wear: any): { [string]: any }
	if not Validate.isIdentifier(itemId) or type(wear) ~= "boolean" then
		return { ok = false, err = "bad_request" }
	end
	local ok, err = DataService.mutate(player, function(profile)
		return ShopLogic.setWorn(profile, itemId, wear, Items :: any)
	end)
	if not ok then
		return { ok = false, err = err }
	end
	AvatarService.refresh(player)
	local def = (Items :: any)[itemId]
	PlayerStateService.notify(
		player,
		if wear then "notify.equipped" else "notify.unequipped",
		{ itemKey = def.nameKey }
	)
	return { ok = true }
end

function ShopService.start()
	RemoteGuard.func(Net.Functions.ShopPurchase, RemoteGuard.STRICT, purchase)
	RemoteGuard.func(Net.Functions.SetWorn, RemoteGuard.STRICT, setWorn)
	RemoteGuard.event(Net.Events.ShopClose, RemoteGuard.DEFAULT, ShopService.close)
	Players.PlayerRemoving:Connect(ShopService.close)
end

return ShopService
