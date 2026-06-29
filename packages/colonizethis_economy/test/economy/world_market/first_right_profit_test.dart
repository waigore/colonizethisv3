import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_economy/src/economy/world_market/first_right_profit.dart';

void main() {
  group('FirstRightProfit constants', () {
    test('kFirstRightMaxProfitRate is 1.0 (#3753 R8.2 — full share, no cap)', () {
      expect(kFirstRightMaxProfitRate, 1.0);
    });

    test('kFirstRightRelationScoreMax is 100', () {
      expect(kFirstRightRelationScoreMax, 100);
    });

    test('kEmbassyOverseasProfitKickbackMultiplier is 0.10 (#3753 R8.3)', () {
      expect(kEmbassyOverseasProfitKickbackMultiplier, 0.10);
    });

    test('FirstRightProfit.zero has zero rate and zero treasury', () {
      expect(FirstRightProfit.zero.profitRate, 0.0);
      expect(FirstRightProfit.zero.profitTreasury, 0.0);
    });
  });

  group('computeFirstRightProfitRate (#3753 R8.2 — full relation-linear)', () {
    test('returns 0.0 at relationScore 0 (lower bound)', () {
      expect(computeFirstRightProfitRate(0), 0.0);
    });

    test('returns 0.75 at relationScore 75 (mid sample, full share)', () {
      expect(computeFirstRightProfitRate(75), closeTo(0.75, 1e-12));
    });

    test('returns kFirstRightMaxProfitRate (1.0) at relationScore 100', () {
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

    test('relationScore 75, 10 units @ 5.0 → 0.75 rate, 37.5 treasury', () {
      final result = computeFirstRightProfit(
        relationScore: 75,
        filledQuantity: 10,
        pricePerUnit: 5.0,
      );
      expect(result.profitRate, closeTo(0.75, 1e-12));
      expect(result.profitTreasury, closeTo(37.5, 1e-12));
    });

    test('relationScore 100, 1 unit @ 1.0 → 1.0 rate, 1.0 treasury', () {
      final result = computeFirstRightProfit(
        relationScore: 100,
        filledQuantity: 1,
        pricePerUnit: 1.0,
      );
      expect(result.profitRate, kFirstRightMaxProfitRate);
      expect(result.profitTreasury, closeTo(1.0, 1e-12));
    });

    test('relationScore 100, 4 units @ 2.5 → 1.0 rate, 10.0 treasury', () {
      final result = computeFirstRightProfit(
        relationScore: 100,
        filledQuantity: 4,
        pricePerUnit: 2.5,
      );
      expect(result.profitRate, kFirstRightMaxProfitRate);
      expect(result.profitTreasury, closeTo(10.0, 1e-12));
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
      final expectedRate = rs / 100.0; // full relation-linear share (R8.2)
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

  group('computeEmbassyKickback (#3753 R8.3 — 10% of relation portion)', () {
    test('relation 100, 10 @ 20.0 → 10*20*1.0*0.10 = 20.0', () {
      expect(
        computeEmbassyKickback(
          relationScore: 100,
          filledQuantity: 10,
          pricePerUnit: 20.0,
        ),
        closeTo(20.0, 1e-12),
      );
    });

    test('relation 50, 10 @ 20.0 → 10*20*0.5*0.10 = 10.0', () {
      expect(
        computeEmbassyKickback(
          relationScore: 50,
          filledQuantity: 10,
          pricePerUnit: 20.0,
        ),
        closeTo(10.0, 1e-12),
      );
    });

    test('decimal relation 80.0, 4 @ 2.5 → 4*2.5*0.80*0.10 = 0.8', () {
      expect(
        computeEmbassyKickback(
          relationScore: 80.0,
          filledQuantity: 4,
          pricePerUnit: 2.5,
        ),
        closeTo(0.8, 1e-12),
      );
    });

    test('relation 0 yields 0.0 kickback', () {
      expect(
        computeEmbassyKickback(
          relationScore: 0,
          filledQuantity: 10,
          pricePerUnit: 20.0,
        ),
        0.0,
      );
    });

    test('negative quantity / zero price yield 0.0 (defensive)', () {
      expect(
        computeEmbassyKickback(
          relationScore: 100,
          filledQuantity: -5,
          pricePerUnit: 20.0,
        ),
        0.0,
      );
      expect(
        computeEmbassyKickback(
          relationScore: 100,
          filledQuantity: 10,
          pricePerUnit: 0.0,
        ),
        0.0,
      );
    });

    test('relation above 100 is clamped to 100 (kickback caps at 10% gross)', () {
      expect(
        computeEmbassyKickback(
          relationScore: 150,
          filledQuantity: 10,
          pricePerUnit: 20.0,
        ),
        closeTo(20.0, 1e-12),
      );
    });
  });
}
