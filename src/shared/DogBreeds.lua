local DogBreeds = {}

local function breed(name, rarity, affinity, personality)
	return {
		name = name,
		rarity = rarity,
		affinity = affinity,
		personality = personality,
	}
end

DogBreeds.BY_ID = {
	golden_retriever  = breed("Golden Retriever",  "Common",   "fetch",   { playful = 2, brave = 1, lazy = 0, curious = 1, protective = 1 }),
	labrador          = breed("Labrador",          "Common",   "fetch",   { playful = 2, brave = 1, lazy = 0, curious = 1, protective = 1 }),
	beagle            = breed("Beagle",            "Common",   "scent",   { playful = 1, brave = 1, lazy = 0, curious = 3, protective = 0 }),
	pug               = breed("Pug",               "Common",   "show",    { playful = 1, brave = 0, lazy = 3, curious = 1, protective = 0 }),
	dachshund         = breed("Dachshund",         "Common",   "dig",     { playful = 1, brave = 1, lazy = 1, curious = 2, protective = 0 }),
	chihuahua         = breed("Chihuahua",         "Common",   "agility", { playful = 1, brave = 2, lazy = 0, curious = 1, protective = 1 }),
	poodle            = breed("Poodle",            "Uncommon", "show",    { playful = 1, brave = 0, lazy = 1, curious = 2, protective = 1 }),
	border_collie     = breed("Border Collie",     "Uncommon", "agility", { playful = 1, brave = 1, lazy = 0, curious = 2, protective = 1 }),
	husky             = breed("Husky",             "Uncommon", "rescue",  { playful = 2, brave = 1, lazy = 0, curious = 1, protective = 1 }),
	german_shepherd   = breed("German Shepherd",   "Uncommon", "rescue",  { playful = 0, brave = 2, lazy = 0, curious = 1, protective = 2 }),
	corgi             = breed("Corgi",             "Uncommon", "show",    { playful = 2, brave = 1, lazy = 0, curious = 1, protective = 1 }),
	dalmatian         = breed("Dalmatian",         "Uncommon", "agility", { playful = 2, brave = 1, lazy = 0, curious = 1, protective = 1 }),
	rottweiler        = breed("Rottweiler",        "Rare",     "rescue",  { playful = 0, brave = 2, lazy = 0, curious = 0, protective = 3 }),
	doberman          = breed("Doberman",          "Rare",     "rescue",  { playful = 0, brave = 2, lazy = 0, curious = 1, protective = 2 }),
	great_dane        = breed("Great Dane",        "Rare",     "show",    { playful = 1, brave = 1, lazy = 2, curious = 0, protective = 1 }),
	saint_bernard     = breed("Saint Bernard",     "Rare",     "rescue",  { playful = 1, brave = 1, lazy = 1, curious = 0, protective = 2 }),
	newfoundland      = breed("Newfoundland",      "Rare",     "rescue",  { playful = 1, brave = 1, lazy = 1, curious = 0, protective = 2 }),
	akita             = breed("Akita",             "Rare",     "rescue",  { playful = 0, brave = 2, lazy = 1, curious = 0, protective = 2 }),
	shiba_inu         = breed("Shiba Inu",         "Rare",     "show",    { playful = 1, brave = 1, lazy = 1, curious = 2, protective = 0 }),
	australian_shepherd = breed("Australian Shepherd", "Rare", "agility", { playful = 1, brave = 1, lazy = 0, curious = 2, protective = 1 }),
	samoyed           = breed("Samoyed",           "Epic",     "show",    { playful = 2, brave = 1, lazy = 0, curious = 1, protective = 1 }),
	bernese           = breed("Bernese Mountain",  "Epic",     "rescue",  { playful = 1, brave = 1, lazy = 1, curious = 0, protective = 2 }),
	weimaraner        = breed("Weimaraner",        "Epic",     "scent",   { playful = 1, brave = 1, lazy = 0, curious = 2, protective = 1 }),
	bloodhound        = breed("Bloodhound",        "Epic",     "scent",   { playful = 0, brave = 1, lazy = 1, curious = 3, protective = 0 }),
	greyhound         = breed("Greyhound",         "Epic",     "agility", { playful = 1, brave = 1, lazy = 1, curious = 1, protective = 1 }),
	whippet           = breed("Whippet",           "Epic",     "agility", { playful = 1, brave = 1, lazy = 1, curious = 1, protective = 1 }),
	basenji           = breed("Basenji",           "Epic",     "scent",   { playful = 1, brave = 1, lazy = 0, curious = 3, protective = 0 }),
	chow_chow         = breed("Chow Chow",         "Epic",     "show",    { playful = 0, brave = 1, lazy = 2, curious = 0, protective = 2 }),
	shar_pei          = breed("Shar-Pei",          "Epic",     "show",    { playful = 0, brave = 1, lazy = 2, curious = 0, protective = 2 }),
	tibetan_mastiff   = breed("Tibetan Mastiff",   "Mythic",   "rescue",  { playful = 0, brave = 2, lazy = 1, curious = 0, protective = 2 }),
	afghan_hound      = breed("Afghan Hound",      "Mythic",   "show",    { playful = 0, brave = 1, lazy = 1, curious = 1, protective = 2 }),
	xoloitzcuintli    = breed("Xoloitzcuintli",    "Mythic",   "scent",   { playful = 0, brave = 2, lazy = 0, curious = 2, protective = 1 }),
	azawakh           = breed("Azawakh",           "Mythic",   "agility", { playful = 0, brave = 2, lazy = 0, curious = 1, protective = 2 }),
	spectral_whippet  = breed("Spectral Whippet",  "Mythic",   "scent",   { playful = 0, brave = 2, lazy = 0, curious = 2, protective = 1 }),
	auroran_hound     = breed("Auroran Hound",     "Mythic",   "rescue",  { playful = 1, brave = 2, lazy = 0, curious = 1, protective = 1 }),
}

DogBreeds.RARITY_WEIGHT = {
	Common   = 60,
	Uncommon = 25,
	Rare     = 10,
	Epic     = 4,
	Mythic   = 1,
}

function DogBreeds.weightedRoll(rng)
	local total = 0
	for _, w in pairs(DogBreeds.RARITY_WEIGHT) do total += w end
	local r = rng:NextInteger(1, total)
	local acc = 0
	for rarity, w in pairs(DogBreeds.RARITY_WEIGHT) do
		acc += w
		if r <= acc then
			local pool = {}
			for id, def in pairs(DogBreeds.BY_ID) do
				if def.rarity == rarity then table.insert(pool, id) end
			end
			return pool[rng:NextInteger(1, #pool)]
		end
	end
	return "golden_retriever"
end

return DogBreeds
