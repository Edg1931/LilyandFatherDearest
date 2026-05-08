local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local Constants = require(game.ReplicatedStorage.Shared.Constants)

local PROFILE_VERSION = 1
local store = DataStoreService:GetDataStore("PawprintProfile_v" .. PROFILE_VERSION)

local PlayerDataService = {}
PlayerDataService.__index = PlayerDataService

local profiles = {}

local function emptyProfile()
	return {
		version = PROFILE_VERSION,
		coins = Constants.STARTING_COINS,
		treats = 0,
		dogs = {},                -- dogId → DogRecord
		followers = {},           -- ordered list of dogIds
		decor = {},               -- placed items on plot
		decorSlots = Constants.PLOT_DECOR_BASE_SLOTS,
		discoveredBreeds = {},
		stats = {
			totalQuests = 0,
			totalGrooms = 0,
			tierUpsAchieved = 0,
			daysActive = 0,
		},
		lastLogin = 0,
		owns = {                  -- properties / gamepasses
			vet = false,
			bigPack = false,
		},
	}
end

function PlayerDataService.get(player)
	return profiles[player.UserId]
end

function PlayerDataService.modify(player, mutator)
	local p = profiles[player.UserId]
	if not p then return nil end
	mutator(p)
	return p
end

function PlayerDataService.signDog(profile, breedId, tier, bond)
	local id = HttpService:GenerateGUID(false)
	local seedHash = HttpService:GenerateGUID(false)  -- in production: HMAC over (ownerId, id, seed) with server secret
	local dog = {
		id = id,
		breed = breedId,
		tier = tier or "Regular",
		bond = bond or 0,
		traits = {},
		groomingStreak = 0,
		questsThisCycle = {},
		seedHash = seedHash,
		signedAt = os.time(),
	}
	profile.dogs[id] = dog
	profile.discoveredBreeds[breedId] = true
	return dog
end

local function load(userId)
	local ok, data = pcall(function() return store:GetAsync("u_" .. userId) end)
	if ok and data and data.version == PROFILE_VERSION then
		return data
	end
	return emptyProfile()
end

local function save(userId, data)
	pcall(function()
		store:SetAsync("u_" .. userId, data)
	end)
end

Players.PlayerAdded:Connect(function(player)
	local profile = load(player.UserId)
	profile.lastLogin = os.time()
	profiles[player.UserId] = profile
end)

Players.PlayerRemoving:Connect(function(player)
	local profile = profiles[player.UserId]
	if profile then save(player.UserId, profile) end
	profiles[player.UserId] = nil
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		local p = profiles[player.UserId]
		if p then save(player.UserId, p) end
	end
end)

return PlayerDataService
