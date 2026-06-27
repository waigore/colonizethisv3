import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'support/init_game_map_view_fixtures.dart';

void main() {
  // Regression coverage for SPEC/ui/observe-mode.md § Map civilian markers
  // (Refs #2685): the base map view filter must not depend on Player.isHuman
  // when an explicit civilianMarkerOwnerIds set is provided.
  group('buildInitGameMapViewData civilianMarkerOwnerIds', () {
    Game twoGpGame({required bool gp1Human, required bool gp2Human}) {
      return minimalGame(
        id: 'civilian_owner_ids',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
          Province(id: 'oldWorld|p2', regionId: 'oldWorld'),
        ],
        oldWorldUnits: [
          Unit(
            id: 'gp1_builder',
            type: kUnitTypeBuilder,
            ownerId: 'gp1',
            locationProvinceId: 'oldWorld|p1',
            tileKey: 'oldWorld|p1|0|0',
            status: UnitStatus.idle,
          ),
          Unit(
            id: 'gp2_explorer',
            type: kUnitTypeExplorer,
            ownerId: 'gp2',
            locationProvinceId: 'oldWorld|p2',
            tileKey: 'oldWorld|p2|1|0',
            status: UnitStatus.idle,
          ),
        ],
        newWorldProvinces: const [
          Province(id: 'newWorld|p1', regionId: 'newWorld'),
        ],
        players: [
          Player(id: 'gp1', displayName: 'GP1', isHuman: gp1Human),
          Player(id: 'gp2', displayName: 'GP2', isHuman: gp2Human),
        ],
      );
    }

    InitGameMapViewData renderView({
      required Game game,
      required Set<String>? civilianMarkerOwnerIds,
    }) {
      final owMap = mapTileGrid(const [
        ['p1', 'p2'],
      ]);
      final nwMap = mapTileGrid(const [
        ['p1'],
      ]);
      final owTopology = regionTopology(
        regionId: 'oldWorld',
        provinceIds: const ['p1', 'p2'],
      );
      final nwTopology = regionTopology(
        regionId: 'newWorld',
        provinceIds: const ['p1'],
      );
      return buildInitGameMapViewData(
        game: game,
        tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
        topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
        cellSize: 8,
        civilianMarkerOwnerIds: civilianMarkerOwnerIds,
      );
    }

    test(
      'global observe owner set: every GP civilian gets a marker even when '
      'isHuman is false on every player (Refs #2685 AC global)',
      () {
        // Mirrors observe handoff: all players have isHuman=false.
        final game = twoGpGame(gp1Human: false, gp2Human: false);
        final view = renderView(
          game: game,
          civilianMarkerOwnerIds: {'gp1', 'gp2'},
        );

        final markers = view.oldWorld.civilianTileMarkers;
        expect(markers, hasLength(2));
        expect(
          markers.map((m) => m.tileKey).toList()..sort(),
          equals(['oldWorld|p1|0|0', 'oldWorld|p2|1|0']),
        );
      },
    );

    test(
      'player observe owner set: only the observed GP civilian gets a marker '
      '(Refs #2685 AC player)',
      () {
        final game = twoGpGame(gp1Human: false, gp2Human: false);
        final view = renderView(
          game: game,
          civilianMarkerOwnerIds: {'gp2'},
        );

        final markers = view.oldWorld.civilianTileMarkers;
        expect(markers, hasLength(1));
        expect(markers.single.tileKey, 'oldWorld|p2|1|0');
        expect(markers.single.unitIds, equals(['gp2_explorer']));
      },
    );

    test(
      'civilianMarkerOwnerIds null falls back to Player.isHuman (legacy '
      'single-player; observe-off no regression — Refs #2685 AC off)',
      () {
        final game = twoGpGame(gp1Human: true, gp2Human: false);
        final view = renderView(
          game: game,
          civilianMarkerOwnerIds: null,
        );

        final markers = view.oldWorld.civilianTileMarkers;
        expect(markers, hasLength(1));
        expect(markers.single.tileKey, 'oldWorld|p1|0|0');
        expect(markers.single.unitIds, equals(['gp1_builder']));
      },
    );

    test(
      'civilianMarkerOwnerIds null after observe handoff (no human) yields '
      'no markers — proves the legacy fallback is the documented bug '
      'callers must avoid (Refs #2685 root cause)',
      () {
        final game = twoGpGame(gp1Human: false, gp2Human: false);
        final view = renderView(
          game: game,
          civilianMarkerOwnerIds: null,
        );

        expect(view.oldWorld.civilianTileMarkers, isEmpty);
      },
    );

    test(
      'civilianMarkerOwnerIds excludes non-civilian and other-owner units '
      '(negative coverage)',
      () {
        final game = twoGpGame(gp1Human: false, gp2Human: false);
        final view = renderView(
          game: game,
          civilianMarkerOwnerIds: {'gp1'},
        );

        final markers = view.oldWorld.civilianTileMarkers;
        expect(markers, hasLength(1));
        expect(markers.single.tileKey, 'oldWorld|p1|0|0');
        expect(
          markers.single.unitIds,
          isNot(contains('gp2_explorer')),
          reason: 'gp2 owner is excluded from the owner set',
        );
      },
    );
  });
}
