local DogBreeds = {}

-- Size buckets drive scale and rig proportions.
DogBreeds.SIZE_SCALE = {
	tiny   = 0.55,
	small  = 0.75,
	medium = 1.00,
	large  = 1.30,
	giant  = 1.70,
}

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

local function breed(o)
	o.personality = o.personality or { playful = 1, brave = 1, lazy = 1, curious = 1, protective = 1 }
	return o
end

DogBreeds.BY_ID = {
	-- ---------- TINY ----------
	chihuahua          = breed({ name="Chihuahua",          rarity="Common",   affinity="agility", size="tiny",   shape="lean",    ears="pointy", tail="curly",   pattern="solid",   primary=rgb(220,180,120), secondary=rgb(255,235,200), temperament="alert",     personality={playful=1,brave=2,lazy=0,curious=1,protective=1} }),
	yorkie             = breed({ name="Yorkshire Terrier", rarity="Common",   affinity="show",    size="tiny",   shape="compact", ears="pointy", tail="fluffy",  pattern="patched", primary=rgb(80,50,40),    secondary=rgb(200,170,120), temperament="alert",     personality={playful=2,brave=1,lazy=0,curious=2,protective=0} }),
	pomeranian         = breed({ name="Pomeranian",        rarity="Uncommon", affinity="show",    size="tiny",   shape="compact", ears="pointy", tail="fluffy",  pattern="solid",   primary=rgb(220,150,80),  secondary=rgb(255,200,140), temperament="energetic", personality={playful=2,brave=1,lazy=0,curious=2,protective=0} }),
	maltese            = breed({ name="Maltese",           rarity="Uncommon", affinity="show",    size="tiny",   shape="compact", ears="floppy", tail="fluffy",  pattern="solid",   primary=rgb(250,250,245), secondary=rgb(245,235,220), temperament="eager",     personality={playful=2,brave=0,lazy=1,curious=1,protective=1} }),
	toy_poodle         = breed({ name="Toy Poodle",        rarity="Uncommon", affinity="show",    size="tiny",   shape="lean",    ears="floppy", tail="fluffy",  pattern="solid",   primary=rgb(80,60,50),    secondary=rgb(40,30,25),    temperament="alert",     personality={playful=1,brave=1,lazy=0,curious=2,protective=1} }),

	-- ---------- SMALL ----------
	beagle             = breed({ name="Beagle",            rarity="Common",   affinity="scent",   size="small",  shape="stocky",  ears="floppy", tail="straight",pattern="patched", primary=rgb(192,138,90),  secondary=rgb(245,235,210), temperament="energetic", personality={playful=1,brave=1,lazy=0,curious=3,protective=0} }),
	pug                = breed({ name="Pug",               rarity="Common",   affinity="show",    size="small",  shape="compact", ears="floppy", tail="curly",   pattern="solid",   primary=rgb(216,200,168), secondary=rgb(60,50,45),    temperament="lazy",      personality={playful=1,brave=0,lazy=3,curious=1,protective=0} }),
	dachshund          = breed({ name="Dachshund",         rarity="Common",   affinity="dig",     size="small",  shape="long",    ears="floppy", tail="straight",pattern="solid",   primary=rgb(138,74,42),   secondary=rgb(60,30,15),    temperament="alert",     personality={playful=1,brave=1,lazy=1,curious=2,protective=0} }),
	frenchie           = breed({ name="French Bulldog",    rarity="Uncommon", affinity="show",    size="small",  shape="compact", ears="pointy", tail="stub",    pattern="patched", primary=rgb(180,170,160), secondary=rgb(245,240,235), temperament="lazy",      personality={playful=1,brave=1,lazy=2,curious=1,protective=0} }),
	boston_terrier     = breed({ name="Boston Terrier",    rarity="Uncommon", affinity="show",    size="small",  shape="compact", ears="pointy", tail="stub",    pattern="patched", primary=rgb(30,30,30),    secondary=rgb(245,245,245), temperament="energetic", personality={playful=2,brave=1,lazy=0,curious=1,protective=1} }),
	shih_tzu           = breed({ name="Shih Tzu",          rarity="Uncommon", affinity="show",    size="small",  shape="compact", ears="floppy", tail="fluffy",  pattern="patched", primary=rgb(220,200,160), secondary=rgb(120,90,70),   temperament="lazy",      personality={playful=1,brave=0,lazy=2,curious=2,protective=0} }),
	cavalier_king      = breed({ name="Cavalier King Charles", rarity="Uncommon", affinity="show", size="small",  shape="lean",    ears="floppy", tail="fluffy",  pattern="patched", primary=rgb(245,235,220), secondary=rgb(150,60,40),   temperament="eager",     personality={playful=2,brave=0,lazy=1,curious=1,protective=1} }),
	jack_russell       = breed({ name="Jack Russell",      rarity="Common",   affinity="agility", size="small",  shape="lean",    ears="pointy", tail="straight",pattern="patched", primary=rgb(245,240,230), secondary=rgb(140,80,40),   temperament="energetic", personality={playful=3,brave=2,lazy=0,curious=2,protective=0} }),
	mini_schnauzer     = breed({ name="Mini Schnauzer",    rarity="Uncommon", affinity="agility", size="small",  shape="compact", ears="pointy", tail="stub",    pattern="solid",   primary=rgb(150,150,150), secondary=rgb(80,80,80),    temperament="alert",     personality={playful=1,brave=1,lazy=0,curious=2,protective=1} }),
	cocker_spaniel     = breed({ name="Cocker Spaniel",    rarity="Uncommon", affinity="fetch",   size="small",  shape="lean",    ears="floppy", tail="fluffy",  pattern="solid",   primary=rgb(220,170,110), secondary=rgb(180,130,80),  temperament="eager",     personality={playful=2,brave=1,lazy=0,curious=1,protective=1} }),

	-- ---------- MEDIUM ----------
	border_collie      = breed({ name="Border Collie",     rarity="Uncommon", affinity="agility", size="medium", shape="lean",    ears="pointy", tail="fluffy",  pattern="patched", primary=rgb(20,20,20),    secondary=rgb(245,245,240), temperament="energetic", personality={playful=1,brave=1,lazy=0,curious=2,protective=1} }),
	australian_shep    = breed({ name="Australian Shepherd", rarity="Rare",   affinity="agility", size="medium", shape="lean",    ears="floppy", tail="stub",    pattern="brindled", primary=rgb(80,60,40),    secondary=rgb(220,210,200), temperament="energetic", personality={playful=1,brave=1,lazy=0,curious=2,protective=1} }),
	corgi              = breed({ name="Corgi",             rarity="Uncommon", affinity="show",    size="medium", shape="long",    ears="pointy", tail="stub",    pattern="patched", primary=rgb(216,160,112), secondary=rgb(250,245,235), temperament="eager",     personality={playful=2,brave=1,lazy=0,curious=1,protective=1} }),
	shiba_inu          = breed({ name="Shiba Inu",         rarity="Rare",    affinity="show",    size="medium", shape="compact", ears="pointy", tail="curly",   pattern="solid",   primary=rgb(232,160,96),  secondary=rgb(245,230,210), temperament="alert",     personality={playful=1,brave=1,lazy=1,curious=2,protective=0} }),
	bulldog            = breed({ name="Bulldog",           rarity="Uncommon", affinity="show",    size="medium", shape="stocky",  ears="floppy", tail="stub",    pattern="patched", primary=rgb(220,200,180), secondary=rgb(180,140,100), temperament="lazy",      personality={playful=0,brave=1,lazy=3,curious=0,protective=1} }),
	whippet            = breed({ name="Whippet",           rarity="Epic",    affinity="agility", size="medium", shape="lean",    ears="pointy", tail="straight",pattern="solid",   primary=rgb(200,190,180), secondary=rgb(160,150,140), temperament="alert",     personality={playful=1,brave=1,lazy=1,curious=1,protective=1} }),
	springer_spaniel   = breed({ name="Springer Spaniel",  rarity="Rare",    affinity="fetch",   size="medium", shape="lean",    ears="floppy", tail="fluffy",  pattern="patched", primary=rgb(80,60,40),    secondary=rgb(245,240,235), temperament="energetic", personality={playful=2,brave=1,lazy=0,curious=2,protective=0} }),
	cattle_dog         = breed({ name="Australian Cattle Dog", rarity="Rare", affinity="agility", size="medium", shape="stocky",  ears="pointy", tail="straight",pattern="brindled", primary=rgb(120,140,160), secondary=rgb(80,60,40),    temperament="alert",     personality={playful=1,brave=2,lazy=0,curious=1,protective=2} }),
	vizsla             = breed({ name="Vizsla",            rarity="Rare",    affinity="scent",   size="medium", shape="lean",    ears="floppy", tail="straight",pattern="solid",   primary=rgb(196,128,80),  secondary=rgb(170,100,60),  temperament="energetic", personality={playful=2,brave=1,lazy=0,curious=2,protective=0} }),
	weimaraner         = breed({ name="Weimaraner",        rarity="Epic",    affinity="scent",   size="medium", shape="lean",    ears="floppy", tail="straight",pattern="solid",   primary=rgb(150,140,150), secondary=rgb(120,110,120), temperament="alert",     personality={playful=1,brave=2,lazy=0,curious=2,protective=1} }),
	brittany           = breed({ name="Brittany",          rarity="Rare",    affinity="fetch",   size="medium", shape="lean",    ears="floppy", tail="stub",    pattern="patched", primary=rgb(245,240,230), secondary=rgb(180,80,50),   temperament="eager",     personality={playful=2,brave=1,lazy=0,curious=2,protective=0} }),
	standard_poodle    = breed({ name="Standard Poodle",   rarity="Rare",    affinity="show",    size="medium", shape="lean",    ears="floppy", tail="fluffy",  pattern="solid",   primary=rgb(245,240,230), secondary=rgb(200,190,180), temperament="alert",     personality={playful=1,brave=1,lazy=0,curious=2,protective=1} }),
	samoyed            = breed({ name="Samoyed",           rarity="Epic",    affinity="show",    size="medium", shape="stocky",  ears="pointy", tail="curly",   pattern="solid",   primary=rgb(252,250,245), secondary=rgb(240,235,220), temperament="eager",     personality={playful=2,brave=1,lazy=0,curious=1,protective=1} }),
	husky              = breed({ name="Husky",             rarity="Uncommon", affinity="rescue",  size="medium", shape="stocky",  ears="pointy", tail="curly",   pattern="patched", primary=rgb(50,50,55),    secondary=rgb(245,245,250), temperament="energetic", personality={playful=2,brave=2,lazy=0,curious=2,protective=1} }),
	dalmatian          = breed({ name="Dalmatian",         rarity="Rare",    affinity="agility", size="medium", shape="lean",    ears="floppy", tail="straight",pattern="spotted", primary=rgb(245,245,240), secondary=rgb(20,20,20),    temperament="energetic", personality={playful=2,brave=1,lazy=0,curious=1,protective=1} }),
	golden_retriever   = breed({ name="Golden Retriever",  rarity="Common",   affinity="fetch",   size="large",  shape="stocky",  ears="floppy", tail="fluffy",  pattern="solid",   primary=rgb(232,183,115), secondary=rgb(255,225,170), temperament="eager",     personality={playful=2,brave=1,lazy=0,curious=1,protective=1} }),
	labrador           = breed({ name="Labrador",          rarity="Common",   affinity="fetch",   size="large",  shape="stocky",  ears="floppy", tail="straight",pattern="solid",   primary=rgb(60,60,60),    secondary=rgb(40,40,40),    temperament="eager",     personality={playful=2,brave=1,lazy=0,curious=1,protective=1} }),
	chocolate_lab      = breed({ name="Chocolate Lab",     rarity="Common",   affinity="fetch",   size="large",  shape="stocky",  ears="floppy", tail="straight",pattern="solid",   primary=rgb(120,75,40),   secondary=rgb(90,55,30),    temperament="eager",     personality={playful=2,brave=1,lazy=0,curious=1,protective=1} }),

	-- ---------- LARGE ----------
	german_shepherd    = breed({ name="German Shepherd",   rarity="Uncommon", affinity="rescue",  size="large",  shape="lean",    ears="pointy", tail="fluffy",  pattern="patched", primary=rgb(106,58,26),   secondary=rgb(30,25,15),    temperament="alert",     personality={playful=0,brave=2,lazy=0,curious=1,protective=2} }),
	boxer              = breed({ name="Boxer",             rarity="Rare",    affinity="agility", size="large",  shape="lean",    ears="pointy", tail="stub",    pattern="patched", primary=rgb(216,150,90),  secondary=rgb(50,40,30),    temperament="energetic", personality={playful=2,brave=2,lazy=0,curious=1,protective=1} }),
	doberman           = breed({ name="Doberman",          rarity="Rare",    affinity="rescue",  size="large",  shape="lean",    ears="pointy", tail="stub",    pattern="patched", primary=rgb(40,25,15),    secondary=rgb(180,110,60),  temperament="alert",     personality={playful=0,brave=2,lazy=0,curious=1,protective=2} }),
	rottweiler         = breed({ name="Rottweiler",        rarity="Rare",    affinity="rescue",  size="large",  shape="stocky",  ears="floppy", tail="stub",    pattern="patched", primary=rgb(20,15,15),    secondary=rgb(140,80,40),   temperament="alert",     personality={playful=0,brave=2,lazy=0,curious=0,protective=3} }),
	akita              = breed({ name="Akita",             rarity="Rare",    affinity="rescue",  size="large",  shape="stocky",  ears="pointy", tail="curly",   pattern="patched", primary=rgb(232,200,150), secondary=rgb(245,240,235), temperament="alert",     personality={playful=0,brave=2,lazy=1,curious=0,protective=2} }),
	greyhound          = breed({ name="Greyhound",         rarity="Epic",    affinity="agility", size="large",  shape="lean",    ears="pointy", tail="straight",pattern="solid",   primary=rgb(180,170,160), secondary=rgb(120,110,100), temperament="alert",     personality={playful=1,brave=1,lazy=2,curious=1,protective=0} }),
	bernese            = breed({ name="Bernese Mountain",  rarity="Epic",    affinity="rescue",  size="large",  shape="stocky",  ears="floppy", tail="fluffy",  pattern="patched", primary=rgb(20,15,15),    secondary=rgb(245,240,235), temperament="lazy",      personality={playful=1,brave=1,lazy=1,curious=0,protective=2} }),
	old_english_sheep  = breed({ name="Old English Sheepdog", rarity="Epic", affinity="rescue",  size="large",  shape="stocky",  ears="floppy", tail="fluffy",  pattern="patched", primary=rgb(220,210,200), secondary=rgb(120,110,100), temperament="lazy",      personality={playful=1,brave=1,lazy=2,curious=1,protective=1} }),
	newfoundland       = breed({ name="Newfoundland",      rarity="Rare",    affinity="rescue",  size="large",  shape="stocky",  ears="floppy", tail="fluffy",  pattern="solid",   primary=rgb(20,20,20),    secondary=rgb(40,40,40),    temperament="lazy",      personality={playful=1,brave=1,lazy=2,curious=0,protective=2} }),
	saint_bernard      = breed({ name="Saint Bernard",     rarity="Rare",    affinity="rescue",  size="large",  shape="stocky",  ears="floppy", tail="fluffy",  pattern="patched", primary=rgb(200,144,112), secondary=rgb(245,240,235), temperament="lazy",      personality={playful=1,brave=1,lazy=2,curious=0,protective=2} }),

	-- ---------- GIANT ----------
	great_dane         = breed({ name="Great Dane",        rarity="Rare",    affinity="show",    size="giant",  shape="lean",    ears="floppy", tail="straight",pattern="solid",   primary=rgb(150,140,160), secondary=rgb(120,110,130), temperament="lazy",      personality={playful=1,brave=1,lazy=2,curious=0,protective=1} }),
	mastiff            = breed({ name="Mastiff",           rarity="Epic",    affinity="rescue",  size="giant",  shape="stocky",  ears="floppy", tail="straight",pattern="solid",   primary=rgb(200,160,110), secondary=rgb(60,40,30),    temperament="lazy",      personality={playful=0,brave=2,lazy=2,curious=0,protective=3} }),
	tibetan_mastiff    = breed({ name="Tibetan Mastiff",   rarity="Mythic",  affinity="rescue",  size="giant",  shape="stocky",  ears="floppy", tail="fluffy",  pattern="patched", primary=rgb(60,30,20),    secondary=rgb(180,120,60),  temperament="alert",     personality={playful=0,brave=2,lazy=1,curious=0,protective=2} }),
	irish_wolfhound    = breed({ name="Irish Wolfhound",   rarity="Epic",    affinity="agility", size="giant",  shape="lean",    ears="floppy", tail="straight",pattern="solid",   primary=rgb(140,130,120), secondary=rgb(100,90,80),   temperament="lazy",      personality={playful=1,brave=2,lazy=1,curious=1,protective=1} }),
	leonberger         = breed({ name="Leonberger",        rarity="Epic",    affinity="rescue",  size="giant",  shape="stocky",  ears="floppy", tail="fluffy",  pattern="solid",   primary=rgb(200,150,90),  secondary=rgb(60,40,30),    temperament="lazy",      personality={playful=1,brave=1,lazy=2,curious=0,protective=2} }),

	-- ---------- FANTASY (top tiers) ----------
	spectral_whippet   = breed({ name="Spectral Whippet",  rarity="Mythic",  affinity="scent",   size="medium", shape="lean",    ears="pointy", tail="straight",pattern="solid",   primary=rgb(170,200,255), secondary=rgb(255,255,255), temperament="alert",     personality={playful=0,brave=2,lazy=0,curious=2,protective=1} }),
	auroran_hound      = breed({ name="Auroran Hound",     rarity="Mythic",  affinity="rescue",  size="large",  shape="lean",    ears="pointy", tail="fluffy",  pattern="brindled",primary=rgb(255,200,150), secondary=rgb(255,150,200), temperament="alert",     personality={playful=1,brave=2,lazy=0,curious=1,protective=1} }),
	cosmic_corgi       = breed({ name="Cosmic Corgi",      rarity="Mythic",  affinity="show",    size="medium", shape="long",    ears="pointy", tail="stub",    pattern="spotted", primary=rgb(80,40,160),   secondary=rgb(255,230,140), temperament="eager",     personality={playful=2,brave=1,lazy=0,curious=2,protective=0} }),
	ember_mastiff      = breed({ name="Ember Mastiff",     rarity="Mythic",  affinity="rescue",  size="giant",  shape="stocky",  ears="floppy", tail="straight",pattern="brindled",primary=rgb(180,40,30),   secondary=rgb(255,140,40),  temperament="alert",     personality={playful=0,brave=2,lazy=1,curious=0,protective=3} }),
	frostfang_husky    = breed({ name="Frostfang Husky",   rarity="Mythic",  affinity="rescue",  size="large",  shape="stocky",  ears="pointy", tail="curly",   pattern="patched", primary=rgb(200,230,255), secondary=rgb(255,255,255), temperament="energetic", personality={playful=2,brave=2,lazy=0,curious=2,protective=1} }),
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
