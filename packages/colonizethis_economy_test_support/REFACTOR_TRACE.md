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
