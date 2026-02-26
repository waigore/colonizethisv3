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

1. Compute firepower score from FRP and RNG (RNG weighted highest per [ships-and-naval.md](../game/ships-and-naval.md) § Naval Combat).
2. Compute durability score from ARM and HULL.
3. Apply medal multipliers and tech modifiers (leader bonuses from [leader-bonuses.md](../game/leader-bonuses.md) do not apply to naval combat).
4. Aggregate into side-level `navalStrength`. Weights from config, tunable per ruleset.

**Per-Engagement Resolution:**

1. Read `navalStrength` for both sides; apply mission modifiers per [ships-and-naval.md](../game/ships-and-naval.md) § Missions and Movement.
2. Apply optional terrain-style modifiers (coastal vs open ocean).
3. Compute casualties (ships sunk/damaged) and retreat attempts.
4. Return: attacker victory, defender victory, stalemate, or mutual destruction — plus casualty ids and retreat flags.

Handles both interception-triggered and end-of-movement battles.

**Retreat Resolution:**

Per [ships-and-naval.md](../game/ships-and-naval.md) § Naval Combat, retreat requires an adjacent friendly/neutral zone.

1. `fleetFleeScore = Σ ship.fleeRating` (retreating side).
2. `pursuerInterceptScore = Σ ship.interceptRating` (opposing side).
3. `R = fleetFleeScore / (fleetFleeScore + pursuerInterceptScore)`.
4. Aggression modifier: cautious ×1.1, normal ×1.0, aggressive ×0.8.
5. `P_retreat = clamp(R × aggressionMod, 0.1, 0.95)`.
6. Resolve with deterministic seeded RNG.
7. Success → surviving ships relocate to neighbouring zone. Failure → additional losses before outcome.

## Integration

- **Phase:** Naval Interception & Naval Combat step ([turn-resolution-phases.md](turn-resolution-phases.md)), after Movement.
- **Upstream:** Fleet state from [naval-movement-resolution.md](naval-movement-resolution.md); diplomacy war state; per-ship stats from colonizethis_data.
- **Downstream:** Casualty and location updates applied to WorldState by turn resolver.

## Constraints

- Deterministic for a given seed.
- All numeric weights and per-ship ratings from colonizethis_data, tunable per ruleset.
- Owned by colonizethis_logic.
