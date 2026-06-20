// Canonical shared `TradeOrder` factories for economy world-market tests.
//
// Refs #3427 step 14 — replaces the previously independent per-suite
// implementations (`matcherBid`/`matcherOffer`, `validatorBid`/
// `validatorOffer`, `bidOrder`/`offerOrder`, and the private `_bid`/`_offer`
// copies). One parameterized bid/offer builder keeps the construction shape
// consistent across every world-market test file.

import 'package:colonizethis_models/colonizethis_models.dart';

/// Builds a `bid`-type [TradeOrder]. `priority` defaults to 1 (the common
/// single-priority test case); callers needing a specific priority pass it.
TradeOrder testBid(String commodityId, int quantity, {int priority = 1}) =>
    TradeOrder(
      commodityId: commodityId,
      type: TradeOrderType.bid,
      quantity: quantity,
      priority: priority,
    );

/// Builds an `offer`-type [TradeOrder]. `originTileKey` is optional so the
/// same factory covers both plain offers and origin-tracked (FRR/purchased
/// tile) offers.
TradeOrder testOffer(
  String commodityId,
  int quantity, {
  int priority = 1,
  String? originTileKey,
}) => TradeOrder(
  commodityId: commodityId,
  type: TradeOrderType.offer,
  quantity: quantity,
  priority: priority,
  originTileKey: originTileKey,
);
