# Turn Resolution Phases

**SPEC/program** — Phase sequence and per-phase behaviour. Overview: [turn-resolution.md](turn-resolution.md).

---

## Phase Sequence

TurnResolver runs phases in **fixed order**:

1. **Orders** (gather / validate; orders are already submitted with WorldState).
2. **Extraction** — Tile yields to stockpile.
3. **Production** — Recipes and labour; outputs to stockpile.
4. **Consumption** — Workers and military consume food and upkeep from stockpile.
5. **Movement** — Apply move orders; update unit locations.
6. **Build / work** — Apply build-unit orders (deduct cost, add unit); apply work orders (stub or one improvement type).
7. **End-of-turn** — Advance turn number; optionally reset unit status (e.g. movement points).

Exact ordering of build vs movement is implementation-defined as long as extraction → production → consumption run before movement and build.

---

## Per-Phase Behaviour

- **Extraction:** For each owned province, compute per-tile effective extraction (min(improvement level, tech cap)); sum by commodity; add to owning player's stockpile. Auto-transport (land) is implicit: all to stockpile.
- **Production:** For each recipe (or per-player production choices), consume inputs and labour from stockpile and WorkerPool; add outputs to stockpile. Insufficient input: skip or partial per spec.
- **Consumption:** Workers consume food (and luxuries per tier) from stockpile; military units consume upkeep. Starvation: remove worker; upkeep shortfall per design.
- **Movement:** Apply validated MoveOrders; set unit location to destination province.
- **Build / work:** Apply BuildUnitOrder (cost, worker for military, add unit); apply WorkOrder (status or one improvement).
- **End-of-turn:** Increment WorldState turn number; clear or carry over orders as designed.

Combat and diplomacy are not in scope; their phases are placeholders or omitted.
