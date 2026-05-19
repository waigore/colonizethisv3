# Repo Layout and Package Plan

**SPEC/program** — In-repo source of truth for repository structure and shared packages. Derived from **TDD 15 (Technical Architecture)**.

---

## Repo layout

Monorepo layout:

- **Root:** `SPEC/`, `packages/`, `app/`, **`ctdev/`** (developer Flutter shell; sim and tooling UI), optional `assets/`, **`tool/`** (standalone CLI tools), tooling (e.g. `analysis_options.yaml`).
- **Flutter app** lives under **`app/`** (not at root). Run and build from `app/` (e.g. `flutter run`, `flutter build macos`). Package work is done in `packages/<name>/`.
- **Ctdev** lives under **`ctdev/`** — Flutter package for development workflows (see [ctdev-app.md](ctdev-app.md)).
- **Standalone CLI tools** (e.g. topology description, map generation) live under **`tool/`**. Run from the **project root** via **Melos**: `melos run <tool_name> -- [args]` (paths in args are relative to repo root). The repo uses a root Dart workspace and Melos for scripts; see [.cursor/rules/colonizethis-tools.mdc](../../.cursor/rules/colonizethis-tools.mdc). Tools may depend on colonizethis_data or a shared reader to load topology.
- **No `server/`** in current scope.

---

## Package list and responsibilities

Five shared Dart packages under `packages/`. TDD 15 allows merging _models and _save into _logic; we use **five separate packages**.

| Package | Contents (TDD 15) | Internal package deps |
|---------|-------------------|------------------------|
| **colonizethis_models** | Data models, schemas, serialization (Game, Player, Orders, WorldState, Province, Unit, etc.). Stockpile, WorkerPool. | None |
| **colonizethis_data** | Constants, tech tree, **static map data**: (1) **region topology** (nodes: provinces, sea zones; links P<->P, P<->S; cross-region); (2) **tile maps** (per region). Ruleset/config (e.g. `rules/` for JSON later). Topology and tile map **formats** and loaders; topology/tile-map **describe** helpers. | None |
| **colonizethis_map** | Topology and tile map **generation** (tile-based map generator), topology inference from tile map, tile map topology validation, and tile map **PNG visualization**. Implements TDD map generation algorithms; consumed by tools and loaders. | colonizethis_data |
| **colonizethis_save** | Save format, schema, migrations | colonizethis_models |
| **colonizethis_logic** | Turn resolution, combat, economy, diplomacy, victory checks, order validation (uses map topology for movement). Extraction, production, stockpile, worker models; tile map or terrain data for costs/combat. | colonizethis_models, colonizethis_data |
| **colonizethis_ai** | AI behavior, planning, personalities | colonizethis_logic (narrow AI-facing contracts only: `order_suggestion_api.dart`, `ai_api.dart`) |
| **colonizethis_debug_console** | Debug-console command parsing/execution contracts and history state for in-game debug tooling. | colonizethis_logic (narrow debug-console contract only: `debug_console_api.dart`), colonizethis_models |

**Config consumers:** colonizethis_logic and colonizethis_ai consume resolved config; app receives config at game load. See [ruleset-config.md](ruleset-config.md). Flutter does not perform merge or file parsing.

**Rule:** No UI in shared packages. Game logic lives only in shared packages; app is shell, routing, and integration.

### `colonizethis_logic` internal mutation helpers

Turn pipelines and order application mutate nested `Game` → `WorldState` → `TurnState` fields frequently. Call sites use **`Game.updateWorldState`**, **`WorldState.updateTurnState`**, and **`TurnPipelineState.updateWorldState`** (`game_world_mutations.dart`, `turn_pipeline_state.dart`) instead of three-level `copyWith` chains. Refs #2560.

**Riverpod in packages:** Canonical `Provider`s for logic/map/AI seams live in optional `di.dart` libraries; see [dependency-injection.md](dependency-injection.md).

---

## Dependency direction

```
app
 └── colonizethis_logic, colonizethis_models, colonizethis_ai, colonizethis_data, colonizethis_save, colonizethis_debug_console

colonizethis_ai
 └── colonizethis_logic

colonizethis_debug_console
 └── colonizethis_logic

colonizethis_logic
 └── colonizethis_models, colonizethis_data

colonizethis_save
 └── colonizethis_models

colonizethis_models  (no package deps)
colonizethis_data    (no package deps)
```

`colonizethis_logic` must not depend on `colonizethis_ai` in either `dependencies` or
`dev_dependencies`; tests that exercise AI behavior belong in `colonizethis_ai/test`.

### Dependency boundary acceptance criteria

- **Given** package metadata for `colonizethis_logic`, **when** dependency analysis reads `dependencies` and `dev_dependencies`, **then** no `colonizethis_ai` entry exists.
- **Given** `colonizethis_ai` imports logic interfaces, **when** static analysis inspects imports under `packages/colonizethis_ai/lib`, **then** imports use narrow logic contract libraries (`order_suggestion_api.dart`, `ai_api.dart`) and do not import `package:colonizethis_logic/colonizethis_logic.dart`.
- **Given** the main logic public barrel `packages/colonizethis_logic/lib/colonizethis_logic.dart`, **when** static analysis inspects exported libraries, **then** no `src/ai/*` export is present and no `src/setup/hidden_agenda_assignment.dart` export is present; AI internals and hidden-agenda setup helpers stay outside the broad logic export surface.
- **Given** Dart source under `app/lib` except `app/lib/config/app_assets.dart` and `app/lib/config/app_constants.dart`, **when** static analysis inspects string literals, **then** direct asset path literals matching `assets/...` or `packages/<pkg>/assets/...` are rejected and diagnostics include file, line, and reason.
- **Given** an app runtime asset reference in `app/lib`, **when** the code compiles, **then** the reference uses root-relative path constants in `app/lib/config/app_constants.dart` (re-exported from `app/lib/config/app_assets.dart`) and/or path builders such as `terrainTileAssetPath` in `app/lib/config/app_assets.dart`.
- **Given** Dart source under `app/`, `packages/`, and `tool/`, **when** static analysis inspects executable AST string literals, **then** raw literals equal to canonical tech IDs are rejected outside canonical declaration sources, generated outputs skipped as whole paths by the identifier-literal scan contract, and approved fixture or test-data paths, with **no** keyed per-symbol waivers (see `SPEC/program/repo-lint.md` — policy distinguishes scope-only wiring from violation allowlists).
- **Given** the tech-ID convention gate reports a violation, **when** a developer inspects the output, **then** each violation includes file path, line, column, and the offending tech ID literal for direct remediation.
- **Given** Dart source under `app/`, `packages/`, and `tool/`, **when** static analysis inspects executable AST string literals, **then** raw literals equal to canonical work target IDs are rejected outside the canonical work-target declaration file, whole-file scope skips for generated or catalog surfaces documented in `tool/check_work_target_constants.dart`, and approved fixture paths, with **no** keyed per-symbol waivers.
- **Given** the work-target convention gate reports a violation, **when** a developer inspects the output, **then** each violation includes file path, line, column, and the offending work target literal with a suggested `kWorkTarget*` constant when available.
- **Given** Dart source under `app/`, `packages/`, and `tool/`, **when** static analysis inspects executable AST string literals, **then** raw literals equal to canonical civilian unit type ids (`Explorer`, `Builder`, `Engineer`, `Spy`, `Merchant`, `Rail Builder` per `SPEC/game/civilian-units.md`) are rejected outside `packages/colonizethis_models/lib/src/civilian_unit_type_ids.dart`, approved fixture/test-data paths, and the single whole-file scope skip for `packages/colonizethis_data/lib/src/ai_personality_config.dart` (personality display strings that may collide with civilian spellings), with **no** keyed per-symbol waivers.
- **Given** the civilian unit type convention gate reports a violation, **when** a developer inspects the output, **then** each violation includes file path, line, column, and the offending literal with a suggested `kUnitType*` constant when available.

### Automated guard gate (CI)

The repository enforces this boundary in CI via:

- `dart run tool/ct_repo_lint.dart` (Quality workflow), including rules `repo.logic_ai_decoupling`, `repo.app_lib_no_broad_suggest_work_orders`, `repo.asset_path_constants`, `repo.tech_id_constants`, `repo.work_target_constants`, and `repo.civilian_unit_type_constants` (see `tool/ct_repo_lint_manifest.yaml` and `SPEC/program/repo-lint.md`).
- `tool/check_logic_ai_decoupling.sh`, `tool/check_asset_path_constants.dart`, and the other `tool/check_*` entrypoints invoked by repo lint.
- `.github/workflows/quality.yml` steps that run unit tests for individual convention checkers (e.g. `test/check_asset_path_constants_test.dart`, `test/check_work_target_constants_test.dart`, …) so checker logic stays covered in CI.

Guard behavior:

- Fails if `packages/colonizethis_logic/pubspec.yaml` declares `colonizethis_ai` under `dependencies` or `dev_dependencies`.
- Fails if `packages/colonizethis_ai/lib/**` imports `package:colonizethis_logic/colonizethis_logic.dart`.
- Fails if `packages/colonizethis_ai/lib/**` imports logic from any path other than `ai_api.dart` or `order_suggestion_api.dart`.
- Fails if `packages/colonizethis_logic/test/**` imports `package:colonizethis_ai/...`.
- Fails if `packages/colonizethis_logic/lib/colonizethis_logic.dart` exports any `src/ai/*` library.
- Fails if `packages/colonizethis_logic/lib/colonizethis_logic.dart` exports `src/setup/hidden_agenda_assignment.dart`.
- Fails if `app/lib/**` contains direct `assets/...` or `packages/<pkg>/assets/...` string literals outside `app/lib/config/app_assets.dart` and `app/lib/config/app_constants.dart`.
- Fails if executable `StringLiteral` AST nodes equal to canonical tech IDs appear outside canonical declaration sources, generated outputs skipped as whole paths by the scan contract, and approved fixture/test-data paths.
- Fails if executable `StringLiteral` AST nodes equal to canonical work target IDs appear outside `packages/colonizethis_logic/lib/src/constants.dart`, approved fixture/test-data paths, and whole-file scope skips for generated or catalog surfaces encoded in `tool/check_work_target_constants.dart` (not keyed per-symbol waivers).
- In PR CI, the tech-ID guard may scan only changed Dart files for faster feedback; if PR diff context is unavailable, it falls back to a full repository scan with the same violation rules.
- In PR CI, the work-target guard may scan only changed Dart files for faster feedback; if PR diff context is unavailable, it falls back to a full repository scan with the same violation rules.
- Fails if executable `StringLiteral` AST nodes equal to canonical civilian unit type ids appear outside `packages/colonizethis_models/lib/src/civilian_unit_type_ids.dart`, approved fixture/test-data paths, and the whole-file scope skip set in `tool/check_civilian_unit_type_constants.dart` (see acceptance criteria above).
- In PR CI, the civilian unit type guard may scan only changed Dart files for faster feedback; if PR diff context is unavailable, it falls back to a full repository scan with the same violation rules.

Civilian unit type guard remediation:

- Add or reuse `kUnitType*` constants in `packages/colonizethis_models/lib/src/civilian_unit_type_ids.dart` (also re-exported from `packages/colonizethis_logic/lib/src/constants.dart` for logic consumers).
- Replace direct string literals in executable code with those constants; extend whole-file scope skips only with SPEC updates and issue tracking—prefer constants and refactors over new waivers.

Asset-path guard remediation:

- Add new root-relative asset path constants in `app/lib/config/app_constants.dart`; add or extend path builders in `app/lib/config/app_assets.dart` (which re-exports the constants library).
- Replace direct string literals in `app/lib/**` with those constants/helpers.
- Keep exclusions explicit and minimal; whole-file scope skips for asset path literals are `app/lib/config/app_assets.dart` and `app/lib/config/app_constants.dart`.

---

## Pub workspace toolchain

Dart/Flutter pin, `pub.dev` advisories expectations, and intentional “not at Latest” dependency caps (until upstream unblocks) are documented in **[pub-workspace-toolchain.md](pub-workspace-toolchain.md)** and **[CONTRIBUTING.md](../../CONTRIBUTING.md)**. See **GitHub #2073** for the rolling upgrade issue.

---

## Flutter app `lib/` structure (TDD 15)

Structure under `app/lib/`:

```
lib/
├── main.dart
├── app.dart
├── config/
│   ├── constants.dart
│   ├── routes.dart
│   └── themes.dart
├── core/
│   ├── models/
│   ├── services/
│   └── utils/
├── features/
│   ├── auth/
│   ├── game/
│   │   ├── flame/       # Flame components: map, battle, HUD (game canvas)
│   │   ├── map/
│   │   ├── orders/
│   │   ├── combat/
│   │   └── widgets/
│   ├── multiplayer/
│   ├── tutorial/
│   └── settings/
├── providers/
└── widgets/
```

Flame owns game canvas and in-game pixel-art UI; Flutter owns app shell, routes, and list/form screens. Communication only via state (Riverpod) and callbacks.

### App providers — recoverable failures (home fleet cargo)

- **Given** `currentGameProvider` holds a game and `homeFleetCargoSummaryProvider` runs the overseas extraction path, **when** `GameService.getMapData` or downstream computation throws, **then** the provider logs the failure at **warn** or higher with `error` and `stackTrace`, returns capacity from the live game state, sets used cargo to `0`, and sets `HomeFleetCargoSummary.isCargoUsedReliable` to **false** so the map HUD does not present `used` as authoritative (display uses `—` for the used value).
- **Given** map data is simply missing for the current game id (no throw), **when** the provider evaluates, **then** it returns used `0` with `isCargoUsedReliable` **true** (expected empty state, not a computation failure).

**Rationale:** GitHub #1531; SPEC/program/logging — avoid silent `catch` in providers; align with core logging principles.

### App `GameService` — `getMapData` and in-memory map cache

- **Given** a `GameService` instance has already populated its in-memory map cache for `gameId` (for example after `loadGame`, `createNewGame`, or an earlier `getMapData` that loaded map data from storage), **when** the app calls `getMapData(gameId)` again, **then** the service returns the cached topology and tile maps **without** invoking `GameSaveAdapter.load` for that call (no redundant read of the game JSON from Hive solely to re-check existence). **Rationale:** GitHub #1560; avoids save-adapter info spam on UI hot paths (map pan/zoom rebuilds).
- **Given** no in-memory map cache entry exists for `gameId`, **when** `getMapData(gameId)` runs, **then** the service follows the usual save/load checks: it returns `null` when the game key is missing or the game JSON does not load, and otherwise returns map data from storage or cache per [save-load.md](save-load.md).
