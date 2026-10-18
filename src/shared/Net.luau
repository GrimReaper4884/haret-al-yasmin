--!strict
-- Remote names and access. The server creates the remotes (Net.serverSetup); clients wait
-- for them (Net.event / Net.func / Net.unreliable). See docs/SYSTEMS_ARCHITECTURE.md §4.

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
	SetSetting = "SetSetting", -- C→S key, value (Logic/Settings validates)
	Notify = "Notify", -- S→C { key, args }
	ClueShow = "ClueShow", -- S→C clueId (clue card)
	RequestProduct = "RequestProduct", -- C→S product key (server validates, then prompts)
	RequestPass = "RequestPass", -- C→S game pass key

	-- Tower defense: lobby queue
	QueueState = "QueueState", -- S→C { partyId, modeId, players, countdown, difficulty, host, max } | nil
	QueueLeave = "QueueLeave", -- C→S
	QueueSetDifficulty = "QueueSetDifficulty", -- C→S difficulty (host only)
	PartyStart = "PartyStart", -- C→S (host only) start the countdown's last seconds now
	PartyList = "PartyList", -- S→C { { id, modeId, difficulty, host, count, max, countdown } }
	-- Tower defense: match
	MatchStart = "MatchStart", -- S→C { matchId, modeId, arenaId, origin, difficulty, players, totalWaves }
	MatchState = "MatchState", -- S→C { phase, wave, countdown, gateHp, gateMax, cash, speed, votes }
	MatchEvents = "MatchEvents", -- S→C { events } (spawn/death/attack/tower…)
	MatchEnd = "MatchEnd", -- S→C { won, waves, reward }
	MatchHome = "MatchHome", -- S→C matchId: the player is back in the lane (drop the match HUD now)
	EnemyPositions = "EnemyPositions", -- S→C (unreliable) { seq, then id, dist, hpFrac triples }, ≤ 24 enemies per packet
	VoteSkip = "VoteSkip", -- C→S
	SetSpeed = "SetSpeed", -- C→S 1 | 2 | 3 (host)
	LeaveMatch = "LeaveMatch", -- C→S
	SetTargeting = "SetTargeting", -- C→S towerId, mode
	UseAbility = "UseAbility", -- C→S towerId (the defender's ultimate)
	-- AFK chamber (the Hakawati's room)
	AfkState = "AfkState", -- S→C { inside, carry, mult, session = { seconds, lira, qirsh, xp, traitStones } } | { inside = false, summary }
	AfkPayout = "AfkPayout", -- S→C { kind, granted, capped, tale }
	AfkEnter = "AfkEnter", -- C→S reason ("menu" | "idle")
	AfkLeave = "AfkLeave", -- C→S
	AfkHop = "AfkHop", -- C→S (idle for IDLE_HOP_SECONDS inside the room)
	DebugCommand = "DebugCommand", -- C→S (Studio only; ignored in production) cmd, arg
}

Net.Unreliable = {
	EnemyPositions = true,
}

Net.Functions = {
	ShopPurchase = "ShopPurchase", -- C→S itemId → result
	SetWorn = "SetWorn", -- C→S itemId, wear → result
	-- Tower defense
	PlaceTower = "PlaceTower", -- C→S unitId, x, z → { ok, err, towerId }
	UpgradeTower = "UpgradeTower", -- C→S towerId → { ok, err }
	SellTower = "SellTower", -- C→S towerId → { ok, err, refund }
	Summon = "Summon", -- C→S n → { ok, err, results }
	SetLoadout = "SetLoadout", -- C→S { unitIds } → { ok, err }
	RerollTrait = "RerollTrait", -- C→S unitId, slot? → { ok, err, trait }
	SetBead = "SetBead", -- C→S unitId, slot (1..3), bead kind → { ok, err }
	ClaimPass = "ClaimPass", -- C→S tier, track → { ok, err, granted }
	RedeemCode = "RedeemCode", -- C→S code → { ok, err, granted }
	ClaimDaily = "ClaimDaily", -- C→S → { ok, err, granted, day }
	PartyCreate = "PartyCreate", -- C→S modeId, difficulty → { ok, err }
	PartyJoin = "PartyJoin", -- C→S partyId → { ok, err }
	PartyReplay = "PartyReplay", -- C→S "replay" | "next" → { ok, err }
	EventBuy = "EventBuy", -- C→S eventId, shop key → { ok, err, granted }
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
		local r: Instance = if Net.Unreliable[name] then Instance.new("UnreliableRemoteEvent") else Instance.new("RemoteEvent")
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

function Net.unreliable(name: string): UnreliableRemoteEvent
	return folder():WaitForChild(name) :: UnreliableRemoteEvent
end

function Net.func(name: string): RemoteFunction
	return folder():WaitForChild(name) :: RemoteFunction
end

return Net
