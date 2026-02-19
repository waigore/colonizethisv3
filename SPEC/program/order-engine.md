# Order Engine

**SPEC/program** — Current-turn order list, validation, merge, and projected effects. Order types: [orders.md](orders.md). Suggestion API: [order-suggestions.md](order-suggestions.md).

---

## Responsibility

The order engine (colonizethis_logic) maintains the **current-turn order list per player**. Invoked on add/remove order. Does **not** apply orders to world state; that happens in TurnResolver.

---

## Validation

**Trigger:** On every add/remove, re-validates the entire list for that player against world state (costs, caps, adjacency, tech per [orders.md](orders.md)).

**Rule:** Validate in **submission order**. First failure rejects that order and all after it. Orders 1..N-1 remain.

**With context:** Uses a PlayerView for visibility rules (move/work orders). Source province = unit's location; need not be owned by player. See [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md).

Returns validation results (accepted / rejected with reason) for UI feedback.

---

## Per-Player Scope

Validation is per-player only. No cross-player conflict resolution at this stage; that happens in turn resolution.

---

## Projected Effects

Supports a **dry-run**: apply orders to a copy of world state, return projected effects for UI (worker count, unit locations, stockpile deltas). No mutation of real state.

---

## Turn Resolution Integration

Before applying orders, TurnResolver runs a **merge** step: combine per-player lists (human + AI) with **human over AI** precedence for conflicts. Then resolve cross-player effects (conflict detection, diplomacy). Then apply in phase order per [turn-resolution-phases.md](turn-resolution-phases.md). The order engine does not perform merge or application.

---

## Determinism

Submission order is stable. Merge uses stable ordering (player id, order type, order id) for deterministic replay.

---

## Diagnostics

ctdev uses OrderEngine to surface order validity in the Orders (AI history) tab. This is purely diagnostic and does not alter orders passed to TurnResolver.
