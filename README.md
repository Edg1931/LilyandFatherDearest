# Pawprint

A dog-breed collection game for Roblox. Up to 20 players per server, on-screen
controls, server-validated trading, and bond-driven dog tier-ups.

See [GAME_DESIGN.md](./GAME_DESIGN.md) for the full design.

## Project Layout

```
src/shared/   → ReplicatedStorage.Shared (data + remotes)
src/server/   → ServerScriptService.Server (authoritative logic)
src/client/   → StarterPlayerScripts.Client (input + UI)
```

## Sync into Roblox Studio

This project uses [Rojo](https://rojo.space/). After installing Rojo:

```sh
rojo serve default.project.json
```

Then in Studio: install the Rojo plugin, click *Connect*, hit *Play*.

## Server Cap

`Players.MaxPlayers = 20` is set in the place properties (Studio); a code-level
fallback in `ServerCapService` rejects 21st joiners.

## Key Files

- `src/server/TradeService.lua` — server-validated trade with hash confirmation
- `src/server/GroomingService.lua` — bond → tier-up roll math
- `src/client/OnScreenControls.lua` — virtual joystick + action ring
- `src/shared/Tiers.lua` — tier definitions and roll probabilities
