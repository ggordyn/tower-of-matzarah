# Tower of Matzarah

## Game Design

- `.claude/game-design-overview.md` is the source of truth for the game's concept, rules, and systems. It is imported here so it loads every session: @game-design-overview.md
- When a game design decision changes or is newly settled (including answers to its "Open Design Questions"), update that file in the same change so it stays current.

## Decision Records

- Technical/architecture decisions live in `.claude/decisions/YYYY-MM-DD-<topic>.md`. Read the relevant record before working on that system; never re-ask a recorded decision. If new work contradicts one, flag it and ask before changing it.
- Implementation plans live in `.claude/plans/YYYY-MM-DD-<topic>.md`. Tick off tasks as they're completed.

## Engine

- Godot **4.7.2**, Forward Plus renderer. Use APIs and advice valid for this version.

## GodotPrompter

Before implementing any Godot system, check for a matching `godot-prompter:*` skill and invoke it (e.g. `player-controller`, `state-machine`, `save-load`, `godot-ui`). For new systems with unclear requirements, start with `godot-prompter:godot-grill`. Full index: `godot-prompter:using-godot-prompter`.

Before building, report the pattern you picked, the alternative you rejected, and why — the choice is the developer's.
