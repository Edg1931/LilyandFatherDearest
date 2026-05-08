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

## Key Files

- `src/server/TradeService.lua` — server-validated trade with hash confirmation
- `src/server/GroomingService.lua` — bond → tier-up roll math
- `src/client/OnScreenControls.lua` — virtual joystick + action ring
- `src/shared/Tiers.lua` — tier definitions and roll probabilities
