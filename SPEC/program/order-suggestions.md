# Order Suggestion API

**SPEC/program** — Enumerates valid candidate orders for AI and tooling. Validator: [order-engine.md](order-engine.md). Order types: [orders.md](orders.md).

---

## Responsibility

Given a player, their current valid order list, and game context, enumerate **candidate orders** (move, build, work, research, naval, diplomatic) guaranteed to be accepted if appended.

---

## Inputs

- `Game` and `MapTopology` (full world state and topology).
- `playerId` for the acting Great Power.
- Current `Orders` for that player (assumed valid prefix).
- A `PlayerView` for `playerId` (see [player-view.md](player-view.md)) — sole source of visibility.

---

## Guarantees

For every suggested order `o`, appending it to the current list and validating via `validatePlayerOrdersWithContext` yields `accepted`.

---

## Rules

- **Province / tile identity:** Province ids and tile keys in suggested orders (destination province, targetTileKey, spawn province, fleet/sea zone ids) use the **prefixed** form and resolution rules per [world-model-identity.md](../game/world-model-identity.md) (same as [orders.md](orders.md)).
- **Work orders (`suggestWorkOrders`):** For civilian **workers** (Builder, Engineer, Rail Builder), candidate work targets use the same tile scope as validation: any **player-controlled** tile (owned province or `purchasedTilesByTileKey`) that passes visibility and the order engine, not only tiles in the unit’s current province (see [civilian-units.md](../game/civilian-units.md): civilians may act on a tile other than their current tile). Explorers, Spies, and Merchants keep their existing province- or rules-specific enumeration. **Performance:** `suggestWorkOrders` may cache, per invocation, the pre-filtered + visibility-sorted tile list keyed by `workTarget` so each distinct work target is computed once per call; per-unit acceptance still runs the order engine over that list until the first valid tile is found.
- **Work order tile selection (`getValidWorkOrderTileKeysWithVisibility`):** For UI tile selection, apply the work-target-specific pre-filter table (e.g. `build_improvement`: owned or purchased tiles with a resource; prospect-required minerals must also pass order-engine validation including prospection (unprospected mineral tiles are excluded); `prospect`: land tiles that are mineral-eligible and not yet prospected — then visibility and order engine). Not every work target is limited to owned/purchased tiles.
- **Visibility:** Uses PlayerView only; may not inspect hidden tiles or enemy units directly. Checks per [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md). Undiscovered factions are **never** valid diplomatic targets for order suggestions.
- **Determinism:** Fixed inputs produce the same set and ordering of suggestions.
- **Build orders:** `suggestBuildOrders` returns affordable, valid build-unit orders for both **military (regiment)** and **naval (ship)** unit types. Each candidate is validated (treasury, stockpile, tech, capital) via the order engine. Ordering is deterministic (e.g. by unit type id).
- **Naval mission orders (`suggestNavalMissionOrders`):** For each eligible fleet, the system tries each value of `FleetMission` (serialized as `FleetMission.name` on `NavalMissionOrder.mission`) and keeps candidates accepted by the order engine. Adding or renaming enum values in [ships-and-naval.md](../game/ships-and-naval.md) therefore updates suggestion enumeration without a separate hardcoded mission list.
- **Diplomatic orders (`suggestDiplomaticOrders`):** Suggests valid diplomatic orders (Declare War, Offer Peace, Alliance, Establish Overture, Grant Aid, Set Subsidy) targeting factions the player knows about. Each candidate is validated with the order engine (`addDiplomaticOrderWithContext`), same as other suggestion families. Optional `tileMapByRegion` matches `suggestWorkOrders` for API symmetry. Visibility rules per [regional discovery model](../game/diplomacy.md):
  - **GP↔GP:** Always visible (global knowledge of major powers).
  - **GP↔Minor:** Always visible (same region/Old World).
  - **GP↔Tribe:** Only if discovered (diplomatic relation exists or province visibility).
- **Primary vs economic suggestions per target:** For each known target **T**, candidates follow `_diplomaticCandidatesForTargetOrdered` (`offerPeace`, `alliance`, `establishOverture`, `grantAid`, `setSubsidy`, `declareWar`). The implementation uses **two passes**: (1) consider **only** non-economic types in that order; append the **first** that passes the order engine against a **trial** list (see below) and **stop** the primary pass. (2) Consider **only** `grantAid` and `setSubsidy` in candidate order; append each that passes against the trial list after step (1), updating the trial after each acceptance. **Grant before subsidy** when both are valid: `grantAid` precedes `setSubsidy` in the template. Multiple entries toward the same **T** in **L** are only as allowed by [orders.md](orders.md) (e.g. one `grantAid` + one `setSubsidy` when no non-economic suggestion was accepted for **T**).
- **Working list:** Initialize **workingOrders** from `currentOrders`. For each **T**, set **trialOrders** = **workingOrders**; run the two passes; then assign **workingOrders** = **trialOrders** so treasury and caps reflect suggestions accepted earlier in the same invocation. Pending orders in `currentOrders` constrain what can be suggested; removing a pending order restores eligibility per engine validation.

**Acceptance criteria (diplomatic suggestions)**

- Given fixed `Game`, `MapTopology`, `PlayerView`, and `Orders` for player P, when `suggestDiplomaticOrders` returns a list L, then when the system appends every order in L to P’s diplomatic slot **in list order** onto a copy of those `Orders` and runs `validatePlayerOrdersWithContext` for P on the combined list, every validation result is **accepted**.
- Given `currentOrders` already includes a non-economic diplomatic order from P to target T, when `suggestDiplomaticOrders` runs with those `currentOrders`, then L contains **no** order with `targetFactionId == T`.
- Given `currentOrders` includes only a valid pending `grantAid` from P to T, when `suggestDiplomaticOrders` runs, then L **may** include a `setSubsidy` toward T if the engine accepts it when merged with `currentOrders`.
- Given `currentOrders` includes no diplomatic order to T, when a prior call returned suggestions toward T and the player removed all diplomatic orders to T from the draft, when `suggestDiplomaticOrders` runs again with the updated `currentOrders`, then the system **may** again include valid suggestions toward T subject to game rules and engine validation.

---

## Consumers

- Minimal AIPlanner (see [ai-planner.md](ai-planner.md)) — passes `tileMapByRegion` when the caller provides it.
- Sim-game default AI (see [sim-game-default-ai.md](sim-game-default-ai.md)) — sim controller passes the same maps used for order validation.
- Full AI (see [ai-systems-impl.md](ai-systems-impl.md)) — domain planners pass `tileMapByRegion` through to `suggestWorkOrders` when provided.
- **Flutter app (`colonizethis_app`):** Riverpod providers (e.g. `availableWorkTargetsProvider`, optional `devExclusiveReservedWorkTileKeysProvider`) **delegate** to `colonizethis_logic` only. They **must not** reimplement Builder/Engineer/Merchant per-tile exclusivity or reservation rules. Reservations combine in-map `currentWork` and pending dev-exclusive work orders per [orders.md](orders.md) § WorkOrder per-tile exclusivity.

### Dev-exclusive tile reservations (logic package)

- **Given** a `Game`, current-turn `Orders`, and a Great Power `playerId`, **the system** builds the set of `targetTileKey` values reserved for that player: tiles with in-progress dev work (Builder/Engineer/Merchant `currentWork`) plus `targetTileKey` of each pending work order whose target is dev-exclusive (`build_improvement`, `upgrade_town`, `build_road`, `build_port`, `build_fort`, `purchase_land`).
- **When** `suggestWorkOrders` evaluates a dev-exclusive target for a unit, **the system** skips candidate tiles in that reserved set (full set, including other units’ pending orders) before order-engine validation.
- **When** `getValidWorkOrderTileKeys` / `getValidWorkOrderTileKeysWithVisibility` lists tiles for **one** unit’s tile picker, **the system** may omit that unit’s **own** pending orders from the reserved set so tiles already selected in the draft order list remain visible for that unit only; other units still treat those tiles as reserved.
- **Then** a second Builder of the same player does not receive an available `build_improvement` suggestion on a tile already targeted by the first Builder’s pending order until that order is removed.

---

## Integration

Lives in colonizethis_logic alongside the order engine. AI and tooling consume it to generate orders.

---

## Helper: Valid Work Order Tile Keys

### `getValidWorkOrderTileKeysWithVisibility`

**Purpose:** Returns the set of tile keys that are valid targets for a work order, filtering by visibility **before** calling the order engine for efficiency.

**Signature:**
```dart
Set<String> getValidWorkOrderTileKeysWithVisibility({
  required Game game,
  required MapTopology topology,
  required PlayerView view,
  required String unitId,
  required String workTarget,
  required Orders currentOrders,
  Map<String, TileMapResult>? tileMapByRegion,
});
```

When `tileMapByRegion` is non-null (app shell, turn resolution), prospect pre-filtering and `prospect` work-order validation use the same terrain-aware eligibility as work application. When null, eligibility falls back to mineral resource ids on `resourceByTileKey` only.

**Pre-filtering by work target type:**

Before iterating candidate tiles, apply work-target-specific filters to dramatically reduce the tile set and avoid expensive order-engine validation for tiles that can never be valid:

| Work target | Province scope | Tile requirements |
|-------------|----------------|-------------------|
| `explore` | Any visible province | Any tile in the province (province-level work) |
| `prospect` | Land provinces (prefixed province id) | Tile must be mineral-eligible (terrain from tile maps when provided, else mineral resource on tile per `isMineralEligibleTile`); tile must **not** already appear in `WorldState.playerProspectedTiles[playerId]` |
| `build_improvement` | Owned or purchased tiles | Tile must have a resource (`resourceByTileKey` non-empty); tile controlled by player |
| `upgrade_town` | Owned provinces only | Province's town tile only |
| `build_road` | Owned or purchased tiles | Any tile controlled by player |
| `build_port` | Owned provinces only | Coastal or river tiles (adjacent to sea zone or river) |
| `build_fort` | Owned provinces only | Province's town tile only |
| `build_rail` | Owned or purchased tiles | Transport level 1 or 2; per-tile terrain resolvable from tile map; player's unlocked tech must allow rail on that terrain per [tech-tree-transport.md](../game/tech-tree-transport.md); tile controlled by player |
| `steal_tech` | Other GP capital provinces | Province must be another Great Power's capital |
| `counter_spy` | Owned provinces only | Any tile in owned province |
| `purchase_land` | Minor/Tribe provinces | Tile must have resource; tile not already purchased; player has embassy and is not at war |

**Tile control definition:** A tile is "controlled by player" when either:
- The tile's province is owned by the player, OR
- The tile appears in `WorldState.purchasedTilesByTileKey` with buyer = player (Merchant purchase)

**Behavior:**
1. Apply work-target-specific pre-filters (province scope, tile requirements) to generate a candidate tile set.
2. Further filter candidate tiles to only those with `VisibilityLevel.fullyVisible` or `VisibilityLevel.fogged` from the given `PlayerView`.
3. For remaining candidate tiles, validate via the order engine (same as `getValidWorkOrderTileKeys`).
4. Returns only tiles that pass all three filters (pre-filter, visibility, validation).

**Why separate from `getValidWorkOrderTileKeys`:**
- `getValidWorkOrderTileKeys` is agnostic to player view (used by AI that operates on full game state).
- The app needs visibility-aware filtering to avoid expensive order-engine calls for invisible tiles.
- Pre-filtering by work-target-specific criteria dramatically reduces the candidate set before order-engine validation.

**Consumers:**
- App UI (civilian units panel for work assignment).

**Acceptance criteria (prospect tile picker and validation)**

- Given a Great Power player and a `prospect` work order candidate tile, when that tile is not mineral-eligible per game rules, then the system rejects the work order with a reason indicating the tile is not mineral-eligible for prospecting.
- Given a Great Power player and a `prospect` work order candidate tile that is already in `playerProspectedTiles` for that player, when the order engine validates the order, then the system rejects the work order with a reason indicating the tile is already prospected.
- Given `getValidWorkOrderTileKeysWithVisibility` is called for an Explorer with work target `prospect` and a non-null `tileMapByRegion`, when the player’s `PlayerView` marks a tile at least fogged, the tile is mineral-eligible, and the tile is not in `playerProspectedTiles` for that player, then the returned set may include that tile (subject to remaining order-engine rules). When the tile is already prospected or not mineral-eligible, then the returned set does not include that tile.

**Notes:**
- When `view` is `null` or visibility data is unavailable, falls back to full map iteration (same as `getValidWorkOrderTileKeys`).
- Tile keys use the standard format: `{regionId}|{provinceId}|{x}|{y}`.
