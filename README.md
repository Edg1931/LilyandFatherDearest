# Pawprint

A dog-breed collection game for Roblox. Up to 20 players per server, on-screen
controls, server-validated trading, and bond-driven dog tier-ups.

See [GAME_DESIGN.md](./GAME_DESIGN.md) for the full design.

## Project Layout

```
src/shared/   → ReplicatedStorage.Shared (data + remotes)
src/server/   → ServerScriptService.Server (authoritative logic)
src/client/   → StarterPlayerScripts.Client (input + UI)
web/          → browser-playable single-player prototype (Vercel target)
```

## Web prototype (mobile-friendly)

`web/` is a vanilla-JS, **3D** single-player demo (Three.js, no build step)
that captures the core loop (quest → bond → tier roll). Useful for previewing
the game on a phone without Roblox Studio. Three.js is loaded directly from
`esm.sh`, so the repo deploys to Vercel as plain static files.

Deploy to Vercel:

1. Push this repo to GitHub.
2. In Vercel, "Add New Project" → import the repo.
3. Either accept the defaults (the bundled `vercel.json` rewrites `/` to `web/index.html`),
   or set **Root Directory** = `web` in Project Settings → General.
4. Deploy. Open the URL on your phone.

Run locally:

```sh
cd web && python3 -m http.server 8080
# or: npx serve web
```

Progress saves to `localStorage`; reset via the help panel.

## Sync into Roblox Studio

This project uses [Rojo](https://rojo.space/) to sync source files into Studio.
Rojo is pinned to a specific version in `rokit.toml`, so the install is two
steps: install Rokit (once on your machine), then let Rokit pull the right
Rojo for this project.

### 1. Install Rokit (once)

**macOS / Linux:**

```sh
curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | sh
```

**Windows (PowerShell):**

```powershell
iwr https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1 -useb | iex
```

Restart your terminal so `rokit` is on your PATH.

### 2. Install Rojo for this project

From the repo root:

```sh
rokit install
```

This reads `rokit.toml` and installs Rojo 7.6.1. Verify:

```sh
rojo --version
```

### 3. Studio plugin

In Roblox Studio: **Plugins → Marketplace → search "Rojo" → Install**. Same
version as the CLI is best.

### 4. Run

```sh
rojo serve default.project.json
```

In Studio: open a Baseplate, click the Rojo plugin → **Connect** → port 34872 →
hit **Play**.

### Alternatives (if Rokit doesn't work for you)

- **Direct binary**: download Rojo for your OS from
  <https://github.com/rojo-rbx/rojo/releases> and put it on PATH.
- **From source**: `cargo install rojo` (requires the Rust toolchain; slow first build).

## Server Cap

`Players.MaxPlayers = 20` is set in the place properties (Studio); a code-level
fallback in `ServerCapService` rejects 21st joiners.

## In-game keybinds

| Key | Action                                                  |
|-----|----------------------------------------------------------|
| `WASD` / left thumb-stick (mobile) | Move                              |
| `E` / 🐾 button | Interact (NPCs, quest markers, treasures, prompts) |
| `F` / 🛁 button | Groom active dog                                |
| `G` / 🦴 button | Feed active dog                                 |
| `H` / 🎾 button | Play with active dog                            |
| `J` / ♥ button | Pet active dog                                   |
| `I` | Toggle Inventory                                            |
| `L` | Toggle Shelter panel                                        |
| `M` | Toggle Decor Shop / House Customizer                        |
| `B` | **Bark** — within range of another player who also barks within 2s, both packs gain +25 bond |
| `Q` | Quick-start the Daily Walk quest (debug)                    |

## World

Eleven districts radiate from a central plaza:

```
                         Park (north)
                            ⬆
                            │
              Mountains ◄──Plaza──► Bakery ► Vet ► Downtown
              + Cave ►                    │
                  │                       ▼
              Home district         Riverside, Dog Park, Beach
```

- **Plaza** — fountain, benches, lampposts, spawn pad
- **Park** — pond + trees + walking paths
- **Bakery district** — three walkable shops with vendor NPCs (treats, grooming kits)
- **Vet district** — hospital interior with Dr Hawthorne who buys you bond, plus the Shelter
- **Dog Park** — fenced agility course (jumps, weave poles, tunnel)
- **Beach** — sand, ocean, pier, lifeguard tower, palm-style trees
- **Downtown** — four skyscrapers + a walkable office
- **Mountain Pass + Cave** — pine-lined road through peaks into a glowing crystal tunnel
- **Home district** — your house + four neighbours past the cave; decor auto-arranges in your yard

## Day & night

`TimeService` cycles a full day every 12 real minutes. Lampposts ignite when night
falls. Sky/ambient/fog all shift through dawn → day → dusk → night colour palettes.

## Dogs

50 breeds across **tiny / small / medium / large / giant** size buckets, each
with a body shape, ear/tail/pattern variant, primary + secondary colors, and a
personality vector. Strays roam the world according to their **temperament**:
energetic dogs cover more ground, lazy dogs dwell longer, shy dogs stay close
to home. Lure a stray with one 🍪 to add it to your collection.

Five fantasy breeds occupy the Mythic tier: Spectral Whippet, Auroran Hound,
Cosmic Corgi, Ember Mastiff, Frostfang Husky.

## Key Files

- `src/shared/DogBreeds.lua` — 50 breeds with size/personality/visual data
- `src/shared/DecorCatalog.lua` — 35 decor items across 7 categories
- `src/server/DogRig.lua` — breed-aware procedural dog model
- `src/server/WorldBuilder.lua` — district + decoration generation
- `src/server/NpcSpawner.lua` — outdoor quest givers + interior vendors
- `src/server/StrayService.lua` — wandering strays + lure
- `src/server/TimeService.lua` — day/night cycle + lamppost toggling
- `src/server/SocialService.lua` — Bark Code social greeting
- `src/server/HouseService.lua` — decor purchase + auto-placement
- `src/server/TradeService.lua` — server-validated trade with hash confirmation
- `src/server/GroomingService.lua` — bond → tier-up roll math
- `src/client/HouseEditorUI.lua` — decor catalog browser
- `src/client/OnScreenControls.lua` — virtual joystick + action ring
- `src/shared/Tiers.lua` — tier definitions and roll probabilities
