# Orders

**SPEC/program** — Order types, validation, and resolution. Reference: [movement.md](movement.md), [SPEC/game/unit-types.md](../game/unit-types.md).

---

## Order Types (Current Scope)

- **MoveOrder** — Unit id, destination province id. Valid if destination is adjacent (see [movement.md](movement.md)); applied in movement phase.
- **BuildUnitOrder** — Unit type (civilian or military), optional spawn province. Valid if player has sufficient stockpile (cost) and, for military, a worker to consume; within unit caps. Applied in build phase: deduct cost, consume worker if military, add unit to world state.
- **WorkOrder** — Unit id, work target (explore, build improvement, prospect). Valid if unit is civilian and in scope. Resolution: minimal stub (e.g. set unit status to working) or apply one improvement type (e.g. Builder increases tile improvement level). Full work completion can span turns per design.

---

## Validation

- **Topology:** MoveOrder destination from colonizethis_data adjacency.
- **Costs:** BuildUnitOrder consumes commodities from player stockpile and (for military) one worker from WorkerPool. Costs and caps from program-level config (colonizethis_data).
- **Caps:** Civilian and military unit counts must not exceed per-player caps after build.

Rejected orders are not applied; state unchanged.

---

## Resolution

Orders are applied in defined phases: build orders (add units, deduct costs) before or after movement as per [turn-resolution-phases.md](turn-resolution-phases.md). Move orders applied in movement phase. Work orders applied in same or separate step; work-in-progress can persist across turns.
