# colonizethis_logic test migration trace (Refs #4090)

Inventory equivalence decisions for orphan suite purge. Schema columns:
`source_file` | `owner_package` | `action` | `evidence`

## Slice A — Economy leaf purge/port

| source_file | owner_package | action | evidence |
|-------------|---------------|--------|----------|
| `test/economy_production_test.dart` | `colonizethis_economy` | delete | All 12 cases match `resolveProductionScenarios` / `effectiveLabourForWorkersScenarios` labels in `economy_production_scenarios.dart` |
| `test/economy_consumption_test.dart` | `colonizethis_economy` | delete | 11/14 exact labels in `consumption_scenarios.dart`; militaryUnits → `militaryUnits fallback consumes 2 food per regiment` (`consumption_phases_scenarios.dart`); navy order → `resolveConsumption wires military→navy→workers strike order and counts`; ships foodUpkeep → `feeds ships from catalog foodUpkeep` |
| `test/economy_extraction_test.dart` | `colonizethis_economy` | delete | All 9 cases match `economy_extraction_scenarios.dart` labels |
| `test/economy_riches_to_treasury_test.dart` | `colonizethis_economy` | delete | All 8 cases match `economy_riches_to_treasury_scenarios.dart` labels |
| `test/economy_logic_test.dart` | `colonizethis_economy` | delete | Smoke duplicates of production/extraction/consumption/riches suites; asserts covered by scenario labels cited above (e.g. `trained workers capped by luxury after food`, `consumes inputs and produces output per recipe`, `military upkeep consumes food before workers`, `non-riches in stockpile are unchanged`) |
| `test/economy_debt_rules_test.dart` | `colonizethis_turn` | port | Ported to `packages/colonizethis_turn/test/economy_debt_rules_test.dart` (`maxDebtForPlayer` lives in turn) |
| `test/economy_consumption_production_integration_test.dart` | `colonizethis_economy` | port | Ported 4 cases into `economy_consumption_production_integration_test.dart` (kept in economy/test to preserve economy_test_support LOC ceiling) |
| `test/build_cost_test.dart` | `colonizethis_economy` | delete | All 9 cases match `build_cost_scenarios.dart` labels |
| `test/worker_action_cost_test.dart` | `colonizethis_economy` | delete | All 13 cases match `worker_action_cost_scenarios.dart` labels |
| `test/sea_transport_test.dart` | `colonizethis_economy` | delete | All 12 cases match `sea_transport_scenarios.dart` / trade-interception labels |
| `test/resource_extractor_part1_segment1_test.dart` | `colonizethis_economy` | delete | All 4 cases match `resource_extractor_scenarios.dart` labels |
| `test/resource_extractor_part1_segment2_test.dart` | `colonizethis_economy` | delete | All 5 cases match `resource_extractor_scenarios.dart` labels |
| `test/resource_extractor_part2_part1_test.dart` | `colonizethis_economy` | delete | All 4 cases match `resource_extractor_scenarios.dart` labels |
| `test/resource_extractor_part2_part2_test.dart` | `colonizethis_economy` | delete | All 5 cases match `resource_extractor_scenarios.dart` labels |
| `test/world_market_trade_order_suggester_test.dart` | `colonizethis_economy` | delete | All 18 cases match `trade_order_suggester_scenarios.dart` labels |
| `test/world_market_trade_order_validator_test.dart` | `colonizethis_economy` | delete | All 12 cases match validator rule scenario labels |
| `test/world_market_trade_order_validator_caps_test.dart` | `colonizethis_economy` | delete | All 13 cases match `validator_cap_scenarios.dart` labels |
| `test/world_market_trade_order_validator_treasury_test.dart` | `colonizethis_economy` | port+delete | Rule-5 treasury scenarios already in `validator_treasury_scenarios.dart`; unique determinism + full-catalog coverage ported into `world_market_trade_order_validator_test.dart` |
| `test/world_market_sellable_quantity_test.dart` | `colonizethis_economy` | delete | All 18 cases match `treasury_sellable_quantity_scenarios.dart` labels |
| `test/world_market_carry_forward_bid_notional_test.dart` | `colonizethis_economy` | port+delete | Expanded `carryForwardBidNotionalScenarios()` with empty/sum/null-price/offer-skip rows; catalog fallback already present; parity rows also exercise `carryForwardBidNotionalByPlayer` |
| `test/world_market_price_discovery_test.dart` | `colonizethis_economy` | delete | All computeNextPrice/MarketActivity labels in `price_discovery_scenarios.dart`; constants `match SPEC values` in `world_market_context_test.dart` |

### Slice A basename collisions resolved (AC3 subset)

| Basename | Status |
|----------|--------|
| `economy_production_test.dart` | removed from logic |
| `build_cost_test.dart` | removed from logic |
| `economy_consumption_test.dart` | removed from logic |
| `economy_extraction_test.dart` | removed from logic |
| `economy_riches_to_treasury_test.dart` | removed from logic |
| `worker_action_cost_test.dart` | removed from logic |
| `sea_transport_test.dart` | removed from logic |
| `world_market_trade_order_suggester_test.dart` | removed from logic (domain peer under `test/economy/world_market/`) |
| `world_market_trade_order_validator_test.dart` | removed from logic (domain peer under `test/economy/world_market/`) |

World/turn collisions (`province_lookup`, `minor_military_parity`, `tile_control`, `turn_resolution_result`) deferred to Slices B/D.

## Slice B — World leaf purge/port (basename collisions)

| source_file | owner_package | action | evidence |
|-------------|---------------|--------|----------|
| `test/tile_control_test.dart` | `colonizethis_world` | delete | All 4 cases match `world/tile_control_test.dart` observables |
| `test/province_lookup_test.dart` | `colonizethis_world` | port+delete | Covered peers in `world/province_lookup_test.dart`; unique legacy/null/update/index contracts ported to `world/province_lookup_unique_ports_test.dart` |
| `test/minor_military_parity_test.dart` | `colonizethis_world` | port+delete | Covered peers in `world/minor_military_parity_test.dart`; unique multi-GP max, dual-region medal-preserving upgrade, unset-GP→1 ported into that file; JSON round-trip covered by models |

### Slice B basename collisions resolved (AC3 subset)

| Basename | Status |
|----------|--------|
| `tile_control_test.dart` | removed from logic |
| `province_lookup_test.dart` | removed from logic |
| `minor_military_parity_test.dart` | removed from logic |

Remaining Slice B orphans (connectivity/movement/player_view/naval leaf suites) deferred.

## Slice B — World / setup leaf purge/port (continued)

| source_file | owner_package | action | evidence |
|-------------|---------------|--------|----------|
| `test/naval_port_province_id_test.dart` | `colonizethis_world` | port+delete | Prefixed + legacy covered by `world/naval_topology_test.dart`; multi-pipe local-id remainder ported there |
| `test/player_view_spy_intel_test.dart` | `colonizethis_world` | delete | Spy-reveal timer case matches `world/player_view_build_test.dart` `foreign province with an active spy-reveal timer shows full intel` |
| `test/province_name_fallback_test.dart` | `colonizethis_setup` | port+delete | Peer `setup/setup_exception_and_seed_coverage_test.dart`; ported determinism + 50-unique non-empty asserts |
| `test/gp_land_connectivity_repair_test.dart` | `colonizethis_setup` | port+delete | Ported unit cases to `setup/gp_land_connectivity_repair_test.dart` (integration peers only used helper) |
| `test/sea_reachable_provinces_distance_test.dart` | `colonizethis_world` | port+delete | Distances 1/2/shortest/region-filter covered by `world/sea_reachable_provinces_test.dart`; ported NW distance-3 route |
| `test/sea_reachable_provinces_distance_part2_test.dart` | `colonizethis_world` | port+delete | Region filter covered; ported distance foreign non-expansion + determinism into same world peer |

Remaining Slice B orphans: connectivity_resolver_* (non-blockade) / naval_test_part1 / naval_test_part2 deferred.

## Slice B — World leaf purge/port (inventory batch)

| source_file | owner_package | action | evidence |
|-------------|---------------|--------|----------|
| `test/player_view_test.dart` | `colonizethis_world` | delete | Covered by `player_view_build_test.dart` + `player_view_helpers_test.dart` |
| `test/movement_test.dart` | `colonizethis_world` | port+delete | Civilian apply covered by `movement_helpers_test.dart`; ported dual-region ambiguous ids, prefixed neighbors, sea-destination reject |
| `test/connectivity_resolver_blockade_additional_test.dart` | `colonizethis_world` | port+delete | Ported auto fleet+diplomacy, same-region two-port, inland-capital toggle to `connectivity_resolver_blockade_additional_test.dart` |
| `test/naval_test_part2_part2_test.dart` | `colonizethis_world` | delete | Covered by `naval_topology_test.dart` |

Remaining Slice B orphans: connectivity_resolver_test / sea / per_player_cache / town_closure / naval_test_part1 / naval_test_part2 deferred.
