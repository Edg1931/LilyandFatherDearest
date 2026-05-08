local Quests = {}

Quests.CATEGORIES = {
	"fetch", "rescue", "scent", "dig", "agility", "show", "walk",
}

Quests.AFFINITY_BONUS = 0.20

Quests.LIBRARY = {
	{
		id = "lost_postman_package",
		category = "fetch",
		title = "The Postman's Package",
		summary = "Henry the postman dropped a package somewhere in the park.",
		coinReward = 80,
		bondReward = 20,
		minLevel = 1,
	},
	{
		id = "puppy_under_bridge",
		category = "rescue",
		title = "Puppy Under the Bridge",
		summary = "A whimper from below — bring the lost puppy home.",
		coinReward = 150,
		bondReward = 35,
		breedReward = "beagle",
		minLevel = 2,
	},
	{
		id = "scent_of_treats",
		category = "scent",
		title = "Trail of Treats",
		summary = "Follow the scent of biscuits across the bakery district.",
		coinReward = 110,
		bondReward = 25,
		minLevel = 1,
	},
	{
		id = "buried_bones",
		category = "dig",
		title = "Buried Bones",
		summary = "Three dig spots glow in the meadow.",
		coinReward = 90,
		bondReward = 20,
		minLevel = 1,
	},
	{
		id = "agility_qualifier",
		category = "agility",
		title = "Agility Qualifier",
		summary = "Run the timed obstacle course at the Park.",
		coinReward = 120,
		bondReward = 25,
		minLevel = 3,
	},
	{
		id = "weekly_dog_show",
		category = "show",
		title = "Weekly Dog Show",
		summary = "Best in show — judges score grooming, breed, and personality.",
		coinReward = 500,
		bondReward = 60,
		weekly = true,
		minLevel = 5,
	},
	{
		id = "daily_walk",
		category = "walk",
		title = "Daily Walk",
		summary = "A quiet walk loop around the neighborhood.",
		coinReward = 30,
		bondReward = 10,
		daily = true,
		minLevel = 1,
	},
}

Quests.BY_ID = {}
for _, q in ipairs(Quests.LIBRARY) do
	Quests.BY_ID[q.id] = q
end

function Quests.computeReward(quest, partyBreedAffinities)
	local affinityHits = 0
	for _, affinity in ipairs(partyBreedAffinities) do
		if affinity == quest.category then affinityHits += 1 end
	end
	local bonus = Quests.AFFINITY_BONUS * affinityHits
	return {
		coins = math.floor(quest.coinReward * (1 + bonus)),
		bond  = math.floor(quest.bondReward * (1 + bonus)),
		breedReward = quest.breedReward,
	}
end

return Quests
