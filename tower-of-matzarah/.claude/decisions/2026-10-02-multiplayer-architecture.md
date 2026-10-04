# Multiplayer architecture — decisions

| Decision | Choice | Why | Revisit when |
|---|---|---|---|
| Scope | Real networking foundation, first milestone kept small: host, join, see each other move | Developer is learning multiplayer but wants the authority model right from the start; prototype net code tends to survive | — |
| Dimension | 3D, retro / low-fi art style | Atmosphere for a dark vertical tower while keeping art cost low | — |
| Language | GDScript | Best documented, developer has prior experience | — |
| Hosting | Listen server (one player hosts and plays), code kept server-authoritative so a dedicated server stays possible | Friends-oriented, non-competitive game; zero hosting cost; standard for the genre on Steam | hidden-info cheating by hosts becomes a real problem, or public matchmaking is added |
| Host trust | Accepted: the host can technically read hidden info (Impostor identity, marks) | Unavoidable when the host runs game logic; acceptable among friends | same as Hosting |
| Authority model | Server-authoritative: clients send input/requests, server validates and decides roles, kills, tasks, votes | Required for a social-deduction game; makes the dedicated-server move a deployment change | — |
| Hidden info delivery | Role-secret data sent only to the peer entitled to it (`rpc_id` / per-peer sync visibility), never broadcast | Prevents non-host clients from reading Impostor identity from memory or traffic | — |
| Platform | Launch on Steam | Developer's stated target | — |
| Player count | 4–8 players, one Impostor | Below 4 deduction is trivial; above 8 strains proximity voice and floor space | playtests show crowding or empty floors |
| Camera | First-person | Preserves horror and scares; darkness and limited view are part of the tension | — |
| Join policy | Join in lobby only; no mid-match joining | Avoids syncing hidden state to late joiners | reconnection work begins |
| Disconnect policy | Disconnected player is removed; living-wizard task requirements shrink accordingly; Impostor disconnect = wizards win | Matches the design's dynamic task scaling; simple and fair | reconnection work begins |

| Movement authority | Client-authoritative movement; server sanity-checks (e.g. max speed) and stays authoritative for kills, tasks, roles, doors, votes | Instant-feeling movement for scares/dodging; far simpler than server-side movement with prediction; movement cheating is low-stakes among friends | cheating or desync complaints in playtests |
| Network transport | Swappable peer behind Godot's `MultiplayerAPI`: ENet for local development, Steam networking (GodotSteam) for playing with friends | One Steam account per PC means local multi-window testing needs ENet; Steam gives NAT traversal, hidden IPs, invites | — |
| First milestone | Step 1: host/join/see each other move over ENet (local multi-window). Step 2: swap to Steam with shared test App ID 480 and play with friends | Learn raw networking first, then real-world friend tests at no cost | — |
| Beta distribution | App ID 480 zips for early friend tests → own Steam App ID (Steam Direct fee) with keys/beta branch/Playtest once the game justifies it | Free path now, clean update delivery later | — |
| First-person body | Local player: viewmodel arms + full body set to shadows-only and hidden from own camera via render layers / `cull_mask`; others see full body | Standard FPS approach; keeps own shadow for atmosphere | — (capsules until art exists) |

## Open / deferred
- Reconnection to an in-progress match — deferred by developer.
- Proximity voice chat — leaning on Steam's voice API played through positional 3D audio; design after the first milestone.
- GodotSteam build/version compatibility with Godot 4.7.2 — verify when installing (step 2).
