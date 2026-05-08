local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local FOLDER_NAME = "PawprintRemotes"

local function ensureFolder()
	local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end
	return folder
end

local function ensureRemote(name, className)
	local folder = ensureFolder()
	local remote = folder:FindFirstChild(name)
	if not remote then
		remote = Instance.new(className)
		remote.Name = name
		remote.Parent = folder
	end
	return remote
end

Remotes.NAMES = {
	-- Player input verbs (client → server)
	InputAction       = "InputAction",        -- groom / feed / play / pet / interact
	-- Pack management
	SetFollower       = "SetFollower",
	-- Trading
	TradeRequest      = "TradeRequest",
	TradeOfferAdd     = "TradeOfferAdd",
	TradeOfferRemove  = "TradeOfferRemove",
	TradeLock         = "TradeLock",
	TradeConfirm      = "TradeConfirm",
	TradeCancel       = "TradeCancel",
	TradeStateUpdate  = "TradeStateUpdate", -- server → client
	-- Quests
	QuestStart        = "QuestStart",
	QuestSubmit       = "QuestSubmit",
	QuestStateUpdate  = "QuestStateUpdate",
	-- World interaction (quest givers, objectives, props)
	WorldInteract     = "WorldInteract",     -- client → server: { entityId, kind, payload }
	WorldEntitySpawn  = "WorldEntitySpawn",  -- server → client: render this marker
	WorldEntityDespawn= "WorldEntityDespawn",
	-- House
	HousePlace        = "HousePlace",
	HouseRemove       = "HouseRemove",
	HouseVisit        = "HouseVisit",
	HouseLeaveTreat   = "HouseLeaveTreat",
	-- Properties (Vet, etc.)
	BuyProperty       = "BuyProperty",
	-- Shelter
	ShelterDonate     = "ShelterDonate",     -- visitor donates one of their dogs to host
	ShelterIntake     = "ShelterIntake",     -- shelter owner intakes a stray (signs to self)
	ShelterAdoptOut   = "ShelterAdoptOut",   -- shelter owner re-signs stray to a visitor
	ShelterStateUpdate= "ShelterStateUpdate",
	-- Tier rolls
	TierRollAttempt   = "TierRollAttempt",
	TierRollResult    = "TierRollResult",
	-- General profile sync
	ProfileSync       = "ProfileSync",
}

Remotes.EVENTS = {}
Remotes.FUNCTIONS = {}

local function init()
	for _, name in pairs(Remotes.NAMES) do
		Remotes.EVENTS[name] = ensureRemote(name, "RemoteEvent")
	end
	-- Functions used where we need a server response
	Remotes.FUNCTIONS.TradeRequestAck = ensureRemote("TradeRequestAck", "RemoteFunction")
	Remotes.FUNCTIONS.GetProfile      = ensureRemote("GetProfile", "RemoteFunction")
end

init()

return Remotes
