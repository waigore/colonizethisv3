import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

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
