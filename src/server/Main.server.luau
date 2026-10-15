--!strict
-- Server bootstrap. Order matters: remotes first, then world, then gameplay services, and
-- DataService.start last so every listener is connected before the first profile loads.

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage:WaitForChild("Shared").Net)
Net.serverSetup()

local Services = ServerScriptService:WaitForChild("Server"):WaitForChild("Services")
local DataService = require(Services.DataService)
local WorldService = require(Services.WorldService)
local NpcService = require(Services.NpcService)
local AvatarService = require(Services.AvatarService)
local PlayerStateService = require(Services.PlayerStateService)
local ShopService = require(Services.ShopService)
local DialogueService = require(Services.DialogueService)
local ClueService = require(Services.ClueService)
local DebugService = require(Services.DebugService)
local MonetizationService = require(Services.MonetizationService)
local PlayerCollisionService = require(Services.PlayerCollisionService)

DataService.init()
WorldService.build()
NpcService.start()
PlayerCollisionService.start()
AvatarService.start()
PlayerStateService.start()
ShopService.start()
DialogueService.start()
ClueService.start()
MonetizationService.start()
DataService.start()
DebugService.start() -- Studio only

print("[HaretAlYasmin] server ready")
