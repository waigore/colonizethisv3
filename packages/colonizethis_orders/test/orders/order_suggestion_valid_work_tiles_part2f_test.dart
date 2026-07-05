import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'valid_work_tiles_test_support.dart';

void main() {
  group('getValidWorkOrderTileKeys', () {
    test(
      'suggestWorkOrders purchase_land includes target in partially revealed minor or tribe province when embassy and diplomacy gates pass',
      () {
        final provOwn = ValidWorkTilesTestSupport.provinceId(
          'own',
          regionId: ValidWorkTilesTestSupport.nw,
        );
        final provMinor = ValidWorkTilesTestSupport.provinceId(
          'm1',
          regionId: ValidWorkTilesTestSupport.nw,
        );
        final tileOwn = ValidWorkTilesTestSupport.tileKey(
          'own',
          0,
          0,
          regionId: ValidWorkTilesTestSupport.nw,
        );
        final m0 = ValidWorkTilesTestSupport.tileKey(
          'm1',
          0,
          0,
          regionId: ValidWorkTilesTestSupport.nw,
        );
        final m1 = ValidWorkTilesTestSupport.tileKey(
          'm1',
          1,
          0,
          regionId: ValidWorkTilesTestSupport.nw,
        );

        final pOwn = Province(
          id: provOwn,
          regionId: ValidWorkTilesTestSupport.nw,
          ownerId: ValidWorkTilesTestSupport.playerId,
        );
        final pMinor = Province(
          id: provMinor,
          regionId: ValidWorkTilesTestSupport.nw,
          ownerId: 'minor1',
        );
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeMerchant,
          ownerId: ValidWorkTilesTestSupport.playerId,
          locationProvinceId: provOwn,
          tileKey: tileOwn,
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: RegionData(provinces: [pOwn, pMinor], units: [unit]),
          tileKeysByRegionAndProvince:
              ValidWorkTilesTestSupport.tileKeysByProvince(
            {
              provOwn: [tileOwn],
              provMinor: [m0, m1],
            },
            regionId: ValidWorkTilesTestSupport.nw,
          ),
          resourceByTileKey: {m1: 'grain'},
          playerVisibilityByTile: {
            ValidWorkTilesTestSupport.playerId: {
              tileOwn: 'fullyVisible',
              m0: 'unknown',
              m1: 'fogged',
            },
          },
        );
        final game = Game(
          id: 'g1916pl1',
          worldState: world,
          players: [ValidWorkTilesTestSupport.playerWithTreasury()],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'Minor 1'),
          ],
          overtureStates: [ValidWorkTilesTestSupport.embassyOverture()],
        );
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'own',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'm1',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [TopologyEdge(id1: 'own', id2: 'm1')],
        );
        final view = buildPlayerView(
          game,
          topology,
          ValidWorkTilesTestSupport.playerId,
        );
        final suggestions = suggestWorkOrders(
          view,
          game,
          topology,
          const Orders(),
        );
        expect(
          suggestions.where(
            (o) =>
                o.target == kWorkTargetPurchaseLand &&
                Unit.provinceIdFromTileKey(o.targetTileKey) == provMinor,
          ),
          isNotEmpty,
        );
      },
    );

    test(
      'suggestWorkOrders purchase_land excludes partially revealed target when embassy or diplomacy preconditions fail',
      () {
        final provOwn = ValidWorkTilesTestSupport.provinceId(
          'own',
          regionId: ValidWorkTilesTestSupport.nw,
        );
        final provMinor = ValidWorkTilesTestSupport.provinceId(
          'm1',
          regionId: ValidWorkTilesTestSupport.nw,
        );
        final tileOwn = ValidWorkTilesTestSupport.tileKey(
          'own',
          0,
          0,
          regionId: ValidWorkTilesTestSupport.nw,
        );
        final m0 = ValidWorkTilesTestSupport.tileKey(
          'm1',
          0,
          0,
          regionId: ValidWorkTilesTestSupport.nw,
        );
        final m1 = ValidWorkTilesTestSupport.tileKey(
          'm1',
          1,
          0,
          regionId: ValidWorkTilesTestSupport.nw,
        );

        final pOwn = Province(
          id: provOwn,
          regionId: ValidWorkTilesTestSupport.nw,
          ownerId: ValidWorkTilesTestSupport.playerId,
        );
        final pMinor = Province(
          id: provMinor,
          regionId: ValidWorkTilesTestSupport.nw,
          ownerId: 'minor1',
        );
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeMerchant,
          ownerId: ValidWorkTilesTestSupport.playerId,
          locationProvinceId: provOwn,
          tileKey: tileOwn,
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: RegionData(provinces: [pOwn, pMinor], units: [unit]),
          tileKeysByRegionAndProvince:
              ValidWorkTilesTestSupport.tileKeysByProvince(
            {
              provOwn: [tileOwn],
              provMinor: [m0, m1],
            },
            regionId: ValidWorkTilesTestSupport.nw,
          ),
          resourceByTileKey: {m1: 'grain'},
          playerVisibilityByTile: {
            ValidWorkTilesTestSupport.playerId: {
              tileOwn: 'fullyVisible',
              m0: 'unknown',
              m1: 'fogged',
            },
          },
        );
        final game = Game(
          id: 'g1916pl2',
          worldState: world,
          players: [ValidWorkTilesTestSupport.playerWithTreasury()],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'Minor 1'),
          ],
        );
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'own',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'm1',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [TopologyEdge(id1: 'own', id2: 'm1')],
        );
        final view = buildPlayerView(
          game,
          topology,
          ValidWorkTilesTestSupport.playerId,
        );
        final suggestions = suggestWorkOrders(
          view,
          game,
          topology,
          const Orders(),
        );
        expect(
          suggestions.where(
            (o) =>
                o.target == kWorkTargetPurchaseLand &&
                Unit.provinceIdFromTileKey(o.targetTileKey) == provMinor,
          ),
          isEmpty,
        );
      },
    );
  });
}
