import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'support/suggestion/valid_work_tiles_test_support.dart';

void main() {
  group('getValidWorkOrderTileKeys', () {
    test(
      'suggestWorkOrders prospect includes mineral tile in partially revealed province when first sorted entry tile is unknown',
      () {
        final provHome = ValidWorkTilesTestSupport.provinceId(
          'home',
          regionId: ValidWorkTilesTestSupport.nw,
        );
        final provTarget = ValidWorkTilesTestSupport.provinceId(
          'tribe1',
          regionId: ValidWorkTilesTestSupport.nw,
        );
        final tileHome = ValidWorkTilesTestSupport.tileKey(
          'home',
          0,
          0,
          regionId: ValidWorkTilesTestSupport.nw,
        );
        final t0 = ValidWorkTilesTestSupport.tileKey(
          'tribe1',
          0,
          0,
          regionId: ValidWorkTilesTestSupport.nw,
        );
        final t1 = ValidWorkTilesTestSupport.tileKey(
          'tribe1',
          1,
          0,
          regionId: ValidWorkTilesTestSupport.nw,
        );

        final pHome = Province(
          id: provHome,
          regionId: ValidWorkTilesTestSupport.nw,
          ownerId: ValidWorkTilesTestSupport.playerId,
        );
        final pTarget = Province(
          id: provTarget,
          regionId: ValidWorkTilesTestSupport.nw,
          ownerId: 'tribe1',
        );
        final explorer = ValidWorkTilesTestSupport.explorerUnit(
          id: 'ex1',
          locationProvinceId: provHome,
          tileKey: tileHome,
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: RegionData(provinces: [pHome, pTarget], units: [explorer]),
          tileKeysByRegionAndProvince:
              ValidWorkTilesTestSupport.tileKeysByProvince(
            {
              provHome: [tileHome],
              provTarget: [t0, t1],
            },
            regionId: ValidWorkTilesTestSupport.nw,
          ),
          resourceByTileKey: {t0: 'grain', t1: 'iron'},
          playerVisibilityByTile: {
            ValidWorkTilesTestSupport.playerId: {
              tileHome: 'fullyVisible',
              t0: 'unknown',
              t1: 'fogged',
            },
          },
        );
        final game = Game(
          id: 'g1916p1',
          worldState: world,
          players: const [ValidWorkTilesTestSupport.defaultPlayer],
          tribes: const [ValidWorkTilesTestSupport.defaultTribe],
          // Refs #3753 R4: a Consulate is required to prospect Tribe provinces.
          overtureStates: const [ValidWorkTilesTestSupport.tribeConsulateOverture],
        );
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'home',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'tribe1',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [TopologyEdge(id1: 'home', id2: 'tribe1')],
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
        final prospect = suggestions
            .where((o) => o.target == kWorkTargetProspect)
            .toList();
        expect(prospect, isNotEmpty);
        expect(prospect.any((o) => o.targetTileKey == t1), isTrue);
      },
    );

    test(
      'suggestWorkOrders prospect excludes partially revealed province when only non-eligible or already prospected mineral tiles remain',
      () {
        final provHome = ValidWorkTilesTestSupport.provinceId(
          'home',
          regionId: ValidWorkTilesTestSupport.nw,
        );
        final provTarget = ValidWorkTilesTestSupport.provinceId(
          'tribe1',
          regionId: ValidWorkTilesTestSupport.nw,
        );
        final tileHome = ValidWorkTilesTestSupport.tileKey(
          'home',
          0,
          0,
          regionId: ValidWorkTilesTestSupport.nw,
        );
        final t0 = ValidWorkTilesTestSupport.tileKey(
          'tribe1',
          0,
          0,
          regionId: ValidWorkTilesTestSupport.nw,
        );
        final t1 = ValidWorkTilesTestSupport.tileKey(
          'tribe1',
          1,
          0,
          regionId: ValidWorkTilesTestSupport.nw,
        );

        final pHome = Province(
          id: provHome,
          regionId: ValidWorkTilesTestSupport.nw,
          ownerId: ValidWorkTilesTestSupport.playerId,
        );
        final pTarget = Province(
          id: provTarget,
          regionId: ValidWorkTilesTestSupport.nw,
          ownerId: 'tribe1',
        );
        final explorer = ValidWorkTilesTestSupport.explorerUnit(
          id: 'ex1',
          locationProvinceId: provHome,
          tileKey: tileHome,
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: RegionData(provinces: [pHome, pTarget], units: [explorer]),
          tileKeysByRegionAndProvince:
              ValidWorkTilesTestSupport.tileKeysByProvince(
            {
              provHome: [tileHome],
              provTarget: [t0, t1],
            },
            regionId: ValidWorkTilesTestSupport.nw,
          ),
          resourceByTileKey: {t0: 'grain', t1: 'iron'},
          playerProspectedTiles: {
            ValidWorkTilesTestSupport.playerId: {t1},
          },
          playerVisibilityByTile: {
            ValidWorkTilesTestSupport.playerId: {
              tileHome: 'fullyVisible',
              t0: 'unknown',
              t1: 'fogged',
            },
          },
        );
        final game = Game(
          id: 'g1916p2',
          worldState: world,
          players: const [ValidWorkTilesTestSupport.defaultPlayer],
          tribes: const [ValidWorkTilesTestSupport.defaultTribe],
          // Refs #3753 R4: a Consulate is required to prospect Tribe provinces.
          overtureStates: const [ValidWorkTilesTestSupport.tribeConsulateOverture],
        );
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'home',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'tribe1',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [TopologyEdge(id1: 'home', id2: 'tribe1')],
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
          suggestions.where((o) => o.target == kWorkTargetProspect),
          isEmpty,
        );
      },
    );
  });
}
