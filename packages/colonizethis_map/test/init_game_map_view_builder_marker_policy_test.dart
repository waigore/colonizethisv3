import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
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

  group('buildInitGameMapViewData port/town co-location', () {
    test(
      'town markers: co-located port and town shifts port drawable to N sea cell',
      () {
        final owMap = mapTileGrid([
          ['p1', 's1'],
          ['p1', 'p1'],
        ]);
        final nwMap = mapTileGrid([
          ['p1'],
        ]);
        final owTopology = regionTopology(
          regionId: 'oldWorld',
          provinceIds: const ['p1'],
          seaZoneIds: const ['s1'],
          edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
        );
        final nwTopology = regionTopology(
          regionId: 'newWorld',
          provinceIds: const ['p1'],
        );
        final game = minimalGame(
          id: 'townPortColoc',
          oldWorldProvinces: const [
            Province(
              id: 'oldWorld|p1',
              regionId: 'oldWorld',
              townTileKey: 'oldWorld|p1|1|1',
            ),
          ],
          portsByProvinceSeaboard: const {
            'oldWorld|p1|seaboard': 'oldWorld|p1|1|1',
          },
        );

        final viewData = buildInitGameMapViewData(
          game: game,
          tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
          topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
          cellSize: 8,
        );

        final tm = viewData.oldWorld.townMarkers.single;
        expect(tm.isPort, isTrue);
        expect(tm.x, 1);
        expect(tm.y, 1);
        expect(tm.portIconX, 1);
        expect(tm.portIconY, 0);
      },
    );
    test(
      'town markers: isPort from seaboard key when value province segment mismatches',
      () {
        final owMap = mapTileGrid([
          ['p2', 'p2', 'p2'],
          ['p2', 'p2', 's1'],
        ]);
        final nwMap = mapTileGrid([
          ['p1'],
        ]);
        final owTopology = regionTopology(
          regionId: 'oldWorld',
          provinceIds: const ['p2'],
          seaZoneIds: const ['s1'],
          edges: const [TopologyEdge(id1: 'p2', id2: 's1')],
        );
        final nwTopology = regionTopology(
          regionId: 'newWorld',
          provinceIds: const ['p1'],
        );
        final game = minimalGame(
          id: 'nonCapitalPortKey',
          oldWorldProvinces: const [
            Province(
              id: 'oldWorld|p2',
              regionId: 'oldWorld',
              townTileKey: 'oldWorld|p2|0|0',
            ),
          ],
          portsByProvinceSeaboard: const {
            'oldWorld|p2|sb': 'oldWorld|p1|2|0',
          },
        );

        final viewData = buildInitGameMapViewData(
          game: game,
          tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
          topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
          cellSize: 8,
        );

        final tm = viewData.oldWorld.townMarkers.single;
        expect(tm.provinceId, 'p2');
        expect(tm.isPort, isTrue);
        expect(tm.portIconX, 2);
        expect(tm.portIconY, 1);
        expect(viewData.oldWorld.portMarkers.single.provinceId, 'p2');
      },
    );
  });

  group('buildInitGameMapViewData', () {
    test(
      'civilian markers include explicit owner ids when isHuman is false',
      () {
        final owMap = mapTileGrid([
          ['p1', 'p2', 'p3'],
        ]);
        final nwMap = mapTileGrid([
          ['p1'],
        ]);
        final owTopology = regionTopology(
          regionId: 'oldWorld',
          provinceIds: const ['p1', 'p2', 'p3'],
        );
        final nwTopology = regionTopology(
          regionId: 'newWorld',
          provinceIds: const ['p1'],
        );
        final game = minimalGame(
          id: 'observe_civilian_markers',
          oldWorldProvinces: const [
            Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
            Province(id: 'oldWorld|p2', regionId: 'oldWorld'),
            Province(id: 'oldWorld|p3', regionId: 'oldWorld'),
          ],
          oldWorldUnits: [
            Unit(
              id: 'u_gp1',
              type: kUnitTypeBuilder,
              ownerId: 'gp1',
              locationProvinceId: 'oldWorld|p1',
              tileKey: 'oldWorld|p1|0|0',
              status: UnitStatus.idle,
            ),
            Unit(
              id: 'u_gp2',
              type: kUnitTypeExplorer,
              ownerId: 'gp2',
              locationProvinceId: 'oldWorld|p3',
              tileKey: 'oldWorld|p3|2|0',
              status: UnitStatus.idle,
            ),
          ],
          newWorldProvinces: const [
            Province(id: 'newWorld|p1', regionId: 'newWorld'),
          ],
          players: const [
            Player(id: 'gp1', displayName: 'Spain', isHuman: false),
            Player(id: 'gp2', displayName: 'France', isHuman: false),
          ],
        );

        final defaultView = buildInitGameMapViewData(
          game: game,
          tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
          topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
          cellSize: 8,
        );
        expect(defaultView.oldWorld.civilianTileMarkers, isEmpty);

        final observeView = buildInitGameMapViewData(
          game: game,
          tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
          topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
          cellSize: 8,
          civilianMarkerOwnerIds: {'gp1', 'gp2'},
        );
        expect(observeView.oldWorld.civilianTileMarkers, hasLength(2));
      },
    );
  });
}
