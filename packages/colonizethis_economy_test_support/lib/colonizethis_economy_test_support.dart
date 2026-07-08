/// Shared world-market test fixtures for `colonizethis_economy` and its
/// sibling test suites (`colonizethis_orders`, `colonizethis_logic`,
/// `colonizethis_diplomacy`).
///
/// Consolidates the previously package-local `world_market_trade_order_
/// validator_test_support.dart` and `world_market_deal_matcher_test_support.
/// dart` copies into one canonical location (Refs #3615 Cluster 6).
library colonizethis_economy_test_support;

export 'src/build_cost_scenarios.dart';
export 'src/boycott_blocked_commodities_scenarios.dart';
export 'src/boycott_blocked_commodities_expectations.dart';
export 'src/boycott_blocked_commodities_test_support.dart';
export 'src/consumption_phases_scenarios.dart';
export 'src/consumption_scenarios.dart';
export 'src/cost_check_scenarios.dart';
export 'src/core_economy_test_support.dart';
export 'src/economy_extraction_scenarios.dart';
export 'src/economy_riches_to_treasury_scenarios.dart';
export 'src/economy_production_scenarios.dart';
export 'src/deal_matcher_scenarios/deal_matcher_scenarios.dart';
export 'src/frr_scenarios/frr_scenarios.dart';
export 'src/game_lookup_helpers_scenarios.dart';
export 'src/lock_recovery_minor_bids_scenarios.dart';
export 'src/lock_recovery_minor_bids_expectations.dart';
export 'src/lock_recovery_minor_bids_test_support.dart';
export 'src/non_gp_auto_offers_scenarios.dart';
export 'src/non_gp_auto_offers_test_support.dart';
export 'src/non_gp_extraction_scenarios.dart';
export 'src/extraction_fixture_support.dart';
export 'src/resource_extractor_scenarios.dart';
export 'src/scenario_runner.dart';
export 'src/sea_transport_scenarios.dart';
export 'src/tile_extraction_pipeline_scenarios.dart';
export 'src/trade_cargo_capacity_scenarios.dart';
export 'src/treasury_scenarios/treasury_scenarios.dart';
export 'src/price_discovery_scenarios.dart';
export 'src/projected_cost_engine_scenarios.dart';
export 'src/purchased_tile_fixture_support.dart';
export 'src/purchased_tile_scenarios/purchased_tile_scenarios.dart';
export 'src/town_manufacturing_bonus_scenarios.dart';
export 'src/trade_interception_scenarios.dart';
export 'src/worker_action_cost_scenarios.dart';
export 'src/trade_order_admission_scenarios.dart';
export 'src/trade_order_factory.dart';
export 'src/trade_order_suggester_expectations.dart';
export 'src/trade_order_suggester_scenarios.dart';
export 'src/trade_order_suggester_test_support.dart';
export 'src/validator_scenarios/validator_scenarios.dart';
