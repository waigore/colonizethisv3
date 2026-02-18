# Naval Combat Resolution

**SPEC/program** — Conflict detection and auto-resolve pipeline for naval battles. Game design: [ships-and-naval.md](../game/ships-and-naval.md). Turn sequence: [turn-resolution-phases.md](turn-resolution-phases.md).

---

## Battle Model (Sea)

Naval combat is orchestrated around a **BattleContextSea per sea zone**:

- **BattleContextSea:** `seaZoneId`, list of **sides** (fleet owner id, list of ship ids, mission type, aggression level, tech snapshot).
- Each side may consist of one or more fleets owned by the same faction that are present in the sea zone when interceptions and end-of-movement contacts are resolved.

---

## Conflict Detection (Sea)

**Input:** WorldState and fleet state after naval movement and interception checks.

For each sea zone that contains at least two factions’ fleets:

1. Group fleets by owner id.
2. For each pair of hostile factions (war state in diplomacy), if both have at least one fleet in the zone, create or update the BattleContextSea for that zone with their ship ids.
3. Beachhead fleets and fleets located in ports participate in sea battles if the opposing side has fleets in the same sea zone.

**Output:** A list of BattleContextSea objects, one per contested sea zone.

---

## Naval Strength Aggregation

Per ship type, colonizethis_data provides naval stats: **FRP, RNG, ARM, HULL, MV**, plus **interceptRating** and **fleeRating**.

For each side in a BattleContextSea:

- Compute a **firepower score** from FRP and RNG (later-era ships and higher RNG increase weight).
- Compute a **durability score** from ARM and HULL.
- Apply medal multipliers and tech modifiers (e.g. explosive shells).
- Aggregate into a side-level **navalStrength** used in auto-resolve.

Exact weighting is defined in config; the resolver treats navalStrength as an analogue of land combat strength.

---

## Per-Engagement Resolver (Sea)

Given two opposing sides in BattleContextSea:

1. Read navalStrength for attacker and defender, plus any mission modifiers (e.g. Patrol/Blockade bonuses, Beachhead penalties).
2. Apply difficulty and terrain-style modifiers if any (e.g. coastal vs open ocean, optional).
3. Run a deterministic formula to compute:
   - Casualties per side (which ships are sunk vs survive damaged).
   - Whether either side attempts retreat (see *Retreat Resolution*).
4. Return a result: attacker victory, defender victory, stalemate (both retain ships), or mutual destruction, plus casualty ship ids and retreat outcome flags.

The same function is used for:

- Fleet-vs-fleet battles from Patrol/Blockade/Beachhead interceptions.
- End-of-movement contacts where hostile fleets share a zone.

---

## Retreat Resolution

Retreat is allowed only if a side has at least one adjacent **friendly or neutral sea zone** to withdraw into.

For the side attempting retreat:

- Compute `fleetFleeScore = sum(ship.fleeRating)` for its ships.
- Compute `pursuerInterceptScore = sum(ship.interceptRating)` for the opposing side’s ships.
- Baseline ratio: `R = fleetFleeScore / (fleetFleeScore + pursuerInterceptScore)`.
- Apply aggression modifier from [ships-and-naval.md](../game/ships-and-naval.md):
  - cautious × 1.1, normal × 1.0, aggressive × 0.8.
- Clamp final probability `P_retreat` to `[0.1, 0.95]` and use deterministic RNG (seeded by game/turn) to decide success.

On **successful retreat**, surviving ships move to a designated neighbouring sea zone. On **failed retreat**, apply additional losses (e.g. extra damage or the loss of a vulnerable ship) before resolving the engagement outcome.

---

## Owner

colonizethis_logic owns BattleContextSea construction, invocation of the naval combat resolver, and application of results to WorldState (fleet compositions and locations). Numeric weights and per-ship ratings are defined in colonizethis_data and may be tuned per ruleset.

