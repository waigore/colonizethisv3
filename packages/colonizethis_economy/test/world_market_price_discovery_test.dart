import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('PriceDiscovery.computeNextPrice', () {
    test('zero volume returns oldPrice unchanged', () {
      final price = PriceDiscovery.computeNextPrice((
        oldPrice: 100.0,
        basePrice: 100,
        newBidQuantity: 0,
        newOfferQuantity: 0,
      ));
      expect(price, 100.0);
    });

    test(
      'bid 20 / offer 10 / oldPrice 100 / base 100 -> ~116.6666 (under cap)',
      () {
        final price = PriceDiscovery.computeNextPrice((
          oldPrice: 100.0,
          basePrice: 100,
          newBidQuantity: 20,
          newOfferQuantity: 10,
        ));
        expect(price, closeTo(100.0 * (1.0 + 1.0 / 6.0), 1e-9));
      },
    );

    test('extreme bid (1000 vs 0) caps delta at +0.20 -> 120.0', () {
      final price = PriceDiscovery.computeNextPrice((
        oldPrice: 100.0,
        basePrice: 100,
        newBidQuantity: 1000,
        newOfferQuantity: 0,
      ));
      expect(price, closeTo(120.0, 1e-9));
    });

    test('extreme offer (0 vs 1000) caps delta at -0.20 -> 80.0', () {
      final price = PriceDiscovery.computeNextPrice((
        oldPrice: 100.0,
        basePrice: 100,
        newBidQuantity: 0,
        newOfferQuantity: 1000,
      ));
      expect(price, closeTo(80.0, 1e-9));
    });

    test('floor clamp: oldPrice 32 with base 100 stays at 30.0', () {
      final price = PriceDiscovery.computeNextPrice((
        oldPrice: 32.0,
        basePrice: 100,
        newBidQuantity: 0,
        newOfferQuantity: 1000,
      ));
      expect(price, 30.0);
    });

    test('floor clamp: oldPrice 30 (already at floor) stays at 30.0', () {
      final price = PriceDiscovery.computeNextPrice((
        oldPrice: 30.0,
        basePrice: 100,
        newBidQuantity: 0,
        newOfferQuantity: 1000,
      ));
      expect(price, 30.0);
    });

    test('zero oldPrice (defensive) recovers to floor on positive volume', () {
      final price = PriceDiscovery.computeNextPrice((
        oldPrice: 0.0,
        basePrice: 100,
        newBidQuantity: 5,
        newOfferQuantity: 5,
      ));
      expect(price, 30.0);
    });

    test('balanced bid==offer keeps oldPrice (delta = 0)', () {
      final price = PriceDiscovery.computeNextPrice((
        oldPrice: 50.0,
        basePrice: 50,
        newBidQuantity: 7,
        newOfferQuantity: 7,
      ));
      expect(price, 50.0);
    });

    test('negative-leaning ratio applies symmetric formula', () {
      final price = PriceDiscovery.computeNextPrice((
        oldPrice: 100.0,
        basePrice: 100,
        newBidQuantity: 10,
        newOfferQuantity: 20,
      ));
      expect(price, closeTo(100.0 * (1.0 - 1.0 / 6.0), 1e-9));
    });
  });

  group('PriceDiscovery.computeMarketActivity', () {
    test('records new totals and computes priceChangePercent', () {
      final activity = PriceDiscovery.computeMarketActivity((
        oldPrice: 100.0,
        basePrice: 100,
        newBidQuantity: 20,
        newOfferQuantity: 10,
      ), filledQuantity: 10);
      expect(activity.totalBidQuantity, 20);
      expect(activity.totalOfferQuantity, 10);
      expect(activity.filledQuantity, 10);
      expect(activity.priceChangePercent, closeTo(1.0 / 6.0, 1e-9));
    });

    test('zero volume yields 0 priceChangePercent', () {
      final activity = PriceDiscovery.computeMarketActivity((
        oldPrice: 100.0,
        basePrice: 100,
        newBidQuantity: 0,
        newOfferQuantity: 0,
      ), filledQuantity: 0);
      expect(activity.priceChangePercent, 0.0);
    });

    test('zero oldPrice (defensive) yields 0 priceChangePercent', () {
      final activity = PriceDiscovery.computeMarketActivity((
        oldPrice: 0.0,
        basePrice: 100,
        newBidQuantity: 5,
        newOfferQuantity: 5,
      ), filledQuantity: 5);
      expect(activity.priceChangePercent, 0.0);
    });

    test('returns MarketActivity instance compatible with empty equality', () {
      final activity = PriceDiscovery.computeMarketActivity((
        oldPrice: 100.0,
        basePrice: 100,
        newBidQuantity: 0,
        newOfferQuantity: 0,
      ), filledQuantity: 0);
      expect(activity, equals(MarketActivity.empty));
    });
  });

  group('PriceDiscovery constants', () {
    test('match SPEC values', () {
      expect(PriceDiscovery.maxDeltaPerTurn, 0.20);
      expect(PriceDiscovery.deltaCoefficient, 0.5);
      expect(PriceDiscovery.priceFloorRatio, 0.30);
    });
  });
}
