# Naval Combat Resolution

## Responsibility

Detects naval conflicts per sea zone and auto-resolves fleet engagements, producing casualty lists and retreat outcomes for the turn pipeline.

## Data Model

- **BattleContextSea:** `seaZoneId`, **side1** (attacker), **side2** (defender).
  - **Side:** fleet owner id, ship instance ids/types, **mission** (`FleetMission` — used for interception eligibility and for the opponent’s retreat formula term derived from mission, not a player “aggression level”).
  - Combines multiple same-faction fleets present in one zone.

## Attacker / side1 mapping

Before interception rolls and combat resolution, each `BattleContextSea` is **normalized** so **side1 = attacker** and **side2 = defender**:

1. **Interception posture:** If exactly one faction had a moving fleet in the sea zone this turn and the other faction’s mission is **Patrol** or **Blockade**, the **interceptor** (Patrol/Blockade side) is the attacker (**side1**), and the **mover** is the defender (**side2**).
2. **Move into contested zone (no interceptor asymmetry):** Else if exactly one faction had a moving fleet in the zone, that **mover** is the attacker (**side1**).
3. **Symmetric case:** Else (both factions moved, or neither did), **side1** is the faction with the **lexicographically smaller** `ownerId`, and **side2** the other (deterministic ordering only).

Combat outcomes use the technical enum: **`side1Victory`** means the **attacker** (side1) wins; **`side2Victory`** means the **defender** (side2) wins.

## Algorithm / Flow

**Conflict Detection:**

1. After movement, scan each sea zone with fleets from 2+ factions.
2. Group by owner; for each hostile pair (war state), create a provisional `BattleContextSea` (side order from detection is arbitrary until normalized).
3. Apply **Attacker / side1 mapping** using this turn’s naval move orders (which fleet ids moved).
4. Beachhead and port fleets participate if opponents occupy the same zone.

**Strength Aggregation (per side):**

1. Compute per-ship strength as:
   - `FRP * 1.0`
   - `RNG * 0.4`
   - `ARM * 0.15`
   - `durability = HULL * (1 + ARM / 10)`
   - `MV * 0.1`
2. Sum all ship strengths into side-level raw `navalStrength`.
3. Multiply each side's raw sum by that faction's **naval feeding morale multiplier** from the current turn's Consumption phase (same breakpoints as land military: coverage ≥ 1.0 → 1.0; 0.5–<1.0 → 0.75; <0.5 → 0.5; see [turn-resolution-phase-details.md](turn-resolution-phase-details.md) § Consumption). When a faction has no ships, naval coverage is treated as 1.0 for this purpose.
4. Leader bonuses from [leader-bonuses.md](../game/leader-bonuses.md) do not apply to naval combat.

**Per-Engagement Resolution:**

1. Read morale-adjusted `navalStrength` for both sides.
2. Compute casualties (ships sunk) from relative strength and deterministic seeded RNG.
3. Compute retreat attempts using the retreat model below.
4. Return one outcome enum (`side1Victory` = attacker wins, `side2Victory` = defender wins, `stalemate`, `mutualDestruction`) and retreat flags.

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
   - `enemyAggression` (**mission-based**, not a faction “aggression level” setting): `0.1` when the **opposing** side’s mission is `patrol`, `0.2` when it is `blockade`, otherwise `0.0`
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

- Given a battle sea zone has no adjacent legal sea zone for the **attacker (side1)** (all adjacent zones contain hostile fleets)  
  When The System resolves retreat for side1  
  Then The System does not evaluate retreat probability and side1 does not retreat.

- Given the **attacker (side1)** survives naval combat and battle context mission for side1 is `patrol`  
  When The System applies naval battle results to world state  
  Then The System recreates side1 fleet with mission `patrol` instead of resetting to `none`.

- Given a naval battle resolves with both sides still having at least one surviving ship  
  When The System builds the battle result payload  
  Then The System sets outcome to `stalemate`.

- Given naval interception and combat phase runs for one turn  
  When The System processes detected battles and resolved outcomes  
  Then The System emits `logic:` debug logs with detected-battle count, post-interception count, battle outcome, and retreat flags.

- Given two at-war fleets in the same sea zone after movement, faction **A** is the only faction that had a naval move order applied this turn for a fleet in that zone, and faction **B** is not on Patrol or Blockade  
  When The System builds the normalized `BattleContextSea` for resolution  
  Then The System sets **side1** (attacker) to faction **A** and **side2** (defender) to faction **B**.

- Given two at-war fleets in the same sea zone after movement, faction **A** had a moving fleet in that zone and faction **B**’s mission in that zone is **Patrol** or **Blockade**  
  When The System builds the normalized `BattleContextSea` for resolution  
  Then The System sets **side1** (attacker) to faction **B** (interceptor) and **side2** (defender) to faction **A** (mover).

- Given two at-war fleets in the same sea zone after movement, neither faction had a moving fleet in that zone this turn, `ownerId` of one side is `gp_alpha` and of the other is `gp_beta`  
  When The System builds the normalized `BattleContextSea` for resolution  
  Then The System sets **side1** to the faction with id `gp_alpha` and **side2** to `gp_beta` (lexicographic order of `ownerId`).

- Given retreat probability is documented for naval combat  
  When a reader checks required inputs for the retreat formula  
  Then The specification does not require any per-side **cautious / normal / aggressive** attribute; only the **opponent’s mission** (`patrol` / `blockade` / other) sets the `enemyAggression` term as defined in § Retreat Resolution.
