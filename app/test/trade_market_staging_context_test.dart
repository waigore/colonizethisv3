import 'package:colonizethis_app/features/game/screens/trade/trade_market_staging_context.dart';
import 'package:colonizethis_app/features/game/screens/trade/trade_section_handlers.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TradeMarketStagingContext', () {
    test('sellableHeadroomForMaps clamps negative headroom to zero', () {
      expect(
        sellableHeadroomForMaps(
          offerCap: const {'grain': 5},
          stagedOffers: const {'grain': 8},
          commodityId: 'grain',
        ),
        0,
      );
    });

    test('onDirectionChanged delegates to handlers', () {
      CommodityId? capturedId;
      var captured = false;
      final staging = TradeMarketStagingContext(
        playerId: 'gp1',
        offerCap: const {},
        stagedOffers: const {},
        bidTypeCap: 3,
        orders: const Orders(),
        market: WorldMarketState.empty,
        handlers: (
          onDirectionChanged: (CommodityId id, TradeOrderType? _) {
            capturedId = id;
            captured = true;
          },
          onQuantityDelta: (_, __) {},
        ),
        firstRightCommodityIds: const {},
      );

      staging.onDirectionChanged('grain', TradeOrderType.bid);

      expect(captured, isTrue);
      expect(capturedId, 'grain');
    });
  });
}
