import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Tests for `TradeOrderSuggester.suggest` treasury bid cap (rule 5).
///
/// Per `SPEC/program/world-market-resolution.md` § Trade order suggestion API
/// and `SPEC/game/world-market.md` rule 7. Refs #3123.
void main() {
  group('TradeOrderSuggester.suggest — cumulative treasury cap (rule 5)', () {
    test('treasury budget is consumed across distinct bids in id order', () {
      final result = TradeOrderSuggester.suggest(
        TradeSuggestionContext(
          playerId: 'gp1',
          bidTypeCap: 6,
          tradeCargoCapacity: 100,
          treasuryBudgetForBids: 90,
          worldMarketState: WorldMarketState(
            prices: {
              CommodityCatalog.iron.id: 30,
              CommodityCatalog.timber.id: 30,
            },
          ),
          commodityNeedByCommodityId: {
            CommodityCatalog.iron.id: 5,
            CommodityCatalog.timber.id: 5,
          },
        ),
      );
      expect(result.bids, hasLength(1));
      expect(result.bids.single.commodityId, CommodityCatalog.iron.id);
      expect(result.bids.single.quantity, 3);
    });

    test('single bid is partial-capped by treasury', () {
      final result = TradeOrderSuggester.suggest(
        TradeSuggestionContext(
          playerId: 'gp1',
          bidTypeCap: 3,
          tradeCargoCapacity: 100,
          treasuryBudgetForBids: 90,
          worldMarketState: WorldMarketState(
            prices: {CommodityCatalog.timber.id: 30},
          ),
          commodityNeedByCommodityId: {CommodityCatalog.timber.id: 5},
        ),
      );
      expect(result.bids.single.quantity, 3);
    });

    test('zero treasury budget suppresses bids entirely', () {
      final result = TradeOrderSuggester.suggest(
        TradeSuggestionContext(
          playerId: 'gp1',
          bidTypeCap: 3,
          tradeCargoCapacity: 100,
          treasuryBudgetForBids: 0,
          worldMarketState: WorldMarketState(
            prices: {CommodityCatalog.timber.id: 30},
          ),
          commodityNeedByCommodityId: {CommodityCatalog.timber.id: 5},
        ),
      );
      expect(result.bids, isEmpty);
    });
  });
}
