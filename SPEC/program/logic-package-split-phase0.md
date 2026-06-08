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
| `combat` | `diplomacy` | **Eliminated** — relation/war + faction-membership lookups retargeted to `world/diplomatic_relation_lookup.dart` and `world/faction_membership.dart` |
| `combat` | `world` | Allowed |
| `world` | `combat` | **Eliminated** — `naval_resolution` (combat orchestration) relocated from `world/` to `turn/` |
| `diplomacy` | `dossier` | Allowed (`dossier/` folds into `colonizethis_diplomacy` at extraction) |
| `world` | `dossier` | **Eliminated** — `naval_resolution` (dossier/dialogue side-effects) relocated from `world/` to `turn/` |
| `economy` | `orders` | **Eliminated** — `OrderValidationResult` moved to `lib/src/validation/`; `projectOrderEffects` import removed by inverting `tradeOrderValidationContextFromGame` (caller-computed `projectedTreasuryDelta`) |
| `orders` | `economy` | Allowed |
| `economy` | `diplomacy` | **Eliminated** — `worldMarketBidTypeCap` / `kWorldMarketBaselineBidTypeCap` moved to `economy/world_market/bid_type_cap.dart`; `DiplomacyFactionMembership` and `enemiesOf` retargeted to their `world/` source files |
| `turn` | `orders` | Allowed |
| `orders` | `turn` | **Eliminated** — trace runtime hoisted to `lib/src/trace/`; `projectOrderEffects` dry-run hoisted to `lib/src/projections/` |
| `turn` | `world` | Allowed |
| `world` | `turn` | **Eliminated** — `trace/` hoisted to `lib/src/`; `turn_resolution_seeds.dart` since relocated into `turn/` (turn-owned, see C3 prerequisite below) |
| `diplomacy` | `ai` | **Eliminated** — `isAiControlled` relocated to `world/ai_control.dart` (a `diplomacy` → `ai_contracts` edge would close the `ai_contracts` → `orders` → `diplomacy` → `ai_contracts` cycle) |
| `ai` | `diplomacy` | **Eliminated** — `DiplomacyFactionMembership` / `isMinorOrTribe` consumed from `world/faction_membership.dart` |
| `turn` | `diplomacy` | Allowed — orchestrator `TurnResolutionResult` variants consume diplomacy phase value types |
| `diplomacy` | `turn` | **Eliminated** — overture/FTP/intervention/call-to-arms offer + decision types and `DiplomacyPhaseResult` moved to `diplomacy/diplomacy_phase_result.dart`; `turn/turn_resolution_result.dart` imports + re-exports them |
| `orders` | `diplomacy` | Allowed — order suggesters consume diplomacy relation/visibility helpers |
| `diplomacy` | `orders` | **Eliminated** — `knownDiplomaticTargetFactionIds` (diplomacy-domain visibility helper) moved from `orders/order_suggestion_helpers.dart` to `diplomacy/known_diplomatic_targets.dart` |

## Edge pair enumerations (wrong-direction symbols)

### `world ↔ turn`

**Wrong:** `world` → `turn` (3 files, fixed in Phase 0 slice)

| Source file | Import | Symbols used | Destination |
|-------------|--------|--------------|-------------|
| `world/movement.dart` | `turn/trace/turn_trace_runtime.dart` | `TurnTraceRuntime` callbacks | `lib/src/trace/turn_trace_runtime.dart` (shared trace buffer) |
| `world/army_movement.dart` | same | same | same |
| `world/naval_resolution.dart` | `turn/turn_seed_constants.dart` | `kTurnResolutionSeedMix`, LCG constants | `lib/src/turn_resolution_seeds.dart` (later relocated into `turn/` — see C3 prerequisite below, after `naval_resolution` moved to `turn/`) |

**Correct:** `turn` → `world` (34 files) — unchanged; orchestrator consumes world helpers.

### `world ↔ setup`

**Wrong:** `world` → `setup` (2 imports in 1 file, fixed in Phase 0 slice)

| Source file | Import | Symbols | Destination |
|-------------|--------|---------|-------------|
| `world/capital_and_gp_fall.dart` | `setup/capital_choice.dart` | `pickCapitalProvinceIdForReassignment`, `setCapitalFor*`, `applyGreatPowerCapitalProvinceTownDevelopment` | `world/capital_reassignment.dart` |
| `world/capital_and_gp_fall.dart` | `setup/town_capital_occupancy.dart` | `stripResourcesAndExtractionImprovementsOnTileKeys` | `world/town_capital_tile_strip.dart` |

**Correct:** `setup` → `world` (29 files) — unchanged.

### `economy ↔ orders`

**Wrong:** `economy` → `orders` (eliminated)

| Import | Symbols | Destination | Status |
|--------|---------|-------------|--------|
| `orders/order_validation_result.dart` | `OrderValidationResult`, `OrderValidationStatus` | `lib/src/validation/order_validation_result.dart` | Fixed |
| `orders/order_projections.dart` | `projectOrderEffects` | Inverted — the order engine computes `projectOrderEffects(...).treasuryDelta` and passes it as `tradeOrderValidationContextFromGame`'s `projectedTreasuryDelta`; the economy builder adds back `stagedBidTotalSpendByPlayer`. | Fixed |

### `economy → diplomacy`

**Wrong:** `economy` → `diplomacy` (eliminated)

| Source file | Import | Symbols | Destination | Status |
|-------------|--------|---------|-------------|--------|
| `economy/world_market/trade_order_validator.dart` | `diplomacy/diplomacy_subsidies_relations_resolver.dart` | `worldMarketBidTypeCap` | `economy/world_market/bid_type_cap.dart` (pure world-market helper relocated into the economy domain; `tradeSlotsForGp` stays in diplomacy) | Fixed |
| `economy/world_market/purchased_tile_index.dart` | `diplomacy/diplomacy_resolver.dart` | `DiplomacyFactionMembership` | `package:colonizethis_world/src/world/faction_membership.dart` (the class already lived in `colonizethis_world`; diplomacy only re-exported it) | Fixed |
| `economy/sea_transport.dart` | `diplomacy/diplomacy_relation_lookup.dart` | `enemiesOf` | `package:colonizethis_world/src/world/diplomatic_relation_lookup.dart` (already a `colonizethis_world` symbol) | Fixed |

`ai_api.dart` and the `colonizethis_logic` barrel now expose `worldMarketBidTypeCap` / `kWorldMarketBaselineBidTypeCap` from the economy file, preserving the public surface for AI/order/UI consumers. The edge is enforced by `repo.logic_domain_import_dag` (`economy->diplomacy` forbidden pair, no grandfather entry).

### `diplomacy → orders`

**Wrong:** `diplomacy` → `orders` (1 file, eliminated)

`orders` sits above `diplomacy` in the target DAG (the `colonizethis_orders` package depends on `colonizethis_diplomacy`), so a `diplomacy → orders` import would push `diplomacy` above the orders layer and block the `colonizethis_diplomacy` extraction. The sole crossing symbol was `knownDiplomaticTargetFactionIds`, a diplomacy-domain visibility helper (it derives targetable faction ids from relations, tile visibility, and sea-reachable New World provinces) that happened to live in the orders helpers file. It depends only on `world/`/`models`/`data`/`constants`, so it relocates cleanly into the diplomacy domain.

| Source file | Import | Symbols | Destination | Status |
|-------------|--------|---------|-------------|--------|
| `diplomacy/gp_tribe_first_contact.dart` | `orders/order_suggestion_helpers.dart` | `knownDiplomaticTargetFactionIds` | `diplomacy/known_diplomatic_targets.dart` | Fixed |

**Correct:** `orders` → `diplomacy` — `orders/order_suggestion_naval_diplomatic.dart` (the diplomatic order suggesters) imports `knownDiplomaticTargetFactionIds` one-way from `diplomacy/known_diplomatic_targets.dart`. `order_suggestion_api.dart` and `ai_api.dart` re-export the symbol from the diplomacy path, so the public surface for AI/order/UI consumers is unchanged.

### `orders ↔ turn`

**Wrong:** `orders` → `turn` (eliminated)

| Source | Import | Symbols | Destination | Status |
|--------|--------|---------|-------------|--------|
| `orders/orders_application.dart` | `lib/src/trace/turn_trace_runtime.dart` | `TurnTraceRuntime` | `lib/src/trace/` (hoisted; now imported directly) | Fixed |
| `orders/orders_application_context.dart` | same | same | same | Fixed |
| `orders/order_projections.dart` | `turn/turn_resolver.dart` | `resolveTurnForGame`, `requireTurnResolutionComplete` | `lib/src/projections/order_projections.dart` (neutral module; may import `turn/`) | Fixed |

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

### `world ↔ combat` and `world ↔ dossier`

**Wrong:** `world` → `combat` (1 import) and `world` → `dossier` (2 imports), all in the single file `world/naval_resolution.dart`, fixed in Phase 0 slice.

`naval_resolution` is not leaf-layer code: it orchestrates naval combat via `combat/naval_combat_resolver.dart` and emits dossier evidence + dialogue side-effects via `dossier/evidence_rules.dart` and `dossier/event_dialogue.dart`. Those targets sit **above** the `colonizethis_world` leaf (`combat` is its own package; `dossier` folds into `colonizethis_diplomacy`). The fix relocates the library (and its `part` fragments) up to the orchestrator layer rather than hoisting symbols down.

| Source | Import | Symbols used | Resolution |
|--------|--------|--------------|------------|
| `world/naval_resolution.dart` | `combat/naval_combat_resolver.dart` | `detectNavalConflicts`, `resolveSeaBattle`, `applyNavalBattleResults`, … | Move file to `turn/naval_resolution.dart` (+ `_helpers`/`_move`/`_battle` parts) |
| `world/naval_resolution.dart` | `dossier/evidence_rules.dart`, `dossier/event_dialogue.dart` | naval-victory dossier + dialogue builders | same relocation |

**Correct:** `turn` → `combat` / `dossier` / `world` — all already allowed; the two turn-phase consumers (`naval_interception_turn_phase.dart`, `movement_phase.dart`) now import `turn/naval_resolution.dart`. Leaf-layer `world/fog_resolution.dart` reaches the re-exported coastal-visibility helpers directly via `world/naval_coastal_visibility.dart`.

### `diplomacy ↔ combat`

**Wrong:** `combat` → `diplomacy` (3 files, fixed in Phase 0 slice)

| Source | Import | Key symbols | Destination |
|--------|--------|-------------|-------------|
| `combat/military_attack_economy.dart` | `diplomacy_resolver.dart` | `DiplomacyFactionMembership`, `isGreatPower` | `world/faction_membership.dart` |
| `combat/naval_combat_resolver.dart` | `diplomacy_relation_lookup.dart` | `hostileFactionsByFaction` | `world/diplomatic_relation_lookup.dart` |
| `combat/unopposed_province_capture.dart` | `diplomacy_relation_lookup.dart` | `factionsAtWar` | `world/diplomatic_relation_lookup.dart` |

**Correct:** `diplomacy` → `combat` — unchanged; `diplomacy_relation_lookup.dart` still imports `combat/military_strength.dart` for power-score aggregation.

### `diplomacy ↔ ai`

Both directions are eliminated. The `ai/` set becomes `colonizethis_ai_contracts` (Phase 4), which depends on `orders` → `diplomacy`; so `diplomacy` → `ai` would close the cycle `ai_contracts` → `orders` → `diplomacy` → `ai_contracts`.

**`ai` → `diplomacy`** (2 files): consumed only `DiplomacyFactionMembership` / `isMinorOrTribe`, retargeted to the leaf `world/faction_membership.dart` (no behavior change). **`diplomacy` → `ai`** (1 file): the sole crossing symbol is the pure player-control query `isAiControlled` (reads `Game.aiControlByGpId` / `Player.isHuman` only), relocated down to `world/ai_control.dart`; both domains consume it via `world/` one-way. `ai_api.dart` re-exports it from the new path, so `colonizethis_ai` is unchanged.

| Source | Import | Symbols used | Destination |
|--------|--------|--------------|-------------|
| `ai/full_ai_civilian_work_selection.dart` | `diplomacy_resolver.dart` | `DiplomacyFactionMembership`, `isMinorOrTribe` | `world/faction_membership.dart` |
| `ai/simple_ai_heuristics.dart` | `diplomacy_resolver.dart` | `DiplomacyFactionMembership` | `world/faction_membership.dart` |
| `diplomacy/intervention_resolver.dart` | `ai/ai_control.dart` | `isAiControlled` | `world/ai_control.dart` |

### `diplomacy ↔ turn`

**Wrong:** `diplomacy` → `turn` (4 files, fixed in Phase 0 slice)

The diplomacy phase resolvers and the turn orchestrator shared a single file, `turn/turn_resolution_result.dart`, which mixed the orchestrator-level `sealed TurnResolutionResult` (the turn-phase pipeline output) with the diplomacy-domain offer/decision value types those variants carry. The diplomacy resolvers consumed only the diplomacy-domain types, producing a wrong-direction `diplomacy → turn` edge. The fix moves the diplomacy-domain types down into the diplomacy domain; the orchestrator file imports them one-way (`turn → diplomacy`) and re-exports them so existing barrel/consumer imports are unchanged.

| Source | Import | Symbols used | Destination |
|--------|--------|--------------|-------------|
| `diplomacy/overture_resolver.dart` | `turn/turn_resolution_result.dart` | `OvertureOffer`, `OvertureDecision` | `diplomacy/diplomacy_phase_result.dart` |
| `diplomacy/intervention_resolver.dart` | same | `InterventionPrompt` | same |
| `diplomacy/diplomacy_resolver.dart` | same | `OvertureDecision`, `CallToArmsDecision`, `CallToArmsPending` | same |
| `diplomacy/ftp_resolver.dart` | same | `FtpOffer`, `FtpDecision` | same |

Types relocated to `diplomacy/diplomacy_phase_result.dart`: `OvertureOffer`, `OvertureDecision`, `InterventionPrompt`, `InterventionDecision`, `CallToArmsPending`, `FtpOffer`, `FtpDecision`, `CallToArmsDecision`, `DiplomacyPhaseResult`. The `sealed TurnResolutionResult` hierarchy and `gameFromTurnResolutionResult` stay in `turn/turn_resolution_result.dart`.

**Correct:** `turn` → `diplomacy` — `turn/turn_resolution_result.dart` imports `diplomacy/diplomacy_phase_result.dart` for the value types its variants carry, and re-exports it so `package:colonizethis_logic` consumers and turn-side importers see the diplomacy types unchanged.

## AI contracts file set (Phase 0 planning, D1)

Four root planner files under `lib/src/ai/`: `ai_planner.dart`, `sim_game_ai.dart`, `simple_ai_heuristics.dart`, `full_ai_civilian_work_selection.dart`. (`ai_control.dart` was retired in Phase 0: its sole helper `isAiControlled` moved to `world/ai_control.dart`.) Satellite `full_ai_civilian_work_*` part files stay colocated until Phase 4 move to `colonizethis_ai_contracts`.

## CI scaffolding (Phase 0)

| Rule ID | Purpose |
|---------|---------|
| `repo.logic_domain_import_dag` | Forbidden cross-domain import pairs; grandfather allowlist until C0 completion |
| `repo.logic_source_file_size` | `lib/src/**/*.dart` ≤500 physical lines; grandfather baseline for remaining offenders |
| `tool/logic_domain_coverage_baseline.dart` | Regenerate per-domain coverage JSON (operator/CI diagnostic) |

Future per-package rules (`repo.world_dead_files`, `repo.world_no_logic_deps`, etc.) are added when packages are created in Phases 1–4.

## Phase 1 slice — `colonizethis_world` (Refs #3290 C1)

**Given** Phase 0 prerequisites on `dev`, **when** the `colonizethis_world` package is extracted, **then**:

- `packages/colonizethis_world` owns `world/`, `utils/`, `event_bus/`, hoisted `trace/`, `game_events.dart`, `logic_validation_exception.dart`, and `game_player_lookup` / `world_constants` helpers.
- `colonizethis_logic` depends on `colonizethis_world` and re-exports `package:colonizethis_world/colonizethis_world.dart` from its barrel for backward compatibility.
- `colonizethis_world/lib/**` imports no `package:colonizethis_logic/**` symbol (`repo.world_no_logic_deps`).
- World-domain tests live under `packages/colonizethis_world/test/`; `colonizethis_logic` remains a **dev_dependency** of `colonizethis_world` for integration fixtures until later phases shrink that surface.

## Phase 1 slice — `colonizethis_economy` (Refs #3290 C1)

**Given** the `colonizethis_world` leaf on `dev`, **when** the `colonizethis_economy` package is extracted, **then**:

- `packages/colonizethis_economy` owns `economy/` (extraction, production, consumption, world-market) and depends only on `colonizethis_world`, `colonizethis_models`, `colonizethis_data`, `colonizethis_logger`.
- `worldMarketBidTypeCap` / `kWorldMarketBaselineBidTypeCap` live in `economy/world_market/bid_type_cap.dart` (not `diplomacy/`).
- `OrderValidationResult` and trade-validation types live in `colonizethis_economy`; `colonizethis_logic` re-exports them for backward compatibility.
- `colonizethis_logic` depends on `colonizethis_economy` and re-exports `package:colonizethis_economy/colonizethis_economy.dart` from its barrel.
- `colonizethis_economy/lib/**` imports no `package:colonizethis_logic/**` symbol (`repo.economy_no_logic_deps`).
- Economy-domain tests live under `packages/colonizethis_economy/test/` and reach ≥90% line coverage; `colonizethis_logic` remains a **dev_dependency** of `colonizethis_economy` for integration fixtures.

### `diplomacy` / `dossier` → `lib/src/constants.dart`

**Wrong:** `diplomacy` / `dossier` → `../constants.dart` (10 files, eliminated)

The monolith `constants.dart` re-exports `GamePlayerLookup` and region ids from `colonizethis_world`. Ten diplomacy/dossier files imported it only for those world symbols (extension methods on `Game` are used implicitly, so static analysis does not flag the import as unused). The fix retargets each file to its real `colonizethis_world` source:

| Source file | Symbols used | Destination |
|-------------|--------------|-------------|
| `diplomacy/diplomacy_resolver.dart`, `overture_resolver.dart`, `ftp_resolver.dart`, `alliance_resolver.dart`, `intervention_resolver.dart`, `diplomacy_relation_lookup.dart`, `diplomacy_subsidies_relations_resolver.dart`, `dossier/evidence_rules.dart` | `GamePlayerLookup` (`playerById`, …) | `package:colonizethis_world/src/game_player_lookup.dart` |
| `diplomacy/known_diplomatic_targets.dart`, `dossier/event_dialogue.dart` | `kRegionNewWorld` | `package:colonizethis_world/src/world_constants.dart` |
| `dossier/event_dialogue.dart` | `GamePlayerLookup` | `package:colonizethis_world/src/game_player_lookup.dart` |

`dossier/` folds into `colonizethis_diplomacy` at extraction; decoupling from `constants.dart` is a Phase 2 prerequisite so the new package depends only on `colonizethis_world`, `colonizethis_combat`, `colonizethis_models`, `colonizethis_data`, and `colonizethis_logger`. Enforced by `test/check_logic_domain_import_dag_test.dart` (no `../constants.dart` under `diplomacy/` or `dossier/`).

### `orders` order/work constant ownership (Refs #3290, Phase 2 prerequisite)

The order/work-domain constants (`kWorkTarget*`, `kMineralResourceIds`, `kProspectableByTerrainType`, `isProspectableTerrain`, `isProspectableTerrainId`) previously lived in the neutral `lib/src/constants.dart` core. They are order-domain values consumed by `orders/` (29 files), `ai/`, and `turn/`. They now live in the `orders` domain at `lib/src/orders/order_work_constants.dart` (the future `colonizethis_orders` package owns them), keeping the neutral core thin.

`lib/src/constants.dart` re-exports `orders/order_work_constants.dart`, so existing `package:colonizethis_logic/src/constants.dart` and `package:colonizethis_logic` barrel consumers keep their import paths and symbols unchanged (back-compat preserved). The `orders/orders.dart` barrel also exports `order_work_constants.dart` so the orders domain is self-contained for extraction. The world/models convenience re-exports (`GamePlayerLookup`, `kRegion*`, `kGridNeighborsCardinal4`, `kUnitType*`) stay in `constants.dart` as a neutral re-export shim.

| Symbols | Before | After | Status |
|---------|--------|-------|--------|
| `kWorkTarget*`, `kMineralResourceIds`, `kProspectableByTerrainType`, `isProspectableTerrain`, `isProspectableTerrainId` | declared in `lib/src/constants.dart` (neutral core) | declared in `orders/order_work_constants.dart` (orders domain); `constants.dart` re-exports | Fixed |

The `repo.work_target_constants` lint (`tool/check_work_target_constants.dart`) derives its canonical work-target ids from the definition file, so its source-of-truth path moves with the constants: it now reads `orders/order_work_constants.dart` (not the `constants.dart` re-export shim). The shim and the `orders/order_work_constants_test.dart` ownership test (which asserts each constant against its raw canonical literal) are exempt from the raw-literal gate alongside the definition file.

### `orders` → `lib/src/constants.dart`

**Wrong:** `orders` → `../constants.dart` (28 files, eliminated)

The neutral `lib/src/constants.dart` sits in the thin `colonizethis_logic` core, which sits **above** the domain packages (it re-exports them). Twenty-eight `orders/` files imported `../constants.dart` for two disjoint symbol groups: the order/work-domain constants (`kWorkTarget*`, `kMineralResourceIds`, prospectability helpers) and the world/models convenience re-exports (`GamePlayerLookup`, `kRegionNewWorld`/`kRegionOldWorld`, `kGridNeighborsCardinal4`, `kUnitType*`). Both groups created a wrong-direction `orders → core` edge — the order constants via a self-referential round-trip (the core only re-exports them from `orders/order_work_constants.dart`), the world/models symbols by masking the allowed `orders → world` / `orders → models` edges behind the core shim. This blocks the `colonizethis_orders` extraction (the package cannot depend on the thin core for its own constants).

The fix retargets each `orders/` file (and the part files that share a retargeted library's scope) to its real source:

| Symbols | Destination |
|---------|-------------|
| `kWorkTarget*`, `kMineralResourceIds`, `kProspectableByTerrainType`, `isProspectableTerrain`, `isProspectableTerrainId` | `orders/order_work_constants.dart` (same domain; relative import) |
| `GamePlayerLookup` (`playerById`, `fleetById`, …) | `package:colonizethis_world/src/game_player_lookup.dart` |
| `kRegionNewWorld`, `kRegionOldWorld`, `kGridNeighborsCardinal4` | `package:colonizethis_world/src/world_constants.dart` |
| `kUnitTypeBuilder`, `kUnitTypeEngineer`, `kUnitTypeMerchant`, … | `package:colonizethis_models/colonizethis_models.dart` |

`lib/src/constants.dart` keeps re-exporting `orders/order_work_constants.dart` and the world/models convenience symbols, so external consumers (`package:colonizethis_logic` barrel, `app/`, `ctdev/`, AI via `ai_api.dart`) keep their import paths and symbols unchanged — only the in-package `orders/` source tree is decoupled. Enforced by `test/check_logic_domain_import_dag_test.dart` (no `../constants.dart` / `../../constants.dart` / `../../../constants.dart` under `orders/`).

### `turn_resolution_seeds` ownership (Refs #3290 C3 prerequisite)

**Wrong (stale neutral hoist):** `turn_resolution_seeds.dart` parked in the neutral `lib/src/` core root with no remaining non-turn consumer.

`turn_resolution_seeds.dart` (`kTurnResolutionSeedMix`, `kTurnResolutionLcg*`) was hoisted from `turn/` to the neutral `lib/src/` core root during Phase 0 solely to break a `world → turn` edge while `world/naval_resolution.dart` consumed the seeds. The `world ↔ combat`/`dossier` slice subsequently relocated `naval_resolution` (and its `part` fragments) up into `turn/`, so every remaining importer of the seeds now lives in the `turn/` domain (`naval_resolution.dart`, `end_of_turn_resolver.dart`, `combat_phase_helpers.dart`, `phases/combat_phase.dart`, `phases/extraction_phase.dart`). The neutral hoist is therefore stale.

The seeds are turn-resolution constants and belong to the `turn` domain, which extracts into `colonizethis_turn` (C3). Keeping them in the neutral `lib/src/` core would force `colonizethis_turn` to depend on the thin `colonizethis_logic` core for its own seed constants. The fix relocates the file into the domain that owns it and drops the neutral-file exception so the import DAG models true ownership.

| Source | Before | After | Status |
|--------|--------|-------|--------|
| `turn_resolution_seeds.dart` (5 turn importers) | `lib/src/turn_resolution_seeds.dart` (neutral core file; allowlisted in `_neutralTopLevelFiles`) | `lib/src/turn/turn_resolution_seeds.dart` (turn domain; removed from `_neutralTopLevelFiles`) | Fixed |

The file is not part of the public barrel and has no external (`app/`, `ctdev/`, AI) consumers, so no re-export shim is needed and the public surface is unchanged. Enforced by `test/check_logic_domain_import_dag_test.dart`: `turn_resolution_seeds.dart` is no longer in the neutral set, the file lives under `turn/`, and a `world → turn/turn_resolution_seeds.dart` import is now a forbidden `world->turn` edge.

### `orders` → `projections` seam (Refs #3290 C2 prerequisite)

**Wrong (deferred):** `orders` → `lib/src/projections/` (1 file, eliminated via injection)

The dry-run projector `projectOrderEffects` (`lib/src/projections/order_projections.dart`) runs the full turn resolver (`turn/turn_resolver.dart`), so it was hoisted to the neutral `projections/` core module to break the direct `orders → turn` edge during Phase 0. The neutral-module mechanism keeps the monolith compiling, but the core `projections/` module sits **above** the domain layer: when `orders` extracts into `colonizethis_orders`, it cannot import a `colonizethis_logic`-core module for its own validation/projection. `order_engine.dart` (its `projectedEffects` method) and the trade-order validation phase in `order_engine_validation.dart` (the non-bid treasury projection) were the only two `orders/` consumers of that core module.

The fix introduces an injected seam instead of a direct import: `OrderEngine` accepts `OrderEffectsProjector? projector` (the same dependency-injection pattern as the existing `validatorFactory`). The `OrderEffectsProjector` typedef and the `ProjectedEffects` value type are owned by the `orders` domain (`orders/order_effects_projector.dart`, `orders/projected_effects.dart` — the latter relocated from `projections/`). The concrete `projectOrderEffects` stays in the neutral core (it must import `turn/`); the turn orchestrator and the app / ctdev / sim-scenario consumers inject it at construction. This removes every `orders/` import of `projections/` and `turn/`, so the orders source tree depends only on `colonizethis_world` / `colonizethis_diplomacy` / `colonizethis_economy` / `colonizethis_models` / `colonizethis_data` / `colonizethis_logger` plus its own domain files.

| Source file | Before | After | Status |
|-------------|--------|-------|--------|
| `orders/order_engine.dart` (`projectedEffects`) | `import '../projections/order_projections.dart'` (`projectOrderEffects`) + `import '../projections/projected_effects.dart'` | injected `OrderEffectsProjector` (`order_effects_projector.dart`); `ProjectedEffects` from `orders/projected_effects.dart` | Fixed |
| `orders/order_engine_validation.dart` (`_runTradeOrderPhase`) | direct `projectOrderEffects(...)` | injected projector threaded from `validatePlayerOrdersWithContext` | Fixed |

`lib/src/projections/order_projections.dart` now imports `ProjectedEffects` from `orders/projected_effects.dart` (a `core → orders` import, the allowed direction). The public surface is unchanged: `package:colonizethis_logic` re-exports `projectOrderEffects` from the core barrel and `ProjectedEffects` / `OrderEffectsProjector` from the orders barrel. Enforced by `test/check_logic_domain_import_dag_test.dart` (no `import '../projections/...'` under `orders/`). The ACs for the seam behavior live in [order-engine.md](order-engine.md) § Injected projector seam.

### `diplomacy` / `dossier` logging decoupling from `logicLog`

**Wrong:** `diplomacy` / `dossier` → `colonizethis_logic` core logging (3 files, eliminated)

Three files logged via the `colonizethis_logic` core `logicLog` (`CtLogger('logic')`), which would force the future `colonizethis_diplomacy` package to depend on the thin logic core just for logging. The fix introduces a single diplomacy-domain logger `diploLog` (`CtLogger('diplomacy')`) in `diplomacy/diplomacy_logging.dart`, mirroring the one-logger-per-package convention already used by `combatLog` (`combat:`) and `economyLog` (`economy:`). Diplomacy/dossier log lines now carry the `diplomacy:` prefix instead of `logic:`; this is the same prefix migration combat performed at extraction and is the only behavioural change (structural logging move, no logic change).

| Source file | Symbol | Before | After |
|-------------|--------|--------|-------|
| `diplomacy/diplomacy_resolver.dart` | `diploLog` | `final diploLog = logicLog;` (imports `src/logging.dart`) | imports + re-exports `diplomacy/diplomacy_logging.dart` (`diploLog`) |
| `diplomacy/ftp_resolver.dart` | `logicLog.i` | imports `../logging.dart` | `diploLog.i` from `diplomacy_logging.dart` (redundant inline `logic:` prefix dropped) |
| `dossier/evidence_rules.dart` | `logicLog.d` | imports `src/logging.dart` | `diploLog.d` from `../diplomacy/diplomacy_logging.dart` |

All other diplomacy files (`alliance_resolver.dart`, `overture_resolver.dart`, `war_resolver.dart`, `intervention_resolver_call_to_arms.dart`, `diplomacy_subsidies_relations_resolver.dart`) already consumed `diploLog` via `diplomacy_resolver.dart`; the re-export keeps them unchanged. Enforced by `test/check_logic_domain_import_dag_test.dart` (no `src/logging.dart`, `package_logger.dart`, `../logging.dart`, `../package_logger.dart`, or the `colonizethis_logic` barrel under `diplomacy/` or `dossier/`).

## Phase 2 slice — `colonizethis_orders` (Refs #3290 C2)

**Given** the `colonizethis_world`, `colonizethis_combat`, `colonizethis_economy`, and `colonizethis_diplomacy` packages on `dev`, **when** the `colonizethis_orders` package is extracted, **then**:

- `packages/colonizethis_orders` owns `orders/` (engine, suggestion APIs, validation, application) and `debug_console/` (supported-id lists for the debug console contract) and depends only on `colonizethis_world`, `colonizethis_diplomacy`, `colonizethis_economy`, `colonizethis_models`, `colonizethis_data`, `colonizethis_logger`.
- `colonizethis_logic` depends on `colonizethis_orders` and re-exports `package:colonizethis_orders/colonizethis_orders.dart` from its barrel for backward compatibility; `ai_api.dart`, `order_suggestion_api.dart`, and `debug_console_api.dart` re-export the narrow contract surfaces from the orders package paths unchanged for `colonizethis_ai` / `colonizethis_debug_console`.
- `colonizethis_orders/lib/**` imports no `package:colonizethis_logic/**` symbol (`repo.orders_no_logic_deps`).
- `colonizethis_orders` uses exactly one logger with the distinct `orders` prefix (`ordersLog`); order-domain log lines carry the `orders:` prefix.
- Orders-domain tests live under `packages/colonizethis_orders/test/` and reach ≥90% line coverage (enforced by the package coverage gate); turn-orchestrator integration tests that import both `turn/` and `orders/` remain in `colonizethis_logic`; `colonizethis_logic` remains a **dev_dependency** of `colonizethis_orders` for integration fixtures.

### `turn` logging decoupling from `logicLog` (Refs #3290 C3 prerequisite)

**Wrong:** `turn` → `colonizethis_logic` core logging (7 files, eliminated)

Seven `turn/` files logged via the `colonizethis_logic` core `logicLog` (`CtLogger('logic')`), which would force the future `colonizethis_turn` package to depend on the thin logic core just for logging. The fix introduces a single turn-domain logger `turnLog` (`CtLogger('turn')`) in `turn/turn_logging.dart`, mirroring the one-logger-per-package convention already used by `ordersLog` (`orders:`), `combatLog` (`combat:`), `economyLog` (`economy:`), and `diploLog` (`diplomacy:`). Turn-orchestrator log lines (including the turn-orchestrated combat-phase lines previously emitted from the core) now carry the `turn:` prefix instead of `logic:`; this is the same prefix migration combat/orders/diplomacy performed at extraction and is the only behavioural change (structural logging move, no logic change).

| Source file | Symbol | Before | After |
|-------------|--------|--------|-------|
| `turn/combat_phase_helpers.dart` | `turnLog.i` | imports `src/logging.dart` (`logicLog`) | `turnLog` from `turn_logging.dart` |
| `turn/end_of_turn_resolver.dart` | `turnLog.i` | imports `src/logging.dart` (`logicLog`) | `turnLog` from `turn_logging.dart` |
| `turn/naval_resolution.dart` | `turnLog.d` | imports `src/logging.dart` (`logicLog`) | `turnLog` from `turn_logging.dart` |
| `turn/phases/combat_phase.dart` | `turnLog.i` | imports `src/logging.dart` (`logicLog`) | `turnLog` from `../turn_logging.dart` |
| `turn/research_resolver.dart` | `turnLog.i` | imports `src/logging.dart` (`logicLog`) | `turnLog` from `turn_logging.dart` |
| `turn/turn_phase_runner.dart` | `turnLog.i` | imports `src/logging.dart` (`logicLog`) | `turnLog` from `turn_logging.dart` |
| `turn/turn_resolver.dart` | `turnLog.i` | imports `src/logging.dart` (`logicLog`) | `turnLog` from `turn_logging.dart` |

The `turn_logging.dart` logger is not part of the public barrel and has no external (`app/`, `ctdev/`, AI) consumers, so no re-export shim is needed and the public API surface is unchanged. Enforced by `test/check_logic_domain_import_dag_test.dart` (no `src/logging.dart`, `package_logger.dart`, `../logging.dart`, `../../logging.dart`, `../package_logger.dart`, `../../package_logger.dart`, the `colonizethis_logic` barrel, or any `logicLog` reference under `turn/`) and pinned by `packages/colonizethis_logic/test/turn/turn_logging_test.dart`.

## Phase 1 slice — `colonizethis_combat` (Refs #3290 C1)

**Given** the `colonizethis_world` leaf on `dev`, **when** the `colonizethis_combat` package is extracted, **then**:

- `packages/colonizethis_combat` owns `combat/` (land + naval resolution, conflict detection, quick-battle, general assignment, military strength/attack economy) and depends only on `colonizethis_world`, `colonizethis_models`, `colonizethis_data`, `colonizethis_logger`.
- `colonizethis_logic` depends on `colonizethis_combat` and re-exports `package:colonizethis_combat/colonizethis_combat.dart` from its barrel for backward compatibility; the `turn/` and `diplomacy/` consumers import combat via `package:colonizethis_combat/...`.
- `colonizethis_combat/lib/**` imports no `package:colonizethis_logic/**` symbol (`repo.combat_no_logic_deps`).
- `colonizethis_combat` uses exactly one logger with the distinct `combat` prefix (`combatLog`); land-combat log lines emitted from the package carry the `combat:` prefix, while turn-orchestrated combat-phase lines emitted from the `turn/` domain carry the `turn:` prefix (migrated from `logic:` by the C3 turn logging-decoupling prerequisite).
- Combat-domain tests live under `packages/colonizethis_combat/test/` and reach ≥90% line coverage (enforced by the package coverage gate); `colonizethis_logic` remains a **dev_dependency** of `colonizethis_combat` for integration fixtures.

## Acceptance criteria (Phase 0 / C0)

- **Given** the monolith on `dev`, **when** `repo.logic_domain_import_dag` runs, **then** zero imports match forbidden pairs outside the documented grandfather allowlist.
- **Given** the files listed in `tool/logic_source_file_size_baseline.json` (the remaining grandfathered offenders, trimmed as Phase 0 decomposes them below 500 lines), **when** `repo.logic_source_file_size` runs, **then** those paths are ignored and any other `lib/src` file above 500 physical lines fails.
- **Given** logic package tests with coverage, **when** `dart run tool/logic_domain_coverage_baseline.dart` runs, **then** it writes/updates `tool/logic_domain_coverage_baseline.json` with per-domain line percentages.
- **Given** wrong-direction `world→turn` and `world→setup` symbols above, **when** the graph is scanned, **then** no `world` file imports `turn/` or `setup/`.
- **Given** `economy/world_market/trade_order_validator.dart`, **when** the graph is scanned, **then** the file imports no `orders/` symbol and `repo.logic_domain_import_dag` carries no `economy->orders` grandfather entry.
- **Given** the four diplomacy resolvers (`overture_resolver.dart`, `intervention_resolver.dart`, `diplomacy_resolver.dart`, `ftp_resolver.dart`), **when** `repo.logic_domain_import_dag` runs, **then** no `diplomacy` file imports `turn/`, `diplomacy->turn` is a forbidden edge, and `repo.logic_domain_import_dag` carries no `diplomacy->turn` grandfather entry.
- **Given** the `diplomacy/` source files, **when** `repo.logic_domain_import_dag` runs, **then** no `diplomacy` file imports `ai/`, `diplomacy->ai` is a forbidden edge, and `repo.logic_domain_import_dag` carries no `diplomacy->ai` grandfather entry.
- **Given** the `diplomacy/` source files, **when** `repo.logic_domain_import_dag` runs, **then** no `diplomacy` file imports `orders/`, `diplomacy->orders` is a forbidden edge, and `repo.logic_domain_import_dag` carries no `diplomacy->orders` grandfather entry.
- **Given** a `Game` with `Player.treasury == 175`, empty staged orders (no bids) and `projectedTreasuryDelta == -50`, **when** `tradeOrderValidationContextFromGame(game, playerId, stagedOrders: <empty>, projectedTreasuryDelta: -50)` builds the context, **then** `TradeOrderValidationContext.treasuryBudgetForBids == 125` (`max(0, 175 − max(0, 50))`).
- **Given** the extracted `colonizethis_orders` package on `dev`, **when** the order/work constant definitions (`kWorkTargetExplore`, `kMineralResourceIds`, `isProspectableTerrainId`, …) are located, **then** they are declared in `packages/colonizethis_orders/lib/src/orders/order_work_constants.dart` and **not** declared in the neutral `packages/colonizethis_logic/lib/src/constants.dart`.
- **Given** a consumer importing `package:colonizethis_logic/colonizethis_logic.dart` or `package:colonizethis_logic/src/constants.dart`, **when** it references `kWorkTargetExplore` or `kMineralResourceIds`, **then** the symbols resolve unchanged because `lib/src/constants.dart` re-exports `package:colonizethis_orders/src/orders/order_work_constants.dart` (`identical(constants.kMineralResourceIds, order_work_constants.kMineralResourceIds) == true`).
- **Given** every `*.dart` file under `packages/colonizethis_orders/lib/src/orders/` (recursive), **when** `test/check_logic_domain_import_dag_test.dart` scans their import directives, **then** none imports the neutral logic core `constants.dart` via `import '../constants.dart';`, `import '../../constants.dart';`, or `import '../../../constants.dart';` (orders consumes order constants from `orders/order_work_constants.dart` and world/models symbols from `colonizethis_world` / `colonizethis_models` directly).
- **Given** the retargeted `orders/` source tree, **when** `dart analyze lib` runs on `colonizethis_logic`, **then** it reports no new errors or warnings versus the pre-change baseline (the order constants resolve via `orders/order_work_constants.dart`, `GamePlayerLookup` via `package:colonizethis_world/src/game_player_lookup.dart`, region/grid constants via `package:colonizethis_world/src/world_constants.dart`, and `kUnitType*` via `package:colonizethis_models/colonizethis_models.dart`).
- **Given** the `colonizethis_logic` source tree, **when** `logicDomainImportNeutralTopLevelFilesForTests()` is read, **then** the set does not contain `turn_resolution_seeds.dart`, the file exists at `packages/colonizethis_logic/lib/src/turn/turn_resolution_seeds.dart`, and no file remains at `packages/colonizethis_logic/lib/src/turn_resolution_seeds.dart` (the seeds are turn-owned, not a neutral core file).
- **Given** a synthetic `world/` file that imports `../turn/turn_resolution_seeds.dart`, **when** `runCheckLogicDomainImportDag` scans the tree, **then** it returns exit code `1` because the now turn-owned seeds make this a forbidden `world->turn` edge.
- **Given** every `*.dart` file under `packages/colonizethis_orders/lib/src/orders/` (recursive), **when** `test/check_logic_domain_import_dag_test.dart` scans their import directives, **then** none imports the neutral core projection module via `import '../projections/order_projections.dart';` or `import '../projections/projected_effects.dart';` (the order engine consumes the dry-run via an injected `OrderEffectsProjector` and the `ProjectedEffects` type from `orders/projected_effects.dart`).
- **Given** the `turn/` source tree, **when** `turn/turn_logging.dart` is read, **then** it declares a single shared `turnLog` whose `prefix == 'turn'` (`CtLogger('turn')`), and emitting `turnLog.i('m')` produces a log line containing `turn: m`.
- **Given** every `*.dart` file under `packages/colonizethis_logic/lib/src/turn/` (recursive) except `turn/turn_logging.dart`, **when** `test/check_logic_domain_import_dag_test.dart` scans their content, **then** none imports the core logging (`package:colonizethis_logic/src/logging.dart`, `package:colonizethis_logic/package_logger.dart`, `../logging.dart`, `../../logging.dart`, `../package_logger.dart`, `../../package_logger.dart`, or the `colonizethis_logic` barrel) and none references the symbol `logicLog` (turn logs via the turn-domain `turnLog`).
