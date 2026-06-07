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
| `turn` | `orders` | Allowed |
| `orders` | `turn` | **Eliminated** — trace runtime hoisted to `lib/src/trace/`; `projectOrderEffects` dry-run hoisted to `lib/src/projections/` |
| `turn` | `world` | Allowed |
| `world` | `turn` | **Eliminated** — `turn_resolution_seeds.dart` and `trace/` hoisted to `lib/src/` |
| `diplomacy` | `ai` | **Eliminated** — `isAiControlled` relocated to `world/ai_control.dart` (a `diplomacy` → `ai_contracts` edge would close the `ai_contracts` → `orders` → `diplomacy` → `ai_contracts` cycle) |
| `ai` | `diplomacy` | **Eliminated** — `DiplomacyFactionMembership` / `isMinorOrTribe` consumed from `world/faction_membership.dart` |
| `turn` | `diplomacy` | Allowed — orchestrator `TurnResolutionResult` variants consume diplomacy phase value types |
| `diplomacy` | `turn` | **Eliminated** — overture/FTP/intervention/call-to-arms offer + decision types and `DiplomacyPhaseResult` moved to `diplomacy/diplomacy_phase_result.dart`; `turn/turn_resolution_result.dart` imports + re-exports them |

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

**Wrong:** `economy` → `orders` (eliminated)

| Import | Symbols | Destination | Status |
|--------|---------|-------------|--------|
| `orders/order_validation_result.dart` | `OrderValidationResult`, `OrderValidationStatus` | `lib/src/validation/order_validation_result.dart` | Fixed |
| `orders/order_projections.dart` | `projectOrderEffects` | Inverted — the order engine computes `projectOrderEffects(...).treasuryDelta` and passes it as `tradeOrderValidationContextFromGame`'s `projectedTreasuryDelta`; the economy builder adds back `stagedBidTotalSpendByPlayer`. | Fixed |

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

## Acceptance criteria (Phase 0 / C0)

- **Given** the monolith on `dev`, **when** `repo.logic_domain_import_dag` runs, **then** zero imports match forbidden pairs outside the documented grandfather allowlist.
- **Given** the files listed in `tool/logic_source_file_size_baseline.json` (the remaining grandfathered offenders, trimmed as Phase 0 decomposes them below 500 lines), **when** `repo.logic_source_file_size` runs, **then** those paths are ignored and any other `lib/src` file above 500 physical lines fails.
- **Given** logic package tests with coverage, **when** `dart run tool/logic_domain_coverage_baseline.dart` runs, **then** it writes/updates `tool/logic_domain_coverage_baseline.json` with per-domain line percentages.
- **Given** wrong-direction `world→turn` and `world→setup` symbols above, **when** the graph is scanned, **then** no `world` file imports `turn/` or `setup/`.
- **Given** `economy/world_market/trade_order_validator.dart`, **when** the graph is scanned, **then** the file imports no `orders/` symbol and `repo.logic_domain_import_dag` carries no `economy->orders` grandfather entry.
- **Given** the four diplomacy resolvers (`overture_resolver.dart`, `intervention_resolver.dart`, `diplomacy_resolver.dart`, `ftp_resolver.dart`), **when** `repo.logic_domain_import_dag` runs, **then** no `diplomacy` file imports `turn/`, `diplomacy->turn` is a forbidden edge, and `repo.logic_domain_import_dag` carries no `diplomacy->turn` grandfather entry.
- **Given** the `diplomacy/` source files, **when** `repo.logic_domain_import_dag` runs, **then** no `diplomacy` file imports `ai/`, `diplomacy->ai` is a forbidden edge, and `repo.logic_domain_import_dag` carries no `diplomacy->ai` grandfather entry.
- **Given** a `Game` with `Player.treasury == 175`, empty staged orders (no bids) and `projectedTreasuryDelta == -50`, **when** `tradeOrderValidationContextFromGame(game, playerId, stagedOrders: <empty>, projectedTreasuryDelta: -50)` builds the context, **then** `TradeOrderValidationContext.treasuryBudgetForBids == 125` (`max(0, 175 − max(0, 50))`).
