local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Quests = require(ReplicatedStorage.Shared.Quests)
local QuestObjectives = require(ReplicatedStorage.Shared.QuestObjectives)
local DogBreeds = require(ReplicatedStorage.Shared.DogBreeds)
local Constants = require(ReplicatedStorage.Shared.Constants)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local PlayerDataService = require(script.Parent.PlayerDataService)
local WorldService = require(script.Parent.WorldService)

local QuestService = {}

-- player → { questId, startedAt, partyDogIds, objectives = { [objId] = state } }
-- objective state: { kind, required, count, hits = {[entityId]=true}, completed = bool }
local active = {}

local function pushState(player)
	Remotes.EVENTS[Remotes.NAMES.QuestStateUpdate]:FireClient(player, { active = active[player] })
end

function QuestService.start(player, questId)
	local quest = Quests.BY_ID[questId]
	if not quest then return false, "no_quest" end
	if active[player] then return false, "already_active" end
	local profile = PlayerDataService.get(player)
	if not profile then return false, "no_profile" end

	local party = {}
	for _, id in ipairs(profile.followers) do
		local dog = profile.dogs[id]
		if dog then table.insert(party, id) end
	end

	local objectiveState = {}
	for _, obj in ipairs(QuestObjectives.forQuest(questId)) do
		objectiveState[obj.id] = {
			kind = obj.kind,
			required = obj.count or 1,
			count = 0,
			hits = {},
			completed = false,
		}
	end

	active[player] = {
		questId = questId,
		startedAt = os.time(),
		partyDogIds = party,
		objectives = objectiveState,
	}

	WorldService.spawnObjectives(player, questId)
	pushState(player)
	return true
end

function QuestService.cancel(player)
	local state = active[player]
	if not state then return end
	WorldService.despawnAllForPlayer(player)
	active[player] = nil
	pushState(player)
end

local function allComplete(state)
	for _, o in pairs(state.objectives) do
		if not o.completed then return false end
	end
	return true
end

function QuestService.recordInteraction(player, entity)
	local state = active[player]
	if not state or state.questId ~= entity.questId then return false, "stale_entity" end
	local obj = state.objectives[entity.objectiveId]
	if not obj or obj.completed then return false, "no_objective" end

	-- scentTrail must be hit in order
	if obj.kind == "scentTrail" and entity.ord ~= (obj.count + 1) then
		return false, "out_of_order"
	end

	if obj.hits[entity.id] then return false, "duplicate" end
	obj.hits[entity.id] = true
	obj.count += 1
	if obj.count >= obj.required then obj.completed = true end

	pushState(player)
	if allComplete(state) then
		return QuestService.complete(player)
	end
	return true
end

function QuestService.complete(player)
	local state = active[player]
	if not state then return false, "no_active" end
	local quest = Quests.BY_ID[state.questId]
	local profile = PlayerDataService.get(player)
	if not profile then return false, "no_profile" end

	local affinities = {}
	for _, dogId in ipairs(state.partyDogIds) do
		local dog = profile.dogs[dogId]
		if dog then
			local breed = DogBreeds.BY_ID[dog.breed]
			if breed then table.insert(affinities, breed.affinity) end
		end
	end
	local reward = Quests.computeReward(quest, affinities)
	profile.coins += reward.coins
	for _, dogId in ipairs(state.partyDogIds) do
		local dog = profile.dogs[dogId]
		if dog then
			dog.bond = math.min(Constants.BOND_MAX, dog.bond + reward.bond)
			dog.questsThisCycle = dog.questsThisCycle or {}
			table.insert(dog.questsThisCycle, quest.id)
			if #dog.questsThisCycle > 7 then table.remove(dog.questsThisCycle, 1) end
		end
	end
	profile.stats.totalQuests = (profile.stats.totalQuests or 0) + 1
	if reward.breedReward then
		PlayerDataService.signDog(profile, reward.breedReward, "Regular", 0)
	end

	WorldService.despawnAllForPlayer(player)
	active[player] = nil
	pushState(player)
	Remotes.EVENTS[Remotes.NAMES.QuestStateUpdate]:FireClient(player, {
		completed = quest.id, reward = reward,
	})
	return true, reward
end

Remotes.EVENTS[Remotes.NAMES.QuestStart].OnServerEvent:Connect(function(player, payload)
	if typeof(payload) ~= "table" or typeof(payload.questId) ~= "string" then return end
	QuestService.start(player, payload.questId)
end)

Remotes.EVENTS[Remotes.NAMES.QuestSubmit].OnServerEvent:Connect(function(player, payload)
	if typeof(payload) == "table" and payload.cancel then
		QuestService.cancel(player)
	end
end)

return QuestService
