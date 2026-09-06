import 'package:colonizethis_logic/colonizethis_logic.dart' show buildPlayerView;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'game_map_area_state_logic_build_improvement_support.dart';

void main() {
  suppressLogsForTests();
  group('GameMapAreaStateLogic', () {
    group('provinceBuildImprovementActionState', () {
      test('shows icon for improvable tile with builder units', () {
        final state = buildImprovementActionState(
          game: buildImprovementTestGame(),
        );
        expect(state.showIcon, isTrue);
        expect(state.enabled, isFalse);
        expect(state.hasMatchingUnits, isTrue);
      });

      test('hides icon when tile has no resource', () {
        final state = buildImprovementActionState(
          game: buildImprovementTestGame(
            includeResource: false,
            techUnlocked: const {},
          ),
          topology: buildImprovementTopology,
        );
        expect(state.showIcon, isFalse);
        expect(state.enabled, isFalse);
      });

      test('shows disabled icon when no builder units exist', () {
        final state = buildImprovementActionState(
          game: buildImprovementTestGame(includeBuilder: false),
          topology: buildImprovementTopology,
        );
        expect(state.showIcon, isTrue);
        expect(state.enabled, isFalse);
        expect(state.hasMatchingUnits, isFalse);
      });

      test(
        'enabled matches getValidWorkOrderTileKeysWithVisibility pipeline when topology null',
        () {
          expectBuildImprovementMatchesPipeline(
            game: buildImprovementTestGame(),
            topologyArg: null,
            view: buildImprovementPlayerView(),
            expectEnabled: false,
          );
        },
      );

      test(
        'enabled matches pipeline for assignable grain tile with topology and materials',
        () {
          final richGame = buildImprovementTestGame(
            ownerId: buildImprovementHumanPlayerId,
            stockpileQuantities: const {'lumber': 10, 'castIron': 10},
            circularSaw: true,
          );
          expectBuildImprovementMatchesPipeline(
            game: richGame,
            topologyArg: buildImprovementTopology,
            view: buildPlayerView(
              richGame,
              buildImprovementTopology,
              buildImprovementHumanPlayerId,
            ),
            expectEnabled: true,
          );
        },
      );

      test(
        'enabled matches pipeline when materials are insufficient for build_improvement',
        () {
          final brokeGame = buildImprovementTestGame(
            ownerId: buildImprovementHumanPlayerId,
            stockpileQuantities: const {},
            circularSaw: true,
          );
          expectBuildImprovementMatchesPipeline(
            game: brokeGame,
            topologyArg: buildImprovementTopology,
            view: buildPlayerView(
              brokeGame,
              buildImprovementTopology,
              buildImprovementHumanPlayerId,
            ),
            expectEnabled: false,
          );
        },
      );
    });
  });
}
