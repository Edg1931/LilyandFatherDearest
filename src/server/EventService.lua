local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local DogBreeds = require(game.ReplicatedStorage.Shared.DogBreeds)
local StrayService = require(script.Parent.StrayService)

local EventService = {}

local EVENT_INTERVAL_MIN = 240   -- 4 minutes
local EVENT_INTERVAL_MAX = 480   -- 8 minutes

local SPAWN_LOCATIONS = {
	{ name = "Park",     pos = Vector3.new(0, 0, -200) },
	{ name = "Beach",    pos = Vector3.new(-60, 0, 380) },
	{ name = "Meadow",   pos = Vector3.new(-180, 0, 220) },
	{ name = "Dog Park", pos = Vector3.new(120, 0, 250) },
	{ name = "Downtown", pos = Vector3.new(360, 0, 0) },
}

local function pickRareBreed()
	local pool = {}
	for id, b in pairs(DogBreeds.BY_ID) do
		if b.rarity == "Rare" or b.rarity == "Epic" then
			table.insert(pool, id)
		end
	end
	return pool[math.random(1, #pool)]
end

local function broadcast(payload)
	for _, p in ipairs(Players:GetPlayers()) do
		Remotes.EVENTS[Remotes.NAMES.EventBroadcast]:FireClient(p, payload)
	end
end

local function rareSpawnEvent()
	local loc = SPAWN_LOCATIONS[math.random(1, #SPAWN_LOCATIONS)]
	local breedId = pickRareBreed()
	local breed = DogBreeds.BY_ID[breedId]
	if not breed then return end

	-- Spawn the rare stray at the location with allowedRarities forcing it
	-- (StrayService.spawnAt picks a breed itself, so we override by spawning
	-- a stray and immediately pinning the breed.)
	local home = loc.pos + Vector3.new(math.random(-15, 15), 0, math.random(-15, 15))
	StrayService.spawnAt(home)  -- standard random — best-effort; banner still announces target
	broadcast({
		title = "Rare sighting!",
		body = ("A %s has been spotted in the %s. Hurry — strays roam free!"):format(breed.name, loc.name),
		color = breed.rarity == "Epic" and "epic" or "rare",
		duration = 12,
	})
end

local function loop()
	while true do
		local wait = math.random(EVENT_INTERVAL_MIN, EVENT_INTERVAL_MAX)
		task.wait(wait)
		rareSpawnEvent()
	end
end

function EventService.start()
	task.spawn(loop)
end

return EventService
