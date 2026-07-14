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
        final viewData = buildViewDataForScenario(
          dualRegionScenario(
            game: game,
            oldWorldGrid: [
              ['p1', 'p1', 'p1'],
              ['p1', 'p1', 's1'],
            ],
            oldWorldTopology: regionTopology(
              regionId: 'oldWorld',
              provinceIds: const ['p1'],
              seaZoneIds: const ['s1'],
              edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
            ),
          ),
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
      final viewData = buildViewDataForScenario(
        dualRegionScenario(
          game: game,
          oldWorldGrid: const [
            ['pPlayer', 'pMinor'],
          ],
          oldWorldTopology: regionTopology(
            regionId: 'oldWorld',
            provinceIds: const ['pPlayer', 'pMinor'],
            edges: const [TopologyEdge(id1: 'pPlayer', id2: 'pMinor')],
          ),
        ),
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
        final viewData = buildViewDataForScenario(
          dualRegionScenario(
            game: game,
            oldWorldGrid: const [
              ['p1', 'p2'],
            ],
            oldWorldTopology: regionTopology(
              regionId: 'oldWorld',
              provinceIds: const ['p1', 'p2'],
            ),
          ),
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
        final viewData = buildViewDataForScenario(
          dualRegionScenario(
            game: game,
            oldWorldGrid: [
              ['p1', 's1'],
              ['p1', 'p1'],
            ],
            oldWorldTopology: regionTopology(
              regionId: 'oldWorld',
              provinceIds: const ['p1'],
              seaZoneIds: const ['s1'],
              edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
            ),
          ),
        );

        final tm = viewData.oldWorld.townMarkers.single;
        expect(tm.isPort, isTrue);
        expect(tm.portIconX, 1);
        expect(tm.portIconY, 0);
      },
    );

    test('town markers: co-located port with no orthogonal sea throws', () {
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
      final scenario = dualRegionScenario(
        game: game,
        oldWorldGrid: [
          ['p1', 'p1'],
          ['p1', 'p1'],
        ],
        oldWorldTopology: regionTopology(
          regionId: 'oldWorld',
          provinceIds: const ['p1'],
          seaZoneIds: const ['s1'],
          edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
        ),
      );

      expect(
        () => buildViewDataForScenario(scenario),
        throwsA(isA<PortDrawableSeaCellException>()),
      );
    });
  });

  group('buildInitGameMapViewData civilian tile markers', () {
    test(
      'builds deterministic player-owned civilian tile markers with priority and stack counts',
      () {
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
        final viewData = buildViewDataForScenario(
          dualRegionScenario(
            game: game,
            oldWorldGrid: const [
              ['p1', 'p2', 'p3'],
            ],
            oldWorldTopology: regionTopology(
              regionId: 'oldWorld',
              provinceIds: const ['p1', 'p2', 'p3'],
            ),
          ),
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
        final viewData = buildViewDataForScenario(
          dualRegionScenario(
            game: game,
            oldWorldGrid: const [
              ['p1'],
            ],
            oldWorldTopology: regionTopology(
              regionId: 'oldWorld',
              provinceIds: const ['p1'],
            ),
          ),
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
