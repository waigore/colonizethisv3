# sim_economy — Economy Simulation Tool

## Responsibility
Standalone CLI tool to simulate a single player's economy loop over N turns using phases 3–6 (Extraction, Riches to treasury, Production, Consumption) per [turn-resolution-phases.md](turn-resolution-phases.md). No map, movement, combat, diplomacy, AI, or trade. Game rules: [stockpiles-and-production.md](../game/stockpiles-and-production.md), [workers-and-population.md](../game/workers-and-population.md).

## Data Model

### CLI Interface

Command: `melos run sim_economy`

| Argument | Required | Description |
|----------|----------|-------------|
| `--script <path>` | No | JSON script with initial state and per-turn instructions |
| `--turns <N>` | When no script | Turns to simulate |
| `--seed <int>` | No | RNG seed for reproducibility |
| `--output <path>` | No | Markdown report path (default: `sim_economy.md` in cwd) |
| `--json-output <path>` | No | Per-turn JSON log path |

### Script Format
Top-level: `metadata`, `initialState` (stockpile, workers, optional military/treasury), `turns` (array). Each turn: `extraction` (commodity → quantity), `workerAssignments` (recipe id → labour), optional `actions` (recruit/train worker, build unit). Ids from [commodity-catalog.md](../game/commodity-catalog.md) and [production-recipes.md](../game/production-recipes.md).

### Modes
- **Random-start** (no script): Bounded random initial state from seed with default per-turn extraction and fixed-fraction recipe assignments.
- **Scripted**: Initial state and per-turn instructions from JSON.

## Algorithm / Flow

Per turn, runs the economy sequence (phases 3–6) per [turn-resolution-phases.md](turn-resolution-phases.md):

1. **Actions** — Recruit/train workers, optional build unit.
2. **Extraction** — Add to stockpile (auto-transport semantics).
3. **Riches to treasury** — Convert riches at base price.
4. **Production** — Run recipes limited by assigned labour and available inputs.
5. **Consumption** — Worker food/luxury consumption, military upkeep.

## Integration

- **Phase:** Development tool; not part of turn resolution.
- **Upstream:** `colonizethis_models` (Stockpile, WorkerPool), `colonizethis_data` (catalog, recipes), `colonizethis_logic` (economy logic).
- **Downstream:** Markdown report (per-turn economy/labour tables with deltas) and optional JSON log (per-turn snapshots; `start[c] + Σdeltas[c] == end[c]`).

## Constraints
- Deterministic: same seed + config → identical simulation.
- Validation errors abort with clear message.
- Output formats are debugging aids, not stable APIs.
