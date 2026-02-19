# Quick Battle Resolution

## Responsibility

Resolver for the Quick Battle tactical mini-game — a bounded, per-round loop that processes player/AI actions and produces casualties and province-flip outcomes compatible with the auto-resolve combat pipeline.

## Data Model

**Input:**

- **Battle context:** attacker/defender faction ids, province id, province terrain, fort/siege details.
- **Lanes and groups (per side):** for each lane (LEFT, CENTER, RIGHT, RESERVE) and line (FRONT, SUPPORT): unit references/composition, aggregated tactical stats (FPN, FPM, RNG, DEF, MVR), cohesion (0–3), lane terrain tag.
- **Control:** starting round (default 1), max rounds (default 3), Quick Battle seed (deterministic).

**Output:**

- Per-side casualties (by unit type; optionally per battalion group).
- Battle outcome: `ATTACKER`, `DEFENDER`, or `MUTUAL_EXHAUSTION`.
- `provinceFlips` boolean.
- `attackerRouts` / `defenderRouts` booleans.
- Final tactical state: surviving composition, cohesion, lane statuses (`INTACT`, `BROKEN`, `EMPTY`).

## Algorithm / Flow

1. Initialize from inputs; `round = 1`.
2. While `round ≤ maxRounds` and no side has collapsed:
   a. Determine initiative (consistent with Phase 3 combat rules).
   b. First side spends 2–3 CP on actions (from caller — UI or AI).
   c. Second side spends CP.
   d. **Resolution step:**
      - Compute lane-level effective strength per side: base tactical stats × `(cohesion / 3)` × terrain modifier × stance/action modifier. Uses the same combat formula family as auto-resolve.
      - Apply action effects (fire → casualties/disruption, defend → defensive bonus, maneuver → unit reassignment ± cohesion cost, fall back → reduced exposure at cohesion cost, assault → high attack potential with terrain risk). Action definitions in [quick-battle.md](../game/quick-battle.md) § Turn structure and actions.
      - Update cohesion per group; check lane/side collapse per [quick-battle.md](../game/quick-battle.md) § Outcome and integration.
   e. Increment `round`.
3. Derive final casualties and outcome from accumulated damage and collapse state.
4. Convert group-level damage into the standard casualty representation used by auto-resolve.

The resolver does not decide actions; it applies actions provided by the caller.

## Integration

- **Phase:** Combat phase, as alternative to auto-resolve ([turn-resolution-phases.md](turn-resolution-phases.md)).
- **Upstream:** Conflict detection and battle ordering from [combat-resolution.md](combat-resolution.md); WorldState and config for constructing input. Tactical stats, terrain modifiers, and difficulty settings shared with auto-resolve.
- **Downstream:** Casualty lists and province-flip flag returned to the combat pipeline; WorldState mutation by turn resolver.

## Constraints

- Deterministic for a given seed.
- Must use the same config sources as auto-resolve (no divergence between modes).
- Does not depend on global singletons; all data supplied or derived from shared config.
- Owned by colonizethis_logic.
