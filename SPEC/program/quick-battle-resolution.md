# Quick Battle resolution (technical)

## Purpose

This spec defines the **technical pipeline** for resolving Quick Battles in Phase 4. Quick Battle is a one-province attacker vs defender tactical mini-game (see `SPEC/game/quick-battle.md`) that feeds the same casualty/flip pipeline as Phase 3 auto-resolve combat. This document focuses on data structures, resolution steps, and integration points; it does not redefine combat rules or tactical stats.

Quick Battle must be:

- **Deterministic for a given seed.**
- **Consistent** with Phase 3 combat (same tactical stats, modifiers, and casualty/flip semantics).
- **Isolated** from UI concerns; the app drives it via a clean API.

## Inputs

Quick Battle resolution receives a single request describing the battle:

- **Battle context**
  - Attacker faction id; defender faction id.
  - Province id (must match the conflict province).
  - Base province terrain and fort/siege details as needed by combat.
- **Lanes and groups (per side)**
  - For each side and lane (`LEFT`, `CENTER`, `RIGHT`, `RESERVE`), and for each line (`FRONT`, `SUPPORT` where applicable):
    - List of unit references or a summarized composition (unit types, counts, medals).
    - Aggregated tactical stats (FPN, FPM, RNG, DEF, MVR) computed from config in `colonizethis_data`.
    - Current cohesion value (integer scale, e.g. 0–3).
  - Lane terrain tag: `OPEN` | `HILL` | `WOODS` | `TOWN` | `SWAMP`.
- **Initial state**
  - Starting round index (normally 1).
  - Max rounds (Phase 4: 3).
- **Randomness**
  - A Quick Battle seed (derived from game/global/AI seeds; see `ai-planner.md`).
  - The resolver uses this seed (and derived sub-seeds) for all random draws.

The resolver should not depend on global singletons; all needed data is supplied or derived from shared configuration.

## Outputs

The resolver returns a result record consumable by the existing combat pipeline:

- **Per-side casualties**
  - Casualties per unit type, at minimum.
  - Optionally, more detailed casualties per battalion group (lane + line) if needed for logging.
- **Battle outcome flags**
  - `winner`: `ATTACKER`, `DEFENDER`, or `MUTUAL_EXHAUSTION` (for future nuance).
  - `provinceFlips`: boolean indicating whether the province changes owner.
  - `attackerRouts` / `defenderRouts`: booleans indicating catastrophic collapse.
- **Final tactical state (for logs or optional UI)**
  - Surviving composition in each lane and line.
  - Final cohesion per group.
  - Summary lane statuses (e.g. `INTACT`, `BROKEN`, `EMPTY`).

The TurnResolver uses `casualties` and `provinceFlips` to mutate `WorldState` exactly as in auto-resolve combat.

## Resolution algorithm (per round)

Quick Battle runs a bounded loop:

1. Initialize from inputs; set `round = 1`.
2. While `round <= maxRounds` and neither side has clearly collapsed:
   - Determine which side acts first (initiative, consistent with Phase 3 rules).
   - For the first side:
     - Start with 2–3 Command Points.
     - Apply each chosen action in sequence (from UI or AI), updating an internal, side-specific “orders” structure for the round.
   - Repeat for the second side.
   - Apply **resolution step**:
     - Compute lane-level effective strengths for both sides (see below).
     - Apply action effects: fire, maneuvers, assaults, and cohesion changes.
     - Check for lane and side collapse (e.g. broken center, multiple broken lanes, or near-zero remaining strength).
   - Increment `round`.
3. After the loop, derive final casualties and outcome flags from accumulated effects and collapse status.

### Lane-level strength computation

For each lane and side, the resolver computes an effective offensive and defensive strength based on:

- Aggregated underlying tactical stats (FPN, FPM, RNG, DEF, MVR) from Phase 3 config.
- Cohesion (higher cohesion scales strength up; low cohesion scales it down).
- Lane terrain tag:
  - `HILL` / `TOWN` → improved defense and often better ranged strength.
  - `WOODS` → improved defense but reduced ranged effectiveness; maneuver penalties.
  - `SWAMP` → penalties to attack, defense, and maneuver.
  - `OPEN` → baseline.
- Current stance or action for the lane (e.g. Defend vs Assault).

These effective strengths are then used in the same family of combat formulas as auto-resolve (attacker vs defender strength comparison plus randomness) to generate casualties and disruption for that round.

### Action effects

Each action type chosen by a side maps to a set of modifiers for that round:

- **Volley Fire:** increases the amount of ranged damage dealt from the chosen lane’s front line (and eligible support) to the opposing lane; largely affects casualties and disruption.
- **Defend / Entrench:** boosts defensive strength and sometimes reduces casualties taken in that lane; imposes a movement penalty.
- **Maneuver:** changes the assignment of units between lanes and lines; may apply a small cohesion cost, especially through bad terrain.
- **Fall Back / Refuse Flank:** pulls units out of immediate danger (reducing exposure to casualties) at the cost of temporary cohesion and possibly ceding battlefield advantage.
- **Assault / Charge:** greatly increases attack potential in one lane, with additional risk if terrain is unfavorable or the enemy remains cohesive.

The resolver does not decide actions; it applies actions provided by the caller.

## Collapse and outcome

At the end of each round, the resolver evaluates:

- Per-lane status:
  - Whether the lane still has cohesive, combat-capable units.
  - Whether the front line is broken (cohesion 0) even if some units remain.
- Side-level morale:
  - Derived from total remaining strength, remaining cohesive groups, and especially the state of `CENTER`.

Conditions that typically indicate **attacker victory**:

- Defender `CENTER` and at least one flank lane broken or empty, with attacker maintaining reasonable cohesion in `CENTER` (and/or both flanks).
- Defender total effective strength drops below a configured threshold while attacker’s remains above.

Conditions for **defender hold**:

- Attacker fails to break `CENTER`, or attacker effective strength/morale drops below threshold while defender retains at least one solid lane.

**Mutual exhaustion** can be used when both sides are badly mauled without a clear line collapse; in Phase 4 this may map to defender holding the province but with unusually high casualties on both sides.

After deciding the winner and whether the province flips, the resolver converts group-level damage into the same casualty representation that auto-resolve uses, so TurnResolver can apply it without special casing.

## Integration with combat phase

Quick Battle fits into the existing combat phase as follows:

- Conflict detection and battle ordering remain unchanged (see `combat-resolution.md` and `turn-resolution-phases.md`).
- For each battle:
  - A **combat mode selection** step chooses Auto-Resolve or Quick Battle.
  - If Quick Battle is chosen:
    - The engine constructs a Quick Battle input request from `WorldState` and config.
    - The app or AI runs the Quick Battle loop (driving actions per round) and calls this resolver each round or at the end, depending on implementation detail.
    - The resulting casualties and flip flag are returned to the main combat pipeline.
  - If Auto-Resolve is chosen:
    - Existing auto-resolve logic runs unchanged.

Quick Battle must use the same configuration sources (tactical stats, terrain/fort modifiers, difficulty settings) as auto-resolve to avoid divergence between the two modes.

