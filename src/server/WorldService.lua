local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local QuestObjectives = require(ReplicatedStorage.Shared.QuestObjectives)

local WorldService = {}

-- Per-player world entities. Each entity is server-owned state; the client
-- gets a spawn message and renders a marker. Interactions come back through
-- Remotes.WorldInteract and are validated against this state.
--
-- entities[player] = { [entityId] = entity }
-- entity = { id, kind, position, questId, objectiveId, ord, consumed }
local entities = {}

-- Hand-picked spawn positions per quest. In production these would live in a
-- ServerStorage Folder of attachments and the spawner would read positions
-- from those. Inline coordinates keep the prototype self-contained.
local SPAWN_POINTS = {
	lost_postman_package = {
		find_package = { Vector3.new(20, 5, 12) },
	},
	puppy_under_bridge = {
		find_puppy = { Vector3.new(-40, 2, -22) },
		carry_home  = { Vector3.new(0, 5, 0) },  -- "your plot" — server resolves to actual plot at runtime
	},
	scent_of_treats = {
		trail = {
			Vector3.new(10, 5, 0),
			Vector3.new(15, 5, 8),
			Vector3.new(22, 5, 14),
			Vector3.new(30, 5, 18),
		},
	},
	buried_bones = {
		dig_three = {
			Vector3.new(-12, 3, 30),
			Vector3.new(-8, 3, 36),
			Vector3.new(-4, 3, 32),
			Vector3.new(0, 3, 38),
			Vector3.new(4, 3, 34),
		},
	},
	agility_qualifier = {
		agility_run = { Vector3.new(50, 5, 50), Vector3.new(60, 5, 80) },  -- start, finish
	},
	weekly_dog_show = {
		showcase = { Vector3.new(0, 5, -50) },
	},
	daily_walk = {
		walk_route = {
			Vector3.new(5, 5, 5),
			Vector3.new(10, 5, 12),
			Vector3.new(20, 5, 8),
			Vector3.new(28, 5, 4),
			Vector3.new(35, 5, 0),
		},
	},
}

local function ensureBucket(player)
	entities[player] = entities[player] or {}
	return entities[player]
end

local function newId() return HttpService:GenerateGUID(false) end

function WorldService.spawnObjectives(player, questId)
	local objectives = QuestObjectives.forQuest(questId)
	local bucket = ensureBucket(player)
	local spawned = {}
	local pointsByObj = SPAWN_POINTS[questId] or {}
	for _, obj in ipairs(objectives) do
		local points = pointsByObj[obj.id] or {}
		for ord, pos in ipairs(points) do
			local entity = {
				id = newId(),
				kind = obj.kind,
				position = pos,
				questId = questId,
				objectiveId = obj.id,
				ord = ord,
				consumed = false,
			}
			bucket[entity.id] = entity
			table.insert(spawned, entity)
			Remotes.EVENTS[Remotes.NAMES.WorldEntitySpawn]:FireClient(player, {
				id = entity.id,
				kind = entity.kind,
				position = entity.position,
				questId = entity.questId,
				objectiveId = entity.objectiveId,
				ord = entity.ord,
			})
		end
	end
	return spawned
end

function WorldService.despawnAllForPlayer(player)
	local bucket = entities[player]
	if not bucket then return end
	for id in pairs(bucket) do
		Remotes.EVENTS[Remotes.NAMES.WorldEntityDespawn]:FireClient(player, { id = id })
	end
	entities[player] = nil
end

function WorldService.despawnEntity(player, entityId)
	local bucket = entities[player]
	if not bucket then return end
	bucket[entityId] = nil
	Remotes.EVENTS[Remotes.NAMES.WorldEntityDespawn]:FireClient(player, { id = entityId })
end

function WorldService.getEntity(player, entityId)
	local bucket = entities[player]
	return bucket and bucket[entityId] or nil
end

function WorldService.entitiesForQuest(player, questId)
	local out = {}
	local bucket = entities[player]
	if not bucket then return out end
	for id, e in pairs(bucket) do
		if e.questId == questId then out[id] = e end
	end
	return out
end

Players.PlayerRemoving:Connect(function(player)
	entities[player] = nil
end)

return WorldService
