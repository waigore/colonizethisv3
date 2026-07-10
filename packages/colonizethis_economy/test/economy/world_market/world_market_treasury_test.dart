// Consolidated treasury bid-budget runners (Refs #3939 phase 3 slice 2).
//
// SPEC/game/world-market.md § Treasury budget for bids,
// SPEC/ui/trade-screen.md § Market tab — treasury bid cap.

import 'package:colonizethis_data/colonizethis_data.dart' as data;
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  final data.ResourceRules rules = data.ResourceRules.defaultRules;

  group('capBidQuantityForBudgets (Refs #3836)', () {
    for (final scenario in capBidQuantityForBudgetsScenarios) {
      test(scenario.label, () {
        expect(
          capBidQuantityForBudgets(
            bidQuantity: scenario.bidQuantity,
            remainingCargoBudget: scenario.remainingCargoBudget,
            remainingTreasuryBudget: scenario.remainingTreasuryBudget,
            unitPrice: scenario.unitPrice,
          ),
          scenario.expected,
        );
      });
    }
  });

  group('effectiveMarketPriceForCommodityId (Refs #3093)', () {
    for (final scenario in effectiveMarketPriceScenarios) {
      test(scenario.label, () {
        final game = buildTreasuryBidBudgetGame(prices: scenario.prices);
        final expected = expectedEffectiveMarketPrice(scenario, rules);
        if (scenario.useCatalogDefault) {
          expect(expected, isNotNull);
        }
        expect(
          effectiveMarketPriceForCommodityId(
            commodityId: scenario.commodityId,
            worldMarket: game.worldMarketState,
            resourceRules: rules,
          ),
          expected,
        );
      });
    }
  });

  group('stagedBidTotalSpendByPlayer (Refs #3093)', () {
    for (final scenario in stagedBidSpendScenarios(rules)) {
      test(scenario.label, () {
        runStagedBidSpendScenario(scenario, rules);
      });
    }
  });

  group('carryForwardBidNotionalByPlayer (Refs #3122)', () {
    for (final scenario in carryForwardBidNotionalScenarios()) {
      test(scenario.label, () {
        runCarryForwardBidNotionalScenario(scenario, rules);
      });
    }
  });

  group('shared bid-spend helper parity (Refs #3427)', () {
    for (final scenario in bidSpendParityScenarios()) {
      test(scenario.label, () {
        runBidSpendParityScenario(scenario, rules);
      });
    }
  });

  group('treasuryAvailableForBidsByPlayer (Refs #3093)', () {
    for (final scenario in treasuryAvailableForBidsScenarios) {
      test(scenario.label, () => runTreasuryAvailableScenario(scenario));
    }
  });

  group('composition: UI clamp budget math (Refs #3093)', () {
    for (final scenario in treasuryUiCompositionScenarios(rules)) {
      test(scenario.label, () => runTreasuryUiCompositionScenario(scenario, rules));
    }
  });

  group('maxAffordableBidQuantity (Refs #3856)', () {
    for (final scenario in maxAffordableBidQuantityScenarios) {
      test(scenario.label, () {
        expect(
          maxAffordableBidQuantity(
            bidRemaining: scenario.bidRemaining,
            pricePerUnit: scenario.pricePerUnit,
            remainingTreasuryBudget: scenario.remainingTreasuryBudget,
          ),
          scenario.expected,
        );
      });
    }
  });

  group('decrementTreasuryForFill (Refs #3856)', () {
    for (final scenario in decrementTreasuryForFillScenarios) {
      test(scenario.label, () => runDecrementTreasuryForFillScenario(scenario));
    }
  });

  group('GpTreasuryCreditAccumulator<int>', () {
    for (final scenario in gpTreasuryCreditIntScenarios()) {
      test(scenario.label, () => runGpTreasuryCreditIntScenario(scenario));
    }
  });

  group('GpTreasuryCreditAccumulator<double> (FRR zero-profit semantics)', () {
    for (final scenario in gpTreasuryCreditDoubleScenarios()) {
      test(scenario.label, () => runGpTreasuryCreditDoubleScenario(scenario));
    }
  });
}
