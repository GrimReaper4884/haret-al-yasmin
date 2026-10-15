--!strict
-- Localized name tags and quest markers above NPCs, and localized ProximityPrompt text.
-- "!" over a quest giver with work available, "?" over the target of an active errand.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Npcs = require(Shared.Config.Npcs)
local Quests = require(Shared.Config.Quests)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local StateController = require(script.Parent.StateController)
local LocaleController = require(script.Parent.LocaleController)

local NpcLabelController = {}

local TAG = "Npc"

type Label = { model: Model, npcId: string, name: TextLabel, marker: TextLabel, prompt: ProximityPrompt? }
local labels: { [Model]: Label } = {}

local function markerFor(npcId: string): string
	for questId, q in Quests :: any do
		local state = StateController.questState(questId)
		if q.giver == npcId and state == "none" then
			return "!"
		end
		if q.target == npcId and state == "active" then
			return "?"
		end
	end
	return ""
end

local function update(l: Label)
	local def = (Npcs :: any)[l.npcId]
	if not def then
		return
	end
	local t = LocaleController.t
	l.name.Text = t(def.nameKey) .. "\n" .. t(def.roleKey)
	l.marker.Text = markerFor(l.npcId)
	if l.prompt then
		l.prompt.ActionText = t("prompt.talk")
		l.prompt.ObjectText = t(def.nameKey)
	end
end

local function attach(model: Instance)
	if not model:IsA("Model") or labels[model] then
		return
	end
	local npcId = model:GetAttribute("NpcId")
	local head = model:WaitForChild("Head", 10)
	if type(npcId) ~= "string" or not head then
		return
	end
	local gui = Create("BillboardGui", {
		Name = "NpcLabel",
		Adornee = head,
		Size = UDim2.fromOffset(160, 70),
		StudsOffset = Vector3.new(0, 2.6, 0),
		MaxDistance = 60,
		AlwaysOnTop = false,
		LightInfluence = 0,
		Parent = head,
	})
	local marker = Theme.label({
		TextSize = 30,
		FontFace = Theme.fontBold,
		TextColor3 = Theme.colors.accent,
		TextStrokeTransparency = 0.4,
		Size = UDim2.new(1, 0, 0, 30),
		Parent = gui,
	})
	local name = Theme.label({
		TextSize = 15,
		FontFace = Theme.fontBold,
		TextColor3 = Theme.colors.buttonText,
		TextStrokeTransparency = 0.3,
		Position = UDim2.fromOffset(0, 30),
		Size = UDim2.new(1, 0, 0, 40),
		Parent = gui,
	})
	local root = model:FindFirstChild("HumanoidRootPart")
	local prompt = root and root:FindFirstChildOfClass("ProximityPrompt")
	local l: Label = { model = model, npcId = npcId, name = name, marker = marker, prompt = prompt }
	labels[model] = l
	update(l)
end

local function updateAll()
	for _, l in labels do
		update(l)
	end
end

function NpcLabelController.start()
	CollectionService:GetInstanceAddedSignal(TAG):Connect(function(m)
		task.spawn(attach, m)
	end)
	CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(m)
		labels[m :: Model] = nil
	end)
	for _, m in CollectionService:GetTagged(TAG) do
		task.spawn(attach, m)
	end
	StateController.Changed:Connect(updateAll)
	LocaleController.Changed:Connect(updateAll)
end

return NpcLabelController
