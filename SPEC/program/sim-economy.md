# sim_economy — Economy Simulation Tool

**SPEC/program** — Standalone CLI tool to simulate a single player’s economy loop. Reuses Phase 2 economy rules without requiring map, topology, or units. References: [stockpiles-and-production.md](../game/stockpiles-and-production.md), [workers-and-population.md](../game/workers-and-population.md), [commodity-catalog.md](../game/commodity-catalog.md), [production-recipes.md](../game/production-recipes.md), [economy-models.md](economy-models.md), [turn-resolution-phases.md](turn-resolution-phases.md).

---

## Purpose and Scope

- **Purpose:** Deterministically simulate a single player’s economy (stockpile + WorkerPool) over N turns using Phase 2 rules: extraction, riches to treasury, production, and consumption. No map, movement, combat, diplomacy, AI, or trade.
- **Owner:** Program layer (Dart CLI, e.g. `melo sim_economy`), implemented in a tools/shared package that depends on `colonizethis_models`, `colonizethis_data`, and `colonizethis_logic`.
- **Scope:** Single-player, single-economy simulation:
  - Uses `Stockpile` and `WorkerPool` models from `colonizethis_models`.
  - Uses commodity catalog and production recipes from `colonizethis_data`.
  - Uses extraction, production, and consumption logic from `colonizethis_logic` (or thin wrappers).

---

## CLI Interface

- Command: `melo sim_economy`.
- Arguments:
  - `--script <path>` (optional): JSON script describing initial state and per-turn instructions. If omitted, the tool uses a randomized “new game”-like initial state and default per-turn behaviour.
  - `--turns <N>` (optional): number of turns to simulate. Required when no script is provided; when a script is present and defines fewer than N turns, the simulation stops after the last scripted turn.
  - `--seed <int>` (optional): RNG seed for reproducible randomized initial states and any default per-turn behaviour.
  - `--output <path>` (optional): path for writing the Markdown report. If omitted, the report is written to `sim_economy.md` in the current working directory.
  - `--json-output <path>` (optional): path for writing the per-turn JSON log. If omitted, no JSON file is written.

Validation errors (malformed script, unknown ids, negative quantities) are reported clearly and abort the run.

---

## Script Format (JSON)

Top-level keys:

- `metadata`: scenario name, total turns.
- `initialState`: starting `stockpile`, `workers` (tiers), optional `militaryUnits` and `treasury`.
- `turns`: array of per-turn objects.

Each `turn` object:

- `turn`: 1-based turn index.
- `extraction`: either a flat `commodityId -> quantity` map, or
  `{ "oldWorld": { ... }, "newWorld": { ... } }` that is summed by commodity.
- `workerAssignments`: list of `{ "recipeId": string, "assignedLabour": int }` (ids match recipes in `colonizethis_data`).
- `actions` (optional): minimal commands:
  - `recruit_worker` (tier, count).
  - `train_worker` (fromTier, toTier, count).
  - Optionally `build_military_unit` (consumes worker + commodities) if consistent with Phase 2 unit rules.

`commodityId` and `recipeId` must come from `[commodity-catalog.md]` and `[production-recipes.md]`.

---

## Modes and Initial State

### Random-start default mode (no `--script`)

The tool samples an initial state from bounded ranges approximating a plausible “new game”:

- **Stockpile ranges (inclusive, integer):**
  - Food: `grain` 40–80, `meat` 20–40.
  - Old World raws: `timber` 20–40, `iron` 10–25, `coal` 10–20, `wool` 10–20, `cotton` 0–10.
  - New World raws (optional; may be 0 by default): `sugarCane` 0–10, `tobacco` 0–10, `furs` 0–10.
  - Manufactured: `lumber` 5–15, `castIron` 5–15, `fabric` 10–20, `paper` 5–10.
  - Luxuries: `refinedSugar` 0–5, `cigars` 0–5, `furHats` 0–5.
  - Riches/advanced: `gold` 0–3, `silver` 0–5, `gems` 0–3, `diamonds` 0–1, `spices` 0–3.
- **WorkerPool:** `peasants` 8–14; `apprentices` 0–3; `journeymen` 0–1; `masters` 0. Implementations may bias toward fewer trained workers while remaining deterministic under a given seed.
- **Military and treasury (optional):** land `militaryUnits` 0–1; `treasury` 50–150 (or a fixed default).

Default per-turn behaviour:

- **Extraction (deterministic vector):**
  - Old World per turn: `grain` 4–6, `meat` 1–3, `timber` 3–5, `iron` 1–3, `coal` 1–2, `wool` 1–2.
  - New World per turn (optional; may be 0): `sugarCane` 0–2, `tobacco` 0–2, `furs` 0–2.
- **Worker assignments:** each turn, compute effective labour from `WorkerPool` (respecting luxury rules). Assign fixed fractions of labour to a small, hard-coded recipe set (e.g. 40% fabric, 30% castIron, 30% lumber), then run recipes subject to input availability. This is a simple baseline, not an AI.

Randomness is controlled solely by `--seed`; same seed and config yield identical simulations.

### Scripted mode (`--script` provided)

- `initialState` in the script can override the randomized default.
- Per-turn extraction and `workerAssignments` come exclusively from the script; the economy loop itself is deterministic given the script and config.

---

## Turn Algorithm

For each turn (from script or default profile), sim_economy runs the Phase 2 economy sequence:

1. **Actions:** Apply `recruit_worker`, `train_worker`, and optional `build_military_unit` using the same costs and WorkerPool rules as the main game (tech gating may be stubbed).
2. **Extraction:** Aggregate extraction for the turn (scripted or default) and add directly to the player’s `Stockpile` (auto-transport semantics; no per-province storage).
3. **Riches to treasury:** Convert all riches in the stockpile to treasury at base price and remove them from the stockpile; treasury is updated each turn by this phase.
4. **Production:** For each recipe referenced by assignments, compute maximum runs limited by:
   - Assigned labour and effective labour from `WorkerPool`.
   - Available input commodities in `Stockpile`.
   Deduct inputs and labour; add outputs to `Stockpile`.
5. **Consumption:** Apply worker food and luxury consumption and one military upkeep step, updating `Stockpile` and `WorkerPool` (starvation removes workers; missing luxuries yield zero labour for trained tiers that turn).
6. **End-of-turn:** Record final state and advance the turn counter, matching the extraction → riches to treasury → production → consumption position in [turn-resolution-phases.md](turn-resolution-phases.md).

Error handling covers insufficient inputs/labour (recipes skipped or partially run), insufficient food/luxuries, and unpaid upkeep according to Phase 2 economy rules.

During the turn, the implementation captures intermediate `Stockpile` states after extraction and after production. Per-phase deltas used in both the Markdown report and JSON log are derived from simple differences between these snapshots, so the reported flows are **exact** given the underlying logic.

---

## Output

Per turn, sim_economy emits:

- Starting `Stockpile` and `WorkerPool`.
- Extraction, riches-to-treasury, production, and consumption deltas by commodity.
- Treasury (reported and updated when riches are present in stockpile after extraction).
- Worker changes (recruited, trained, starved) and military upkeep status.
- Ending `Stockpile` and `WorkerPool`.

### Default human-readable output (Markdown)

After the simulation completes, `sim_economy` writes a Markdown report to disk:

- If `--output <path>` is provided, the report is written to that path.
- Otherwise, the report is written to `sim_economy.md` in the current working directory.

- **Run header and metadata:**
  - Title (e.g. `# sim_economy run`).
  - Small table with seed, script path (if any), total turns, and timestamp.
- **Initial state:**
  - Table for starting `Stockpile` (non-zero commodities, or full catalog) with columns: `Commodity`, `Quantity`.
  - Table for starting `WorkerPool` with columns: `Class`, `Count`.
  - An \"Other\" table listing `militaryUnits` and `treasury` when available.
- **Per turn (two tables per turn):**
  - **Economy table (A)** — stockpiles and flows, one row per commodity:
    - Columns: `Commodity`, `Start`, `End`, `Δ`, `Flows`, `Reason`.
    - `Start` / `End` are total quantities at the beginning and end of the turn.
    - `Δ` is `End - Start`.
    - `Flows` is a compact string of exact per-phase deltas, e.g. `E+5, P+1, C-2`, where:
      - `E` is the extraction phase delta (after applying extraction).
      - `P` is the production phase delta (net change during production).
      - `C` is the consumption phase delta (net change during consumption).
      - Components that are exactly zero may be omitted to keep the cell compact.
    - `Reason` is a short, human-readable explanation of which systems drove the net change, such as:
      - `worker food` when worker consumption affects food commodities.
      - `military upkeep` when military units contribute to food consumption.
      - `production output` / `production inputs` when recipes produce or consume that commodity.
      - Combinations like `worker food + military upkeep` or `extraction + production inputs` when multiple systems apply.
    - `Reason` is descriptive only and not intended as a stable machine API.
  - **Labour table (B)** — workers and assignments in a single mixed table:
    - Columns: `Type`, `Name`, `Start`, `End`, `Δ / Labour`, `Notes`.
    - Worker rows (`Type = W`):
      - `Start` / `End` from `WorkerPool` at the beginning and end of the turn.
      - `Δ / Labour` shows the signed change (e.g. `Δ -1` for peasants).
    - Assignment rows (`Type = R`):
      - `Name` is `recipeId`.
      - `Δ / Labour` shows `L <assignedLabour>` for that recipe.
      - `Start` / `End` are not applicable and may be shown as `-`.
      - `Notes` can optionally describe the primary output commodity.

The Markdown report is a **debugging and analysis aid**, not a stable external API. Its structure may evolve together with the CLI tool.

### Machine-readable log (`--json-output`, JSON)

When `--json-output <path>` is provided, `sim_economy` writes a JSON array of per-turn objects to the given path. Each object contains:

- `turn`: 1-based turn index.
- `stockpileStart`, `stockpileAfterExtraction`, `stockpileAfterRiches`, `stockpileAfterProduction`, `stockpileEnd`: maps `commodityId -> quantity`.
- `workersStart`, `workersEnd`: `WorkerPool` snapshots as JSON.
- `deltaExtraction`, `deltaRiches`, `deltaProduction`, `deltaConsumption`: maps `commodityId -> delta` for each phase.
- `treasuryDeltaFromRiches`, `treasuryEndOfTurn`: treasury change from riches phase and treasury at end of turn (when available).
- `workerAssignments`: list of `{ "recipeId": string, "assignedLabour": int }` used that turn.

The identity `stockpileStart[c] + deltaExtraction[c] + deltaRiches[c] + deltaProduction[c] + deltaConsumption[c] == stockpileEnd[c]` holds for every commodity `c` reported.

