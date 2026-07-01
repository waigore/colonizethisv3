/// Shared world-market test fixtures for `colonizethis_economy` and its
/// sibling test suites (`colonizethis_orders`, `colonizethis_logic`,
/// `colonizethis_diplomacy`).
///
/// Consolidates the previously package-local `world_market_trade_order_
/// validator_test_support.dart` and `world_market_deal_matcher_test_support.
/// dart` copies into one canonical location (Refs #3615 Cluster 6).
library colonizethis_economy_test_support;

export 'src/bid_spend_game_factory.dart';
export 'src/deal_matcher_test_support.dart';
export 'src/frr_credits_test_support.dart';
export 'src/non_gp_extraction_test_support.dart';
export 'src/resource_extractor_test_support.dart';
export 'src/tile_map_test_support.dart';
export 'src/purchased_tile_riches_test_support.dart';
export 'src/treasury_bid_budget_test_support.dart';
export 'src/trade_order_factory.dart';
export 'src/trade_order_validator_test_support.dart';
