# Order Suggestion API

**SPEC/program** — Enumerates valid candidate orders for AI and tooling. Validator: [order-engine.md](order-engine.md). Order types: [orders.md](orders.md).

---

## Responsibility

Given a player, their current valid order list, and game context, enumerate **candidate orders** (move, build, work, research) guaranteed to be accepted if appended.

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
- **Work orders (`suggestWorkOrders`):** AI suggestions default to the unit's current province for simplicity. This is an AI heuristic, not a validation constraint.
- **Work order tile selection (`getValidWorkOrderTileKeysWithVisibility`):** For UI tile selection, candidates include tiles in all owned provinces and purchased tiles per the work-target-specific rules above.
- **Visibility:** Uses PlayerView only; may not inspect hidden tiles or enemy units directly. Checks per [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md). Undiscovered factions are **never** valid diplomatic targets for order suggestions.
- **Determinism:** Fixed inputs produce the same set and ordering of suggestions.
- **Build orders:** `suggestBuildOrders` returns affordable, valid build-unit orders for both **military (regiment)** and **naval (ship)** unit types. Each candidate is validated (treasury, stockpile, tech, capital) via the order engine. Ordering is deterministic (e.g. by unit type id).
- **Diplomatic orders:** `suggestDiplomaticOrders` suggests valid diplomatic orders (Declare War, Offer Peace, Alliance, Establish Overture, Grant Aid, Set Subsidy) targeting factions the player knows about. Visibility rules per [regional discovery model](../game/diplomacy.md):
  - **GP↔GP:** Always visible (global knowledge of major powers).
  - **GP↔Minor:** Always visible (same region/Old World).
  - **GP↔Tribe:** Only if discovered (diplomatic relation exists or province visibility).

---

## Consumers

- Minimal AIPlanner (see [ai-planner.md](ai-planner.md))
- Sim-game default AI (see [sim-game-default-ai.md](sim-game-default-ai.md))
- Full AI (see [ai-systems-impl.md](ai-systems-impl.md))

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
});
```

**Pre-filtering by work target type:**

Before iterating candidate tiles, apply work-target-specific filters to dramatically reduce the tile set and avoid expensive order-engine validation for tiles that can never be valid:

| Work target | Province scope | Tile requirements |
|-------------|----------------|-------------------|
| `explore` | Any visible province | Any tile in the province (province-level work) |
| `prospect` | Any visible province | Tile must be mineral-eligible terrain (swamp, hills, mountain, desert) |
| `build_improvement` | Owned or purchased tiles | Tile must have a resource (`resourceByTileKey` non-empty); tile controlled by player |
| `upgrade_town` | Owned provinces only | Province's town tile only |
| `build_road` | Owned or purchased tiles | Any tile controlled by player |
| `build_port` | Owned provinces only | Coastal or river tiles (adjacent to sea zone or river) |
| `build_fort` | Owned provinces only | Province's town tile only |
| `build_rail` | Owned or purchased tiles | Tile must have road level ≥ 1 and be controlled by player |
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
- UI tooling (app, ctterm) needs visibility-aware filtering to avoid expensive order-engine calls for invisible tiles.
- Pre-filtering by work-target-specific criteria dramatically reduces the candidate set before order-engine validation.

**Consumers:**
- App UI (civilian units panel for work assignment).
- ctterm (TUI work order assignment).

**Notes:**
- When `view` is `null` or visibility data is unavailable, falls back to full map iteration (same as `getValidWorkOrderTileKeys`).
- Tile keys use the standard format: `{regionId}|{provinceId}|{x}|{y}`.
