# Tower of Matzarah — Game Design Overview

## Concept

A multiplayer social-deduction game (Among Us-style) built in Godot. A group of wizards enters a demon's tower to free it from a haunting by climbing to the top together. One wizard is secretly possessed by the demon from the start — the **Impostor**. The impostor can manipulate the tower, trigger traps, scare and stun wizards, and try to isolate and kill them, while pretending to be a normal wizard.

## Platform & Presentation

- **3D** with a **retro / low-fi art style** — atmospheric for a dark vertical tower while keeping art cost low.
- **First-person** camera, to preserve horror and scares.
- Online multiplayer among friends, **4–8 players** with one Impostor; one player hosts. Planned release on **Steam**.
- Players join in the lobby only. A player who disconnects mid-match is removed (task requirements shrink with living wizards); if the Impostor disconnects, the wizards win. Reconnection is not yet designed.

## Win / Loss Structure

The primary, always-active goal is for all wizards to reach the top of the tower together. Victory isn't strictly binary — each side has a tiered outcome:

- **Wizards**: full win (reach the top *and* the impostor was exiled) > partial win (reach the top, impostor survived undetected) > loss (fail to reach the top)
- **Impostor**: full win (prevents the wizards from completing the climb) > partial win (survives undetected the whole match even if the wizards succeed) > loss (exiled, and the wizards still succeed)

This layered structure gives the impostor a reason to keep playing even after being caught (see Spirit Phase below), and gives wizards a real incentive to investigate and accuse rather than just rushing upward.

## Corruption System

Each floor has its own **local corruption meter** (not a tower-wide clock), so pressure is tied to decisions made on that specific floor rather than punishing the whole run for one slow floor.

- Corruption doesn't kill directly. Instead, it inflicts a **debuff** on wizards exposed to it for too long: blurred vision, slowed movement, muted sound cues, and increased vulnerability to traps.
- The debuff worsens the longer a wizard stays in corrupted areas, and fades the longer they stay out of them.
- **Cleansing options**, in increasing order of risk/cost:
  1. **Partnered cleanse** — fast and relatively safe.
  2. **Solo cleanse** — slower, forces the wizard to stand still, leaving them exposed.
  3. **Retreat** away from the corrupted area — safe, but very slow and costs tower progress.
- There is intentionally no hard softlock: even if every wizard is corrupted at once, the worst outcome is being "extremely vulnerable," not an automatic death.
- Corruption exposure on a floor also feeds into the demon's power growth (see Demon Ability Progression).

## Tasks

Tasks are split into three functional categories:

1. **Progression tasks** — required to unlock the door to the next floor. Mostly cooperative, with a visible shared counter (e.g. "3/5 complete"). These are the critical path and the main tool for forcing wizards to group up.
2. **Corruption-cleanse tasks** — reactive, tied to the debuff system, not always active.
3. **Utility/support tasks** — optional, mostly solo-friendly, help the group indirectly without gating progress (e.g. relighting braziers to extend safe/lit zones, repairing cracked floor sections or hazards).

Cooperative progression tasks are designed as small real-time minigames requiring genuine individual input from each participant — not just synchronized button-holding. This makes tasks feel meaningful and also opens up a subtle, deniable sabotage vector: an impostor who's "helping" can intentionally fumble their part without it looking suspicious.

**Progression task ideas defined so far:**

- **Glyph Relay**: One wizard sees a hidden rune sequence and calls it out loud; the other casts it on a panel under time pressure. Solo fallback: slower, requires memorizing chunks and running back and forth between the glyph source and the input point.
- **Mirror Channeling**: One wizard redirects a beam of light using movable mirrors/prisms; the other stabilizes/receives it at a distant altar, requiring real-time verbal coordination. A possible late-game twist: moving obstacles that intermittently block the beam.
- **Weight-Matching Platform**: Wizards (and possibly carried items) must distribute themselves across pressure plates so total weight balances within a tolerance — a puzzle rather than a simple hold-button mechanic.
- **Rune-Position Circle**: Each wizard gets a different symbol/color prompt and must move to the matching rune position on a circle whose layout shuffles each attempt. Wrong or slow placement destabilizes the ritual.

Cooperative task requirements scale dynamically with the number of living wizards remaining (e.g. "2 of however many are left"), so progress can never be hard-blocked by deaths.

## Impostor Gameplay Loop (While Alive)

The impostor's toolkit is built so that normal movement and sabotage prep look identical — there's no "performed" animation that gives them away during setup.

- **Marking**: Passive, with no animation or visible tell. Happens automatically just by walking near or through trap locations during normal movement (including while faking tasks). Marking is limited to the impostor's current floor.
- **Spirit Mode**: The core activation mechanic, designed as a *multitasking* tool rather than a high-commitment channel:
  - The impostor's consciousness leaves their body to trigger marked traps or scout the floor, but the dip can be **canceled quickly** at any time.
  - A **short cooldown** applies whether they cancel early or complete the dip, preventing spamming.
  - Limited strictly to the impostor's **current floor**.
  - **Audio/perception follows the spirit, not the body** — spirit mode doubles as a spying tool, letting the impostor overhear nearby conversations and suspicions.
  - **The body is fully blind and deaf while unattended** — a genuine risk/reward trade-off between offense (scouting/triggering) and defense (staying responsive if approached).
  - The body stays visually still and unresponsive during spirit mode — that stillness is the only tell. There is no disguise mechanic layered on top of it.
  - **Warning system**: an aura radius equal to the normal proximity-voice-chat range. If a wizard enters that radius, the impostor gets a generic warning (no info on who, how many, or threat level). There is no additional grace period beyond that warning.
- **Spells and Murder** are the only actions with distinct, visible animations — rare, high-commitment, and high-payoff if witnessed.
- The **kill ability** is the impostor's reward for staying alive and undiscovered. It should have range limits, require isolation (no nearby witnesses), a cooldown between uses, and leave a discoverable body.

## Spirit Phase (After Being Exiled)

If the impostor is caught and exiled, their human body dies, but the demon persists as a **weakened spirit**:

- Loses the ability to kill directly, but retains indirect lethality through environmental hazards: triggering traps, collapsing floor sections, etc.
- Hazards are **telegraphed** with visible tells (spreading cracks, glowing glyphs, warning sounds) so attentive wizards can avoid them or warn others — especially in early floors.
- **Darkness is the spirit's key amplifier**: it can dim or extinguish lights to make tells harder to spot. The counterplay is clear — relight torches, stay in lit areas.
- Hazards are environmental/area-based rather than targeted at specific wizards, fitting the "weakened" theme.
- The spirit's win condition shifts from active hunting to **stalling/interfering** long enough that corruption or environmental hazards wear the wizards down instead.

## Demon Ability Progression

- Ability unlocks follow a **fixed tier order** (not fully random) to keep match pacing consistent and learnable. Rough shape: early tier = scares/minor sabotage → mid tier = stronger traps/stuns → late tier = major tower control.
- Within each tier, **corruption exposure weights the random roll** — higher corruption on a floor skews the roll toward the nastier end of that tier's pool. This directly rewards sloppy/slow wizard play with a scarier impostor.
- **Scares** are the baseline early toolset:
  - Early scares are dodgeable, with a clear, learnable tell (a flicker, a sound, a shadow) and a reasonable reaction window.
  - Later scares are harder to dodge — shorter or subtler tells, often paired with the darkness mechanic.
  - Some traps/glyphs can carry a built-in scare effect, combining stun/blind/deafen with a physical hazard.
- Exact tier count and full ability roster are still undecided, pending floor count/structure decisions.

## Open Design Questions

- Total number of floors, and floor size/pacing.
- Exact number of demon ability tiers and their full contents.
- Full task roster and variety beyond the four progression tasks defined above.
- Corruption-cleanse task design (deferred).
- Accusation/exile mechanic — how wizards actually accuse, vote on, or catch the impostor (not yet designed).

## Implementation Notes for Godot

This is a multiplayer game, so core systems to plan around:
- Networked player state (wizard vs. impostor role, position, corruption debuff level, alive/dead/spirit state).
- A floor/room manager tracking per-floor corruption level, task completion counts, and door-lock state.
- A trap/mark system tied to floor geometry, with network-synced "marked" state readable only by the impostor.
- A proximity voice chat system, since it's load-bearing for both normal play and the Spirit Mode warning mechanic (aura radius = voice chat radius).
- A spirit-mode state machine for the impostor: active/canceled/cooldown, with perception source switching between body and spirit position.
- Ability-tier unlock system driven by an XP/corruption-accumulation value, with weighted random selection within the current tier.
