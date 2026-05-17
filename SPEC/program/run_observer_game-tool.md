# run_observer_game tool (CLI)

**SPEC/program** — Standalone workspace package `tool/run_observer_game`, executable `run_observer_game`. Full-AI observer campaigns with turn traces and HTML/HTML-paired snapshots; global calendar cap at mapped year **1800** applies via shared game/rules (`SPEC/game/turn-time-mapping.md`). Stakeholder decisions: GitHub **#2498**.

## Invocation

From repo root (paths in args are relative to repo root):

```bash
melos run run_observer_game -- [options]
```

## CLI surface (normative)

| Flag | Meaning |
|------|---------|
| `--help` / `-h` | Usage on **stdout**; exit **0**. |
| `--output <dir>` | Required for a real run: artifact root `<dir>/observer-traces/<gameId>/…`. |
| `--seed <int>` | Optional; matches `init_game` / `GameSetupConfig` semantics when omitted vs set. |
| `--max-turns <int>` | Optional; default = campaign calendar cap turn **T** (`yearAtTurn(T)==1800` under game mapping; **201** for `gdd01`). Lower values shorten runs. |
| `--config <path>` | Optional JSON `GameSetupConfig` consistent with **`init_game`**. |
| `--verify-conquest` | After success: turn-1 vs turn-100 OW per-GP net +3 provinces (exit **5** on failure; requires `--max-turns >= 100` or no cap). |
| `--verify-colonial-expansion` | After success: turn-150 snapshot checks NW GP ownership and extractable improvement ratio (exit **6** on failure; requires `--max-turns >= 150` or no cap). |

**Errors:** Diagnostics via `logger`; user-facing failures → **stderr** and non-zero exit; no raw stack traces by default (match `init_game`).

## Artifact layout

Under `<output>/observer-traces/<gameId>/`:

### Full trace mode (default)

Active when **no** `--verify-*` flag is set.

- Merged turn-trace JSON per resolved turn (no pruning of prior turns for the run; exporter must not apply the default 10-file cap — see `SPEC/program/turn-resolution-json-trace.md`).
- Per turn (post-resolution): `turn-<zero-padded>.snapshot.json` and `turn-<zero-padded>.html` — **same canonical** `ObserverSnapshot` data; HTML is a render only.
- End: `run-summary.json` — `termination_reason` (`military_victory` \| `calendar_1800` \| `max_turns_override` \| …), `declared_winner_player_id` or none per `SPEC/game/victory.md` / calendar-cap winner rules (`greatPowerPowerScore`, tie → **no-one** where specified), final turn, seed, paths to artifacts.

### Minimal trace mode (auto when `--verify-*` is set)

Active when **`--verify-conquest` and/or `--verify-colonial-expansion`** is passed (no separate nightly flag). Refs **#2534**.

- **No** merged turn-trace JSON, **no** `.html`, **no** in-memory phase tracing (`onTurnTracePhase` / `turnTraceRuntime` off).
- **ObserverSnapshot** JSON only on turns required by the active verify flags (union):
  - `--verify-conquest` → `turn-000001.snapshot.json`, `turn-000100.snapshot.json`
  - `--verify-colonial-expansion` → `turn-000150.snapshot.json`
  - Both (nightly) → those **three** snapshots plus `run-summary.json` only.
- **`run-summary.json`** always written at end (`minimal_trace_mode: true` in summary when minimal mode ran).
- **Artifact size cap:** cumulative bytes under the game trace directory must stay **strictly below 300 MB** (`300 * 1024 * 1024`); if a write would exceed the cap, the run aborts with exit **7** (`artifact_size_cap_exceeded`). Canonical nightly verify inputs are expected to be far below the cap; the cap guards regressions that reintroduce large artifacts.

## ObserverSnapshot (`ObserverSnapshot` v2)

Versioned map written to `turn-<nnnnnn>.snapshot.json` and embedded (escaped) in paired `turn-<nnnnnn>.html`. **`observerSnapshotSchemaVersion` is `2`.**

| Field | Meaning |
|-------|---------|
| `observerSnapshotSchemaVersion` | Always `2` for this shape (v1 lacked extraction rollups). |
| `gameId` | Game id string. |
| `turnNumber` | Post-resolution turn index (`Game.worldState.turnState.turnNumber`). |
| `calendarYearAtTurnStart` | `yearAtTurn(turnNumber)` using the game's active `TurnTimeMapping` (if `turnNumber` is below 1, the lookup uses 1). |
| `calendarCampaignHalted` | Mirrors `Game.calendarCampaignHalted`. |
| `players` | One object per `game.players`: ids, display name, human flag, GP power score, treasury, military strength / fleet hints, sorted tech unlock ids. |
| `provinceOwnershipSorted` | Sorted list of `{ id, ownerId }` for every province (`allProvinces`), ids prefixed per world model. |
| `diplomacyRelationSummariesSorted` | Stable string lines summarizing each `diplomacyRelations` row (pair, score, level, war/peace). |
| `militaryArmySummariesSorted` | One string per land army (id, owner, region, regiment count). |
| `militaryFleetSummariesSorted` | One string per fleet (id, owner, ship count). |
| `extractableResourceTileCount` | Count of extractable resource tiles on GP-owned land at snapshot time (see § Extractable tile definition). |
| `improvedExtractableResourceTileCount` | Subset of the above with `improvementLevel >= 1`. |

HTML is a render-only wrapper: the `<pre>` body uses the **same** pretty-printed JSON bytes as the `.snapshot.json` file (after `HtmlEscape`).

## Turn processing wall-clock budget (Refs #2507)

Each **resolved turn** in the session loop measures the same segment as the app next-turn worker: **`generateOrdersForGameFullAI`** through **`validateOrdersAndResolveTurnFromTrustedOrders`** returning **`TurnResolutionComplete`**. That segment shares the **15 000 ms** ceiling **`kTurnProcessingWallClockBudgetMs`** ([turn-resolution.md](turn-resolution.md) § Turn processing wall-clock budget). **Excluded:** `runInitGame`, trace export, snapshot/HTML writes, and `run-summary.json` I/O. Nightly observer runs are integration targets; the **quality** gate enforces the budget via `colonizethis_ai` perf test on **turn 1** of **`GameSetupConfig.defaultConfig`**.

## Relationship to app / ctdev

- **App:** Merged trace file export when **`CT_DEBUG_CONSOLE=true`** (`--dart-define`); see logging/env TDD notes in **#2498**.
- **Ctdev:** `SimGameController.turnTraceEnabled` defaults from the same compile-time flag **`CT_DEBUG_CONSOLE`** (`ctdev/lib/ct_debug_console.dart`), so long sim sessions can emit merged trace files without a code change.
- **Tool:** Full trace mode always emits merged traces; minimal mode (verify flags) skips them.

## Conquest regression verification (Refs #2504)

`lib/observer_conquest_verify.dart` compares `turn-000001.snapshot.json` vs `turn-000100.snapshot.json` under a game trace directory: each Great Power `gp1`–`gp6` must gain **≥3** net **Old World** provinces (`oldWorld|…` ids only). Canonical seed **42**, **100** resolved turns. Pass **`--verify-conquest`** after a successful run (exit **5** on failure).

## Colonial expansion verification (Refs #2509)

`lib/observer_colonial_verify.dart` reads `turn-000150.snapshot.json`:

- **Global NW ownership:** every `provinceOwnershipSorted` row with id prefix `newWorld|` has `ownerId` ∈ `{gp1,…,gp6}`.
- **Improvement coverage:** `improvedExtractableResourceTileCount / extractableResourceTileCount >= 0.70` (if denominator is **0**, pass only when both counts are zero).

Pass **`--verify-colonial-expansion`** after a successful run (exit **6** on failure; requires `--max-turns >= 150` or no turn cap). Rollup computation: `lib/observer_extractable_rollup.dart` (init static resource grid ∩ GP-owned provinces at verify turn; excludes capital and province town tiles per [extraction-and-improvements.md](../game/extraction-and-improvements.md)).

Unit tests cover parsers; full observer runs are slow and are **not** in the default `quality` gate. **Nightly:** `.github/workflows/nightly.yml` job `observer_conquest_verify` runs seed **42**, **150** turns, **`--verify-conquest`**, and **`--verify-colonial-expansion`** daily at **23:00 Asia/Hong_Kong** (`0 15 * * *` UTC; `workflow_dispatch` supported).

## Coverage

CI: **≥ 80% line coverage on `tool/run_observer_game/lib/`** (`quality` workflow: `tool/check_coverage_threshold.sh 80 tool/run_observer_game` after `dart test --coverage` for that package).

## Acceptance (tool-specific)

- Given `melos run run_observer_game -- --help`, when the command completes, then exit code is **0** and stdout describes options and artifact layout at a high level.
- Given a successful multi-turn run (**S4+**), when outputs are written, then layout matches § Artifact layout and summary matches **#2498** ACs.
