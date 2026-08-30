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
    runLabeledScenarios(capBidQuantityForBudgetsScenarios, (scenario) {
      expect(
        capBidQuantityForBudgets(
          bidQuantity: scenario.bidQuantity,
          remainingCargoBudget: scenario.remainingCargoBudget,
          remainingTreasuryBudget: scenario.remainingTreasuryBudget,
          unitPrice: scenario.unitPrice,
        ),
        scenario.expected,
      );
    }, labelOf: (s) => s.label);
  });

  group('effectiveMarketPriceForCommodityId (Refs #3093)', () {
    runLabeledScenarios(effectiveMarketPriceScenarios, (scenario) {
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
    }, labelOf: (s) => s.label);
  });

  group('stagedBidTotalSpendByPlayer (Refs #3093)', () {
    runLabeledScenarios(stagedBidSpendScenarios(rules), (scenario) {
      runStagedBidSpendScenario(scenario, rules);
    }, labelOf: (s) => s.label);
  });

  group('carryForwardBidNotionalByPlayer (Refs #3122)', () {
    runLabeledScenarios(carryForwardBidNotionalScenarios(), (scenario) {
      runCarryForwardBidNotionalScenario(scenario, rules);
    }, labelOf: (s) => s.label);
  });

  group('shared bid-spend helper parity (Refs #3427)', () {
    runLabeledScenarios(bidSpendParityScenarios(), (scenario) {
      runBidSpendParityScenario(scenario, rules);
    }, labelOf: (s) => s.label);
  });

  group('treasuryAvailableForBidsByPlayer (Refs #3093)', () {
    runLabeledScenarios(treasuryAvailableForBidsScenarios, (scenario) {
      runTreasuryAvailableScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('composition: UI clamp budget math (Refs #3093)', () {
    runLabeledScenarios(treasuryUiCompositionScenarios(rules), (scenario) {
      runTreasuryUiCompositionScenario(scenario, rules);
    }, labelOf: (s) => s.label);
  });

  group('maxAffordableBidQuantity (Refs #3856)', () {
    runLabeledScenarios(maxAffordableBidQuantityScenarios, (scenario) {
      expect(
        maxAffordableBidQuantity(
          bidRemaining: scenario.bidRemaining,
          pricePerUnit: scenario.pricePerUnit,
          remainingTreasuryBudget: scenario.remainingTreasuryBudget,
        ),
        scenario.expected,
      );
    }, labelOf: (s) => s.label);
  });

  group('decrementTreasuryForFill (Refs #3856)', () {
    runLabeledScenarios(decrementTreasuryForFillScenarios, (scenario) {
      runDecrementTreasuryForFillScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('GpTreasuryCreditAccumulator<int>', () {
    runLabeledScenarios(gpTreasuryCreditIntScenarios(), (scenario) {
      runGpTreasuryCreditIntScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('GpTreasuryCreditAccumulator<double> (FRR zero-profit semantics)', () {
    runLabeledScenarios(gpTreasuryCreditDoubleScenarios(), (scenario) {
      runGpTreasuryCreditDoubleScenario(scenario);
    }, labelOf: (s) => s.label);
  });
}
