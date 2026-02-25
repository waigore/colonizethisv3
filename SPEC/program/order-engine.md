# Order Engine

**SPEC/program** — Current-turn order list, validation, merge, and projected effects. Order types: [orders.md](orders.md). Suggestion API: [order-suggestions.md](order-suggestions.md).

---

## Responsibility

The order engine (colonizethis_logic) maintains the **current-turn order list per player**. Invoked on add/remove order. Does **not** apply orders to world state; that happens in TurnResolver.

---

## Validation

**Trigger:** On every add/remove, re-validates the entire list for that player against world state (costs, caps, adjacency, tech per [orders.md](orders.md)).

**Scope:** The engine validates **move**, **build**, **work**, **diplomatic**, **naval move**, and **naval mission** orders. **Research** orders are validated in the research phase (TurnResolver), not in the engine. Diplomatic orders are held and validated per-player like other order types (preconditions for war/peace, alliances, overtures, grants, and subsidies) and then passed into the merge step.

**Rule:** Validate in **submission order**. First failure rejects that order and all after it. Orders 1..N-1 remain.

**With context:** Uses a PlayerView for visibility rules (move/work orders). Source province = unit's location; need not be owned by player. See [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md).

Returns validation results (accepted / rejected with reason) for UI feedback.

---

## Per-Player Scope

Validation is per-player only. No cross-player conflict resolution at this stage; that happens in turn resolution.

---

## Projected Effects

Supports a **dry-run**: apply orders via the resolver (which returns **new** state); return projected effects for UI (worker count, treasury delta, unit locations, stockpile deltas). The engine does **not** mutate the passed-in game; the caller may pass the live game. No mutation of real state.

`projectedEffects` accepts an optional `tileMapByRegion`. When omitted or empty, the dry-run uses no tile maps and **expected extraction is zero**; callers (e.g. SimGameController) may pass tile maps when available so projected extraction is non-zero. See [order-projections.md](order-projections.md).

---

## Turn Resolution Integration

Before applying orders, TurnResolver runs a **merge** step: combine per-player lists (human + AI) with **human over AI** precedence for conflicts. Merge includes **diplomatic** orders (human over AI per type+target), using only those diplomatic orders that passed OrderEngine validation for each player. Then resolve cross-player effects (conflict detection, diplomacy). Then apply in phase order per [turn-resolution-phases.md](turn-resolution-phases.md). The order engine does not perform merge or application.

---

## End-of-turn order list

**(a) Clear or carry over:** After turn resolution, the current-turn order list is **cleared** (not carried over). Each turn starts with an empty order list; players submit orders for that turn; after End-of-turn those orders have been applied and are not reused for the next turn.

**(b) Responsibility:** TurnResolver does not mutate the OrderEngine or the caller's order data; it only reads orders. The **caller** (app, ctdev, or scenario runner) that owns the order list or OrderEngine is responsible for clearing or replacing it after TurnResolver returns, so that the next turn starts with a fresh order list. Merge and apply for the next turn happen when that turn's Orders phase runs (see [turn-resolution-phase-details.md](turn-resolution-phase-details.md) § End-of-turn).

---

## Determinism

Submission order is stable. Merge uses stable ordering (player id, order type, order id) for deterministic replay.

---

## Acceptance criteria

- **Validation:** On add/remove with context, the full list for that player is validated in submission order; first rejection rejects that order and all subsequent; validation results (accepted/rejected + reason) are returned for UI.
- **Diplomatic validation:** Diplomatic orders (Declare War, Offer Peace, Alliance, Establish Overture, GrantAid, SetSubsidy) are validated by the engine with the same submission-order semantics as other orders. At a minimum, Declare War and Offer Peace respect current relationState preconditions, overtures respect the overture-stage chain and treasury costs, GrantAid requires an Embassy and SetSubsidy requires at least a Consulate, and `Establish Overture` orders targeting a faction currently at `AT_WAR` with the player are rejected and do not deduct treasury.
- **Merge:** Human + AI orders merged with human over AI for conflicts; ordering is stable for deterministic replay (player id, then conflict key / order type as specified).
- **Projected effects:** Dry-run returns worker count, treasury delta, and when implemented unit locations and stockpile deltas for UI; no mutation of the passed-in game from the caller's perspective.
- **No application:** Order engine does not apply orders to world state; TurnResolver applies after merge.

---

## Diagnostics

ctdev uses OrderEngine to surface order validity in the Orders (AI history) tab. This is purely diagnostic and does not alter orders passed to TurnResolver.
