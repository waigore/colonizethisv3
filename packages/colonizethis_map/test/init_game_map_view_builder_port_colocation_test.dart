import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'support/init_game_map_view_fixtures.dart';

void main() {
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
}
