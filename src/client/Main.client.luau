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

StateController.start()
LocaleController.start()
HudController.start()
DialogueController.start()
ShopController.start()
ToastController.start()
NpcLabelController.start()
