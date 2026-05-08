local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local QuestObjectives = require(ReplicatedStorage.Shared.QuestObjectives)

local WorldService = require(script.Parent.WorldService)
local QuestService = require(script.Parent.QuestService)
local AntiCheatService = require(script.Parent.AntiCheatService)

local InteractionService = {}

local function withinRange(player, entity)
	local char = player.Character
	if not char then return false end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return false end
	return (root.Position - entity.position).Magnitude <= QuestObjectives.MAX_INTERACT_DISTANCE
end

function InteractionService.handle(player, payload)
	if typeof(payload) ~= "table" then return end
	local entityId = payload.entityId
	if typeof(entityId) ~= "string" then return end

	local entity = WorldService.getEntity(player, entityId)
	if not entity then
		AntiCheatService.flag(player, "interact_unknown_entity", { entityId = entityId })
		return
	end
	if entity.consumed then return end
	if not withinRange(player, entity) then
		AntiCheatService.flag(player, "interact_out_of_range", { entityId = entityId })
		return
	end

	entity.consumed = true
	WorldService.despawnEntity(player, entityId)
	QuestService.recordInteraction(player, entity)
end

Remotes.EVENTS[Remotes.NAMES.WorldInteract].OnServerEvent:Connect(function(player, payload)
	InteractionService.handle(player, payload)
end)

return InteractionService
