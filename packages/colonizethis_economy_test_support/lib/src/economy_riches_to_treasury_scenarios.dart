// dart format off
// Table-driven riches-to-treasury scenarios (Refs #3939 phase 3 slice 9).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'core_economy_test_support.dart';

/// One row in [resolveRichesToTreasuryScenarios].
typedef ResolveRichesToTreasuryScenario = ({String label, Map<CommodityId, int> stockpileDeltas, double? richesCashMultiplier, int expectedTreasuryDelta, Map<CommodityId, int> expectedStockpile, String? refs});

List<ResolveRichesToTreasuryScenario> resolveRichesToTreasuryScenarios() => [
  (label: 'converts spices to treasury at base price', stockpileDeltas: {'spices': 4}, richesCashMultiplier: null, expectedTreasuryDelta: 4 * 50, expectedStockpile: {'spices': 0}, refs: null),
  (label: 'converts multiple riches and sums treasury delta', stockpileDeltas: {'spices': 2, 'silver': 1}, richesCashMultiplier: null, expectedTreasuryDelta: 2 * 50 + richesBasePrice('silver'), expectedStockpile: {'spices': 0, 'silver': 0}, refs: null),
  (label: 'non-riches in stockpile are unchanged', stockpileDeltas: {'grain': 10, 'gold': 2}, richesCashMultiplier: null, expectedTreasuryDelta: 2 * richesBasePrice('gold'), expectedStockpile: {'grain': 10, 'gold': 0}, refs: null),
  (label: 'richesCashMultiplier scales treasury delta', stockpileDeltas: {'spices': 2}, richesCashMultiplier: 1.5, expectedTreasuryDelta: (2 * 50 * 1.5).truncate(), expectedStockpile: {'spices': 0}, refs: null),
  (label: 'zero riches yields zero delta and unchanged stockpile', stockpileDeltas: {'grain': 5}, richesCashMultiplier: null, expectedTreasuryDelta: 0, expectedStockpile: {'grain': 5}, refs: null),
  (label: 'empty stockpile yields zero delta', stockpileDeltas: const {}, richesCashMultiplier: null, expectedTreasuryDelta: 0, expectedStockpile: const {}, refs: null),
];

void verifyResolveRichesToTreasuryScenario(ResolveRichesToTreasuryScenario scenario) {
  final stockpile = stockpileWithDeltas(scenario.stockpileDeltas);
  final result = scenario.richesCashMultiplier == null ? resolveRichesToTreasury(stockpile: stockpile) : resolveRichesToTreasury(stockpile: stockpile, richesCashMultiplier: scenario.richesCashMultiplier!);
  expect(result.treasuryDelta, scenario.expectedTreasuryDelta);
  for (final MapEntry(:key, :value) in scenario.expectedStockpile.entries) {
    expect(result.stockpile.quantityOf(key), value);
  }
}

/// One row in [pendingRichesTreasuryDeltaScenarios].
typedef PendingRichesTreasuryDeltaScenario = ({String label, Map<CommodityId, int> stockpileDeltas, int expectedDelta, String? refs});

List<PendingRichesTreasuryDeltaScenario> pendingRichesTreasuryDeltaScenarios() => [
  (label: 'matches resolveRichesToTreasury treasuryDelta', stockpileDeltas: {'spices': 3, 'gold': 1}, expectedDelta: 0, refs: null),
  (label: 'returns zero when stockpile has no riches', stockpileDeltas: {'grain': 5}, expectedDelta: 0, refs: null),
];

void verifyPendingRichesTreasuryDeltaScenario(PendingRichesTreasuryDeltaScenario scenario) {
  final stockpile = stockpileWithDeltas(scenario.stockpileDeltas);
  if (scenario.label.startsWith('matches resolveRichesToTreasury')) {
    expect(pendingRichesTreasuryDelta(stockpile: stockpile), resolveRichesToTreasury(stockpile: stockpile).treasuryDelta);
    return;
  }
  expect(pendingRichesTreasuryDelta(stockpile: stockpile), scenario.expectedDelta);
}
// dart format on
