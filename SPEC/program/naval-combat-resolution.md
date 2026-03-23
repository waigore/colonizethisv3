# Naval Combat Resolution

## Responsibility

Detects naval conflicts per sea zone and auto-resolves fleet engagements, producing casualty lists and retreat outcomes for the turn pipeline.

## Data Model

- **BattleContextSea:** `seaZoneId`, list of sides.
  - **Side:** fleet owner id, ship ids, mission type, aggression level, tech snapshot.
  - Combines multiple same-faction fleets present in one zone.

## Algorithm / Flow

**Conflict Detection:**

1. After movement and interception, scan each sea zone with fleets from 2+ factions.
2. Group by owner; for each hostile pair (war state), create/update a BattleContextSea.
3. Beachhead and port fleets participate if opponents occupy the same zone.

**Strength Aggregation (per side):**

1. Compute per-ship strength as:
   - `FRP * 1.0`
   - `RNG * 0.4`
   - `ARM * 0.15`
   - `durability = HULL * (1 + ARM / 10)`
   - `MV * 0.1`
2. Sum all ship strengths into side-level `navalStrength`.
3. Leader bonuses from [leader-bonuses.md](../game/leader-bonuses.md) do not apply to naval combat.

**Per-Engagement Resolution:**

1. Read `navalStrength` for both sides.
2. Compute casualties (ships sunk) from relative strength and deterministic seeded RNG.
3. Compute retreat attempts using the retreat model below.
4. Return one outcome enum (`side1Victory`, `side2Victory`, `stalemate`, `mutualDestruction`) and retreat flags.

Handles both interception-triggered and end-of-movement battles.

**Retreat Resolution:**

Per [ships-and-naval.md](../game/ships-and-naval.md) § Naval Combat, retreat requires an adjacent friendly/neutral zone.

1. Determine if at least one adjacent sea zone is legal:
   - Legal when no hostile fleet is present in that adjacent zone.
   - Hostility uses diplomacy `atWar` relation with the retreating side.
2. If no legal adjacent zone exists, retreat chance is not evaluated and retreat is disallowed.
3. If a legal adjacent zone exists, compute:
   - `baseChance = 0.6`
   - `speedAdvantage = (ownAvgMV - enemyAvgMV) * 0.1`
   - `enemyAggression = 0.1` when enemy mission is `patrol`, `0.2` when enemy mission is `blockade`, otherwise `0.0`
   - `P_retreat = clamp(baseChance + speedAdvantage - enemyAggression, 0.1, 0.95)`
4. Resolve with deterministic seeded RNG.
5. Success relocates surviving ships to a legal adjacent zone.

## Interception Model

When one side moved into a contested sea zone and the opposing side is on `patrol` or `blockade`, interception probability is:

1. `fleetInterceptScore = Σ ship.interceptRating` for interceptor ships.
2. `targetFleeScore = Σ ship.fleeRating` for moving fleet ships.
3. `ratio = fleetInterceptScore / (fleetInterceptScore + targetFleeScore)`.
4. `missionFactor = 0.5` for Patrol, `0.9` for Blockade.
5. `P_intercept = clamp(missionFactor * ratio, 0.05, 0.85)`.

## Integration

- **Phase:** Naval Interception & Naval Combat step ([turn-resolution-phases.md](turn-resolution-phases.md)), after Movement.
- **Upstream:** Fleet state from [naval-movement-resolution.md](naval-movement-resolution.md); diplomacy war state; per-ship stats from colonizethis_data.
- **Downstream:** Casualty and location updates applied to WorldState by turn resolver.

## Constraints

- Deterministic for a given seed.
- All per-ship ratings come from colonizethis_data.
- Owned by colonizethis_logic.

## Acceptance Criteria

- Given side 1 has one `carrack` in a sea battle context  
  When The System computes naval strength  
  Then The System uses `FRP*1.0 + RNG*0.4 + ARM*0.15 + HULL*(1+ARM/10) + MV*0.1` for that ship and returns the exact summed value for the side.

- Given an interceptor with intercept score `8`, a moving target with flee score `2`, and mission `blockade`  
  When The System computes interception probability  
  Then The System computes `ratio = 8/(8+2)`, applies mission factor `0.9`, and clamps the result to `[0.05, 0.85]`.

- Given a battle sea zone has no adjacent legal sea zone for side 1 (all adjacent zones contain hostile fleets)  
  When The System resolves retreat for side 1  
  Then The System does not evaluate retreat probability and side 1 does not retreat.

- Given side 1 survives naval combat and battle context mission for side 1 is `patrol`  
  When The System applies naval battle results to world state  
  Then The System recreates side 1 fleet with mission `patrol` instead of resetting to `none`.

- Given a naval battle resolves with both sides still having at least one surviving ship  
  When The System builds the battle result payload  
  Then The System sets outcome to `stalemate`.

- Given naval interception and combat phase runs for one turn  
  When The System processes detected battles and resolved outcomes  
  Then The System emits `logic:` debug logs with detected-battle count, post-interception count, battle outcome, and retreat flags.
