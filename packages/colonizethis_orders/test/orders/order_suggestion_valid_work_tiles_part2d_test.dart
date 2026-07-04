import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'valid_work_tiles_test_support.dart';

void main() {
  group('getValidWorkOrderTileKeys', () {
    test(
      'suggestWorkOrders explore includes partially revealed province when first sorted entry tile is unknown but later tile is fogged',
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
          playerVisibilityByTile: {
            ValidWorkTilesTestSupport.playerId: {
              tileHome: 'fullyVisible',
              t0: 'unknown',
              t1: 'fogged',
            },
          },
        );
        final game = Game(
          id: 'g1916e1',
          worldState: world,
          players: const [ValidWorkTilesTestSupport.defaultPlayer],
          tribes: const [ValidWorkTilesTestSupport.defaultTribe],
          // Refs #3753 R4: a Consulate is required to explore Tribe provinces.
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
        final explore = suggestions
            .where((o) => o.target == kWorkTargetExplore)
            .toList();
        expect(explore, isNotEmpty);
        expect(
          explore.any(
            (o) => Unit.provinceIdFromTileKey(o.targetTileKey) == provTarget,
          ),
          isTrue,
        );
      },
    );

    test(
      'suggestWorkOrders explore excludes partially revealed province when no bundled entry tile passes move validation',
      () {
        final provHome = ValidWorkTilesTestSupport.provinceId(
          'home',
          regionId: ValidWorkTilesTestSupport.nw,
        );
        final provTarget = ValidWorkTilesTestSupport.provinceId(
          'gp2p',
          regionId: ValidWorkTilesTestSupport.nw,
        );
        final tileHome = ValidWorkTilesTestSupport.tileKey(
          'home',
          0,
          0,
          regionId: ValidWorkTilesTestSupport.nw,
        );
        final t0 = ValidWorkTilesTestSupport.tileKey(
          'gp2p',
          0,
          0,
          regionId: ValidWorkTilesTestSupport.nw,
        );
        final t1 = ValidWorkTilesTestSupport.tileKey(
          'gp2p',
          1,
          0,
          regionId: ValidWorkTilesTestSupport.nw,
        );

        final gp2 = const Player(id: 'gp2', displayName: 'P2', isHuman: false);
        final pHome = Province(
          id: provHome,
          regionId: ValidWorkTilesTestSupport.nw,
          ownerId: ValidWorkTilesTestSupport.playerId,
        );
        final pTarget = Province(
          id: provTarget,
          regionId: ValidWorkTilesTestSupport.nw,
          ownerId: 'gp2',
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
          playerVisibilityByTile: {
            ValidWorkTilesTestSupport.playerId: {
              tileHome: 'fullyVisible',
              t0: 'unknown',
              t1: 'fogged',
            },
          },
        );
        final game = Game(
          id: 'g1916e2',
          worldState: world,
          players: [ValidWorkTilesTestSupport.defaultPlayer, gp2],
        );
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'home',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'gp2p',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [TopologyEdge(id1: 'home', id2: 'gp2p')],
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
                o.target == kWorkTargetExplore &&
                Unit.provinceIdFromTileKey(o.targetTileKey) == provTarget,
          ),
          isEmpty,
        );
      },
    );
  });
}
