import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';


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
    const rateCases = <({int score, double expected})>[
      (score: 0, expected: 0.0),
      (score: 75, expected: 0.75),
      (score: 100, expected: kFirstRightMaxProfitRate),
      (score: -25, expected: 0.0),
      (score: 150, expected: kFirstRightMaxProfitRate),
    ];

    for (final c in rateCases) {
      test('returns ${c.expected} at relationScore ${c.score}', () {
        final result = computeFirstRightProfitRate(c.score);
        if (c.expected == kFirstRightMaxProfitRate || c.expected == 0.0) {
          expect(result, c.expected);
        } else {
          expect(result, closeTo(c.expected, 1e-12));
        }
      });
    }

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
    const profitCases = <({
      int relationScore,
      int filledQuantity,
      double pricePerUnit,
      double expectedRate,
      double expectedTreasury,
      bool expectZero,
    })>[
      (
        relationScore: 0,
        filledQuantity: 10,
        pricePerUnit: 5.0,
        expectedRate: 0.0,
        expectedTreasury: 0.0,
        expectZero: true,
      ),
      (
        relationScore: 75,
        filledQuantity: 10,
        pricePerUnit: 5.0,
        expectedRate: 0.75,
        expectedTreasury: 37.5,
        expectZero: false,
      ),
      (
        relationScore: 100,
        filledQuantity: 1,
        pricePerUnit: 1.0,
        expectedRate: kFirstRightMaxProfitRate,
        expectedTreasury: 1.0,
        expectZero: false,
      ),
      (
        relationScore: 100,
        filledQuantity: 4,
        pricePerUnit: 2.5,
        expectedRate: kFirstRightMaxProfitRate,
        expectedTreasury: 10.0,
        expectZero: false,
      ),
      (
        relationScore: 100,
        filledQuantity: 0,
        pricePerUnit: 5.0,
        expectedRate: 0.0,
        expectedTreasury: 0.0,
        expectZero: true,
      ),
      (
        relationScore: 100,
        filledQuantity: 10,
        pricePerUnit: 0.0,
        expectedRate: 0.0,
        expectedTreasury: 0.0,
        expectZero: true,
      ),
      (
        relationScore: 100,
        filledQuantity: -5,
        pricePerUnit: 5.0,
        expectedRate: 0.0,
        expectedTreasury: 0.0,
        expectZero: true,
      ),
      (
        relationScore: 100,
        filledQuantity: 5,
        pricePerUnit: -1.0,
        expectedRate: 0.0,
        expectedTreasury: 0.0,
        expectZero: true,
      ),
    ];

    for (final c in profitCases) {
      test(
        'relationScore ${c.relationScore}, qty ${c.filledQuantity} @ '
        '${c.pricePerUnit} → rate ${c.expectedRate}, treasury '
        '${c.expectedTreasury}',
        () {
          final result = computeFirstRightProfit(
            relationScore: c.relationScore,
            filledQuantity: c.filledQuantity,
            pricePerUnit: c.pricePerUnit,
          );
          if (c.expectZero) {
            expect(result, FirstRightProfit.zero);
            expect(result.profitTreasury, 0.0);
          } else {
            expect(result.profitRate, closeTo(c.expectedRate, 1e-12));
            expect(result.profitTreasury, closeTo(c.expectedTreasury, 1e-12));
          }
        },
      );
    }

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
    const kickbackCases = <({
      num relationScore,
      int filledQuantity,
      double pricePerUnit,
      double expected,
    })>[
      (relationScore: 100, filledQuantity: 10, pricePerUnit: 20.0, expected: 20.0),
      (relationScore: 50, filledQuantity: 10, pricePerUnit: 20.0, expected: 10.0),
      (relationScore: 80.0, filledQuantity: 4, pricePerUnit: 2.5, expected: 0.8),
      (relationScore: 0, filledQuantity: 10, pricePerUnit: 20.0, expected: 0.0),
      (relationScore: 100, filledQuantity: -5, pricePerUnit: 20.0, expected: 0.0),
      (relationScore: 100, filledQuantity: 10, pricePerUnit: 0.0, expected: 0.0),
      (relationScore: 150, filledQuantity: 10, pricePerUnit: 20.0, expected: 20.0),
    ];

    for (final c in kickbackCases) {
      test(
        'relation ${c.relationScore}, ${c.filledQuantity} @ ${c.pricePerUnit} '
        '→ ${c.expected}',
        () {
          expect(
            computeEmbassyKickback(
              relationScore: c.relationScore,
              filledQuantity: c.filledQuantity,
              pricePerUnit: c.pricePerUnit,
            ),
            closeTo(c.expected, 1e-12),
          );
        },
      );
    }
  });
}
