import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

final TileMapResult _grainTileMap = singleTileMap(Resource.grain);
final TileMapResult _ironTileMap = singleTileMap(Resource.iron);

void main() {
  group('ResourceExtractor', () {
    for (final scenario in resourceExtractorConnectivityCapScenarios(
      grainTileMap: _grainTileMap,
    )) {
      test(scenario.label, () => runResourceExtractorScenario(scenario));
    }

    test(
      resourceExtractorPlayerTechCapScenario(grainTileMap: _grainTileMap).label,
      () => runResourceExtractorScenario(
        resourceExtractorPlayerTechCapScenario(grainTileMap: _grainTileMap),
      ),
    );

    for (final scenario in resourceExtractorMineralTownDevScenarios(
      ironTileMap: _ironTileMap,
      grainTileMap: _grainTileMap,
    )) {
      test(scenario.label, () => runResourceExtractorScenario(scenario));
    }

    test(
      townRuleNonPortNoCapScenario().label,
      () => runResourceExtractorScenario(townRuleNonPortNoCapScenario()),
    );

    test(
      townRulePortCapScenario().label,
      () => runResourceExtractorScenario(townRulePortCapScenario()),
    );

    test(
      overseasExtractionScenario().label,
      () => runResourceExtractorScenario(overseasExtractionScenario()),
    );

    test(
      blockadedOverseasPortScenario().label,
      () => runResourceExtractorScenario(blockadedOverseasPortScenario()),
    );

    test(
      pathTransportCapScenario(grainTileMap: _grainTileMap).label,
      () => runResourceExtractorScenario(
        pathTransportCapScenario(grainTileMap: _grainTileMap),
      ),
    );

    for (final scenario in resourceExtractorEmptyConnectivityScenarios()) {
      test(scenario.label, () => runResourceExtractorScenario(scenario));
    }

    test(
      'skips connected tile and logs when province missing from region (world-model)',
      () {
        final captured = <LogEvent>[];
        void listener(LogEvent e) => captured.add(e);
        Logger.addLogListener(listener);
        addTearDown(() {
          Logger.removeLogListener(listener);
          captured.clear();
        });
        Logger.level = Level.error;
        addTearDown(() => Logger.level = Level.off);

        final tileMap = _grainTileMap;
        final tileState = tileStateFromSpecs(const [
          TileImprovementSpec('oldWorld|p1|0|0', improvement: 2, roadLevel: 2),
        ]);
        final player = Player(
          id: 'pl1',
          displayName: 'Spain',
          isHuman: true,
          capitalProvinceId: 'oldWorld|p1',
          capitalTile: const CapitalTile(
            regionId: 'oldWorld',
            provinceId: 'oldWorld|p1',
            x: 0,
            y: 0,
          ),
        );
        final game = TestFixtures.minimalGame(
          id: 'g1',
          capitalTileGrainBonusPerTurn: 0,
          oldWorld: const RegionData(provinces: []),
          tileState: tileState,
          players: [player],
        );
        final result = computeExtraction(
          game: game,
          tileMapByRegion: {'oldWorld': tileMap},
          connectivityResult: connectivityFor({'oldWorld|p1|0|0'}),
          techCapForPlayer: (_) => 4,
        );
        expect(result['pl1']!.land['grain'], isNull);
        expect(
          captured.any(
            (e) => e.message.contains('extraction province missing'),
          ),
          isTrue,
        );
      },
    );

    test(
      capitalGrainBonusScenario().label,
      () => runResourceExtractorScenario(capitalGrainBonusScenario()),
    );

    for (final scenario in tileExtractionContributionScenarios(
      grainTileMap: _grainTileMap,
    )) {
      test(scenario.label, () => runTileExtractionContributionScenario(scenario));
    }
  });
}
