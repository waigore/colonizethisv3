# Naval Movement Resolution

## Responsibility

Resolves fleet movement orders, triggers ship-reveal for coastal provinces, and runs naval interception checks for patrolling/blockading fleets.

## Data Model

- **Fleet:** owner, location (either **at sea:** `seaZoneId`; or **in port:** `inPortAtProvinceId`), list of ships (type, individual or count), mission type. Exactly one of `seaZoneId` or `inPortAtProvinceId` is set. Home fleet always has `inPortAtProvinceId` = capital province.
- Stored in WorldState per region. Ships built appear in home fleet (in port at capital).
- Per-ship stats from colonizethis_data: FRP, RNG, ARM, HULL, MV, `interceptRating`, `fleeRating`.
- **Docking rule:** A fleet may only go in port at a province **owned by the fleet's owner** (SPEC/game/ships-and-naval.md).

## Algorithm / Flow

**Movement:**

1. For a fleet **at sea:** validate destination is adjacent (S↔S or P↔S) via topology. If destination is a **port** (P↔S), the target province must be **owned by the fleet owner**; otherwise reject. On apply: if moving to a sea zone, set fleet to that sea zone (at sea); if moving to a **non‑capital** port, set fleet to in port at that province. If moving to the player’s **capital** province, **merge** ships into the **Home Fleet** and **remove** the sea‑going fleet (see [ships-and-naval.md](../game/ships-and-naval.md) § Home Fleet).
2. For a fleet **in port:** destination must be an adjacent sea zone (undock). On apply: set fleet to at sea in that sea zone.
3. Trigger **ship reveal** when a fleet **enters** a sea zone (move to sea zone or undock into one).
4. Home fleet cannot move; orders targeting it are no-ops.
5. Applying a **successful naval move** for a sea‑going fleet clears that fleet’s **mission** and mission targets for the resulting state (`none` / null targets), including after merge into Home Fleet (Home Fleet remains mission `none`).

**Ship Reveal:**

On fleet entering sea zone S: for each province P with a P↔S edge (within the **destination sea zone's region** only), set coastal tiles of P to `revealed` for fleet owner. Province identity for which tiles to reveal must use full province id (`regionId|localId`) and region-scoped lookup per [world-model-identity.md](../game/world-model-identity.md). Updates visibility state per [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md).

Also on entering S: set all **water** tile keys belonging to S in `tileKeysByRegionAndProvince[regionId][S]` to **fully visible** for the fleet owner so open-ocean hexes are visible while the fleet is present; **End-of-turn** [distant sea zone fog](fog-and-exploration-resolution.md) may fog them again when no owned coast is adjacent and no fleet of that player is at sea in S.

On fleet **docking** at a port province (including merge into Home Fleet at capital): set **all** tiles of that province listed in `tileKeysByRegionAndProvince` to `revealed` for the fleet owner (same visibility field names as elsewhere), so unrevealed coastal hinterland from fog is uncovered when the player brings a fleet into port.

**Interception Checks:**

Only fleets **at sea** on Patrol or Blockade mission participate. For each such fleet (see [ships-and-naval.md](../game/ships-and-naval.md) § Missions and Movement), evaluate against hostile fleets **moving into that sea zone** (including fleets that **leave port** into that zone):

1. `fleetInterceptScore = Σ ship.interceptRating` (intercepting fleet).
2. `targetEvasionScore = Σ ship.fleeRating` (target fleet).
3. `ratio = fleetInterceptScore / (fleetInterceptScore + targetEvasionScore)`.
4. Mission factor: Patrol = 0.5, Blockade = 0.9.
5. `P_intercept = clamp(missionFactor × ratio, 0.05, 0.85)`.
6. On success, create a BattleContextSea and invoke [naval-combat-resolution.md](naval-combat-resolution.md).

Exact numeric values in ruleset config; formula shape: mission factor × relative strength × tech/composition.

**Trade/Transport Interception:**

During Extraction/Trade phase, overseas cargo on home-fleet ships may be raided. Reuses the interception framework with modifications per [ships-and-naval.md](../game/ships-and-naval.md) § Trade and Transport Interception:

1. Only evaluated when intercepting faction is at war with home fleet owner.
2. Compute `base` as above. Civilian-only targets may receive a `civilianTargetBonus` (e.g. ×1.25–1.5).
3. Compute `escortStrength` and `cargoStrength` exactly as defined in [ships-and-naval.md](../game/ships-and-naval.md) and derive `escortFactor` from the documented `lossReduction` formula.
4. `P_cargo_intercept = clamp(1.2 × base × (1 - escortFactor), 0.1, 0.9)`.
5. `P_ship_sunk = clamp(0.4 × base × (1 - escortFactor), 0.02, 0.5)`.
6. Reduce delivered quantities; remove sunk merchant ships from home fleet.

**Join home fleet:**

A `join_home_fleet` order is valid only when the fleet is **in port at the player's capital province**. On apply: merge that fleet's ships into the home fleet and remove the sea-going fleet.

**Build Ship:**

BuildUnitOrder for naval type; spawns in home fleet (in port at capital). Costs from colonizethis_data ship economy catalog.

**Orders draft (human):** Submitting a **naval move** for fleet **F** replaces any prior **naval move** for **F** and removes any **naval mission** order for **F** from the current-turn draft. During turn resolution, if fleet **F** has a **naval move** order, **naval mission** orders for **F** are not applied that turn (move takes precedence if both appear after merge).

## Integration

- **Phase:** Movement phase (alongside land movement); interception in Naval Interception & Naval Combat step ([turn-resolution-phases.md](turn-resolution-phases.md)). Trade interception during Extraction/Trade.
- **Upstream:** Fleet orders from [orders.md](orders.md); topology from map data.
- **Downstream:** Updated fleet locations and visibility in WorldState; BattleContextSea to [naval-combat-resolution.md](naval-combat-resolution.md); cargo reductions to [auto-transport.md](auto-transport.md).

## Constraints

- Deterministic for a given seed.
- S↔S topology edges required from map generation.
- Owned by colonizethis_logic; numeric config from colonizethis_data.
