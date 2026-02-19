# Order Engine

**SPEC/program** — Current-turn order list, validation, and projected effects. Reference: [orders.md](orders.md), [turn-resolution-phases.md](turn-resolution-phases.md). Phase 4 design per [phase-4-project-tasks.md](../project/phase-4-project-tasks.md).

---

## Responsibility

The **order engine** (colonizethis_logic) maintains the **current-turn order list per player** (build, move, work, diplomacy, etc.). It is invoked on **add order** and **remove order**. It does **not** apply orders to world state; that happens only during turn resolution (TurnResolver).

---

## Validation

**Trigger:** On every new order (or removal), the order engine **re-validates the entire current-turn order list** for that player against **current world state** and the current list (costs, caps, adjacency, diplomacy, topology, research orders, etc. per [orders.md](orders.md)).

**Rule:** Validate in **submission order**. The **first** order that fails validation is **rejected**, and **every order after it in the same turn for that player is also rejected**. Sequence of submission therefore matters: if order 3 is invalid, orders 3, 4, 5, … are rejected; orders 1 and 2 remain.

When validation runs **with context** (`validatePlayerOrdersWithContext(game, topology, playerId)`), the engine must use the **same visibility data** as the order suggestion API (i.e. a PlayerView built from that game, topology, and playerId) to enforce visibility rules for move and work orders. See [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md) (Order visibility rules). The **source province** for move and work validation is the unit's located province (`Unit.locationProvinceId`). There is no requirement that the source province be owned by the player; visibility rules still apply (source must be visible when validating with context).

Rejected orders are not applied; the engine returns validation results (accepted / rejected with reason) for UI feedback.

---

## Per-player scope

During the turn, validation is **per-player only**. Each player's list is validated against world state and that player's own orders. There is no cross-player conflict resolution at this stage. Orders that affect other players (e.g. attacks, diplomacy) are validated only for the issuing player's constraints; cross-player resolution happens at turn resolution.

---

## Projected effects

The order engine (or a dedicated preview API) must support a **dry-run**: apply the current order set to a **copy** of world state (or defined subset) and return **projected effects** for UI. Example: "training one worker would result in one extra worker next turn." What is projected: e.g. start of next turn after full resolution (or end of current turn after application). Outputs exposed: e.g. worker count, unit locations after movement, stockpile deltas. No mutation of real world state.

---

## Turn resolution

Before applying orders, the **merge** step combines per-player lists (human + AI) with defined **precedence** (e.g. human over AI for conflicting orders; see [ai-planner.md](ai-planner.md) or [orders.md](orders.md)). Research orders are merged the same way (one research assignment per player per turn; human over AI for conflicting slot assignments). Then **resolve cross-player effects** (conflict detection for moves/attacks, diplomacy phase). Then apply the resolved order set in **phase order** (Diplomacy, Extraction, … Consumption, Research, Movement, Combat, Build/work, End-of-turn per [turn-resolution-phases.md](turn-resolution-phases.md)). The order engine does not perform merge or application; TurnResolver (or equivalent) consumes the per-player lists from the order engine and runs merge and resolution.

---

## Determinism

Order sequence is **submission order**. Merge and resolution use **stable ordering** (e.g. by player id, then order type, then order id) so replay is deterministic for the same inputs (world state, human orders, AI seeds).

---

## Location

Order engine logic lives in **colonizethis_logic**. UI may call the projected-effects API for feedback. Save/load: current-turn orders may be persisted with the game state so that "end turn" can be deferred; validation is re-run on load if world state is restored.

---

## Diagnostics consumers

OrderEngine is also used by **developer tooling** to surface order validity without changing gameplay:

- The **ctdev** Running Game screen keeps an in-memory history of orders generated per Great Power per turn (including AI-generated orders for human GPs while in sim mode).
- For each player and turn, ctdev constructs an `OrderEngine` instance seeded with that player's orders and calls `validatePlayerOrdersWithContext(game, topology, playerId)` to obtain a sequence of `OrderValidationResult` values in submission order.
- The results (accepted/rejected + reason) are rendered in the **Orders (AI history)** tab alongside human-readable summaries (unit id and type, origin/destination, **target tile** for work orders). WorkOrder validation checks **targetTileKey** (exists in world, in allowed province, terrain/tech rules for the action). Diagnostic summaries for work orders include unit, action, and target tile. This is purely diagnostic: it does **not** alter the orders passed into `TurnResolver` and must be deterministic for a given game state and topology.

---

## Order suggestion API

The order engine is also the **validator** for a higher-level **order suggestion API** used by AI and tooling:

- **Purpose:** Given a player `P`, their current valid order list, and the game/topology context, enumerate **candidate orders** (move, build, work, research) that:
  - Obey all rules in [orders.md](orders.md) and this document.
  - Are guaranteed to be accepted if appended to the end of `P`'s current order list.
- **Inputs:**
  - `Game` and `MapTopology` (full world state and topology).
  - `playerId` for the acting Great Power.
  - Current `Orders` for that player (assumed valid prefix).
  - A `PlayerView` for `playerId` (see [player-view.md](player-view.md)) that limits what the suggester can see under fog of war.
- **Guarantee:** For every suggested order `o`, if it is appended after the current list for `playerId` and validated via `validatePlayerOrdersWithContext`, the last `OrderValidationResult` is `accepted`.
- **Determinism:** For a fixed `(Game, topology, playerId, Orders, PlayerView)`, the set and ordering of suggestions is deterministic (e.g. sorted by unit id and destination for moves).

The suggestion API suggests **work orders only for the unit's current province** (the unit's source province per [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md)) and tile when applicable. It must never suggest work for a province the unit is not in. Visibility checks for suggestions are defined in [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md) (Order visibility rules).

The suggestion API itself lives alongside the order engine implementation in `colonizethis_logic` and must use `PlayerView` as its only source of map/visibility information; it may not inspect hidden tiles or enemy units directly. The Phase 4 minimal AIPlanner (colonizethis_logic), the sim-game default AI ([sim-game-default-ai.md](sim-game-default-ai.md)), and the Phase 6 full AI (colonizethis_ai) consume this API. For now, AIPlanner and defaultSimGameAi share the same **simple heuristics** implementation; see [ai-planner.md](ai-planner.md) and [sim-game-default-ai.md](sim-game-default-ai.md). Full AI behaviour is defined in [ai-systems-impl.md](ai-systems-impl.md).
