# Turn Resolution Phases

**SPEC/program** — Phase sequence and per-phase behaviour. Overview: [turn-resolution.md](turn-resolution.md).

---

## Phase Sequence

TurnResolver runs phases in **fixed order**:

1. **Orders** (gather / validate; orders are already submitted with WorldState).
2. **Extraction** — Tile yields to stockpile.
3. **Riches to treasury** — Riches in stockpile convert to treasury at base price and are removed from stockpile.
4. **Production** — Recipes and labour; outputs to stockpile.
5. **Consumption** — Workers and military consume food and upkeep from stockpile.
6. **Movement** — Apply move orders; update unit locations.
7. **Build / work** — Apply build-unit orders (deduct cost, add unit); apply work orders (stub or one improvement type).
8. **End-of-turn** — Advance turn number; optionally reset unit status (e.g. movement points).

Exact ordering of build vs movement is implementation-defined as long as extraction → riches to treasury → production → consumption run before movement and build.

---

## Per-Phase Behaviour

- **Extraction:** For each owned province, compute per-tile effective extraction (min(improvement level, tech cap)); sum by commodity; add to owning player's stockpile. Auto-transport (land) is implicit: all to stockpile.
- **Riches to treasury:** For each player, for each riches commodity (gold, silver, gems, diamonds, spices) in the stockpile, add quantity × basePrice to the player's treasury; then remove that quantity from the stockpile (riches convert to cash and are consumed). Base prices: spices = 50; others derived from relative scarcity (spawn weights) so scarcer riches have higher base price. Reference: Imperialism II 02-economy, GDD 04.
- **Production:** For each recipe (or per-player production choices), consume inputs and labour from stockpile and WorkerPool; add outputs to stockpile. Insufficient input: skip or partial per spec.
- **Consumption:** Workers consume food (and luxuries per tier) from stockpile; military units consume upkeep. Starvation: remove worker; upkeep shortfall per design.
- **Movement:** Apply validated MoveOrders; set unit location to destination province.
- **Build / work:** Apply BuildUnitOrder (cost, worker for military, add unit); apply WorkOrder (status or one improvement).
- **End-of-turn:** Increment WorldState turn number; clear or carry over orders as designed.

Combat and diplomacy are not in scope; their phases are placeholders or omitted.
