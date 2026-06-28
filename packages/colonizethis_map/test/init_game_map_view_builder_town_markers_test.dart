import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'support/init_game_map_view_fixtures.dart';

void main() {
  group('buildInitGameMapViewData town markers', () {
    test(
      'town markers: isPort with prefixed Province.id; port icon on port tile when separate from town',
      () {
        final owMap = mapTileGrid([
          ['p1', 'p1', 'p1'],
          ['p1', 'p1', 's1'],
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
          id: 'townPortSep',
          oldWorldProvinces: const [
            Province(
              id: 'oldWorld|p1',
              regionId: 'oldWorld',
              townTileKey: 'oldWorld|p1|0|0',
            ),
          ],
          portsByProvinceSeaboard: const {
            'oldWorld|p1|seaboard': 'oldWorld|p1|2|0',
          },
        );

        final viewData = buildInitGameMapViewData(
          game: game,
          tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
          topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
          cellSize: 8,
        );

        final tm = viewData.oldWorld.townMarkers.single;
        expect(tm.provinceId, 'p1');
        expect(tm.isPort, isTrue);
        expect(tm.isCoastal, isFalse);
        expect(tm.touchesSea, isTrue);
        expect(tm.x, 0);
        expect(tm.y, 0);
        expect(tm.portIconX, 2);
        expect(tm.portIconY, 1);
      },
    );


    test('town markers include non-player provinces with townTileKey', () {
      final owMap = mapTileGrid([
        ['pPlayer', 'pMinor'],
      ]);
      final nwMap = mapTileGrid([
        ['p1'],
      ]);
      final owTopology = regionTopology(
        regionId: 'oldWorld',
        provinceIds: const ['pPlayer', 'pMinor'],
        edges: const [TopologyEdge(id1: 'pPlayer', id2: 'pMinor')],
      );
      final nwTopology = regionTopology(
        regionId: 'newWorld',
        provinceIds: const ['p1'],
      );
      final game = minimalGame(
        id: 'town_non_player',
        oldWorldProvinces: const [
          Province(
            id: 'oldWorld|pPlayer',
            regionId: 'oldWorld',
            ownerId: 'gp1',
            townTileKey: 'oldWorld|pPlayer|0|0',
          ),
          Province(
            id: 'oldWorld|pMinor',
            regionId: 'oldWorld',
            ownerId: 'minor1',
            townTileKey: 'oldWorld|pMinor|1|0',
          ),
        ],
        players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor')],
      );

      final viewData = buildInitGameMapViewData(
        game: game,
        tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
        topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
        cellSize: 8,
      );

      expect(viewData.oldWorld.townMarkers, hasLength(2));
      final ids = viewData.oldWorld.townMarkers
          .map((m) => m.provinceId)
          .toSet();
      expect(ids, containsAll({'pPlayer', 'pMinor'}));
    });

    test(
      'town markers include non-player provinces with valid townTileKey',
      () {
        final owMap = mapTileGrid([
          ['p1', 'p2'],
        ]);
        final nwMap = mapTileGrid([
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
        final game = minimalGame(
          id: 'towns_non_player',
          oldWorldProvinces: const [
            Province(
              id: 'oldWorld|p1',
              regionId: 'oldWorld',
              ownerId: 'gp1',
              townTileKey: 'oldWorld|p1|0|0',
            ),
            Province(
              id: 'oldWorld|p2',
              regionId: 'oldWorld',
              ownerId: 'ai_minor',
              townTileKey: 'oldWorld|p2|1|0',
            ),
          ],
          players: const [
            Player(id: 'gp1', displayName: 'Player GP', isHuman: true),
          ],
          minorNations: const [
            MinorNation(id: 'ai_minor', displayName: 'AI Minor Nation'),
          ],
        );

        final viewData = buildInitGameMapViewData(
          game: game,
          tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
          topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
          cellSize: 8,
        );

        expect(viewData.oldWorld.townMarkers.length, equals(2));
        expect(
          viewData.oldWorld.townMarkers.any(
            (m) => m.provinceId == 'p1' && m.x == 0 && m.y == 0,
          ),
          isTrue,
        );
        expect(
          viewData.oldWorld.townMarkers.any(
            (m) => m.provinceId == 'p2' && m.x == 1 && m.y == 0,
          ),
          isTrue,
        );
      },
    );

    test(
      'town markers: port on capital tile places port drawable on sea by town',
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
          id: 'townPortCap',
          oldWorldProvinces: const [
            Province(
              id: 'oldWorld|p1',
              regionId: 'oldWorld',
              ownerId: 'gp1',
              townTileKey: 'oldWorld|p1|1|1',
            ),
          ],
          players: const [
            Player(
              id: 'gp1',
              displayName: 'GP',
              isHuman: true,
              capitalProvinceId: 'oldWorld|p1',
              capitalTile: CapitalTile(
                regionId: 'oldWorld',
                provinceId: 'oldWorld|p1',
                x: 0,
                y: 0,
              ),
            ),
          ],
          portsByProvinceSeaboard: const {'oldWorld|p1|sb': 'oldWorld|p1|0|0'},
        );

        final viewData = buildInitGameMapViewData(
          game: game,
          tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
          topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
          cellSize: 8,
        );

        final tm = viewData.oldWorld.townMarkers.single;
        expect(tm.isPort, isTrue);
        expect(tm.portIconX, 1);
        expect(tm.portIconY, 0);
      },
    );

    test(
      'town markers: co-located port with no orthogonal sea throws',
      () {
        final owMap = mapTileGrid([
          ['p1', 'p1'],
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
          id: 'townPortFall',
          oldWorldProvinces: const [
            Province(
              id: 'oldWorld|p1',
              regionId: 'oldWorld',
              townTileKey: 'oldWorld|p1|1|1',
            ),
          ],
          portsByProvinceSeaboard: const {'oldWorld|p1|sb': 'oldWorld|p1|1|1'},
        );

        expect(
          () => buildInitGameMapViewData(
            game: game,
            tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
            topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
            cellSize: 8,
          ),
          throwsA(isA<PortDrawableSeaCellException>()),
        );
      },
    );
  });
}
