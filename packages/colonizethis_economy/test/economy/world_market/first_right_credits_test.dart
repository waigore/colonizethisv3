// Consolidated FRR credits + profit runners (Refs #3939 phase 3).
//
// Issue-AC audit groups for World Market First Right of Refusal (#2992 D5)
// are retained below so reviewers / `verify-github-issue` can audit AC↔test
// coverage without a separate D5 contract file.
//
// Issue AC → group mapping (#3753 R8 supersedes the #2992 40%-cap amounts):
//  AC #1 — in `world_market_deal_matcher_test.dart` (DealMatcher).
//  AC #2 — relation 75 credits 10*20*0.75 = 150 treasury (full share).
//  AC #3 — relation 100 credits exactly 100% of sale value.
//  AC #4 — relation 0 credits 0 treasury (lower bound; D2 FRR-match excluded).
//  AC #5 — multi-GP attribution, no cross-credit.

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

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

  group('computeFirstRightCredits (#2992 D4)', () {
    for (final scenario in frrCreditsDefensiveScenarios()) {
      test(scenario.label, () => runFrrCreditsScenario(scenario));
    }
  });

  group('computeFirstRightCredits aggregation (#3753 R8.2 full share)', () {
    for (final scenario in frrCreditsAggregationScenarios()) {
      test(scenario.label, () => runFrrCreditsScenario(scenario));
    }
  });

  group('computeFirstRightCredits embassy kickbacks (#3753 R8.3)', () {
    for (final scenario in frrCreditsKickbackScenarios()) {
      test(scenario.label, () => runFrrCreditsScenario(scenario));
    }
  });

  group('AC #2 — relation 75 credits 10*20*0.75 = 150 treasury (full)', () {
    for (final scenario in frrIssueAcD5CreditsAc2Scenarios()) {
      test(scenario.label, () => runFrrCreditsScenario(scenario));
    }
  });

  group('AC #3 — relation 100 credits exactly 100% of sale value', () {
    for (final scenario in frrIssueAcD5CreditsAc3Scenarios()) {
      test(scenario.label, () => runFrrCreditsScenario(scenario));
    }
  });

  group('AC #4 — relation 0 credits 0 treasury (no overseas profit)', () {
    for (final scenario in frrIssueAcD5CreditsAc4Scenarios()) {
      test(scenario.label, () => runFrrCreditsScenario(scenario));
    }
  });

  group('AC #5 — multi-GP attribution, no cross-credit', () {
    for (final scenario in frrIssueAcD5CreditsAc5Scenarios()) {
      test(scenario.label, () => runFrrCreditsScenario(scenario));
    }
  });
}
