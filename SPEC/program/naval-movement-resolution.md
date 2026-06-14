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

On fleet **successfully** entering sea zone S: for each province P with a P↔S edge (within the **destination sea zone's region** only), set **coastal ring** land tiles of P to **`fullyVisible`** for the fleet owner. **Coastal ring** means each land tile key in P’s list is updated only if its `(x,y)` has an orthogonal neighbor `(x±1,y)` or `(x,y±1)` matching some water tile key listed for S in `tileKeysByRegionAndProvince[regionId][L]`, where `L` is S’s **local** sea id (topology may store S as `regionId|L` in the combined graph; indexing uses `L` only). **Inland** land tiles in P are not changed by this rule. Province identity must use full province id (`regionId|localId`) via `toFullProvinceId(regionId, topologyProvinceNodeId)` and region-scoped lookup per [world-model-identity.md](../game/world-model-identity.md). Updates visibility state per [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md).

Also on entering S: set all **water** tile keys belonging to S in `tileKeysByRegionAndProvince[regionId][L]` to **fully visible** for the fleet owner so open-ocean hexes are visible while the fleet is present; **End-of-turn** [distant sea zone fog](fog-and-exploration-resolution.md) may fog them again when no owned coast is adjacent and no fleet of that player is at sea in S.

On fleet **docking** at an **owned** port province (including merge into Home Fleet at capital): player-owned provinces are already **`fullyVisible`** for that owner; implementation may set tiles to `fullyVisible` for idempotency. No special reveal pass is required for visibility beyond ownership rules.

**Interception Checks:**

Only fleets **at sea** on Patrol or Blockade mission participate. For each such fleet (see [ships-and-naval.md](../game/ships-and-naval.md) § Missions and Movement), evaluate against hostile fleets **moving into that sea zone** (including fleets that **leave port** into that zone):

1. `fleetInterceptScore = Σ ship.interceptRating` (intercepting fleet).
2. `targetEvasionScore = Σ ship.fleeRating` (target fleet).
3. `ratio = fleetInterceptScore / (fleetInterceptScore + targetEvasionScore)`.
4. Mission factor: Patrol = 0.5, Blockade = 0.9.
5. `P_intercept = clamp(missionFactor × ratio, 0.05, 0.85)`.
6. On success, create a BattleContextSea and invoke [naval-combat-resolution.md](naval-combat-resolution.md).

For current product, interception uses hardcoded constants in logic code (no ruleset lookup):

- Patrol mission factor: `0.5` (`kNavalInterceptMissionFactorPatrol`).
- Blockade mission factor: `0.9` (`kNavalInterceptMissionFactorBlockade`).
- Clamp bounds: `[0.05, 0.85]`.
- Formula: `P_intercept = clamp(missionFactor × ratio, 0.05, 0.85)`.

**Privateering interception bonus (tech-gated).** When the **intercepting** fleet's owner has `privateering_companies` in `techUnlocked` (Great Power doctrine; [tech-tree-naval.md](../game/tech-tree-naval.md)), the System multiplies that fleet's `fleetInterceptScore` by the single deterministic multiplicative constant `kPrivateeringInterceptBonus = 1.25` (range 1.10–1.30, strictly > 1.0) **before** computing `ratio` and applying the `[0.05, 0.85]` clamp, so the clamp bounds remain the hard limits. The bonus applies only to the intercepting side and is never applied when the tech is absent from the intercepting owner's `techUnlocked` set. The target/evading side is unaffected. The bonus is a fixed code constant (no ruleset lookup) and deterministic for fixed inputs.

**Trade/Transport Interception:**

During Extraction/Trade phase, overseas cargo on home-fleet ships may be raided. Reuses the interception framework with modifications per [ships-and-naval.md](../game/ships-and-naval.md) § Trade and Transport Interception:

1. Only evaluated when intercepting faction is at war with home fleet owner.
2. Compute `base` as above. Civilian-only targets may receive a `civilianTargetBonus` (e.g. ×1.25–1.5).
3. Compute `escortStrength` and `cargoStrength` exactly as defined in [ships-and-naval.md](../game/ships-and-naval.md) and derive `escortFactor` from the documented `lossReduction` formula.
4. `P_cargo_intercept = clamp(1.2 × base × (1 - escortFactor), 0.1, 0.9)`.
5. `P_ship_sunk = clamp(0.4 × base × (1 - escortFactor), 0.02, 0.5)`.
6. Reduce delivered quantities; remove sunk merchant ships from home fleet.

For current product, trade/transport interception also uses hardcoded constants in logic code (no ruleset lookup), including:

- `civilianTargetBonus = 1.25`
- `actionFactorPatrol = 0.5`
- `blockadeBonusFactor = 1.5`
- `escortFactorMax = 0.5`
- `escortStrengthWeight = 0.3`
- `civilianShipLossPenalty = 2.0`
- `raidEfficiencyMin = 0.3`, `raidEfficiencyMax = 0.7`

**Privateering trade-raid bonus (tech-gated).** When an **intercepting** enemy fleet's owner has `privateering_companies` in `techUnlocked`, the System multiplies that fleet's `interceptRating` contribution to the aggregate `fleetInterceptScore` by the single deterministic multiplicative constant `kPrivateeringTradeRaidBonus = 1.25` (range 1.10–1.30, strictly > 1.0) **before** deriving `ratio`, `base`, and the documented `P_cargo_intercept` / `P_ship_sunk` clamps, so those clamps remain the hard limits. The bonus is applied per intercepting owner that holds the tech (an enemy fleet whose owner lacks the tech contributes its unscaled `interceptRating`), is never applied for owners without the tech, and is a fixed code constant (no ruleset lookup), deterministic for fixed inputs.

**Join home fleet:**

A `join_home_fleet` order is valid only when the fleet is **in port at the player's capital province**. On apply: merge that fleet's ships into the home fleet and remove the sea-going fleet.

This movement-order contract is distinct from the immediate UI fleet-management transfer flow in `SPEC/ui/naval-units-fleet-management.md` (selected-ship transfer into Home Fleet). Scope B transfer behavior does not broaden `join_home_fleet` order validation unless this section is explicitly revised.

**Build Ship:**

BuildUnitOrder for naval type; spawns in home fleet (in port at capital). Costs from colonizethis_data ship economy catalog.

**Orders draft (human):** Submitting a **naval move** for fleet **F** replaces any prior **naval move** for **F** and removes any **naval mission** order for **F** from the current-turn draft. During turn resolution, if fleet **F** has a **naval move** order, **naval mission** orders for **F** are not applied that turn (move takes precedence if both appear after merge).

## Integration

- **Phase:** Movement phase (alongside land movement); interception in Naval Interception & Naval Combat step ([turn-resolution-phases.md](turn-resolution-phases.md)). Trade interception during Extraction/Trade.
- **Upstream:** Fleet orders from [orders.md](orders.md); topology from map data.
- **Combined topology:** Runtime graph is **combined** `MapTopology` (prefixed node/edge ids per [map-data.md](map-data.md)). For a fleet **in port**, resolving the adjacent sea zone (undock, validation, UI move picks) uses `seaZoneIdForProvince` and related helpers; those lookups must succeed for **local province id + regionId** against that graph, not only against per-region local-id graphs.
- **Downstream:** Updated fleet locations and visibility in WorldState; BattleContextSea to [naval-combat-resolution.md](naval-combat-resolution.md); cargo reductions to [auto-transport.md](auto-transport.md).

## Constraints

- Deterministic for a given seed.
- S↔S topology edges required from map generation.
- Owned by colonizethis_logic; numeric config from colonizethis_data.

## Acceptance Criteria

- Given combined `MapTopology` sea node ids prefixed as `regionId|localSeaId` and `WorldState.tileKeysByRegionAndProvince[regionId]` keyed by `localSeaId` for water tiles  
  When a fleet successfully enters destination sea zone S during Movement  
  Then the System loads water tile keys from `tileKeysByRegionAndProvince[regionId][localSeaId(S)]` and applies the strict orthogonal coastal-ring land reveal and full water reveal for the fleet owner as specified in **Ship Reveal** above.

- Given naval interception probability is computed for a fleet on `patrol` or `blockade` with fixed intercept and flee scores  
  When the System resolves interception in current product  
  Then the System uses hardcoded mission factors (`patrol=0.5`, `blockade=0.9`) and computes `P_intercept = clamp(missionFactor × ratio, 0.05, 0.85)` with no ruleset lookup.

- Given an interceptor fleet on `patrol` or `blockade` whose owner does **not** have `privateering_companies` in `techUnlocked`, with fixed intercept and flee scores  
  When the System computes interception probability for fleet movement resolution  
  Then the System computes `P_intercept = clamp(missionFactor × ratio, 0.05, 0.85)` using the unscaled `fleetInterceptScore` (no privateering bonus applied).

- Given an interceptor fleet on `patrol` or `blockade` whose owner **has** `privateering_companies` in `techUnlocked`, with fixed intercept and flee scores where `targetEvasionScore > 0`  
  When the System computes interception probability for fleet movement resolution  
  Then the System multiplies `fleetInterceptScore` by `kPrivateeringInterceptBonus = 1.25` before computing `ratio` and the `[0.05, 0.85]` clamp, producing a `P_intercept` strictly greater than the no-tech baseline for the same scores while remaining within `[0.05, 0.85]`, deterministic for fixed inputs.

- Given trade/transport interception runs during Extraction/Trade for fixed seed and identical game state  
  When the System applies cargo and ship-loss reduction formulas  
  Then the System uses documented named code constants (including `civilianTargetBonus`, mission factors, escort constants, and raid-efficiency bounds) and produces deterministic outputs.

- Given trade/transport interception runs during Extraction/Trade and **no** intercepting enemy fleet owner has `privateering_companies` in `techUnlocked`  
  When the System aggregates `fleetInterceptScore` and applies the cargo/ship-loss formulas for a fixed seed  
  Then the System uses each enemy fleet's unscaled `interceptRating` (no privateering bonus) and produces the baseline reduced-delivered and ship-loss outputs.

- Given trade/transport interception runs during Extraction/Trade and an intercepting enemy fleet owner **has** `privateering_companies` in `techUnlocked`  
  When the System aggregates `fleetInterceptScore` for a fixed seed and identical game state  
  Then the System multiplies that owner's intercepting fleet `interceptRating` contributions by `kPrivateeringTradeRaidBonus = 1.25` before deriving `ratio`/`base` and the `P_cargo_intercept` / `P_ship_sunk` clamps, yielding reduced delivered cargo less than or equal to the no-tech baseline (strictly less for inputs where the higher intercept probability changes the rounded outcome) while remaining within the documented clamp bounds, deterministic for fixed inputs.
