import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'support/init_game_map_view_fixtures.dart';

void main() {
  group('buildInitGameMapViewData visibility and unit presence', () {
    test('applies visibilityByTile map to CellViewData.visibility', () {
      final game = minimalGame(
        id: 'visibility',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
        ],
        newWorldProvinces: const [
          Province(id: 'newWorld|p1', regionId: 'newWorld', ownerId: 'gp2'),
        ],
        players: const [
          Player(id: 'gp1', displayName: 'GP1', isHuman: false),
          Player(id: 'gp2', displayName: 'GP2', isHuman: false),
        ],
      );
      final scenario = dualRegionScenario(
        game: game,
        oldWorldGrid: const [
          ['p1', 'p1'],
        ],
        oldWorldTopology: regionTopology(
          regionId: 'oldWorld',
          provinceIds: const ['p1'],
        ),
      );

      // Two tiles in OW: (0,0) and (1,0). One tile in NW: (0,0).
      final viewData = buildViewDataForScenario(
        scenario,
        visibilityByTile: const {
          'oldWorld|p1|0|0': TileVisibility.visible,
          'oldWorld|p1|1|0': TileVisibility.fogged,
          'newWorld|p1|0|0': TileVisibility.unrevealed,
        },
      );

      // Old World visibility mapping.
      final owCells = viewData.oldWorld.cells;
      final firstOwCell = owCells.singleWhere((c) => c.x == 0 && c.y == 0);
      final secondOwCell = owCells.singleWhere((c) => c.x == 1 && c.y == 0);
      expect(firstOwCell.visibility, TileVisibility.visible);
      expect(secondOwCell.visibility, TileVisibility.fogged);

      // New World visibility mapping.
      final nwCell = viewData.newWorld.cells.single;
      expect(nwCell.visibility, TileVisibility.unrevealed);
    });

    test(
      'province unit presence shows own province counts and hides other province without visible intel',
      () {
        final game = minimalGame(
          id: 'presence_hidden_other',
          oldWorldProvinces: const [
            Province(id: 'oldWorld|pOwn', regionId: 'oldWorld', ownerId: 'gp1'),
            Province(
              id: 'oldWorld|pOther',
              regionId: 'oldWorld',
              ownerId: 'gp2',
            ),
          ],
          oldWorldUnits: [
            Unit(
              id: 'u_builder',
              type: kUnitTypeBuilder,
              ownerId: 'gp1',
              locationProvinceId: 'oldWorld|pOwn',
              status: UnitStatus.idle,
            ),
            Unit(
              id: 'u_pikemen',
              type: 'pikemen',
              ownerId: 'gp2',
              locationProvinceId: 'oldWorld|pOther',
              status: UnitStatus.idle,
            ),
          ],
          fleets: [
            Fleet(
              id: 'f_other',
              ownerId: 'gp2',
              regionId: 'oldWorld',
              inPortAtProvinceId: 'oldWorld|pOther',
              ships: [ShipInstance(id: 'ship_1', typeId: 'frigate')],
            ),
          ],
          players: const [
            Player(id: 'gp1', displayName: 'GP1', isHuman: true),
            Player(id: 'gp2', displayName: 'GP2', isHuman: false),
          ],
        );
        final viewData = buildViewDataForScenario(
          dualRegionScenario(
            game: game,
            oldWorldGrid: const [
              ['pOwn', 'pOther'],
            ],
            oldWorldTopology: regionTopology(
              regionId: 'oldWorld',
              provinceIds: const ['pOwn', 'pOther'],
              edges: const [TopologyEdge(id1: 'pOwn', id2: 'pOther')],
            ),
          ),
          visibilityByTile: const {
            'oldWorld|pOwn|0|0': TileVisibility.visible,
            'oldWorld|pOther|1|0': TileVisibility.unrevealed,
          },
        );

        final own =
            viewData.oldWorld.provinceUnitPresenceByProvinceId['oldWorld|pOwn'];
        final other = viewData
            .oldWorld
            .provinceUnitPresenceByProvinceId['oldWorld|pOther'];
        expect(own, isNotNull);
        expect(other, isNotNull);

        expect(own!.intelVisible, isTrue);
        expect(own.civilianCount, 1);
        expect(own.regimentCount, 0);
        expect(own.shipCount, 0);

        expect(other!.intelVisible, isFalse);
        expect(other.civilianCount, 0);
        expect(other.regimentCount, 1);
        expect(other.shipCount, 1);
      },
    );

    test(
      'province unit presence exposes other province counts when tile is visible',
      () {
        final game = minimalGame(
          id: 'presence_visible_other',
          oldWorldProvinces: const [
            Province(
              id: 'oldWorld|pOther',
              regionId: 'oldWorld',
              ownerId: 'gp2',
            ),
          ],
          oldWorldUnits: [
            Unit(
              id: 'u_builder_other',
              type: kUnitTypeBuilder,
              ownerId: 'gp2',
              locationProvinceId: 'oldWorld|pOther',
              status: UnitStatus.idle,
            ),
            Unit(
              id: 'u_pikemen_other',
              type: 'pikemen',
              ownerId: 'gp2',
              locationProvinceId: 'oldWorld|pOther',
              status: UnitStatus.idle,
            ),
          ],
          fleets: [
            Fleet(
              id: 'f_other_visible',
              ownerId: 'gp2',
              regionId: 'oldWorld',
              inPortAtProvinceId: 'oldWorld|pOther',
              ships: [ShipInstance(id: 'ship_7', typeId: 'frigate')],
            ),
          ],
          players: const [
            Player(id: 'gp1', displayName: 'GP1', isHuman: true),
            Player(id: 'gp2', displayName: 'GP2', isHuman: false),
          ],
        );
        final viewData = buildViewDataForScenario(
          dualRegionScenario(
            game: game,
            oldWorldGrid: const [
              ['pOther'],
            ],
            oldWorldTopology: regionTopology(
              regionId: 'oldWorld',
              provinceIds: const ['pOther'],
            ),
          ),
          visibilityByTile: const {
            'oldWorld|pOther|0|0': TileVisibility.visible,
          },
        );

        final other = viewData
            .oldWorld
            .provinceUnitPresenceByProvinceId['oldWorld|pOther'];
        expect(other, isNotNull);
        expect(other!.intelVisible, isTrue);
        expect(other.civilianCount, 1);
        expect(other.regimentCount, 1);
        expect(other.shipCount, 1);
      },
    );
  });
}
