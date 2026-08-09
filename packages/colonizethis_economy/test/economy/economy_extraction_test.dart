import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

// --- Slice C runners (Refs #4108) ---
// dart format off
void runApplyExtractionToStockpileExpectation({
  Stockpile? initialStockpile,
  Map<String, int>? initialDeltas,
  required Map<String, int> extracted,
  required StockpileQuantityPins expectedQuantities,
}) {
  final stockpile = initialStockpile ?? (initialDeltas == null ? const Stockpile() : stockpileWithDeltas(initialDeltas));
  final updated = applyExtractionToStockpile(stockpile, extracted);
  for (final entry in expectedQuantities.entries) {
    expect(updated.quantityOf(entry.key), entry.value);
  }
}

void runApplyExtractionForPlayersExpectation({
  required Game game,
  required Map<String, Map<String, int>> extractedByPlayerId,
  List<PlayerStockpilePin>? stockpilePins,
  bool expectUnchangedPlayers = false,
}) {
  final updated = applyExtractionForPlayers(game, extractedByPlayerId);
  if (expectUnchangedPlayers) {
    expect(updated.players, game.players);
    return;
  }
  for (final pin in stockpilePins ?? const []) {
    expect(updated.players[pin.playerIndex].stockpile.quantityOf(pin.commodityId), pin.quantity);
  }
}

void runApplyExtractionToStockpileScenario(ApplyExtractionToStockpileScenario scenario) {
  runApplyExtractionToStockpileExpectation(
    initialStockpile: scenario.initialStockpile,
    initialDeltas: scenario.initialDeltas,
    extracted: scenario.extracted,
    expectedQuantities: scenario.expectedQuantities,
  );
}

void runApplyExtractionForPlayersScenario(ApplyExtractionForPlayersScenario scenario) {
  runApplyExtractionForPlayersExpectation(
    game: scenario.game,
    extractedByPlayerId: scenario.extractedByPlayerId,
    stockpilePins: scenario.stockpilePins,
    expectUnchangedPlayers: scenario.expectUnchangedPlayers,
  );
}
// dart format on

/// Tests for economy_extraction.dart. SPEC/program/auto-transport.md.
void main() {
  runLabeledScenarioGroup(
    'applyExtractionToStockpile',
    applyExtractionToStockpileScenarios(),
    runApplyExtractionToStockpileScenario,
    labelOf: (s) => s.label,
  );

  runLabeledScenarioGroup(
    'applyExtractionForPlayers',
    applyExtractionForPlayersScenarios(),
    runApplyExtractionForPlayersScenario,
    labelOf: (s) => s.label,
  );
}
