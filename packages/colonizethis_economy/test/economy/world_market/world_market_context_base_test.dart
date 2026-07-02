import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';


/// Dedicated unit tests for the shared world-market context base.
/// Verifies the common field carrying and the optional-stockpile default
/// (issue #3396 cluster 4). SPEC/game/world-market.md.

/// Minimal concrete subclass exercising the abstract base constructor.
class _TestContext extends WorldMarketContextBase {
  const _TestContext({
    required super.playerId,
    required super.bidTypeCap,
    required super.tradeCargoCapacity,
    super.availableStockpileByCommodityId,
  });
}

void main() {
  group('WorldMarketContextBase', () {
    test('carries the four shared fields through the constructor', () {
      const stockpile = <CommodityId, int>{'grain': 5, 'silver': 2};
      const ctx = _TestContext(
        playerId: 'gp1',
        bidTypeCap: 6,
        tradeCargoCapacity: 12,
        availableStockpileByCommodityId: stockpile,
      );

      expect(ctx.playerId, 'gp1');
      expect(ctx.bidTypeCap, 6);
      expect(ctx.tradeCargoCapacity, 12);
      expect(ctx.availableStockpileByCommodityId, stockpile);
    });

    test('availableStockpileByCommodityId defaults to empty when omitted', () {
      const ctx = _TestContext(
        playerId: 'gp2',
        bidTypeCap: 0,
        tradeCargoCapacity: 0,
      );

      expect(ctx.availableStockpileByCommodityId, isEmpty);
    });
  });
}
