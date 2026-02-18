# Research Resolution

**SPEC/program** — Technical research phase: inputs, validation, treasury deduction, progress, completion, state updates. Game rules: [tech-tree.md](../game/tech-tree.md), [tech-tree-catalog.md](../game/tech-tree-catalog.md). Phase order: [turn-resolution-phases.md](turn-resolution-phases.md).

---

## Purpose

The Research phase runs **after** Production and Consumption. It consumes per-player **research orders** (slot → techId, funding per slot), deducts spending from treasury, adds progress, and completes techs when progress ≥ cost. Completed techs update the player’s techUnlocked and any derived state (extraction cap, military level). Location: colonizethis_logic.

---

## Inputs

- **Game:** Current world state and players (treasury, techUnlocked, research progress per slot).
- **Per-player research orders:** Structure: slot index → techId (or empty), funding level per slot. Orders are merged (human + AI) like other orders; precedence per [order-engine.md](order-engine.md). Only Great Powers submit research orders. AI research orders are produced by the active AI backend: Phase 4 minimal AIPlanner or Phase 6 full AI (colonizethis_ai) when enabled; see [phase-6-project-tasks.md](../project/phase-6-project-tasks.md) and [SPEC/ai/](../ai/).

---

## Validation (before or during phase)

- Tech id is in the catalog.
- **All prerequisites** of that tech are in the player’s techUnlocked set. A tech B depending on A is **never** in the available set until A is completed; B cannot be started in the same turn A completes.
- Slot count ≤ max (3 base, 4 with University).
- **Total research commitment** for the turn ≤ player treasury. If orders exceed treasury, implementation may reject or reduce (e.g. reduce funding) per spec; commitment is validated so that spending can be deducted.
- Tech not already researched (not in techUnlocked).

---

## Phase Steps

1. **For each GP:** Read that player’s research orders (slot assignments and funding per slot).
2. **Validate** treasury and prerequisites per above; reject or reduce invalid slots.
3. **Deduct** research spending from each player’s treasury (cost committed for this turn; no relation to “turn income”).
4. **Add progress** per slot: funding level maps to research points per turn (per GDD funding presets); add points to the tech’s progress for that slot.
5. **Completion:** For each slot where progress ≥ tech’s research cost: set techUnlocked[techId] = true, clear that slot’s progress (slot becomes empty), update derived state (extraction cap, military level from catalog).
6. Persist updated players (techUnlocked, research progress) in Game.

---

## Research Orders Structure

Per player, per turn: a **research assignment** (e.g. Map&lt;slotIndex, techId&gt; or list of slot entries) and **funding per slot** (None / Low / Medium / High / Maximum). Goal slot is UI-only (sorting); no spending or progress. Cancel: clearing a slot **loses all progress** for that tech (GDD / Imperialism II); no partial save.

---

## Merge Semantics

Human and AI research orders are merged like other order types. Precedence (e.g. human over AI for conflicting slot assignments) follows the existing order-merge spec. Merge is possible only when total cost fits in treasury and prerequisites are satisfied; a tech B that depends on A cannot be in any slot until A is completed.
