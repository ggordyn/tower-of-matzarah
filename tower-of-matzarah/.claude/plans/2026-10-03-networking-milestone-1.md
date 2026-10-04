# Networking milestone 1 — host, join, see each other move

Decisions: `.claude/decisions/2026-10-02-multiplayer-architecture.md`
Goal: two local instances over ENet; one hosts, one joins; both control a first-person capsule and see the other move. Steam (App ID 480) is milestone step 2, a separate plan.

## Design summary

- **Replication**: built-in `MultiplayerSpawner` + `MultiplayerSynchronizer` (rejected: hand-written spawn/position RPCs — ~3× code, easy to get late-join wrong).
- **Network autoload** (`res://network/network.gd`, name `Network`): owns the peer; `host_game()`, `join_game(address)`, `leave_game()`; signals `player_connected`, `player_disconnected`, `connection_failed(reason)`, `server_disconnected`. Only place that knows the transport (ENet now, Steam later).
- **Version check**: `SceneMultiplayer` auth stage. Client sends `var_to_bytes({game, version})`; host compares against `GAME_ID` and `application/config/version`, then `complete_auth` or explains + `disconnect_peer`.
- **Main** (`res://main/main.tscn`): `Level` slot + `LevelSpawner` (spawnable: test_room.tscn) + `UI/MainMenu`. Swaps menu ↔ world on Network signals.
- **TestRoom** (`res://levels/test_room.tscn`): CSG geometry, 8 spawn markers, `Players` container, `PlayerSpawner` using a custom `spawn_function` (data `{peer_id, position}`) so spawn positions survive client authority. Server-only: spawns/despawns players on Network signals.
- **Player** (`res://player/player.tscn`): `CharacterBody3D` named by peer ID; authority set in `_enter_tree()`; local copy gets camera, mouse capture, input, `Body.cast_shadow = SHADOWS_ONLY`; remote copies disable physics process. Synchronizer replicates `position`, `rotation` every physics frame.
- **Server speed check**: server validates per-update distance against max speed + tolerance; sends owner-only correction on violation.

## Tasks

- [x] **Task 1: Network autoload + main menu + Main scene** — host/join from the menu; print confirmations on both sides; error messages for port-in-use and unreachable host.
  Skills: `godot-prompter:multiplayer-basics`, `godot-prompter:godot-ui`, `godot-prompter:scene-organization`
- [x] **Task 2: Version check** — auth handshake; verify by mismatching versions between two instances.
  Skills: `godot-prompter:multiplayer-basics`
- [x] **Task 3: Test room + first-person capsule player** — playable offline first: WASD, mouse look, gravity, Esc releases mouse.
  Skills: `godot-prompter:player-controller`, `godot-prompter:input-handling`, `godot-prompter:3d-essentials`
- [x] **Task 4: Spawning + synchronization** — LevelSpawner, PlayerSpawner with spawn function, authority, synchronizer; two windows see each other move.
  Skills: `godot-prompter:multiplayer-basics`, `godot-prompter:multiplayer-sync`
- [x] **Task 5: Disconnect handling** — leaving player removed everywhere; host quit returns clients to menu.
  Skills: `godot-prompter:multiplayer-basics`
- [x] **Task 6: Server speed sanity check** — owner-only correction on impossible movement.
  Skills: `godot-prompter:multiplayer-sync`

## Known limitation
Remote players may look choppy over real networks; interpolation is a follow-up.
