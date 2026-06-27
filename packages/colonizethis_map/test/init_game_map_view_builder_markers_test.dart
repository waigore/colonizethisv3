import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'support/init_game_map_view_fixtures.dart';

void main() {
  group('buildInitGameMapViewData markers', () {
    test('uses full province ids for ownership and unit markers', () {
      final owMap = mapTileGrid([
        ['p1', 'p2'],
      ]);
      final nwMap = mapTileGrid([
        ['p1'],
      ]);
      final owTopology = regionTopology(
        regionId: 'oldWorld',
        provinceIds: const ['p1', 'p2'],
        edges: const [TopologyEdge(id1: 'p1', id2: 'p2')],
      );
      final nwTopology = regionTopology(
        regionId: 'newWorld',
        provinceIds: const ['p1'],
      );

      final game = minimalGame(
        id: 'fullIds',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
          Province(id: 'oldWorld|p2', regionId: 'oldWorld', ownerId: 'gp2'),
        ],
        oldWorldUnits: [
          Unit(
            id: 'u1',
            type: 'Army',
            ownerId: 'gp1',
            locationProvinceId: 'oldWorld|p1',
            status: UnitStatus.idle,
          ),
        ],
        newWorldProvinces: const [
          Province(id: 'newWorld|p1', regionId: 'newWorld', ownerId: 'gp3'),
        ],
        players: const [
          Player(id: 'gp1', displayName: 'GP1', isHuman: false),
          Player(id: 'gp2', displayName: 'GP2', isHuman: false),
          Player(id: 'gp3', displayName: 'GP3', isHuman: false),
        ],
      );

      final viewData = buildInitGameMapViewData(
        game: game,
        tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
        topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
        cellSize: 8,
      );

      final owCells = viewData.oldWorld.cells.where((c) => !c.isSea).toList();
      expect(owCells.length, 2);
      final p1Cell = owCells.singleWhere((c) => c.regionCellId == 'p1');
      final p2Cell = owCells.singleWhere((c) => c.regionCellId == 'p2');
      expect(p1Cell.ownerFactionId, 'gp1');
      expect(p2Cell.ownerFactionId, 'gp2');

      // Unit marker for gp1 is placed in province p1 (x = 0).
      expect(viewData.oldWorld.unitMarkers, hasLength(1));
      final marker = viewData.oldWorld.unitMarkers.single;
      expect(marker.ownerFactionId, 'gp1');
      expect(marker.x, 0);
      expect(marker.y, 0);
    });

    test(
      'includes capital markers for minor nations and tribes with null displayName',
      () {
        final owMap = mapTileGrid([
          ['p1', 's1'],
          ['s1', 's1'],
        ]);
        final nwMap = mapTileGrid([
          ['p1', 's1'],
          ['s1', 's1'],
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
          seaZoneIds: const ['s1'],
          edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
        );
        final game = minimalGame(
          id: 'capitals',
          oldWorldProvinces: const [
            Province(
              id: 'oldWorld|p1',
              regionId: 'oldWorld',
              displayName: 'OW',
            ),
          ],
          newWorldProvinces: const [
            Province(
              id: 'newWorld|p1',
              regionId: 'newWorld',
              displayName: 'NW',
            ),
          ],
          minorNations: [
            MinorNation(
              id: 'minor1',
              displayName: null,
              capitalTile: CapitalTile(
                regionId: 'oldWorld',
                provinceId: 'oldWorld|p1',
                x: 0,
                y: 0,
              ),
            ),
          ],
          tribes: [
            Tribe(
              id: 'tribe1',
              displayName: null,
              capitalTile: CapitalTile(
                regionId: 'newWorld',
                provinceId: 'newWorld|p1',
                x: 0,
                y: 0,
              ),
            ),
          ],
        );

        final viewData = buildInitGameMapViewData(
          game: game,
          tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
          topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
          cellSize: 8,
        );

        expect(viewData.oldWorld.capitalMarkers, hasLength(1));
        expect(viewData.oldWorld.capitalMarkers.single.factionId, 'minor1');
        expect(viewData.oldWorld.capitalMarkers.single.displayName, 'minor1');

        expect(viewData.newWorld.capitalMarkers, hasLength(1));
        expect(viewData.newWorld.capitalMarkers.single.factionId, 'tribe1');
        expect(viewData.newWorld.capitalMarkers.single.displayName, 'tribe1');
      },
    );

    test('includes port markers from portsByProvinceSeaboard', () {
      final owMap = mapTileGrid([
        ['p1', 's1'],
        ['s1', 's1'],
      ]);
      final nwMap = mapTileGrid([
        ['p1', 's1'],
        ['s1', 's1'],
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
        seaZoneIds: const ['s1'],
        edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
      );
      final game = minimalGame(
        id: 'ports',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
        ],
        newWorldProvinces: const [
          Province(id: 'newWorld|p1', regionId: 'newWorld'),
        ],
        portsByProvinceSeaboard: const {
          'oldWorld|p1|seaboard': 'oldWorld|p1|0|1',
        },
      );

      final viewData = buildInitGameMapViewData(
        game: game,
        tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
        topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
        cellSize: 8,
      );

      expect(viewData.oldWorld.portMarkers, hasLength(1));
      expect(viewData.oldWorld.portMarkers.single.x, 0);
      expect(viewData.oldWorld.portMarkers.single.y, 1);
      expect(viewData.oldWorld.portMarkers.single.provinceId, 'p1');
      expect(
        viewData.oldWorld.portMarkers.single.seaboardKey,
        'oldWorld|p1|seaboard',
      );
    });
  });
}
