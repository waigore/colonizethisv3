# Quick Battle Resolution

**SPEC/program** — Quick Battle resolution pipeline. Province identity: [world-model-identity.md](../game/world-model-identity.md).

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

- **Province identity:** Battle context province id and any province lookup (e.g. applying casualties or province flip) follow [world-model-identity.md](../game/world-model-identity.md): use prefixed form (`regionId|localId`); never look up by province id alone.
- Deterministic for a given seed.
- Must use the same config sources as auto-resolve (no divergence between modes).
- Does not depend on global singletons; all data supplied or derived from shared config.
- Owned by colonizethis_logic.

## Acceptance criteria

- Given the same Quick Battle seed and identical inputs (battle context, lanes and groups per side, starting round, max rounds)  
  When the resolver runs to completion twice  
  Then the resolver returns the same battle outcome (ATTACKER, DEFENDER, or MUTUAL_EXHAUSTION), the same per-side casualties, the same provinceFlips and attackerRouts/defenderRouts flags, and the same final tactical state (surviving composition, cohesion, lane statuses).

- Given the resolver has completed a Quick Battle run  
  When the caller inspects the resolver output  
  Then the output conforms to the Data Model § Output: per-side casualties (by unit type or battalion group), battle outcome, provinceFlips boolean, attackerRouts/defenderRouts booleans, and final tactical state with lane statuses INTACT, BROKEN, or EMPTY.

- Given combat phase invokes Quick Battle as an alternative to auto-resolve for a province  
  When the resolver returns casualty lists and province-flip flag  
  Then the combat pipeline applies the result via the same integration point as auto-resolve (e.g. applyQuickBattleResultToGame or equivalent); WorldState mutation is performed by the turn resolver per [turn-resolution-phases.md](turn-resolution-phases.md).

- Given the resolver receives battle context that includes a province id  
  When the resolver or downstream pipeline applies casualties or province flip for that battle  
  Then the province id is in prefixed form (`regionId|localId`) and any province lookup follows [world-model-identity.md](../game/world-model-identity.md); the resolver does not look up by province id alone or assume a default region.
