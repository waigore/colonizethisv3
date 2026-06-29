import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('getValidWorkOrderTileKeys', () {
    test(
      'suggestWorkOrders prospect includes mineral tile in partially revealed province when first sorted entry tile is unknown',
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
          resourceByTileKey: {t0: 'grain', t1: 'iron'},
          playerVisibilityByTile: {
            playerId: {tileHome: 'fullyVisible', t0: 'unknown', t1: 'fogged'},
          },
        );
        final game = Game(
          id: 'g1916p1',
          worldState: world,
          players: [player],
          tribes: [tribe],
          // Refs #3753 R4: a Consulate is required to prospect Tribe provinces.
          overtureStates: const [
            OvertureState(
              gpId: playerId,
              targetId: 'tribe1',
              stage: OvertureStage.tradeConsulate,
            ),
          ],
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
          resourceByTileKey: {t0: 'grain', t1: 'iron'},
          playerProspectedTiles: {
            playerId: {t1},
          },
          playerVisibilityByTile: {
            playerId: {tileHome: 'fullyVisible', t0: 'unknown', t1: 'fogged'},
          },
        );
        final game = Game(
          id: 'g1916p2',
          worldState: world,
          players: [player],
          tribes: [tribe],
          // Refs #3753 R4: a Consulate is required to prospect Tribe provinces.
          overtureStates: const [
            OvertureState(
              gpId: playerId,
              targetId: 'tribe1',
              stage: OvertureStage.tradeConsulate,
            ),
          ],
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
        expect(
          suggestions.where((o) => o.target == kWorkTargetProspect),
          isEmpty,
        );
      },
    );
  });
}
