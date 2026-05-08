local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local DogBreeds = require(ReplicatedStorage.Shared.DogBreeds)
local Constants = require(ReplicatedStorage.Shared.Constants)
local PlayerDataService = require(script.Parent.PlayerDataService)

local DogService = {}

local activeFollowers = {}  -- player → { dogId → model }

function DogService.spawnFollower(player, dogId)
	local profile = PlayerDataService.get(player)
	if not profile then return nil end
	local dog = profile.dogs[dogId]
	if not dog then return nil end

	local cap = profile.owns.bigPack and Constants.MAX_FOLLOWERS_BIG_PACK or Constants.MAX_FOLLOWERS_DEFAULT
	activeFollowers[player] = activeFollowers[player] or {}
	local count = 0
	for _ in pairs(activeFollowers[player]) do count += 1 end
	if count >= cap then return nil end

	-- In a fully-built project, we'd clone a rig from ServerStorage here.
	local model = Instance.new("Model")
	model.Name = ("Dog_%s_%s"):format(dog.breed, dog.id:sub(1, 6))
	local hum = Instance.new("Humanoid")
	hum.Parent = model
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 1.5, 3)
	root.Parent = model
	model.PrimaryPart = root
	model.Parent = workspace

	activeFollowers[player][dogId] = model
	return model
end

function DogService.dismissFollower(player, dogId)
	local set = activeFollowers[player]
	if not set then return end
	local model = set[dogId]
	if model then model:Destroy() end
	set[dogId] = nil
end

local PASSIVE_BOND_INTERVAL = 30
local lastTick = 0

RunService.Heartbeat:Connect(function()
	local now = os.clock()
	if now - lastTick < PASSIVE_BOND_INTERVAL then return end
	lastTick = now

	for player, set in pairs(activeFollowers) do
		local profile = PlayerDataService.get(player)
		if profile then
			for dogId in pairs(set) do
				local dog = profile.dogs[dogId]
				if dog then
					dog.bond = math.min(Constants.BOND_MAX, dog.bond + Constants.BOND_PASSIVE_FOLLOW_PER_30S)
				end
			end
		end
	end
end)

function DogService.giveStarter(player)
	local profile = PlayerDataService.get(player)
	if not profile then return end
	if next(profile.dogs) then return end  -- already has dogs
	local rng = Random.new()
	local pool = { "golden_retriever", "labrador", "beagle", "pug", "dachshund" }
	local breedId = pool[rng:NextInteger(1, #pool)]
	PlayerDataService.signDog(profile, breedId, "Regular", 50)
end

return DogService
