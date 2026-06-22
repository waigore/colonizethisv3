import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('trade order factory', () {
    test('testBid builds a bid-type TradeOrder with defaults', () {
      final order = testBid('timber', 5);
      expect(order.commodityId, 'timber');
      expect(order.type, TradeOrderType.bid);
      expect(order.quantity, 5);
      expect(order.priority, 1);
      expect(order.originTileKey, isNull);
    });

    test('testOffer builds an offer-type TradeOrder and tracks origin tile', () {
      final order = testOffer(
        'iron',
        9,
        priority: 3,
        originTileKey: 'oldWorld|M1|0|0',
      );
      expect(order.type, TradeOrderType.offer);
      expect(order.quantity, 9);
      expect(order.priority, 3);
      expect(order.originTileKey, 'oldWorld|M1|0|0');
    });
  });

  group('validator helpers', () {
    test('validatorBid / validatorOffer delegate to the shared factory', () {
      expect(validatorBid('wool', 2).type, TradeOrderType.bid);
      expect(validatorOffer('wool', 2).type, TradeOrderType.offer);
    });

    test('validatorCtx exposes its defaults and overrides', () {
      final ctx = validatorCtx();
      expect(ctx.playerId, 'gp1');
      expect(ctx.bidTypeCap, 6);
      expect(ctx.tradeCargoCapacity, 100);

      final custom = validatorCtx(playerId: 'gp2', bidTypeCap: 1);
      expect(custom.playerId, 'gp2');
      expect(custom.bidTypeCap, 1);
    });
  });

  group('deal matcher helpers', () {
    test('matcherInputs defaults treasury budget per bidding faction', () {
      final inputs = matcherInputs(
        bidsByFactionId: {
          'gpA': [matcherBid('timber', 1)],
        },
      );
      expect(inputs.bidsByFactionId.keys, contains('gpA'));
      expect(inputs.treasuryBudgetByBuyerFactionId['gpA'], 1 << 30);
      expect(inputs.pricesByCommodityId['timber'], 30.0);
    });

    test('matcherInputs honors an explicit treasury budget override', () {
      final inputs = matcherInputs(
        bidsByFactionId: {
          'gpA': [matcherBid('timber', 1)],
        },
        treasuryBudgetByBuyerFactionId: const {'gpA': 42},
      );
      expect(inputs.treasuryBudgetByBuyerFactionId['gpA'], 42);
    });

    test('frrMatcherTestIndex builds a single-tile attribution index', () {
      final index = frrMatcherTestIndex();
      final attribution = index.attributionForTileKey('oldWorld|M1|0|0');
      expect(attribution, isNotNull);
      expect(attribution!.owningGpId, 'gpA');
      expect(attribution.sourceFactionId, 'M1');
      expect(index.isEmpty, isFalse);
    });
  });
}
