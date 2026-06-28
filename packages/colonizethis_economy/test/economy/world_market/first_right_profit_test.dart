import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_economy/src/economy/world_market/first_right_profit.dart';

void main() {
  group('FirstRightProfit constants', () {
    test('kFirstRightMaxProfitRate is 0.40 (SPEC/game/world-market.md)', () {
      expect(kFirstRightMaxProfitRate, 0.40);
    });

    test('kFirstRightRelationScoreMax is 100', () {
      expect(kFirstRightRelationScoreMax, 100);
    });

    test('FirstRightProfit.zero has zero rate and zero treasury', () {
      expect(FirstRightProfit.zero.profitRate, 0.0);
      expect(FirstRightProfit.zero.profitTreasury, 0.0);
    });
  });

  group('computeFirstRightProfitRate (#2992 D3)', () {
    test('returns 0.0 at relationScore 0 (lower bound)', () {
      expect(computeFirstRightProfitRate(0), 0.0);
    });

    test('returns 0.30 at relationScore 75 (mid sample)', () {
      expect(computeFirstRightProfitRate(75), closeTo(0.30, 1e-12));
    });

    test('returns kFirstRightMaxProfitRate at relationScore 100', () {
      expect(computeFirstRightProfitRate(100), kFirstRightMaxProfitRate);
    });

    test('clamps to 0.0 for negative relationScore', () {
      expect(computeFirstRightProfitRate(-25), 0.0);
    });

    test('clamps to kFirstRightMaxProfitRate above 100', () {
      expect(computeFirstRightProfitRate(150), kFirstRightMaxProfitRate);
    });

    test('is monotonically non-decreasing across 0..100', () {
      double prev = -1.0;
      for (var s = 0; s <= 100; s++) {
        final r = computeFirstRightProfitRate(s);
        expect(r, greaterThanOrEqualTo(prev));
        expect(r, inInclusiveRange(0.0, kFirstRightMaxProfitRate));
        prev = r;
      }
    });
  });

  group('computeFirstRightProfit (#2992 D3 + D4 helper)', () {
    test('relationScore 0 yields FirstRightProfit.zero (no profit)', () {
      final result = computeFirstRightProfit(
        relationScore: 0,
        filledQuantity: 10,
        pricePerUnit: 5.0,
      );
      expect(result, FirstRightProfit.zero);
      expect(result.profitTreasury, 0.0);
    });

    test('relationScore 75, 10 units @ 5.0 → 0.30 rate, 15.0 treasury', () {
      final result = computeFirstRightProfit(
        relationScore: 75,
        filledQuantity: 10,
        pricePerUnit: 5.0,
      );
      expect(result.profitRate, closeTo(0.30, 1e-12));
      expect(result.profitTreasury, closeTo(15.0, 1e-12));
    });

    test('relationScore 100, 1 unit @ 1.0 → 0.40 rate, 0.40 treasury', () {
      final result = computeFirstRightProfit(
        relationScore: 100,
        filledQuantity: 1,
        pricePerUnit: 1.0,
      );
      expect(result.profitRate, kFirstRightMaxProfitRate);
      expect(result.profitTreasury, closeTo(0.40, 1e-12));
    });

    test('relationScore 100, 4 units @ 2.5 → 0.40 rate, 4.0 treasury', () {
      final result = computeFirstRightProfit(
        relationScore: 100,
        filledQuantity: 4,
        pricePerUnit: 2.5,
      );
      expect(result.profitRate, kFirstRightMaxProfitRate);
      expect(result.profitTreasury, closeTo(4.0, 1e-12));
    });

    test('zero filledQuantity → zero profit even at max relation', () {
      final result = computeFirstRightProfit(
        relationScore: 100,
        filledQuantity: 0,
        pricePerUnit: 5.0,
      );
      expect(result, FirstRightProfit.zero);
    });

    test('zero pricePerUnit → zero profit even at max relation', () {
      final result = computeFirstRightProfit(
        relationScore: 100,
        filledQuantity: 10,
        pricePerUnit: 0.0,
      );
      expect(result, FirstRightProfit.zero);
    });

    test('negative filledQuantity is clamped to zero (defensive)', () {
      final result = computeFirstRightProfit(
        relationScore: 100,
        filledQuantity: -5,
        pricePerUnit: 5.0,
      );
      expect(result, FirstRightProfit.zero);
    });

    test('negative pricePerUnit is clamped to zero (defensive)', () {
      final result = computeFirstRightProfit(
        relationScore: 100,
        filledQuantity: 5,
        pricePerUnit: -1.0,
      );
      expect(result, FirstRightProfit.zero);
    });

    test('treasury equals filledQuantity * pricePerUnit * profitRate', () {
      const rs = 50;
      const qty = 7;
      const price = 3.5;
      final r = computeFirstRightProfit(
        relationScore: rs,
        filledQuantity: qty,
        pricePerUnit: price,
      );
      final expectedRate = (rs / 100.0) * kFirstRightMaxProfitRate;
      expect(r.profitRate, closeTo(expectedRate, 1e-12));
      expect(r.profitTreasury, closeTo(qty * price * expectedRate, 1e-12));
    });

    test('FirstRightProfit equality works on identical (rate, treasury)', () {
      const a = FirstRightProfit(profitRate: 0.30, profitTreasury: 15.0);
      const b = FirstRightProfit(profitRate: 0.30, profitTreasury: 15.0);
      const c = FirstRightProfit(profitRate: 0.30, profitTreasury: 15.5);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });

    test('toString is informative for trace logs', () {
      const r = FirstRightProfit(profitRate: 0.40, profitTreasury: 4.0);
      expect(r.toString(), contains('0.4'));
      expect(r.toString(), contains('4.0'));
    });
  });
}
