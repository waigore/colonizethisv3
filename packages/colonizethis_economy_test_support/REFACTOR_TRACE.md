# Economy test-support refactor trace (Refs #4108)

Maps Slice C scenario-table modules to consumer test runners and preserved test descriptions.

Baseline: `dev` before Slice C — `colonizethis_economy_test_support/lib` physical LOC ~7,490 (phase-7 ratchet ceiling).

## Slice C — relocate imperative runners to consumer tests

Pattern: merge typedefs/enums/factory functions from `*_expectations.dart` into paired `*_scenarios.dart` (tables only); move all `void run*` functions and private helpers into destination economy test files under `// --- Slice C runners (Refs #4108) ---`; delete expectations modules; drop barrel exports.

| scenario module | runners relocated to | expectations deleted | refs |
|-----------------|----------------------|----------------------|------|
| `worker_economy_scenarios.dart` | `worker_economy_test.dart` | `worker_economy_expectations.dart` | #4108 |
| `commodity_totals_scenarios.dart` | `economy/commodity_totals_test.dart` | `commodity_totals_expectations.dart` | #4108 |
| `build_cost_scenarios.dart` | `build_cost_test.dart` | `build_cost_expectations.dart` | #4108 |
| `economy_extraction_scenarios.dart` | `economy_extraction_test.dart` | `economy_extraction_expectations.dart` | #4108 |
| `consumption_scenarios.dart` | `economy_consumption_test.dart` | `consumption_expectations.dart` | #4108 |
| `consumption_phases_scenarios.dart` | `economy_consumption_phases_test.dart` | `consumption_phases_expectations.dart` | #4108 |
| `economy_production_scenarios.dart` | `economy_production_test.dart` | `economy_production_expectations.dart` | #4108 |
| `projected_cost_engine_scenarios.dart` | `economy/projected_cost_engine_test.dart` | `projected_cost_engine_expectations.dart` | #4108 |
| `sea_transport_scenarios.dart` | `sea_transport_test.dart` | `sea_transport_expectations.dart` | #4108 |
| `tile_extraction_contribution_scenarios.dart` | `tile_extraction_pipeline_test.dart` | `tile_extraction_contribution_expectations.dart` | #4108 |
| `tile_extraction_pipeline_scenarios.dart` | `tile_extraction_pipeline_test.dart` | `tile_extraction_pipeline_expectations.dart` | #4108 |
| `trade_cargo_capacity_scenarios.dart` | `economy/trade_cargo_capacity_test.dart` | `trade_cargo_capacity_expectations.dart` | #4108 |
| `trade_interception_scenarios.dart` (apply) | `trade_interception_test.dart` | `trade_interception_expectations.dart` | #4108 |
| `trade_interception_scenarios.dart` (scan) | `trade_interception_scan_test.dart` | (same file) | #4108 |
| `worker_action_cost_scenarios.dart` | `worker_action_cost_test.dart` | `worker_action_cost_expectations.dart` | #4108 |

### Preserved descriptions — consumption

| test description | scenario module | consumer test | refs |
|------------------|-----------------|---------------|------|
| peasants consume 1 food each (grain or meat) | `consumption_scenarios.dart` | `economy_consumption_test.dart` | #3939 |
| trained tiers consume 2 food each | `consumption_scenarios.dart` | `economy_consumption_test.dart` | #3939 |
| food strike: masters fed before peasants when food is tight | `consumption_scenarios.dart` | `economy_consumption_test.dart` | #3939 |
| food strike: journeymen fed before apprentices and peasants | `consumption_scenarios.dart` | `economy_consumption_test.dart` | #3939 |
| food strike: pool unchanged when no food | `consumption_scenarios.dart` | `economy_consumption_test.dart` | #3939 |
| grain used before meat when both available | `consumption_scenarios.dart` | `economy_consumption_test.dart` | #3939 |
| zero workers and zero military leaves stockpile unchanged | `consumption_scenarios.dart` | `economy_consumption_test.dart` | #3939 |
| unknown ship type id throws ConsumptionUnknownShipTypeException | `consumption_scenarios.dart` | `economy_consumption_test.dart` | #3939 |
| resolveConsumption wires military→navy→workers strike order and counts | `consumption_scenarios.dart` | `economy_consumption_test.dart` | #3939 |
| luxury only for food-fed trained; no sugar deducted if apprentice on strike | `consumption_scenarios.dart` | `economy_consumption_test.dart` | #3939 |
| trained workers consume tier luxuries when food-fed | `consumption_scenarios.dart` | `economy_consumption_test.dart` | #3939 |
| luxury strike: food-fed but short luxury → idle capped, partial deduction | `consumption_scenarios.dart` | `economy_consumption_test.dart` | #3939 |

### Preserved descriptions — consumption phases

| test description | scenario module | consumer test | refs |
|------------------|-----------------|---------------|------|
| per-type foodUpkeep fully feeds regiments from catalog | `consumption_phases_scenarios.dart` | `economy_consumption_phases_test.dart` | #3939 |
| militaryUnits fallback consumes 2 food per regiment | `consumption_phases_scenarios.dart` | `economy_consumption_phases_test.dart` | #3939 |
| insufficient food partially feeds regiments | `consumption_phases_scenarios.dart` | `economy_consumption_phases_test.dart` | #3939 |
| no regiments and no military leaves stockpile unchanged | `consumption_phases_scenarios.dart` | `economy_consumption_phases_test.dart` | #3939 |
| unknown regiment id contributes count but no food demand | `consumption_phases_scenarios.dart` | `economy_consumption_phases_test.dart` | #3939 |
| feeds ships from catalog foodUpkeep | `consumption_phases_scenarios.dart` | `economy_consumption_phases_test.dart` | #3939 |
| insufficient food partially feeds ships | `consumption_phases_scenarios.dart` | `economy_consumption_phases_test.dart` | #3939 |
| unknown ship id throws before any food is deducted | `consumption_phases_scenarios.dart` | `economy_consumption_phases_test.dart` | #3939 |
| empty fleet leaves stockpile unchanged | `consumption_phases_scenarios.dart` | `economy_consumption_phases_test.dart` | #3939 |
| feeds trained tiers (2 food) and peasants (1 food) | `consumption_phases_scenarios.dart` | `economy_consumption_phases_test.dart` | #3939 |
| priority Masters→...→Peasants: masters fed before peasants | `consumption_phases_scenarios.dart` | `economy_consumption_phases_test.dart` | #3939 |
| grain consumed before meat | `consumption_phases_scenarios.dart` | `economy_consumption_phases_test.dart` | #3939 |
| no food leaves all tiers on strike | `consumption_phases_scenarios.dart` | `economy_consumption_phases_test.dart` | #3939 |
| assigns one luxury per food-fed worker when supply suffices | `consumption_phases_scenarios.dart` | `economy_consumption_phases_test.dart` | #3939 |
| luxury strike: short supply caps count and deducts what exists | `consumption_phases_scenarios.dart` | `economy_consumption_phases_test.dart` | #3939 |
| no food-fed workers deducts nothing | `consumption_phases_scenarios.dart` | `economy_consumption_phases_test.dart` | #3939 |
| no luxury available deducts nothing | `consumption_phases_scenarios.dart` | `economy_consumption_phases_test.dart` | #3939 |
| grain then meat, returns consumed amount | `consumption_phases_scenarios.dart` | `economy_consumption_phases_test.dart` | #3939 |
| caps consumed at available when demand exceeds supply | `consumption_phases_scenarios.dart` | `economy_consumption_phases_test.dart` | #3939 |

### Preserved descriptions — production, projected cost, sea transport, tile pipeline, trade cargo, trade interception, worker action cost

See `colonizethis_economy/REFACTOR_TRACE.md` phase-3 slices 35–37 for the canonical description→scenario mappings now served from table-only modules with runners in:

- `economy_production_test.dart` (12 rows)
- `economy/projected_cost_engine_test.dart` (4 rows)
- `sea_transport_test.dart` (8 rows)
- `tile_extraction_pipeline_test.dart` (8 rows; contribution group moved from `resource_extractor_test.dart`)
- `economy/trade_cargo_capacity_test.dart` (7 rows)
- `trade_interception_test.dart` (9 apply rows)
- `trade_interception_scan_test.dart` (4 scan rows)
- `worker_action_cost_test.dart` (13 rows)

Barrel: `colonizethis_economy_test_support.dart` — removed Slice C expectations exports; scenario modules remain the public table API.

Deferred (out of Slice C scope): remaining expectations modules (`boycott_blocked_commodities`, `game_lookup_helpers`, `lock_recovery_minor_bids`, `province_extraction_snapshot`, `purchased_tile`, `resource_extractor`, `town_manufacturing_bonus`, `trade_order_suggester`, treasury/validator/deal-matcher families).

## Wave 2 Slice A — leaf leftovers + Development panel runner (Refs #4410)

Pattern: merge pin types/assert helpers from leftover `*_expectations.dart` into the paired `*_scenarios.dart` (or a same-folder `*_pins.dart` when the pair would exceed 220 lines); relocate `runDevelopmentPanelReadModelExpectation` into the consumer test; delete emptied expectation modules; re-export public pin types from the surviving sibling.

| module | destination | runners relocated to | expectations deleted |
|--------|-------------|----------------------|----------------------|
| `boycott_blocked_commodities_*` | `boycott_blocked_commodities_scenarios.dart` | (thin `run*` stayed in scenarios) | `boycott_blocked_commodities_expectations.dart` |
| `lock_recovery_minor_bids_*` | `lock_recovery_minor_bids_scenarios.dart` | (thin `run*` stayed in scenarios) | `lock_recovery_minor_bids_expectations.dart` |
| `world_market_context_base_*` | `world_market_context_base_scenarios.dart` | n/a (assert helper only) | `world_market_context_base_expectations.dart` |
| `price_discovery_*` | `price_discovery_scenarios.dart` | (thin `run*` stayed in scenarios) | `price_discovery_expectations.dart` |
| `game_lookup_helpers_*` | `game_lookup_helpers_scenarios.dart` | (thin `run*` stayed in scenarios) | `game_lookup_helpers_expectations.dart` |
| `frr_profit_*` | `first_right_profit_scenarios.dart` | (thin `run*` stayed in scenarios) | `frr_profit_expectations.dart` |
| `non_gp_extraction_*` | `non_gp_extraction_pins.dart` (pair 193+45 > 220) | (thin `runNonGpExtractionScenario` stayed in scenarios) | `non_gp_extraction_expectations.dart` |
| `development_panel_read_model_*` | table-only `development_panel_read_model_scenarios.dart` | `economy/development_panel_read_model_test.dart` | `development_panel_read_model_expectations.dart` |

Still deferred after Slice A (Slices B–D): `province_extraction_snapshot`, `purchased_tile`, `resource_extractor`, `town_manufacturing_bonus`, `trade_order_suggester`, `non_gp_auto_offers`, remaining treasury/validator/deal-matcher/FRR-credits families, LOC ratchet, `repo.economy_test_support_no_expectations_modules`.

## Wave 2 Slice B — extraction / town family (Refs #4410)

Pattern: relocate mid-size `run*` bodies into consumer tests; merge leftover pin types into a same-folder sibling that stays ≤220 (not always the paired scenarios file).

| module | destination | runners relocated to | expectations deleted |
|--------|-------------|----------------------|----------------------|
| `town_manufacturing_bonus_*` | `town_manufacturing_bonus_scenarios.dart` | `economy/town_manufacturing_bonus_test.dart` (`runTownManufacturingBonusGamePin`) | `town_manufacturing_bonus_expectations.dart` |
| `resource_extractor_*` | `resource_extractor_scenario_runner.dart` | `economy/resource_extractor_test.dart` (`runResourceExtractorScenario`) | `resource_extractor_expectations.dart` |
| `non_gp_auto_offers_*` | `non_gp_auto_offers_test_support.dart` | (thin `runNonGpAutoOffersScenario` stayed in scenarios) | `non_gp_auto_offers_expectations.dart` |
| `province_extraction_snapshot_*` | `province_extraction_snapshot_pins.dart` (pair 144+97 > 220) | `economy/province_extraction_snapshot_builder_test.dart` (thin `run*` wrappers) | `province_extraction_snapshot_expectations.dart` |

## Wave 2 Slice C — world-market families (Refs #4410)

Pattern: merge leftover pin types/assert helpers into a same-folder sibling that stays ≤220 (not the near-cap table files). Split `purchased_tile` index vs riches rather than dumping both into one destination.

| module | destination | runners relocated to | expectations deleted |
|--------|-------------|----------------------|----------------------|
| `deal_matcher_*` | `deal_matcher_scenario.dart` | (thin `runDealMatcherScenario` stayed) | `deal_matcher_expectations.dart` |
| `validator_*` | `validator_scenario.dart` | (thin `runTradeOrderValidatorScenario` stayed) | `validator_expectations.dart` |
| `treasury_*` | `treasury_test_support.dart` | n/a (assert helpers only) | `treasury_expectations.dart` |
| `treasury_player_context_*` | `treasury_player_context_scenarios.dart` | (thin `runPlayerContextScenario` stayed) | `treasury_player_context_expectations.dart` |
| `trade_order_suggester_*` | `trade_order_suggester_test_support.dart` | (thin `runTradeOrderSuggesterScenario` stayed) | `trade_order_suggester_expectations.dart` |
| `frr_credits_*` | `frr_credits_test_support.dart` | (thin `runFrrCreditsScenario` stayed) | `frr_credits_expectations.dart` |
| `purchased_tile_*` (index) | `purchased_tile_index_test_support.dart` | n/a (assert helpers only) | (split; file deleted below) |
| `purchased_tile_*` (riches) | `purchased_tile_riches_test_support.dart` | n/a (assert helpers only) | `purchased_tile_expectations.dart` |

## Wave 2 Slice D — CI ratchet (Refs #4410)

- `economyTestSupportLocCeiling` 7150 → 6590 (measured 6540; slack 50).
- Added `repo.economy_test_support_no_expectations_modules` (`tool/check_economy_test_support_no_expectations_modules.dart`).
- `SPEC/program/repo-lint.md` and `tool/ct_repo_lint_manifest.yaml` match the new ceiling and gate.
