import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

final TileMapResult _grainTileMap = singleTileMap(Resource.grain);
final TileMapResult _ironTileMap = singleTileMap(Resource.iron);

// --- Wave 2 runners (Refs #4410) ---
void runResourceExtractorScenario(ResourceExtractorScenario scenario) {
  final tileState = tileStateFromSpecs(scenario.tileSpecs);
  final tileMapByRegion = tileMapByRegionForResourceExtractor(scenario);
  final game = gameForResourceExtractor(scenario, tileState);
  if (scenario.blockadedOverseasPin != null) {
    assertBlockadedOverseasPin(
      game: game,
      tileMapByRegion: tileMapByRegion,
      pin: scenario.blockadedOverseasPin!,
    );
    return;
  }
  final captured = scenario.expectLogMessageContains != null
      ? <LogEvent>[]
      : null;
  void Function(LogEvent)? listener;
  if (captured != null) {
    listener = captured.add;
    Logger.addLogListener(listener);
    Logger.level = Level.error;
  }
  try {
    final connectivity =
        scenario.connectivityByPlayer ??
        connectivityFor(
          scenario.connected,
          pathTransportCap: scenario.pathTransportCap,
        );
    if (scenario.techCapComparisonPin != null) {
      assertTechCapComparisonPin(
        game: game,
        tileMapByRegion: tileMapByRegion,
        connectivityResult: connectivity,
        pin: scenario.techCapComparisonPin!,
      );
      return;
    }
    final result = computeExtraction(
      game: game,
      tileMapByRegion: tileMapByRegion,
      connectivityResult: connectivity,
      techCapForPlayer: scenario.techCapForPlayer ?? ((_) => scenario.techCap),
    );
    scenario.verify(result);
    if (captured != null) {
      expect(
        captured.any(
          (e) => e.message.contains(scenario.expectLogMessageContains!),
        ),
        isTrue,
      );
    }
  } finally {
    if (listener != null) {
      Logger.removeLogListener(listener);
      Logger.level = Level.off;
    }
  }
}

void main() {
  group('ResourceExtractor', () {
    runLabeledScenarios(
      resourceExtractorConnectivityCapScenarios(grainTileMap: _grainTileMap),
      (scenario) {
        runResourceExtractorScenario(scenario);
      },
      labelOf: (s) => s.label,
    );

    runLabeledScenarios(
      resourceExtractorMineralTownDevScenarios(
        ironTileMap: _ironTileMap,
        grainTileMap: _grainTileMap,
      ),
      (scenario) {
        runResourceExtractorScenario(scenario);
      },
      labelOf: (s) => s.label,
    );

    runLabeledScenarios(resourceExtractorEmptyConnectivityScenarios(), (
      scenario,
    ) {
      runResourceExtractorScenario(scenario);
    }, labelOf: (s) => s.label);

    runLabeledScenarios(
      resourceExtractorSpecialCaseScenarios(grainTileMap: _grainTileMap),
      (scenario) {
        runResourceExtractorScenario(scenario);
      },
      labelOf: (s) => s.label,
    );
  });
}
