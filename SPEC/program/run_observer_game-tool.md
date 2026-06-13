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
| `--profiles <dir>` | Optional directory of per-GP `AiProfile` JSON files keyed `<playerId>.json`; overrides AI personality params at decision time (see § Per-GP AI profiles). |
| `--verify-conquest` | After success: turn-1 vs turn-100 OW per-GP net +3 provinces (exit **5** on failure; requires `--max-turns >= 100` or no cap). |
| `--verify-colonial-expansion` | After success: turn-150 snapshot checks NW GP ownership and extractable improvement ratio (exit **6** on failure; requires `--max-turns >= 150` or no cap). |
| `--verify-workforce` | After success: turn-100 snapshot checks every Great Power `gp1`–`gp6` has `peasants >= 15` AND `apprentices + journeymen + masters >= 8` (exit **8** on failure; requires `--max-turns >= 100` or no cap; Refs #2692 S10). |

**Errors:** Diagnostics via `logger`; user-facing failures → **stderr** and non-zero exit; no raw stack traces by default (match `init_game`).

## Full-AI setup (no post-init override)

The observer always builds a **fully-AI** game **at init** by forcing `GameSetupConfig.humanGreatPowerSlotIndices = {}` (empty) regardless of any `--config` JSON or `--seed` override (see [game-setup-pipeline.md](game-setup-pipeline.md) § Human/AI slot assignment). Consequently every Great Power has `isHuman == false` and `aiControlByGpId[gpId] == true` from creation; the tool does **not** mutate `aiControlByGpId` after init. Snapshot player rollups therefore report `"isHuman": false` for every GP including `gp1`.

## Per-GP AI profiles (`--profiles`, Refs #3437)

`--profiles <dir>` loads `AiProfile` JSON (`SPEC/ai/ai-parameter-registry.md`) per Great Power and overrides hardcoded AI personality parameters at decision time per [ai-profile-overrides.md](../ai/ai-profile-overrides.md):

- Files are keyed by **`playerId`**: `<dir>/<playerId>.json` (the in-game player id, e.g. `gp1.json`). The set of GPs comes from the loaded setup (`game.players`), **not** from scanning the directory.
- A GP without a matching file uses its default hardcoded personality. Files not matching any GP `playerId` are ignored and logged at **warn** (`session` sub-prefix `observer:profile_unmatched`).
- Each matched file is parsed via `AiProfile.fromJson`. A missing directory or any unparseable/invalid profile file aborts the run with a clear **stderr** message and exit **9** (`profile_load_failed`) before the turn loop starts; valid profiles log one **info** line `observer:profiles_loaded count=<n>`.
- The loaded `Map<String, AiProfile>` (keyed by `playerId`) is passed into `generateOrdersForGameFullAI`; each GP's active `profile_id` appears in its turn trace under `state.decisionContext.profileId`.
- Omitting `--profiles` is byte-for-byte identical to prior behavior.

## Artifact layout

Under `<output>/observer-traces/<gameId>/`:

### Full trace mode (default)

Active when **no** `--verify-*` flag is set.

- Merged turn-trace JSON per resolved turn (no pruning of prior turns for the run; exporter must not apply the default 10-file cap — see `SPEC/program/turn-resolution-json-trace.md`).
- Per turn (post-resolution): `turn-<zero-padded>.snapshot.json` and `turn-<zero-padded>.html` — **same canonical** `ObserverSnapshot` data; HTML is a render only.
- End: `run-summary.json` — `termination_reason` (`military_victory` \| `calendar_1800` \| `max_turns_override` \| …), `declared_winner_player_id` or none per `SPEC/game/victory.md` / calendar-cap winner rules (`greatPowerPowerScore`, tie → **no-one** where specified), final turn, seed, paths to artifacts.

### Minimal trace mode (auto when `--verify-*` is set)

Active when **`--verify-conquest`, `--verify-colonial-expansion`, and/or `--verify-workforce`** is passed (no separate nightly flag). Refs **#2534**, **#2692 S10**.

- **No** merged turn-trace JSON, **no** `.html`, **no** in-memory phase tracing (`onTurnTracePhase` / `turnTraceRuntime` off).
- **ObserverSnapshot** JSON only on turns required by the active verify flags (union):
  - `--verify-conquest` → `turn-000001.snapshot.json`, `turn-000100.snapshot.json`
  - `--verify-colonial-expansion` → `turn-000150.snapshot.json`
  - `--verify-workforce` → `turn-000100.snapshot.json`
  - All three (nightly) → those **three** distinct snapshots (turns 1, 100, 150) plus `run-summary.json` only.
- **`run-summary.json`** always written at end (`minimal_trace_mode: true` in summary when minimal mode ran).
- **Artifact size cap:** cumulative bytes under the game trace directory must stay **strictly below 300 MB** (`300 * 1024 * 1024`); if a write would exceed the cap, the run aborts with exit **7** (`artifact_size_cap_exceeded`). Canonical nightly verify inputs are expected to be far below the cap; the cap guards regressions that reintroduce large artifacts.

## ObserverSnapshot (`ObserverSnapshot` v4)

Versioned map written to `turn-<nnnnnn>.snapshot.json` and embedded (escaped) in paired `turn-<nnnnnn>.html`. **`observerSnapshotSchemaVersion` is `4`** (Refs **#2692** S10a → S10b; v3 added per-player `workerPool`, v4 adds per-player `luxuryStockpile` + `lastTurnLuxuryProduction`).

| Field | Meaning |
|-------|---------|
| `observerSnapshotSchemaVersion` | `4` (v3 lacked luxury rollups; v2 lacked `workerPool`; v1 lacked extraction rollups). |
| `gameId` | Game id string. |
| `turnNumber` | Post-resolution turn index (`Game.worldState.turnState.turnNumber`). |
| `calendarYearAtTurnStart` | `yearAtTurn(turnNumber)` using the game's active `TurnTimeMapping` (if `turnNumber` is below 1, the lookup uses 1). |
| `calendarCampaignHalted` | Mirrors `Game.calendarCampaignHalted`. |
| `players` | One object per `game.players`: ids, display name, human flag, GP power score, treasury, military strength / fleet hints, sorted tech unlock ids, **`workerPool`** (peasants / apprentices / journeymen / masters mirroring `Player.workerPool`), **`luxuryStockpile`** (`refinedSugar`, `cigars`, `furHats` quantities from `Player.stockpile`, with absent commodities serialized as `0`), and **`lastTurnLuxuryProduction`** (same three commodity ids, summed from the most recent `productionByRecipeByPlayerId` callback when `buildObserverSnapshotJson` is passed `lastTurnProductionByRecipeByPlayerId`; absent player ids and non-luxury recipe outputs serialize to `0`). |
| `provinceOwnershipSorted` | Sorted list of `{ id, ownerId }` for every province (`allProvinces`), ids prefixed per world model. |
| `diplomacyRelationSummariesSorted` | Stable string lines summarizing each `diplomacyRelations` row (pair, score, level, war/peace). |
| `militaryArmySummariesSorted` | One string per land army (id, owner, region, regiment count). |
| `militaryFleetSummariesSorted` | One string per fleet (id, owner, ship count). |
| `extractableResourceTileCount` | Count of extractable resource tiles on GP-owned land at snapshot time (see § Extractable tile definition). |
| `improvedExtractableResourceTileCount` | Subset of the above with `improvementLevel >= 1`. |

HTML is a render-only wrapper: the `<pre>` body uses the **same** pretty-printed JSON bytes as the `.snapshot.json` file (after `HtmlEscape`).

## Turn processing wall-clock budget (Refs #2507)

### Per-turn measurement, logging, and summary (Refs #3393 Phase 6c)

A single `Stopwatch` wraps the budget segment per resolved turn in **both** full-trace and minimal-trace modes; it starts immediately before `generateOrdersForGameFullAI` and stops immediately after `validateOrdersAndResolveTurnFromTrustedOrders` returns, **before** any trace export, snapshot/HTML write, or `run-summary.json` I/O.

- **Logging signal (`session` sub-prefix):** Each resolved turn emits exactly one timing line. At or under budget → **info** `observer:turn_processing turn=<n> ms=<int> budgetMs=15000 overBudget=false`. Over budget (`ms > kTurnProcessingWallClockBudgetMs`) → **warning** `observer:turn_processing_over_budget turn=<n> ms=<int> budgetMs=15000`. These are grep-stable tokens for budget-regression triage and complement the per-phase `logic` logs in [logging/turn-resolution.md](logging/turn-resolution.md).
- **`run-summary.json` fields (`runSummarySchemaVersion: 2`):** the summary additionally carries `turn_processing_wall_clock_budget_ms` (the `15000` ceiling), `turn_processing_wall_clock_ms_by_turn` (one entry per resolved turn, in resolution order), `max_turn_processing_wall_clock_ms`, `turns_over_wall_clock_budget` (count), and `over_wall_clock_budget_turn_numbers` (post-resolution turn numbers that breached the ceiling). For a zero-turn run (`--max-turns 0`) the list is empty and `max_turn_processing_wall_clock_ms` is `0`.

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

**Phase-entry budget (Refs #2848).** Complementing the turn-150 colonial gate, every Great Power `gp1`–`gp6` must reach `ObserverGoalPhase.colonial` by turn **90** on seed **42** (leaves **≥ 60** post-entry turns for NW acquisition + improvements). Measurement check only — **not** wired into `--verify-colonial-expansion` exit codes. Regression-guarded by `packages/colonizethis_ai/test/seed42_observer_colonial_phase_entry_budget_test.dart` (currently `skip`ped pending EXPAND-side gating; Refs #2847 / #2924 / #2925).

Unit tests cover parsers; full observer runs are slow and are **not** in the default `quality` gate. **Nightly:** `.github/workflows/nightly.yml` job `observer_conquest_verify` runs seed **42**, **150** turns, **`--verify-conquest`**, **`--verify-colonial-expansion`**, and **`--verify-workforce`** daily at **23:00 Asia/Hong_Kong** (`0 15 * * *` UTC; `workflow_dispatch` supported).

## Workforce sustain verification (Refs #2692 S10 + S10b)

`lib/observer_workforce_verify.dart` reads `turn-000100.snapshot.json` and, per `gp1`–`gp6`, asserts `peasants >= 15` AND `apprentices + journeymen + masters >= 8` AND, for each trained tier with a non-zero count, `luxuryStockpile + lastTurnLuxuryProduction >= tier count` for the matched luxury commodity (`apprentices ↔ refinedSugar`, `journeymen ↔ cigars`, `masters ↔ furHats` — Requirement §21 bullet 4 of issue #2692). Pass **`--verify-workforce`** after a successful run (exit **8** on failure; requires `--max-turns >= 100` or no turn cap). Food production sustain (§21 bullet 3, `grain + meat`) remains deferred behind `kObserverWorkforceFoodProductionDeferred`; thresholds, parser contract, and the deferral marker live in [observer-workforce-verify.md](observer-workforce-verify.md). `ObserverSnapshot` v4 surfaces `luxuryStockpile` and `lastTurnLuxuryProduction` per player; the session runner wires `onProductionComplete` through `validateOrdersAndResolveTurnFromTrustedOrders` and forwards the captured `productionByRecipeByPlayerId` into `buildObserverSnapshotJson` for aggregation.

## Coverage

CI: **≥ 80% line coverage on `tool/run_observer_game/lib/`** (`quality` workflow: `tool/check_coverage_threshold.sh 80 tool/run_observer_game` after `dart test --coverage` for that package).

## Acceptance (tool-specific)

- Given `melos run run_observer_game -- --help`, when the command completes, then exit code is **0** and stdout describes options and artifact layout at a high level.
- Given `--profiles <dir>` pointing at a directory containing `<playerId>.json` for a Great Power whose personality weights differ from that leader's defaults, when a turn is resolved, then that GP's turn-trace `state.decisionContext.profileId` equals the profile's `profile_id` and its `thresholds.derived.domainWeights` differ from a run without `--profiles`.
- Given `--profiles <dir>` where `<dir>` does not exist or contains an unparseable `<playerId>.json`, when the tool runs, then it writes a clear stderr message and exits **9** without resolving turns.
- Given `--profiles <dir>` containing a file that matches no Great Power `playerId`, when the tool runs, then that file is ignored, a `session` warn line `observer:profile_unmatched` is logged, and the run proceeds normally.
- Given a successful multi-turn run (**S4+**), when outputs are written, then layout matches § Artifact layout and summary matches **#2498** ACs.
- Given a successful run that resolves **N ≥ 1** turns, when `run-summary.json` is written, then `runSummarySchemaVersion` is `2`, `turn_processing_wall_clock_ms_by_turn` is a list of exactly **N** non-negative integers, `turn_processing_wall_clock_budget_ms` equals `kTurnProcessingWallClockBudgetMs` (`15000`), and `max_turn_processing_wall_clock_ms` equals the maximum of that list.
- Given a run with `--max-turns 0`, when `run-summary.json` is written, then `turn_processing_wall_clock_ms_by_turn` is an empty list, `max_turn_processing_wall_clock_ms` is `0`, and `turns_over_wall_clock_budget` is `0`.
- Given a resolved turn whose measured segment is at or under `15000` ms, when the turn completes, then the `session` logger emits exactly one **info** line containing `observer:turn_processing turn=<n>` with `overBudget=false`; given a resolved turn whose segment exceeds `15000` ms, then the `session` logger instead emits a **warning** line containing `observer:turn_processing_over_budget turn=<n>` and the turn number is appended to `over_wall_clock_budget_turn_numbers` in `run-summary.json`.
