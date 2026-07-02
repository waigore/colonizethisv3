/// Shared world-market test fixtures for `colonizethis_economy` and its
/// sibling test suites (`colonizethis_orders`, `colonizethis_logic`,
/// `colonizethis_diplomacy`).
///
/// Consolidates the previously package-local `world_market_trade_order_
/// validator_test_support.dart` and `world_market_deal_matcher_test_support.
/// dart` copies into one canonical location (Refs #3615 Cluster 6).
library colonizethis_economy_test_support;

export 'src/bid_spend_game_factory.dart';
export 'src/boycott_blocked_commodities_test_support.dart';
export 'src/core_economy_test_support.dart';
export 'src/deal_matcher_frr_scenarios.dart';
export 'src/deal_matcher_priority_scenarios.dart';
export 'src/deal_matcher_scenarios.dart';
export 'src/deal_matcher_sell_priority_scenarios.dart';
export 'src/deal_matcher_test_support.dart';
export 'src/deal_matcher_treasury_scenarios.dart';
export 'src/effective_market_price_scenarios.dart';
export 'src/frr_credits_test_support.dart';
export 'src/non_gp_extraction_test_support.dart';
export 'src/resource_extractor_test_support.dart';
export 'src/staged_bid_spend_scenarios.dart';
export 'src/tile_map_test_support.dart';
export 'src/treasury_available_scenarios.dart';
export 'src/purchased_tile_riches_test_support.dart';
export 'src/treasury_bid_budget_test_support.dart';
export 'src/treasury_bid_budget_scenarios.dart';
export 'src/trade_order_factory.dart';
export 'src/trade_order_suggester_test_support.dart';
export 'src/trade_order_validator_scenarios.dart';
export 'src/trade_order_validator_test_support.dart';
