// dart format off
// Compact economy extraction assertions (Refs #3939 phase 3 slice 34).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'core_economy_test_support.dart';
import 'economy_extraction_scenarios.dart';

/// Expected commodity quantities on a stockpile after extraction.
typedef StockpileQuantityPins = Map<String, int>;

void runApplyExtractionToStockpileExpectation({Stockpile? initialStockpile, Map<String, int>? initialDeltas, required Map<String, int> extracted, required StockpileQuantityPins expectedQuantities}) {
  final stockpile = initialStockpile ?? (initialDeltas == null ? const Stockpile() : stockpileWithDeltas(initialDeltas));
  final updated = applyExtractionToStockpile(stockpile, extracted);
  for (final entry in expectedQuantities.entries) {
    expect(updated.quantityOf(entry.key), entry.value);
  }
}

ApplyExtractionToStockpileScenario applyExtractionToStockpileScenario({required String label, Map<String, int>? initialDeltas, Stockpile? initialStockpile, required Map<String, int> extracted, required StockpileQuantityPins expectedQuantities}) => (label: label, run: () => runApplyExtractionToStockpileExpectation(initialStockpile: initialStockpile, initialDeltas: initialDeltas, extracted: extracted, expectedQuantities: expectedQuantities), refs: null);

/// One player's expected stockpile commodity quantity after [applyExtractionForPlayers].
typedef PlayerStockpilePin = ({int playerIndex, String commodityId, int quantity});

void runApplyExtractionForPlayersExpectation({required Game game, required Map<String, Map<String, int>> extractedByPlayerId, List<PlayerStockpilePin>? stockpilePins, bool expectUnchangedPlayers = false}) {
  final updated = applyExtractionForPlayers(game, extractedByPlayerId);
  if (expectUnchangedPlayers) {
    expect(updated.players, game.players);
    return;
  }
  for (final pin in stockpilePins ?? const []) {
    expect(updated.players[pin.playerIndex].stockpile.quantityOf(pin.commodityId), pin.quantity);
  }
}

ApplyExtractionForPlayersScenario applyExtractionForPlayersScenario({required String label, required Game game, required Map<String, Map<String, int>> extractedByPlayerId, List<PlayerStockpilePin>? stockpilePins, bool expectUnchangedPlayers = false}) => (label: label, run: () => runApplyExtractionForPlayersExpectation(game: game, extractedByPlayerId: extractedByPlayerId, stockpilePins: stockpilePins, expectUnchangedPlayers: expectUnchangedPlayers), refs: null);
// dart format on
