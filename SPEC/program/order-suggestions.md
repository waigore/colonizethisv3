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
- **Work orders:** Suggested only for the unit's current province and tile. Never suggests work for a province the unit is not in.
- **Visibility:** Uses PlayerView only; may not inspect hidden tiles or enemy units directly. Checks per [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md). **Exception:** Diplomatic suggestions for Great Powers and Minor Nations are global knowledge (not restricted by PlayerView); Tribes are suggested only when discovered (relation exists or visible province).
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

**Behavior:**
1. Filters candidate tiles to only those with `VisibilityLevel.fullyVisible` or `VisibilityLevel.fogged` (visible or previously explored) from the given `PlayerView`.
2. For remaining visible tiles, validates via the order engine (same as `getValidWorkOrderTileKeys`).
3. Returns only tiles that pass both visibility and validation checks.

**Why separate from `getValidWorkOrderTileKeys`:**
- `getValidWorkOrderTileKeys` is agnostic to player view (used by AI that operates on full game state).
- UI tooling (app, ctterm) needs visibility-aware filtering to avoid expensive order-engine calls for invisible tiles.
- Filtering by visibility **first** dramatically reduces the number of order-engine validations needed.

**Consumers:**
- App UI (civilian units panel for work assignment).
- ctterm (TUI work order assignment).

**Notes:**
- When `view` is `null` or visibility data is unavailable, falls back to full map iteration (same as `getValidWorkOrderTileKeys`).
- Tile keys use the standard format: `{regionId}|{provinceId}|{x}|{y}`.
