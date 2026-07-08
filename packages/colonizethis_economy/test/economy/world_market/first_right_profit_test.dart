// Table-driven unit tests for FirstRightProfit (Refs #3856).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

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
    for (final scenario in firstRightProfitRateScenarios()) {
      test(scenario.label, () {
        runFirstRightProfitRateScenario(scenario);
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
    for (final scenario in firstRightProfitScenarios()) {
      test(scenario.label, () {
        runFirstRightProfitScenario(scenario);
      });
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
    for (final scenario in embassyKickbackScenarios()) {
      test(scenario.label, () {
        runEmbassyKickbackScenario(scenario);
      });
    }
  });
}
