# Logging — map generation

**SPEC/program/logging** — Annex to [logging.md](logging.md). Applies to **map** package code, **tool/generate_map**, init-game map orchestration, and any host that triggers generation.

---

## Info (parameters and results)

- **Start:** One **info** line with **all** generation inputs that affect output: at minimum `seed`, `numProvinces` (or per-region counts), `numContinents`, derived or explicit **grid** `width`/`height`, `seaFraction`, toggles (`joinContinents`, `skipFillLakes`, `seedBeforeAssignment`, etc.), and `regionId` when generation is per-region. Align field names with [map-data.md](../map-data.md) / [game-setup-pipeline.md](../game-setup-pipeline.md) where applicable.
- **Milestones:** **Info** lines at **phase boundaries** named consistently with [tile-map-gen-algorithm.md](../tile-map-gen-algorithm.md) (e.g. topology fixed, province assignment complete). Each line includes `pass` or `phase` name and **summary scalars** (counts, not full rasters).
- **End:** **Info** line with **result summary**: province count realized, continent count, failure/success, and any **diagnostic** scalar required by [game-setup-pipeline.md](../game-setup-pipeline.md) for OW/NW generation calls.

---

## Debug (intermediates)

- **Per pass / step:** **Debug** lines for **intermediate** state: e.g. iteration counts, convergence flags, histogram summaries, bounding metrics. Do not log full tile grids at info; if a pass needs raster inspection, use **debug** with **hash or dimensions + sample** unless a spec explicitly requires more for a tool.

---

## CLI and tools

- Human-readable **reports** to stdout remain allowed per CLI contract; **operational** progress must still use `logger` with `map:` (via `mapLogger`) for parity with in-app runs.

---

## Acceptance criteria

- **Given** a map generation run with known parameters, **when** generation completes successfully, **then** the log contains one **info** line that includes those parameters and one **info** summary line with outcome counts.
- **Given** a multi-pass generator, **when** each named pass completes, **then** there is at least one **debug** line (or documented exception) recording pass-local metrics sufficient to compare two runs with the same seed.
