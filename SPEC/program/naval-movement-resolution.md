# Naval Movement Resolution

## Responsibility

Resolves fleet movement orders, triggers ship-reveal for coastal provinces, and runs naval interception checks for patrolling/blockading fleets.

## Data Model

- **Fleet:** owner, seaZoneId, list of ships (type, individual or count), mission type.
- Stored in WorldState per region. Ships built appear in home fleet (capital port).
- Per-ship stats from colonizethis_data: FRP, RNG, ARM, HULL, MV, `interceptRating`, `fleeRating`.

## Algorithm / Flow

**Movement:**

1. For each fleet with a move order, validate destination is adjacent (S↔S or P↔S) via topology.
2. Update fleet location to destination sea zone.
3. Trigger **ship reveal** (see below).

**Ship Reveal:**

On fleet entering sea zone S: for each province P with a P↔S edge, set coastal tiles of P to `revealed` for fleet owner. Updates visibility state per [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md).

**Interception Checks:**

For each fleet on Patrol or Blockade mission (see [ships-and-naval.md](../game/ships-and-naval.md) § Missions and Movement), evaluate against hostile fleets moving through the zone or entering/leaving a blockaded port:

1. `fleetInterceptScore = Σ ship.interceptRating` (intercepting fleet).
2. `targetEvasionScore = Σ ship.fleeRating` (target fleet).
3. `ratio = fleetInterceptScore / (fleetInterceptScore + targetEvasionScore)`.
4. Mission factor: Patrol = 0.5, Blockade = 0.9.
5. Apply tech/composition bonuses to `fleetInterceptScore` (e.g. +20% from privateering_companies).
6. `P_intercept = clamp(missionFactor × ratio, 0.05, 0.85)`.
7. On success, create a BattleContextSea and invoke [naval-combat-resolution.md](naval-combat-resolution.md).

Exact numeric values in ruleset config; formula shape: mission factor × relative strength × tech/composition.

**Trade/Transport Interception:**

During Extraction/Trade phase, overseas cargo on home-fleet ships may be raided. Reuses the interception framework with modifications per [ships-and-naval.md](../game/ships-and-naval.md) § Trade and Transport Interception:

1. Only evaluated when intercepting faction is at war with home fleet owner.
2. Compute `base` as above. Civilian-only targets may receive a `civilianTargetBonus` (e.g. ×1.25–1.5).
3. Compute `escortStrength` and `cargoStrength` exactly as defined in [ships-and-naval.md](../game/ships-and-naval.md) and derive `escortFactor` from the documented `lossReduction` formula.
4. `P_cargo_intercept = clamp(1.2 × base × (1 - escortFactor), 0.1, 0.9)`.
5. `P_ship_sunk = clamp(0.4 × base × (1 - escortFactor), 0.02, 0.5)`.
6. Reduce delivered quantities; remove sunk merchant ships from home fleet.

**Build Ship:**

BuildUnitOrder for naval type; spawns in home fleet (capital port). Costs from colonizethis_data ship economy catalog.

## Integration

- **Phase:** Movement phase (alongside land movement); interception in Naval Interception & Naval Combat step ([turn-resolution-phases.md](turn-resolution-phases.md)). Trade interception during Extraction/Trade.
- **Upstream:** Fleet orders from [orders.md](orders.md); topology from map data.
- **Downstream:** Updated fleet locations and visibility in WorldState; BattleContextSea to [naval-combat-resolution.md](naval-combat-resolution.md); cargo reductions to [auto-transport.md](auto-transport.md).

## Constraints

- Deterministic for a given seed.
- S↔S topology edges required from map generation.
- Owned by colonizethis_logic; numeric config from colonizethis_data.
