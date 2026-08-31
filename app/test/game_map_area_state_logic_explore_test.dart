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
    group('provinceExploreActionState', () {
      const humanPlayerId = 'gp1';
      const selectedTileKey = 'oldWorld|p1|0|0';
      final game = ct_models.Game(
        id: 'g',
        worldState: ct_models.WorldState(
          turnState: const ct_models.TurnState(
            phase: ct_models.TurnPhase.orders,
            turnNumber: 1,
          ),
          oldWorld: ct_models.RegionData(
            provinces: const [
              ct_models.Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
            ],
            units: [
              ct_models.Unit(
                id: 'u_explorer',
                type: ct_models.kUnitTypeExplorer,
                ownerId: humanPlayerId,
                locationProvinceId: 'oldWorld|p1',
                tileKey: selectedTileKey,
              ),
            ],
          ),
          newWorld: const ct_models.RegionData(),
        ),
        players: const [
          ct_models.Player(
            id: humanPlayerId,
            displayName: 'Human',
            isHuman: true,
          ),
        ],
      );

      RegionMapViewData regionWithCells(List<TileVisibility> vis) =>
          RegionMapViewData(
            regionId: 'oldWorld',
            width: 2,
            height: 1,
            cellSize: 16,
            cells: [
              for (var i = 0; i < vis.length; i++)
                CellViewData(
                  x: i,
                  y: 0,
                  regionCellId: 'p1',
                  isSea: false,
                  visibility: vis[i],
                ),
            ],
            capitalMarkers: const [],
            portMarkers: const [],
            factionColors: const {},
            greatPowerFactionIds: const {},
            terrainColors: const {},
            unitMarkers: const [],
          );

      final partial = regionWithCells(const [
        TileVisibility.fogged,
        TileVisibility.unrevealed,
      ]);

      ({bool showIcon, bool enabled, bool hasMatchingUnits}) explore(
        ct_models.Game g,
        RegionMapViewData region,
      ) => GameMapAreaStateLogicProvinceActions.provinceExploreActionState(
        game: g,
        humanPlayerId: humanPlayerId,
        selectedTileKey: selectedTileKey,
        selectedRegion: region,
        cachedExploreEligibleTileKeys: const {'oldWorld|p1|1|0'},
      );

      test(
        'shows enabled icon in partially revealed province with cached target',
        () {
          final state = explore(game, partial);
          expect(state.showIcon, isTrue);
          expect(state.enabled, isTrue);
        },
      );

      test('hides icon when province is fully revealed', () {
        expect(
          explore(
            game,
            regionWithCells(const [
              TileVisibility.fogged,
              TileVisibility.fogged,
            ]),
          ).showIcon,
          isFalse,
        );
      });

      test('shows disabled icon when no explorers exist', () {
        final state = explore(
          game.copyWith(
            worldState: game.worldState.copyWith(
              oldWorld: ct_models.RegionData(
                provinces: game.worldState.oldWorld.provinces,
                units: const [],
              ),
            ),
          ),
          partial,
        );
        expect(state.showIcon, isTrue);
        expect(state.enabled, isFalse);
      });
    });
  });
}
