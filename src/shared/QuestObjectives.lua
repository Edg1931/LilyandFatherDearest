local QuestObjectives = {}

-- Objective shapes:
--   findItem      → interact with a single world entity
--   findStray     → interact with a hidden stray NPC
--   reachLocation → enter a region (server check on heartbeat)
--   digSpot       → interact with N of M dig spots
--   scentTrail    → interact with sequenced scent points in order
--   routeWalk     → enter a sequence of waypoints within timeLimit
--   agility       → start gate → finish gate within timeLimit

QuestObjectives.BY_QUEST = {
	lost_postman_package = {
		{ id = "find_package", kind = "findItem", count = 1, hint = "Search the park benches and the bakery alley." },
	},
	puppy_under_bridge = {
		{ id = "find_puppy", kind = "findStray", count = 1, hint = "Listen for whimpers near the river bridge." },
		{ id = "carry_home", kind = "reachLocation", count = 1, hint = "Bring the puppy back to your house plot." },
	},
	scent_of_treats = {
		{ id = "trail", kind = "scentTrail", count = 4, hint = "Follow the biscuit trail from bakery to bakery." },
	},
	buried_bones = {
		{ id = "dig_three", kind = "digSpot", count = 3, hint = "Glowing dig spots appear in the meadow." },
	},
	agility_qualifier = {
		{ id = "agility_run", kind = "agility", count = 1, timeLimit = 60, hint = "Reach the finish gate within 60 seconds." },
	},
	weekly_dog_show = {
		{ id = "showcase", kind = "findItem", count = 1, hint = "Present your dog to the judges' podium." },
	},
	daily_walk = {
		{ id = "walk_route", kind = "routeWalk", count = 5, timeLimit = 300, hint = "Walk past 5 waypoints around the neighborhood." },
	},
}

QuestObjectives.MAX_INTERACT_DISTANCE = 12  -- studs between player and target

function QuestObjectives.forQuest(questId)
	return QuestObjectives.BY_QUEST[questId] or {}
end

return QuestObjectives
