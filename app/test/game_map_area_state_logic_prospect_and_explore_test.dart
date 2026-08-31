import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show VisibilityLevel;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'game_map_area_state_logic_prospect_and_explore_support.dart';

void main() {
  suppressLogsForTests();
  group('GameMapAreaStateLogic', () {
    group('provinceProspectActionState', () {
      expectProspectExplore(
        name: 'shows enabled icon for visible, unprospected mineral tile',
        game: prospectExploreMakeGame(),
        visibility: VisibilityLevel.fullyVisible,
        showIcon: true,
        enabled: true,
        hasMatchingUnits: true,
      );
      expectProspectExplore(
        name: 'hides icon when selected tile already prospected',
        game: prospectExploreMakeGame(includeProspectedTile: true),
        visibility: VisibilityLevel.fogged,
        showIcon: false,
        enabled: false,
        hasMatchingUnits: false,
      );
      expectProspectExplore(
        name: 'shows disabled icon when human has zero explorer units',
        game: prospectExploreMakeGame(includeExplorer: false),
        visibility: VisibilityLevel.fullyVisible,
        showIcon: true,
        enabled: false,
        hasMatchingUnits: false,
      );
      expectProspectExplore(
        name:
            'shows disabled icon for Minor/Tribe province without a Consulate',
        game: prospectExploreMakeGame(
          provinceOwnerId: 'tribe1',
          tribes: const [kProspectExploreTribe],
        ),
        visibility: VisibilityLevel.fogged,
        showIcon: true,
        enabled: false,
      );
      expectProspectExplore(
        name: 'shows enabled icon for Minor/Tribe province with a Consulate',
        game: prospectExploreMakeGame(
          provinceOwnerId: 'tribe1',
          tribes: const [kProspectExploreTribe],
          overtureStates: const [
            ct_models.OvertureState(
              gpId: kProspectExploreHumanPlayerId,
              targetId: 'tribe1',
              stage: ct_models.OvertureStage.tradeConsulate,
            ),
          ],
        ),
        visibility: VisibilityLevel.fogged,
        showIcon: true,
        enabled: true,
      );
      expectProspectExplore(
        name: 'hides icon for unknown-visibility tiles',
        game: prospectExploreMakeGame(),
        visibility: VisibilityLevel.unknown,
        showIcon: false,
        enabled: false,
        hasMatchingUnits: false,
      );
      expectProspectExplore(
        name:
            'hides prospect shortcut for wool on hills when tile map marks hills',
        game: prospectExploreMakeGame(resourceOverride: 'wool'),
        visibility: VisibilityLevel.fullyVisible,
        showIcon: false,
        enabled: false,
        hasMatchingUnits: false,
        tileMapByRegion: {
          'oldWorld': TileMapResult(
            width: 1,
            height: 1,
            grid: const [
              ['p1'],
            ],
            terrainGrid: const [
              [TerrainType.hills],
            ],
            resourceGrid: const [
              [Resource.wool],
            ],
          ),
        },
      );
    });

    group('provinceExploreActionState', () {
      test(
        'shows enabled icon in partially revealed province with cached target',
        () {
          final state = prospectExploreAction(
            prospectExploreExploreGame,
            prospectExplorePartialRegion,
          );
          expect(state.showIcon, isTrue);
          expect(state.enabled, isTrue);
        },
      );

      test('hides icon when province is fully revealed', () {
        expect(
          prospectExploreAction(
            prospectExploreExploreGame,
            prospectExploreRegionWithCells(const [
              TileVisibility.fogged,
              TileVisibility.fogged,
            ]),
          ).showIcon,
          isFalse,
        );
      });

      test('shows disabled icon when no explorers exist', () {
        final game = prospectExploreExploreGame;
        final state = prospectExploreAction(
          game.copyWith(
            worldState: game.worldState.copyWith(
              oldWorld: ct_models.RegionData(
                provinces: game.worldState.oldWorld.provinces,
                units: const [],
              ),
            ),
          ),
          prospectExplorePartialRegion,
        );
        expect(state.showIcon, isTrue);
        expect(state.enabled, isFalse);
      });
    });
  });
}
