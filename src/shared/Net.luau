--!strict
-- Remote names and access. The server creates the remotes (Net.serverSetup); clients wait
-- for them (Net.event / Net.func). See docs/SYSTEMS_ARCHITECTURE.md §4.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Net = {}

Net.Events = {
	StateSync = "StateSync", -- S→C snapshot
	DialogueShow = "DialogueShow", -- S→C
	DialogueHide = "DialogueHide", -- S→C
	DialogueChoose = "DialogueChoose", -- C→S choiceIndex
	DialogueClose = "DialogueClose", -- C→S
	ShopShow = "ShopShow", -- S→C shopId
	ShopClose = "ShopClose", -- C→S
	SetLanguage = "SetLanguage", -- C→S "en" | "ar"
	Notify = "Notify", -- S→C { key, args }
}

Net.Functions = {
	ShopPurchase = "ShopPurchase", -- C→S itemId → result
	SetWorn = "SetWorn", -- C→S itemId, wear → result
}

local FOLDER_NAME = "Remotes"

function Net.serverSetup(): Folder
	assert(RunService:IsServer(), "Net.serverSetup is server-only")
	local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if folder then
		folder:Destroy() -- never trust pre-existing remotes
	end
	local newFolder = Instance.new("Folder")
	newFolder.Name = FOLDER_NAME
	for _, name in Net.Events do
		local r = Instance.new("RemoteEvent")
		r.Name = name :: string
		r.Parent = newFolder
	end
	for _, name in Net.Functions do
		local r = Instance.new("RemoteFunction")
		r.Name = name :: string
		r.Parent = newFolder
	end
	newFolder.Parent = ReplicatedStorage
	return newFolder
end

local function folder(): Instance
	return ReplicatedStorage:WaitForChild(FOLDER_NAME)
end

function Net.event(name: string): RemoteEvent
	return folder():WaitForChild(name) :: RemoteEvent
end

function Net.func(name: string): RemoteFunction
	return folder():WaitForChild(name) :: RemoteFunction
end

return Net
