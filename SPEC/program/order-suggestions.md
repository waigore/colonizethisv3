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
- **Visibility:** Uses PlayerView only; may not inspect hidden tiles or enemy units directly. Checks per [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md).
- **Determinism:** Fixed inputs produce the same set and ordering of suggestions.
- **Build orders:** `suggestBuildOrders` returns affordable, valid build-unit orders for both **military (regiment)** and **naval (ship)** unit types. Each candidate is validated (treasury, stockpile, tech, capital) via the order engine. Ordering is deterministic (e.g. by unit type id).

---

## Consumers

- Minimal AIPlanner (see [ai-planner.md](ai-planner.md))
- Sim-game default AI (see [sim-game-default-ai.md](sim-game-default-ai.md))
- Full AI (see [ai-systems-impl.md](ai-systems-impl.md))

---

## Integration

Lives in colonizethis_logic alongside the order engine. AI and tooling consume it to generate orders.
