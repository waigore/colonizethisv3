import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('getValidWorkOrderTileKeys', () {
    test(
      'suggestWorkOrders explore includes partially revealed province when first sorted entry tile is unknown but later tile is fogged',
      () {
        const playerId = 'gp1';
        const nw = 'newWorld';
        const provHome = '$nw|home';
        const provTarget = '$nw|tribe1';
        final tileHome = '$nw|home|0|0';
        final t0 = '$nw|tribe1|0|0';
        final t1 = '$nw|tribe1|1|0';

        final player = const Player(
          id: playerId,
          displayName: 'GP',
          isHuman: false,
        );
        final tribe = const Tribe(id: 'tribe1', displayName: 'T');
        final pHome = Province(id: provHome, regionId: nw, ownerId: playerId);
        final pTarget = Province(
          id: provTarget,
          regionId: nw,
          ownerId: 'tribe1',
        );
        final explorer = Unit(
          id: 'ex1',
          type: kUnitTypeExplorer,
          ownerId: playerId,
          locationProvinceId: provHome,
          tileKey: tileHome,
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: RegionData(provinces: [pHome, pTarget], units: [explorer]),
          tileKeysByRegionAndProvince: {
            nw: {
              provHome: [tileHome],
              provTarget: [t0, t1],
            },
          },
          playerVisibilityByTile: {
            playerId: {tileHome: 'fullyVisible', t0: 'unknown', t1: 'fogged'},
          },
        );
        final game = Game(
          id: 'g1916e1',
          worldState: world,
          players: [player],
          tribes: [tribe],
        );
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'home',
              regionId: nw,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'tribe1',
              regionId: nw,
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [TopologyEdge(id1: 'home', id2: 'tribe1')],
        );
        final view = buildPlayerView(game, topology, playerId);
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
        const playerId = 'gp1';
        const nw = 'newWorld';
        const provHome = '$nw|home';
        const provTarget = '$nw|gp2p';
        final tileHome = '$nw|home|0|0';
        final t0 = '$nw|gp2p|0|0';
        final t1 = '$nw|gp2p|1|0';

        final player = const Player(
          id: playerId,
          displayName: 'GP',
          isHuman: false,
        );
        final gp2 = const Player(id: 'gp2', displayName: 'P2', isHuman: false);
        final pHome = Province(id: provHome, regionId: nw, ownerId: playerId);
        final pTarget = Province(id: provTarget, regionId: nw, ownerId: 'gp2');
        final explorer = Unit(
          id: 'ex1',
          type: kUnitTypeExplorer,
          ownerId: playerId,
          locationProvinceId: provHome,
          tileKey: tileHome,
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: RegionData(provinces: [pHome, pTarget], units: [explorer]),
          tileKeysByRegionAndProvince: {
            nw: {
              provHome: [tileHome],
              provTarget: [t0, t1],
            },
          },
          playerVisibilityByTile: {
            playerId: {tileHome: 'fullyVisible', t0: 'unknown', t1: 'fogged'},
          },
        );
        final game = Game(
          id: 'g1916e2',
          worldState: world,
          players: [player, gp2],
        );
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'home',
              regionId: nw,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'gp2p',
              regionId: nw,
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [TopologyEdge(id1: 'home', id2: 'gp2p')],
        );
        final view = buildPlayerView(game, topology, playerId);
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
