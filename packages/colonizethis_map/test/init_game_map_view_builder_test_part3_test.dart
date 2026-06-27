import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'support/init_game_map_view_fixtures.dart';

void main() {
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
