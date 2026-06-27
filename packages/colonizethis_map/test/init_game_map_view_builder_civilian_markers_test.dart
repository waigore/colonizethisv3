import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'support/init_game_map_view_fixtures.dart';

void main() {
  group('buildInitGameMapViewData civilian tile markers', () {
    test(
      'builds deterministic player-owned civilian tile markers with priority and stack counts',
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
          id: 'civilian_markers',
          oldWorldProvinces: const [
            Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
            Province(id: 'oldWorld|p2', regionId: 'oldWorld'),
            Province(id: 'oldWorld|p3', regionId: 'oldWorld'),
          ],
          oldWorldUnits: [
            // Same tile; representative should be Builder by priority.
            Unit(
              id: 'u_builder',
              type: kUnitTypeBuilder,
              ownerId: 'gp_human',
              locationProvinceId: 'oldWorld|p1',
              tileKey: 'oldWorld|p1|0|0',
              status: UnitStatus.working,
              assignedTileKey: 'oldWorld|p1|0|0',
            ),
            Unit(
              id: 'u_spy',
              type: kUnitTypeSpy,
              ownerId: 'gp_human',
              locationProvinceId: 'oldWorld|p1',
              tileKey: 'oldWorld|p1|0|0',
              status: UnitStatus.idle,
            ),
            Unit(
              id: 'u_engineer',
              type: kUnitTypeEngineer,
              ownerId: 'gp_human',
              locationProvinceId: 'oldWorld|p2',
              tileKey: 'oldWorld|p2|1|0',
              status: UnitStatus.idle,
            ),
            // Non-human civilian is excluded.
            Unit(
              id: 'u_ai_builder',
              type: kUnitTypeBuilder,
              ownerId: 'gp_ai',
              locationProvinceId: 'oldWorld|p3',
              tileKey: 'oldWorld|p3|2|0',
              status: UnitStatus.idle,
            ),
            // Human military is excluded.
            Unit(
              id: 'u_human_military',
              type: 'pikemen',
              ownerId: 'gp_human',
              locationProvinceId: 'oldWorld|p1',
              status: UnitStatus.idle,
            ),
            // Human civilian in other region is excluded from OW marker set.
            Unit(
              id: 'u_other_region',
              type: kUnitTypeMerchant,
              ownerId: 'gp_human',
              locationProvinceId: 'newWorld|p1',
              tileKey: 'newWorld|p1|0|0',
              status: UnitStatus.idle,
            ),
          ],
          newWorldProvinces: const [
            Province(id: 'newWorld|p1', regionId: 'newWorld'),
          ],
          players: const [
            Player(id: 'gp_human', displayName: 'Human', isHuman: true),
            Player(id: 'gp_ai', displayName: 'AI', isHuman: false),
          ],
        );

        final viewData = buildInitGameMapViewData(
          game: game,
          tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
          topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
          cellSize: 8,
        );

        final markers = viewData.oldWorld.civilianTileMarkers;
        expect(markers, hasLength(2));

        final tile00 = markers.singleWhere(
          (m) => m.tileKey == 'oldWorld|p1|0|0',
        );
        expect(tile00.stackCount, 2);
        expect(tile00.representativeUnitType, kUnitTypeBuilder);
        expect(tile00.representativeIsAssigned, isTrue);
        expect(tile00.unitIds, equals(['u_builder', 'u_spy']));
        expect(tile00.unitTypes['u_builder'], kUnitTypeBuilder);
        expect(tile00.unitTypes['u_spy'], kUnitTypeSpy);

        final tile10 = markers.singleWhere(
          (m) => m.tileKey == 'oldWorld|p2|1|0',
        );
        expect(tile10.stackCount, 1);
        expect(tile10.representativeUnitType, kUnitTypeEngineer);
        expect(tile10.representativeIsAssigned, isFalse);
        expect(tile10.unitIds, equals(['u_engineer']));
      },
    );

    test(
      'capital marker and stacked civilian marker can co-exist on same tile key',
      () {
        final owMap = mapTileGrid([
          ['p1'],
        ]);
        final nwMap = mapTileGrid([
          ['p1'],
        ]);
        final owTopology = regionTopology(
          regionId: 'oldWorld',
          provinceIds: const ['p1'],
        );
        final nwTopology = regionTopology(
          regionId: 'newWorld',
          provinceIds: const ['p1'],
        );
        final game = minimalGame(
          id: 'capital_civilian_overlap',
          oldWorldProvinces: const [
            Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
          ],
          oldWorldUnits: [
            Unit(
              id: 'u_builder',
              type: kUnitTypeBuilder,
              ownerId: 'gp1',
              locationProvinceId: 'oldWorld|p1',
              tileKey: 'oldWorld|p1|0|0',
            ),
            Unit(
              id: 'u_explorer',
              type: kUnitTypeExplorer,
              ownerId: 'gp1',
              locationProvinceId: 'oldWorld|p1',
              tileKey: 'oldWorld|p1|0|0',
            ),
          ],
          newWorldProvinces: const [
            Province(id: 'newWorld|p1', regionId: 'newWorld'),
          ],
          players: const [
            Player(
              id: 'gp1',
              displayName: 'Human',
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
        );

        final viewData = buildInitGameMapViewData(
          game: game,
          tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
          topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
          cellSize: 8,
        );

        expect(viewData.oldWorld.capitalMarkers, hasLength(1));
        final cap = viewData.oldWorld.capitalMarkers.single;
        expect(cap.x, 0);
        expect(cap.y, 0);

        expect(viewData.oldWorld.civilianTileMarkers, hasLength(1));
        final marker = viewData.oldWorld.civilianTileMarkers.single;
        expect(marker.tileKey, 'oldWorld|p1|0|0');
        expect(marker.stackCount, 2);
      },
    );
  });
}
