// Shared fixtures for world_market_phase_treasury_clamp_test (Refs #4342 Slice C).

import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/world_market_test_support.dart';

/// Phase-handler coverage for the world-market treasury clamp (Refs #3115).
///
/// SPEC anchors:
/// - `SPEC/program/world-market-resolution.md` § Step C (treasury clamp,
///   matchQty formula, running tally, truncation note).
/// - `SPEC/program/world-market-resolution.md` § Step E (bid-side
///   filled-quantity aggregation for price discovery).
/// - `SPEC/game/world-market.md` § Treasury budget for bids
///   (resolver-side enforcement).

/// Shared clamp fixture: buyer treasury 100, timber @ 30, offer 10 / bid 10
/// (fills 3 under the budget; used by AC#1 / price-discovery cases).
Game runWorldMarketTimberClampTreasury100() => runTreasuryClampPhase(
      sellerStockpile: const Stockpile().applyDelta('timber', 10),
      sellerTreasury: 0,
      buyerTreasury: 100,
      marketPrices: const {'timber': 30},
      orders: gpGpTimberTradeOrders(offerQuantity: 10, bidQuantity: 10),
    );
