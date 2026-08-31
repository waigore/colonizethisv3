// Concern split under repo.app_test_file_size (Refs #4013, #4352):
// provinceProspectActionState and provinceExploreActionState.

import 'package:colonizethis_app/features/game/flame/map_state/map_state.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show PlayerView, VisibilityLevel;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

/// Densified in-file helpers for prospect/explore action-state suites (Refs #4021).
void main() {
  suppressLogsForTests();
  group('GameMapAreaStateLogic', () {
    group('provinceProspectActionState', () {
      const humanPlayerId = 'gp1';
      const selectedTileKey = 'oldWorld|p1|0|0';
      const selectedProvinceId = 'oldWorld|p1';
      const tribe = ct_models.Tribe(id: 'tribe1', displayName: 'Tribe');

      ct_models.Game makeGame({
        bool includeExplorer = true,
        bool includeProspectedTile = false,
        String? resourceOverride,
        String? provinceOwnerId,
        List<ct_models.Tribe> tribes = const [],
        List<ct_models.OvertureState> overtureStates = const [],
      }) {
        final resourceByTileKey = resourceOverride != null
            ? {selectedTileKey: resourceOverride}
            : const {selectedTileKey: 'iron'};
        return ct_models.Game(
          id: 'g',
          worldState: ct_models.WorldState(
            turnState: const ct_models.TurnState(
              phase: ct_models.TurnPhase.orders,
              turnNumber: 1,
            ),
            oldWorld: ct_models.RegionData(
              provinces: [
                ct_models.Province(
                  id: selectedProvinceId,
                  regionId: 'oldWorld',
                  ownerId: provinceOwnerId,
                ),
              ],
              units: includeExplorer
                  ? [
                      ct_models.Unit(
                        id: 'u_explorer',
                        type: ct_models.kUnitTypeExplorer,
                        ownerId: humanPlayerId,
                        locationProvinceId: selectedProvinceId,
                        tileKey: selectedTileKey,
                        status: ct_models.UnitStatus.idle,
                      ),
                    ]
                  : const [],
            ),
            newWorld: const ct_models.RegionData(provinces: [], units: []),
            resourceByTileKey: resourceByTileKey,
            playerProspectedTiles: includeProspectedTile
                ? const {
                    humanPlayerId: {selectedTileKey},
                  }
                : const {},
          ),
          players: const [
            ct_models.Player(
              id: humanPlayerId,
              displayName: 'Human',
              isHuman: true,
            ),
          ],
          minorNations: const [],
          tribes: tribes,
          overtureStates: overtureStates,
        );
      }

      ({bool showIcon, bool enabled, bool hasMatchingUnits}) prospectState({
        required ct_models.Game game,
        required VisibilityLevel visibility,
        Map<String, TileMapResult>? tileMapByRegion,
      }) {
        return GameMapAreaStateLogicProvinceActions.provinceProspectActionState(
          game: game,
          humanPlayerId: humanPlayerId,
          selectedTileKey: selectedTileKey,
          playerView: PlayerView(
            playerId: humanPlayerId,
            player: const ct_models.Player(
              id: humanPlayerId,
              displayName: 'Human',
              isHuman: true,
            ),
            ownUnitsById: {},
            provincesById: {},
            visibilityByTile: {selectedTileKey: visibility},
            prospectedTiles: {},
            diplomacyByOtherId: {},
          ),
          topology: null,
          currentOrders: const ct_models.Orders(),
          tileMapByRegion: tileMapByRegion,
        );
      }

      void expectProspect({
        required String name,
        required ct_models.Game game,
        required VisibilityLevel visibility,
        required bool showIcon,
        required bool enabled,
        bool? hasMatchingUnits,
        Map<String, TileMapResult>? tileMapByRegion,
      }) {
        test(name, () {
          final state = prospectState(
            game: game,
            visibility: visibility,
            tileMapByRegion: tileMapByRegion,
          );
          expect(state.showIcon, showIcon);
          expect(state.enabled, enabled);
          if (hasMatchingUnits != null) {
            expect(state.hasMatchingUnits, hasMatchingUnits);
          }
        });
      }

      expectProspect(
        name: 'shows enabled icon for visible, unprospected mineral tile',
        game: makeGame(),
        visibility: VisibilityLevel.fullyVisible,
        showIcon: true,
        enabled: true,
        hasMatchingUnits: true,
      );
      expectProspect(
        name: 'hides icon when selected tile already prospected',
        game: makeGame(includeProspectedTile: true),
        visibility: VisibilityLevel.fogged,
        showIcon: false,
        enabled: false,
        hasMatchingUnits: false,
      );
      expectProspect(
        name: 'shows disabled icon when human has zero explorer units',
        game: makeGame(includeExplorer: false),
        visibility: VisibilityLevel.fullyVisible,
        showIcon: true,
        enabled: false,
        hasMatchingUnits: false,
      );
      // Refs #3753 R4/R4b: Minor/Tribe prospect needs Consulate+.
      expectProspect(
        name:
            'shows disabled icon for Minor/Tribe province without a Consulate',
        game: makeGame(provinceOwnerId: 'tribe1', tribes: const [tribe]),
        visibility: VisibilityLevel.fogged,
        showIcon: true,
        enabled: false,
      );
      expectProspect(
        name: 'shows enabled icon for Minor/Tribe province with a Consulate',
        game: makeGame(
          provinceOwnerId: 'tribe1',
          tribes: const [tribe],
          overtureStates: const [
            ct_models.OvertureState(
              gpId: humanPlayerId,
              targetId: 'tribe1',
              stage: ct_models.OvertureStage.tradeConsulate,
            ),
          ],
        ),
        visibility: VisibilityLevel.fogged,
        showIcon: true,
        enabled: true,
      );
      expectProspect(
        name: 'hides icon for unknown-visibility tiles',
        game: makeGame(),
        visibility: VisibilityLevel.unknown,
        showIcon: false,
        enabled: false,
        hasMatchingUnits: false,
      );
      expectProspect(
        name:
            'hides prospect shortcut for wool on hills when tile map marks hills',
        game: makeGame(resourceOverride: 'wool'),
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
}
