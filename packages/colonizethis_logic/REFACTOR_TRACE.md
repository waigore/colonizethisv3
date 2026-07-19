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

## Slice B — World leaf purge/port (connectivity + naval)

| source_file | owner_package | action | evidence |
|-------------|---------------|--------|----------|
| `test/connectivity_resolver_test.dart` | `colonizethis_world` | port+delete | Ported all 5 GP road/town cases to `world/connectivity_resolver_gp_road_town_test.dart` (non-GP peers only partial) |
| `test/connectivity_resolver_sea_test.dart` | `colonizethis_world` | port+delete | Ported all 3 GP sea/port cases to `world/connectivity_resolver_gp_sea_test.dart` (blockade peers only negative overseas) |
| `test/connectivity_resolver_per_player_province_cache_test.dart` | `colonizethis_world` | port+delete | Ported both multi-player cache pins to `world/connectivity_resolver_per_player_province_cache_test.dart` |
| `test/connectivity_resolver_town_closure_worklist_test.dart` | `colonizethis_world` | port+delete | Ported multi-town + 40-port-map pins to `world/connectivity_resolver_town_closure_worklist_test.dart` |
| `test/naval_test_part1_test.dart` | `colonizethis_world` | port+delete | Ported local-id index/adjacency/fleet-pick cases to `world/naval_local_topology_part1_test.dart` (3 cases overlapped `naval_topology_test.dart`) |
| `test/naval_test_part2_test.dart` | `colonizethis_world` | port+delete | Ported lookup/combined-topology pins to `world/naval_local_topology_part2_test.dart` (5 cases overlapped `naval_topology_test.dart`) |

Slice B world connectivity/naval leaf orphans complete. Remaining issue slices: C (setup), D (orders/combat/diplomacy/turn), E (thin residual + CI).

## Slice C — Setup leaf purge/port (capital / warp / assignment / seed)

| source_file | owner_package | action | evidence |
|-------------|---------------|--------|----------|
| `test/effective_setup_seed_test.dart` | `colonizethis_setup` | delete | Covered by `setup/setup_exception_and_seed_coverage_test.dart` (`resolveEffectiveSetupSeed` positive/zero/negative) |
| `test/capital_choice_test.dart` | `colonizethis_setup` | port+delete | Ported to `setup/capital_choice_test.dart` (no prior peer suite) |
| `test/capital_choice_assignment_test.dart` | `colonizethis_setup` | port+delete | Ported to `setup/capital_choice_assignment_test.dart` |
| `test/capital_choice_classification_test.dart` | `colonizethis_setup` | port+delete | Ported to `setup/capital_choice_classification_test.dart` |
| `test/capital_choice_reassignment_test.dart` | `colonizethis_setup` | port+delete | Ported to `setup/capital_choice_reassignment_test.dart` |
| `test/warp_zone_generator_test.dart` | `colonizethis_setup` | port+delete | Ported to `setup/warp_zone_generator_test.dart` |
| `test/province_assignment_test.dart` | `colonizethis_setup` | port+delete | Ported to `setup/province_assignment_test.dart` |

| `test/minor_tribe_starting_development_test.dart` | `colonizethis_setup` | port+delete | Ported to `setup/minor_tribe_starting_development_test.dart` |
| `test/minor_tribe_starting_development_select_test.dart` | `colonizethis_setup` | port+delete | Ported to `setup/minor_tribe_starting_development_select_test.dart` |
| `test/minor_tribe_starting_development_integration_test.dart` | `colonizethis_setup` | port+delete | Ported to `setup/minor_tribe_starting_development_integration_test.dart` |
| `test/gp_old_world_resource_redistribution_test.dart` | `colonizethis_setup` | port+delete | Ported to `setup/gp_old_world_resource_redistribution_test.dart` |
| `test/gp_old_world_terrain_redistribution_test.dart` | `colonizethis_setup` | port+delete | Ported to `setup/gp_old_world_terrain_redistribution_test.dart` |
| `test/gp_starting_grain_integration_test.dart` | `colonizethis_setup` | port+delete | Ported to `setup/gp_starting_grain_integration_test.dart` |
| `test/game_setup_creation_and_assignment_part1_segment1_test.dart` | `colonizethis_setup` | port+delete | Ported to `setup/game_setup_creation_and_assignment_part1_segment1_test.dart` |
| `test/game_setup_creation_and_assignment_part1_segment2_test.dart` | `colonizethis_setup` | port+delete | Ported to `setup/game_setup_creation_and_assignment_part1_segment2_test.dart` |
| `test/game_setup_creation_and_assignment_part2_test.dart` | `colonizethis_setup` | port+delete | Ported to `setup/game_setup_creation_and_assignment_part2_test.dart` |
| `test/game_setup_creation_and_assignment_part2_assignment_test.dart` | `colonizethis_setup` | port+delete | Ported to `setup/game_setup_creation_and_assignment_part2_assignment_test.dart` |
| `test/game_setup_landmass_gp_count_gt_landmass_test.dart` | `colonizethis_setup` | port+delete | Ported to `setup/game_setup_landmass_gp_count_gt_landmass_test.dart` |
| `test/game_setup_landmass_visibility_and_gp_test.dart` | `colonizethis_setup` | port+delete | Ported to `setup/game_setup_landmass_visibility_and_gp_test.dart` |
| `test/game_setup_variants_and_naming_test.dart` | `colonizethis_setup` | port+delete | Ported to `setup/game_setup_variants_and_naming_test.dart` |
| `test/game_setup_variants_and_naming_additional_test.dart` | `colonizethis_setup` | port+delete | Ported to `setup/game_setup_variants_and_naming_additional_test.dart` |

Slice C setup leaf orphans complete (`game_setup_*` / `capital_choice_*` / `gp_*` / `minor_tribe_*` / `warp_zone` / `province_assignment` / `effective_setup_seed`). Remaining issue slices: D (orders/combat/diplomacy/turn + combat-adjacent capital reassignment), E (thin residual + CI). Characterization `game_setup_snapshot_test.dart` deferred to Slice D/E eligibility gate.

## Slice D — Orders / combat / diplomacy / turn residual

| source_file | owner_package | action | evidence |
|-------------|---------------|--------|----------|
| `test/army_integration_combine_split_test.dart` | `colonizethis_world` | delete | Covered by `world/army_commands_test.dart` combine/split groups |
| `test/army_integration_ensure_reconcile_test.dart` | `colonizethis_world` | delete | Covered by `world/army_migration_test.dart` ensure/reconcile groups |
| `test/army_integration_test.dart` | `colonizethis_orders` + `colonizethis_world` | port+delete | `last order per armyId wins` → `orders/army_move_order_draft_mutations_test.dart`; adjacent/home-army moves covered by `world/army_movement_test.dart`; sequential cross-region ported into that peer |
| `test/army_move_picker_destinations_test.dart` | `colonizethis_orders` | port+delete | Ported to `orders/army_move_picker_destinations_test.dart` (declare-war / sort destinations absent from scenario runner) |
| `test/draft_orders_naval_test.dart` | `colonizethis_orders` | port+delete | Ported to `orders/draft_orders_naval_test.dart` |
| `test/civilian_work_draft_commit_validation_test.dart` | `colonizethis_orders` | port+delete | Ported to `orders/civilian_work_draft_commit_validation_test.dart` |
| `test/civilian_work_orders_issue_2070_test.dart` | `colonizethis_orders` | port+delete | Ported to `orders/civilian_work_orders_issue_2070_test.dart` |
| `test/combat_logging_test.dart` | `colonizethis_combat` | port+delete | Ported to `combat/combat_logging_resolve_battle_context_test.dart` (turn peer covers phase-level logs only) |
| `test/capital_reassignment_after_combat_test.dart` | `colonizethis_world` | port+delete | Ported to `world/capital_reassignment_after_combat_unique_ports_test.dart` (seaboard preference + no port/tileState side effects; peers cover clear/fatal) |
| `test/faction_capital_reassignment_after_combat_test.dart` | `colonizethis_world` | delete | Covered by `world/capital_and_gp_fall_reassignment_test.dart` minor/tribe groups |
| `test/faction_terminal_fall_test.dart` | `colonizethis_world` | delete | Covered by `world/capital_and_gp_fall_terminal_test.dart` |
| `test/hostile_factions_by_faction_test.dart` | `colonizethis_world` | port+delete | Ported to `world/hostile_factions_by_faction_test.dart` (empty/three-party/atPeace pins beyond peer adjacency smoke) |
| `test/upsert_relation_test.dart` | `colonizethis_diplomacy` | port+delete | Ported to `diplomacy/upsert_relation_test.dart` |
| `test/turn_resolution_result_test.dart` | `colonizethis_diplomacy` + `colonizethis_turn` | delete | Equality/`DiplomacyPhaseResult.isPending` covered by `diplomacy_phase_result_value_types_test.dart`; `gameFromTurnResolutionResult` covered by `turn/turn_resolution_result_test.dart` |
| `test/turn_resolution_result_flow_test.dart` | `colonizethis_turn` | port+delete | Ported to `turn/turn_resolution_result_flow_test.dart` (`requireTurnResolutionComplete` error hints + sealed `.game`) |
| `test/game_events_test.dart` | `colonizethis_world` | delete | Subtype construction covered by `world/event_bus/game_event_bus_test.dart` |

### Slice D basename collisions resolved (AC3 subset)

| Basename | Status |
|----------|--------|
| `turn_resolution_result_test.dart` | removed from logic |

Slice D orders/combat/diplomacy/turn leaf orphans complete. Remaining: Slice E (thin residual + CI ratchet + characterization gate + AC10 map dep). Characterization snapshots deferred to Slice E eligibility gate.
