local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Quests = require(ReplicatedStorage.Shared.Quests)
local DogBreeds = require(ReplicatedStorage.Shared.DogBreeds)
local Constants = require(ReplicatedStorage.Shared.Constants)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local PlayerDataService = require(script.Parent.PlayerDataService)

local QuestService = {}

local activeQuest = {}  -- player → { questId, startedAt, partyDogIds }

function QuestService.start(player, questId)
	local quest = Quests.BY_ID[questId]
	if not quest then return false, "no_quest" end
	if activeQuest[player] then return false, "already_active" end
	local profile = PlayerDataService.get(player)
	if not profile then return false, "no_profile" end

	local party = {}
	for _, id in ipairs(profile.followers) do
		local dog = profile.dogs[id]
		if dog then table.insert(party, id) end
	end

	activeQuest[player] = {
		questId = questId,
		startedAt = os.time(),
		partyDogIds = party,
	}
	return true
end

function QuestService.submit(player, questId)
	local active = activeQuest[player]
	if not active or active.questId ~= questId then return false, "not_active" end
	local quest = Quests.BY_ID[questId]
	local profile = PlayerDataService.get(player)
	if not profile then return false, "no_profile" end

	local affinities = {}
	for _, dogId in ipairs(active.partyDogIds) do
		local dog = profile.dogs[dogId]
		if dog then
			local breed = DogBreeds.BY_ID[dog.breed]
			if breed then table.insert(affinities, breed.affinity) end
		end
	end
	local reward = Quests.computeReward(quest, affinities)

	profile.coins += reward.coins
	for _, dogId in ipairs(active.partyDogIds) do
		local dog = profile.dogs[dogId]
		if dog then
			dog.bond = math.min(Constants.BOND_MAX, dog.bond + reward.bond)
			table.insert(dog.questsThisCycle, quest.id)
			if #dog.questsThisCycle > 7 then
				table.remove(dog.questsThisCycle, 1)
			end
		end
	end
	profile.stats.totalQuests = (profile.stats.totalQuests or 0) + 1

	if reward.breedReward then
		PlayerDataService.signDog(profile, reward.breedReward, "Regular", 0)
	end

	activeQuest[player] = nil
	return true, reward
end

Remotes.EVENTS[Remotes.NAMES.QuestStart].OnServerEvent:Connect(function(player, payload)
	if typeof(payload) ~= "table" or typeof(payload.questId) ~= "string" then return end
	QuestService.start(player, payload.questId)
end)

Remotes.EVENTS[Remotes.NAMES.QuestSubmit].OnServerEvent:Connect(function(player, payload)
	if typeof(payload) ~= "table" or typeof(payload.questId) ~= "string" then return end
	local ok, reward = QuestService.submit(player, payload.questId)
	Remotes.EVENTS[Remotes.NAMES.QuestStateUpdate]:FireClient(player, { ok = ok, reward = reward })
end)

return QuestService
