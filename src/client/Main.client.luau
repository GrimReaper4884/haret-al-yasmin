--!strict
-- Client bootstrap. State and locale first; UI controllers subscribe to them.

local Controllers = script.Parent:WaitForChild("Controllers")

local StateController = require(Controllers.StateController)
local LocaleController = require(Controllers.LocaleController)
local HudController = require(Controllers.HudController)
local DialogueController = require(Controllers.DialogueController)
local ShopController = require(Controllers.ShopController)
local ToastController = require(Controllers.ToastController)
local NpcLabelController = require(Controllers.NpcLabelController)
local ClueController = require(Controllers.ClueController)
local WardrobeController = require(Controllers.WardrobeController)

StateController.start()
LocaleController.start()
HudController.start()
DialogueController.start()
ShopController.start()
ToastController.start()
NpcLabelController.start()
ClueController.start()
WardrobeController.start()
