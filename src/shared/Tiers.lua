local Tiers = {}

Tiers.ORDER = {
	"Regular",
	"Rare",
	"Epic",
	"Mega",
	"Legendary",
	"Neon",
	"Mythic",
}

Tiers.NEXT = {
	Regular   = "Rare",
	Rare      = "Epic",
	Epic      = "Mega",
	Mega      = "Legendary",
	Legendary = "Neon",
	Neon      = "Mythic",
	Mythic    = nil,
}

Tiers.COMBINE_REQUIRED = {
	Mega       = 4,
	Legendary  = 4,
	Neon       = 4,
	Mythic     = 4,
}

Tiers.VISUAL = {
	Regular   = { effect = "none" },
	Rare      = { effect = "shimmer" },
	Epic      = { effect = "particle_soft" },
	Mega      = { effect = "color_shift" },
	Legendary = { effect = "glow_paws" },
	Neon      = { effect = "glow_paws_tail" },
	Mythic    = { effect = "neon_full_body_breath" },
}

function Tiers.canRoll(tier)
	return Tiers.NEXT[tier] ~= nil and tier ~= "Neon" and tier ~= "Mythic"
end

function Tiers.requiresCombine(tier)
	local next = Tiers.NEXT[tier]
	return next and Tiers.COMBINE_REQUIRED[next] or nil
end

return Tiers
