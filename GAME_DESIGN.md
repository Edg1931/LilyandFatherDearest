# Pawprint — Design Document

A dog-breed collection game in the spirit of Adopt Me, built for Roblox.
The fantasy: every dog has a soul; every player builds a pack; the world rewards
the player who *cares*, not the player who *grinds*.

---

## 1. Pillars

1. **Bond beats grind.** Tier-up odds are driven by relationship, not raw playtime.
2. **Trade like a vault.** Server-validated trades; impossible to scam, lose, or dupe.
3. **The world is the home.** Houses, yards, and shelters are persistent, visitable
   spaces — your collection lives in the world, not in a menu.
4. **Mobile first, cross-platform always.** On-screen controls are the canonical
   input scheme; PC/console map onto the same verbs.
5. **Twenty-player intimacy.** Hard cap of 20 per server. Small worlds make
   friendships, trades, and dog shows feel personal.

---

## 2. Core Loop

```
Quest → Earn coins + treats + breed unlocks
   ↓
Bring dogs to follow you (up to 3) → bond rises during quests
   ↓
Groom + play + feed at home → bond meter fills
   ↓
Bond threshold reached → "Tier Roll" attempt unlocked
   ↓
Roll succeeds → dog ascends tier (Regular → Rare → … → Neon → Mythic)
   ↓
New tier unlocks rarer quests, decor, and pack synergies
```

Every loop pass takes 5–15 minutes. Tier rolls cluster around the 30–90 minute mark
for a typical session.

---

## 3. Dog Tiers

| Tier        | Visual             | Source                                                      |
|-------------|--------------------|-------------------------------------------------------------|
| Regular     | Normal coat        | Quests, shelter adoption, starter                           |
| Rare        | Shimmer outline    | Quest rewards (uncommon), tier-up roll                      |
| Epic        | Soft particle aura | Tier-up roll from Rare                                      |
| Mega        | Color-shift coat   | Combine 4 Epics of same breed OR tier-up roll               |
| Legendary   | Glowing pawprints  | Combine 4 Megas OR rare quest chain                         |
| Neon        | Glow on 4 paws + tail | Combine 4 Legendaries (same breed) at >95% bond         |
| Mythic Neon | Full-body neon, breath particles | Combine 4 Neons (any breeds) — endgame trophy   |

**Rule:** A dog never *loses* tier. A failed roll just consumes the attempt; bond
keeps rising.

### Tier-Up Math

Bond meter is 0–1000. Tier-roll attempts unlock at 250 / 500 / 800 / 1000.

```
P(success) = base[tier] + 0.001 * bond_above_threshold
           + 0.05 * grooming_streak_days
           + 0.10 * if_dog_was_in_quest_top3_today
```

Capped at 0.85 per attempt. Failed rolls don't reset bond — they reset *attempt
charges*, which regenerate at 1/day.

This means: a player who logs in daily and actually plays with their dog will
ascend it in ~2 weeks. A whale who buys premium currency cannot skip this — there
is no "buy a tier-up" item. Premium currency only buys cosmetics, decor, and
quest-energy refills.

---

## 4. Breeds

Launch with 60 breeds across 5 rarity buckets (Common → Mythic). Real breeds
(Golden Retriever, Border Collie, Husky, Poodle, etc.) plus a dozen "fantasy"
breeds (Spectral Whippet, Auroran Hound) for the high-rarity slots.

Each breed has:
- A base **personality vector**: `{playful, brave, lazy, curious, protective}` (sums to 5).
- Rolled **traits** at hatch: 2 random modifiers (e.g. *Sniffer*, *Swift*, *Cuddler*).
- A **breed affinity**: bonus on a specific quest type (e.g. Beagles +20% on scent quests).

Personality is what makes two Huskies feel different. It also drives **Pack
Synergy** (§7).

---

## 5. On-Screen Controls

Canonical scheme — same on phone, tablet, gamepad, and PC:

```
┌──────────────────────────────────────────┐
│  ☰ menu              💰 1,240   ❤ 67/100 │
│                                          │
│                                          │
│                                          │
│   ╭───╮                          ╭────╮  │
│   │ ◎ │                          │ 🐾 │  │
│   ╰───╯                          ╰────╯  │
│   joystick                       interact│
│                          ╭────╮  ╭────╮  │
│                          │ 🛁 │  │ 🦴 │  │
│                          ╰────╯  ╰────╯  │
│                          groom    feed   │
└──────────────────────────────────────────┘
```

- Single virtual joystick (left thumb) — movement.
- Action ring (right thumb) — context-sensitive: interact / groom / feed / pet.
- Top-left HUD: coins, energy.
- Top-right: pack avatars (drag to dismiss a follower).

PC: WASD + E/F/G/H map to the four action ring slots. Gamepad: left stick + face
buttons. The controls module is one source of truth — the input layer just
forwards verbs.

---

## 6. Anti-Cheat Trade Scanner

The trade window is the single most-attacked surface in any pet collection game.
Pawprint hardens it on five layers:

1. **Server-authoritative offers.** The client never sends "give X dog to Y player"
   — it sends `OfferAdd(slotId, dogId)`. The server confirms ownership at every
   step; clients only render projections of server state.
2. **Lock-and-confirm.** Both players must press *Lock*. After lock, neither side
   can modify. A 5-second confirmation timer runs visibly. Either side may cancel.
3. **Identity hash.** When you press *Lock*, the server hashes the opponent's offer
   and shows you the hash. After confirm, the server re-hashes — if mismatched,
   trade voids. Prevents "swap-at-the-last-millisecond" client exploits.
4. **Item attestation.** Each dog carries a server-signed `attestation` blob
   `{ownerId, dogId, tier, bond, seedHash, signature}`. Trades require valid
   attestations from both sides. Duped dogs (cloned via state-rollback exploits)
   carry stale attestations and are rejected.
5. **Audit ledger.** Every trade writes an immutable record. If a player reports a
   scam, support reads the ledger — there's no he-said-she-said.

**Trades are limited to dogs and decor.** No cross-account currency, no premium
items in trade. This is a deliberate design choice: removes the entire genre of
"pay-for-rare" black-market scams.

---

## 7. Pack & Following

You can have **up to 3 dogs follow you** (5 with the *Big Pack* gamepass cosmetic;
ratio of dogs at home / following is purely aesthetic, no power gain).

Followers:
- Animate naturally (idle, run, sit, sniff) — server picks states from a small
  state machine; clients interpolate.
- Interact with the world: bark at NPCs, chase squirrels, dig at marked spots.
- Earn bond passively while following (1 / 30s).

### Pack Synergy

Combinations of personalities unlock pack abilities:

- **2× brave + 1× protective** → "Guardian Pack": NPC enemies hesitate to attack you.
- **3× curious** → "Treasure Pack": rare dig spots glow within 30 m.
- **2× playful + 1× any** → "Cheer Pack": +20% coins from minigame quests.

There are 12 launch synergies. Players discover them; they are listed in the
*Kennel Almanac* once unlocked. **Synergies don't stack with paid power.**

---

## 8. House & Yard

Each player gets a persistent **plot** (private, instanced, server-side persistent).

- **Decor budget**: starts with 50 placement slots; expand with currency.
- **Display modes** for collected dogs:
  - *Walking around* the yard (animated)
  - *Sitting on a podium* (showcase)
  - *Sleeping in beds* (cute)
  - *In storage* (kennel — no slot cost, but they don't earn passive bond)
- **Visit mode**: friends can teleport to your plot. Visitor permissions
  (read / play-with-dogs / leave-treat) are configurable.
- **Treats from visitors**: a visitor can leave one daily treat per host. The
  treat gives the host's pack a small bond boost. This makes social hosting
  *mechanically* rewarding, not just social.

### Vet & Shelter (Endgame Property)

Buying a Vet ($50,000 in-game) unlocks a buildable shelter on your plot:

- Other players can **donate strays** they don't want — strays go into your shelter.
- Strays come with random breed + low bond + 0 attestations until you "intake" them
  (which signs them to your account).
- You can adopt them out to other players, take a small coin fee, or keep them.
- Running a popular shelter earns weekly *Patron Coin* bonuses.

This turns generosity (giving away dogs) into a viable path. Hoarders can hoard;
shelterers earn.

---

## 9. Quests

Quest categories:

| Category   | Verb            | Example                                         |
|------------|-----------------|-------------------------------------------------|
| Fetch      | Retrieve item   | "Find the postman's lost package."              |
| Rescue     | Find a stray    | "A puppy is stuck under the bridge — bring it home." |
| Scent      | Follow trail    | Beagles +20%; track the scent across town.       |
| Dig        | Excavate spot   | Pack synergy *Treasure* reveals rare spots.     |
| Agility    | Timed obstacle  | Border Collies +20%.                            |
| Show       | Best-in-breed   | Weekly server event; judge picks a winner.      |
| Daily Walk | Idle walk loop  | Low-effort daily for casual players.            |

Each quest specifies which dogs were "in your party" — only present followers earn
bond, and only their breed affinities count. This makes the *choice* of who to
bring into a quest meaningful.

---

## 10. Economy

Two currencies:

- **Coins** — earned from quests, jobs, and shelter operations. Spent on decor,
  accessories, and properties.
- **Treats** — premium currency, purchasable or earned slowly via daily login.
  Spent on cosmetic dog skins, faster grooming animations, and quest-energy
  refills. **Never on tier-ups.**

### Jobs

Around the world, repeatable side jobs:

- **Dog Walker** — escort NPC dogs along a route (timed, pays per dog).
- **Park Ranger** — clean litter, plant trees (pays per item).
- **Bakery Helper** — minigame, pays per round.
- **Photographer** — snap pictures of wild dog NPCs (rare-breed snaps pay more).

Jobs respect a cooldown so a single grindy player can't drain the server economy.

---

## 11. Server Cap (20)

Roblox lets us set `Players.MaxPlayers = 20` at the place level. We belt-and-brace
this in code: a `ServerCapService` listens to `PlayerAdded` and politely kicks any
21st joiner with a friendly message ("This world is full — try a different
server"). MatchMaking (Roblox's built-in) handles routing to a non-full instance.

20 is intentional: enough for a busy park, small enough that you start to
recognize names.

---

## 12. Innovative Twists (the "outside the box" list)

1. **Dog Memory.** Each dog tracks the *last 7 quests* it joined. NPCs reference
   it: "Oh, this Husky was at the bakery yesterday!" Tiny but it makes the world
   feel alive.
2. **Bark-Code.** Two players can press *Bark Together* near each other; if both
   press within 1 s, both packs gain a tiny bond boost. Costs nothing. Encourages
   strangers to greet each other.
3. **Weather-Driven Spawns.** Rain spawns Newfoundlands; snow spawns Huskies;
   fog spawns rare breeds. Drives players to log in across conditions.
4. **Scent Trails Between Servers.** Once per day, a "stray" leaves a scent trail
   in your server that, if followed, hands off to a friend's server next time you
   visit them. Cross-server breadcrumbs without a real cross-server.
5. **Dog Show Spectator Mode.** During the weekly show, non-competing players in
   the server can vote *People's Choice*. Vote-power is proportional to how much
   time you've spent at home (not how much you spent on premium). Casual players'
   votes count.
6. **Lost Dog Posters.** When you log out with dogs in pack, there's a 1% chance
   one of them appears on a "lost dog" poster in another player's server for 10
   minutes. Returning it earns the finder a treat; the original owner doesn't lose
   the dog (it auto-returns at session start). Pure social delight.
7. **Inheritance.** Two of your bonded dogs at home can have a *playdate*; once
   per week, one of them produces a puppy carrying mixed traits (not breeds — a
   Beagle stays a Beagle, but inherits a personality modifier from its
   playmate). No real breeding mechanics; just a soft "kids of the kennel"
   gesture.
8. **No Trading Highs.** Trade values are *not* surfaced in-game. There is no
   "rarity index" UI. This kills the "WFL?" toxicity prevalent in collector
   games — your dog is worth what you feel it's worth.
9. **The Memorial Tree.** When a player permanently retires a dog (a deliberate,
   confirmed action), it joins a glowing tree in the central park, with the
   player's chosen epitaph. Creates a sense of legacy.
10. **Photo Mode Currency.** Each dog has a *photogenic stat* that grows when
    you take screenshots in-game. High-photogenic dogs earn small Treats when
    other players "like" your photos in the Park gallery. Aesthetic play loop.

---

## 13. Tech Architecture (Roblox / Rojo)

```
src/
├── shared/         → ReplicatedStorage.Shared       (data, remotes, constants)
│   ├── Tiers.lua
│   ├── DogBreeds.lua
│   ├── Remotes.lua
│   ├── Constants.lua
│   └── Quests.lua
├── server/         → ServerScriptService.Server      (authoritative logic)
│   ├── init.server.lua
│   ├── PlayerDataService.lua
│   ├── DogService.lua
│   ├── TradeService.lua          ← anti-cheat scanner
│   ├── GroomingService.lua
│   ├── QuestService.lua
│   ├── EconomyService.lua
│   ├── HouseService.lua
│   ├── ServerCapService.lua
│   └── AntiCheatService.lua
└── client/         → StarterPlayerScripts.Client     (input, UI, projections)
    ├── init.client.lua
    ├── OnScreenControls.lua
    ├── HUD.lua
    ├── InventoryUI.lua
    ├── TradeUI.lua
    └── HouseEditorUI.lua
```

Server is authoritative for everything that affects state. Client renders. Remotes
are typed (one `RemoteEvent` per verb, validated argument shape). Persistent data
uses `DataStoreService` with versioned profile schemas; a third-party library like
ProfileService is recommended for production (session locking, retries).

---

## 14. Out-of-Scope (v1)

- Real-money trades, NFTs, or external marketplaces.
- Dog-on-dog combat.
- Open-ended breeding (intentionally — see §12.7).
- Cross-server matchmaking beyond the scent-trail gimmick.

We can revisit these post-launch based on what players actually love.
