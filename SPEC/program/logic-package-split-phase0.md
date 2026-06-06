# Logic package split — Phase 0 prerequisites

**SPEC/program** — Boundary enumeration and monolith prerequisites for epic #3290 (split `colonizethis_logic` into domain packages). Phase 0 runs **inside** the monolith before any package extraction.

## Scope

Phase 0 deliverables (child issue C0):

1. Written enumeration of wrong-direction symbols for each bidirectional edge pair.
2. Break wrong-direction imports where extraction is low-risk (shared modules under `lib/src/`).
3. Per-domain coverage baseline recorded in `tool/logic_domain_coverage_baseline.json`.
4. CI scaffolding: domain import DAG checker, 500-line source gate (grandfathered baseline), future per-package rule hooks.

## Target domain DAG (one-way)

| From | To | Status after Phase 0 slice |
|------|-----|---------------------------|
| `setup` | `world` | Allowed |
| `world` | `setup` | **Eliminated** — capital reassignment helpers live in `world/` |
| `diplomacy` | `world` | Allowed |
| `world` | `diplomacy` | **Eliminated** — `world/faction_membership.dart`, `world/diplomatic_relation_lookup.dart` |
| `diplomacy` | `combat` | Allowed |
| `combat` | `diplomacy` | Deferred — 3 files |
| `economy` | `orders` | Partial — `OrderValidationResult` moved to `lib/src/validation/`; `projectOrderEffects` import remains |
| `orders` | `economy` | Allowed |
| `turn` | `orders` | Allowed |
| `orders` | `turn` | Deferred — 3 files; trace runtime hoisted to `lib/src/trace/` but projections still import `turn_resolver` |
| `turn` | `world` | Allowed |
| `world` | `turn` | **Eliminated** — `turn_resolution_seeds.dart` and `trace/` hoisted to `lib/src/` |
| `diplomacy` | `ai` | Allowed (becomes `diplomacy` → `ai_contracts` after Phase 4) |
| `ai` | `diplomacy` | Deferred — 2 files |

## Edge pair enumerations (wrong-direction symbols)

### `world ↔ turn`

**Wrong:** `world` → `turn` (3 files, fixed in Phase 0 slice)

| Source file | Import | Symbols used | Destination |
|-------------|--------|--------------|-------------|
| `world/movement.dart` | `turn/trace/turn_trace_runtime.dart` | `TurnTraceRuntime` callbacks | `lib/src/trace/turn_trace_runtime.dart` (shared trace buffer) |
| `world/army_movement.dart` | same | same | same |
| `world/naval_resolution.dart` | `turn/turn_seed_constants.dart` | `kTurnResolutionSeedMix`, LCG constants | `lib/src/turn_resolution_seeds.dart` |

**Correct:** `turn` → `world` (34 files) — unchanged; orchestrator consumes world helpers.

### `world ↔ setup`

**Wrong:** `world` → `setup` (2 imports in 1 file, fixed in Phase 0 slice)

| Source file | Import | Symbols | Destination |
|-------------|--------|---------|-------------|
| `world/capital_and_gp_fall.dart` | `setup/capital_choice.dart` | `pickCapitalProvinceIdForReassignment`, `setCapitalFor*`, `applyGreatPowerCapitalProvinceTownDevelopment` | `world/capital_reassignment.dart` |
| `world/capital_and_gp_fall.dart` | `setup/town_capital_occupancy.dart` | `stripResourcesAndExtractionImprovementsOnTileKeys` | `world/town_capital_tile_strip.dart` |

**Correct:** `setup` → `world` (29 files) — unchanged.

### `economy ↔ orders`

**Wrong:** `economy` → `orders` (2 imports in `trade_order_validator.dart`)

| Import | Symbols | Destination | Status |
|--------|---------|-------------|--------|
| `orders/order_validation_result.dart` | `OrderValidationResult`, `OrderValidationStatus` | `lib/src/validation/order_validation_result.dart` | Fixed |
| `orders/order_projections.dart` | `projectOrderEffects` | Extract dry-run API to `lib/src/order_projection_api.dart` (depends on `turn`) | Deferred |

### `orders ↔ turn`

**Wrong:** `orders` → `turn` (3 files)

| Source | Import | Symbols | Proposed destination |
|--------|--------|---------|---------------------|
| `orders/orders_application.dart` | `turn/trace/turn_trace_runtime.dart` | `TurnTraceRuntime` | `lib/src/trace/` (hoisted; import path updated) |
| `orders/orders_application_context.dart` | same | same | same |
| `orders/order_projections.dart` | `turn/turn_resolver.dart` | `resolveTurnForGame`, `requireTurnResolutionComplete` | Invert: callback injection or move projections to `turn/` |

### `world ↔ diplomacy`

**Wrong:** `world` → `diplomacy` (6 files, fixed in Phase 0 slice)

| Source | Import | Key symbols | Destination |
|--------|--------|-------------|-------------|
| `world/connectivity_resolver.dart` | `diplomacy_relation_lookup.dart` | `factionsAtWar` | `world/diplomatic_relation_lookup.dart` |
| `world/civilian_ownership_legality.dart` | `diplomacy_resolver.dart` | `DiplomacyFactionMembership` | `world/faction_membership.dart` |
| `world/civilian_tile_occupancy.dart` | `diplomacy_resolver.dart` | `isGreatPower`, `isMinorOrTribe` | `world/faction_membership.dart` |
| `world/naval_mission_orders.dart` | `diplomacy_relation_lookup.dart` | `factionsAtWar` | `world/diplomatic_relation_lookup.dart` |
| `world/naval_resolution.dart` | `diplomacy_relation_lookup.dart` | `hostileFactionsByFaction` | `world/diplomatic_relation_lookup.dart` |
| `world/province_ownership_transfer.dart` | `diplomacy_resolver.dart` | `DiplomacyFactionMembership` | `world/faction_membership.dart` |

**Correct:** `diplomacy` → `world` — `diplomacy_relation_lookup.dart` and `diplomacy_resolver.dart` re-export the shared world modules for existing consumers.

### `diplomacy ↔ combat`

**Wrong:** `combat` → `diplomacy` (3 files)

| Source | Import | Key symbols | Proposed destination |
|--------|--------|-------------|---------------------|
| `combat/military_attack_economy.dart` | `diplomacy_resolver.dart` | war/ownership checks | `world/` or invert via `combat` callbacks |
| `combat/naval_combat_resolver.dart` | `diplomacy_relation_lookup.dart` | relation at war | `world/diplomatic_relation_view.dart` |
| `combat/unopposed_province_capture.dart` | `diplomacy_relation_lookup.dart` | same | same |

### `diplomacy ↔ ai`

**Wrong:** `ai` → `diplomacy` (2 files); **allowed:** `diplomacy/intervention_resolver.dart` → `ai/ai_control.dart`

| Source | Import | Proposed fix |
|--------|--------|--------------|
| `ai/full_ai_civilian_work_selection.dart` | `diplomacy_resolver.dart` | Inject legality predicate from `ai_contracts` consumer |
| `ai/simple_ai_heuristics.dart` | `diplomacy_resolver.dart` | same |

## AI contracts file set (Phase 0 planning, D1)

Five root planner files under `lib/src/ai/` (not eight): `ai_planner.dart`, `ai_control.dart`, `sim_game_ai.dart`, `simple_ai_heuristics.dart`, `full_ai_civilian_work_selection.dart`. Satellite `full_ai_civilian_work_*` part files stay colocated until Phase 4 move to `colonizethis_ai_contracts`.

## CI scaffolding (Phase 0)

| Rule ID | Purpose |
|---------|---------|
| `repo.logic_domain_import_dag` | Forbidden cross-domain import pairs; grandfather allowlist until C0 completion |
| `repo.logic_source_file_size` | `lib/src/**/*.dart` ≤500 physical lines; grandfather baseline for remaining offenders |
| `tool/logic_domain_coverage_baseline.dart` | Regenerate per-domain coverage JSON (operator/CI diagnostic) |

Future per-package rules (`repo.world_dead_files`, `repo.world_no_logic_deps`, etc.) are added when packages are created in Phases 1–4.

## Acceptance criteria (Phase 0 / C0)

- **Given** the monolith on `dev`, **when** `repo.logic_domain_import_dag` runs, **then** zero imports match forbidden pairs outside the documented grandfather allowlist.
- **Given** the files listed in `tool/logic_source_file_size_baseline.json` (the remaining grandfathered offenders, trimmed as Phase 0 decomposes them below 500 lines), **when** `repo.logic_source_file_size` runs, **then** those paths are ignored and any other `lib/src` file above 500 physical lines fails.
- **Given** logic package tests with coverage, **when** `dart run tool/logic_domain_coverage_baseline.dart` runs, **then** it writes/updates `tool/logic_domain_coverage_baseline.json` with per-domain line percentages.
- **Given** wrong-direction `world→turn` and `world→setup` symbols above, **when** the graph is scanned, **then** no `world` file imports `turn/` or `setup/`.
