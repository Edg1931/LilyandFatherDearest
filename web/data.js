export const TIERS = ["Regular", "Rare", "Epic", "Mega", "Legendary", "Neon", "Mythic"];

export const TIER_NEXT = {
  Regular: "Rare", Rare: "Epic", Epic: "Mega", Mega: "Legendary",
  Legendary: "Neon", Neon: "Mythic", Mythic: null,
};

export const TIER_VISUAL = {
  Regular:   { ring: "transparent",         label: "" },
  Rare:      { ring: "#7ec8ff",             label: "Rare" },
  Epic:      { ring: "#b984ff",             label: "Epic" },
  Mega:      { ring: "#ff8ad6",             label: "Mega" },
  Legendary: { ring: "#ffd866",             label: "Legendary" },
  Neon:      { ring: "#7dffd1",             label: "Neon" },
  Mythic:    { ring: "#ff6b6b",             label: "Mythic" },
};

export const BOND_MAX = 1000;
export const BOND_THRESHOLDS = [250, 500, 800, 1000];
export const TIER_ROLL_BASE = {
  Regular: 0.30, Rare: 0.20, Epic: 0.12, Mega: 0.07, Legendary: 0.04,
};
export const TIER_ROLL_CAP = 0.85;

export const BREEDS = {
  golden_retriever: { name: "Golden Retriever", rarity: "Common",   emoji: "🦮", color: "#e8b773", affinity: "fetch"  },
  labrador:         { name: "Labrador",         rarity: "Common",   emoji: "🐕", color: "#3a3a3a", affinity: "fetch"  },
  beagle:           { name: "Beagle",           rarity: "Common",   emoji: "🐶", color: "#c08a5a", affinity: "scent"  },
  pug:              { name: "Pug",              rarity: "Common",   emoji: "🐶", color: "#d8c8a8", affinity: "show"   },
  dachshund:        { name: "Dachshund",        rarity: "Common",   emoji: "🌭", color: "#8a4a2a", affinity: "dig"    },
  poodle:           { name: "Poodle",           rarity: "Uncommon", emoji: "🐩", color: "#f0e6d2", affinity: "show"   },
  border_collie:    { name: "Border Collie",    rarity: "Uncommon", emoji: "🐕", color: "#1a1a1a", affinity: "agility"},
  husky:            { name: "Husky",            rarity: "Uncommon", emoji: "🐕‍🦺", color: "#9ec4d6", affinity: "rescue" },
  corgi:            { name: "Corgi",            rarity: "Uncommon", emoji: "🐕", color: "#d8a070", affinity: "show"   },
  german_shepherd:  { name: "German Shepherd",  rarity: "Uncommon", emoji: "🐕‍🦺", color: "#6a3a1a", affinity: "rescue" },
  rottweiler:       { name: "Rottweiler",       rarity: "Rare",     emoji: "🐕", color: "#1a0a0a", affinity: "rescue" },
  saint_bernard:    { name: "Saint Bernard",    rarity: "Rare",     emoji: "🐕", color: "#c89070", affinity: "rescue" },
  shiba_inu:        { name: "Shiba Inu",        rarity: "Rare",     emoji: "🐕", color: "#e8a060", affinity: "show"   },
  samoyed:          { name: "Samoyed",          rarity: "Epic",     emoji: "🐶", color: "#fafafa", affinity: "show"   },
  bloodhound:       { name: "Bloodhound",       rarity: "Epic",     emoji: "🐕", color: "#7a3a1a", affinity: "scent"  },
  greyhound:        { name: "Greyhound",        rarity: "Epic",     emoji: "🐕", color: "#a8a0a0", affinity: "agility"},
  spectral_whippet: { name: "Spectral Whippet", rarity: "Mythic",   emoji: "👻", color: "#aaccff", affinity: "scent"  },
  auroran_hound:    { name: "Auroran Hound",    rarity: "Mythic",   emoji: "✨", color: "#ffccaa", affinity: "rescue" },
};

export const RARITY_WEIGHT = { Common: 60, Uncommon: 25, Rare: 10, Epic: 4, Mythic: 1 };

export const QUESTS = {
  daily_walk: {
    title: "Daily Walk", category: "walk",
    summary: "Stroll past 4 waypoints around the neighborhood.",
    coinReward: 60, bondReward: 18,
    objectives: [{ id: "walk", kind: "waypoints", count: 4, hint: "Walk over the glowing markers" }],
    waypoints: [{ x: 360, y: 240 }, { x: 480, y: 280 }, { x: 540, y: 380 }, { x: 460, y: 460 }],
  },
  lost_postman_package: {
    title: "The Postman's Package", category: "fetch",
    summary: "Henry the postman lost a package somewhere in the park.",
    coinReward: 110, bondReward: 22,
    objectives: [{ id: "find", kind: "findItem", count: 1, hint: "Find the package emoji" }],
    waypoints: [{ x: 720, y: 320 }],
  },
  buried_bones: {
    title: "Buried Bones", category: "dig",
    summary: "Three glowing dig spots in the meadow. Tap interact when standing on one.",
    coinReward: 90, bondReward: 24,
    objectives: [{ id: "dig", kind: "digSpot", count: 3, hint: "Stand on a spot and tap interact" }],
    waypoints: [
      { x: 200, y: 460 }, { x: 240, y: 520 }, { x: 160, y: 560 },
      { x: 280, y: 480 }, { x: 220, y: 600 },
    ],
  },
  scent_of_treats: {
    title: "Trail of Treats", category: "scent",
    summary: "Follow the biscuit trail in order, bakery to bakery.",
    coinReward: 130, bondReward: 28,
    objectives: [{ id: "trail", kind: "scentTrail", count: 4, hint: "In order: nearest first" }],
    waypoints: [
      { x: 800, y: 180 }, { x: 880, y: 240 }, { x: 920, y: 320 }, { x: 880, y: 400 },
    ],
  },
  puppy_under_bridge: {
    title: "Puppy Under the Bridge", category: "rescue",
    summary: "A whimper from below. Find the puppy, then bring it home.",
    coinReward: 180, bondReward: 38,
    breedReward: "beagle",
    objectives: [
      { id: "find", kind: "findItem", count: 1, hint: "Search near the river" },
      { id: "home", kind: "reachLocation", count: 1, hint: "Return to your house plot" },
    ],
    waypoints: [{ x: 540, y: 720, kind: "find" }, { x: 200, y: 200, kind: "home" }],
  },
};

export const NPCS = [
  { id: "postman",       emoji: "📮", x: 700, y: 280, line: "Help! I lost a package!", quest: "lost_postman_package" },
  { id: "ranger",        emoji: "🌳", x: 240, y: 420, line: "There's something buried here…",  quest: "buried_bones" },
  { id: "baker",         emoji: "🥐", x: 820, y: 220, line: "My biscuits trailed off…",        quest: "scent_of_treats" },
  { id: "park_keeper",   emoji: "🪴", x: 380, y: 220, line: "Care for a daily walk?",          quest: "daily_walk" },
  { id: "stranger",      emoji: "🌉", x: 540, y: 680, line: "I heard a whimper under the bridge.", quest: "puppy_under_bridge" },
];

export const SHELTER_SEED_STRAYS = [
  { breed: "labrador",        tier: "Regular", bond: 100 },
  { breed: "shiba_inu",       tier: "Regular", bond: 80 },
  { breed: "border_collie",   tier: "Rare",    bond: 220 },
];

export function rollBreedByRarity() {
  const total = Object.values(RARITY_WEIGHT).reduce((a, b) => a + b, 0);
  let r = Math.floor(Math.random() * total);
  for (const [rarity, w] of Object.entries(RARITY_WEIGHT)) {
    r -= w;
    if (r < 0) {
      const pool = Object.entries(BREEDS).filter(([_, b]) => b.rarity === rarity).map(([id]) => id);
      return pool[Math.floor(Math.random() * pool.length)];
    }
  }
  return "golden_retriever";
}
