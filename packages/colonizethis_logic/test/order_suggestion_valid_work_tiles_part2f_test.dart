import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('getValidWorkOrderTileKeys', () {
    test(
      'suggestWorkOrders purchase_land includes target in partially revealed minor or tribe province when embassy and diplomacy gates pass',
      () {
        const playerId = 'gp1';
        const nw = 'newWorld';
        const provOwn = '$nw|own';
        const provMinor = '$nw|m1';
        final tileOwn = '$nw|own|0|0';
        final m0 = '$nw|m1|0|0';
        final m1 = '$nw|m1|1|0';

        final player = Player(
          id: playerId,
          displayName: 'GP',
          isHuman: false,
          treasury: 500,
        );
        final pOwn = Province(id: provOwn, regionId: nw, ownerId: playerId);
        final pMinor = Province(id: provMinor, regionId: nw, ownerId: 'minor1');
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeMerchant,
          ownerId: playerId,
          locationProvinceId: provOwn,
          tileKey: tileOwn,
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: RegionData(provinces: [pOwn, pMinor], units: [unit]),
          tileKeysByRegionAndProvince: {
            nw: {
              provOwn: [tileOwn],
              provMinor: [m0, m1],
            },
          },
          resourceByTileKey: {m1: 'grain'},
          playerVisibilityByTile: {
            playerId: {tileOwn: 'fullyVisible', m0: 'unknown', m1: 'fogged'},
          },
        );
        final game = Game(
          id: 'g1916pl1',
          worldState: world,
          players: [player],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'Minor 1'),
          ],
          overtureStates: const [
            OvertureState(
              gpId: playerId,
              targetId: 'minor1',
              stage: OvertureStage.embassy,
              sinceTurn: 0,
            ),
          ],
        );
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'own',
              regionId: nw,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'm1',
              regionId: nw,
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [TopologyEdge(id1: 'own', id2: 'm1')],
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
        const playerId = 'gp1';
        const nw = 'newWorld';
        const provOwn = '$nw|own';
        const provMinor = '$nw|m1';
        final tileOwn = '$nw|own|0|0';
        final m0 = '$nw|m1|0|0';
        final m1 = '$nw|m1|1|0';

        final player = Player(
          id: playerId,
          displayName: 'GP',
          isHuman: false,
          treasury: 500,
        );
        final pOwn = Province(id: provOwn, regionId: nw, ownerId: playerId);
        final pMinor = Province(id: provMinor, regionId: nw, ownerId: 'minor1');
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeMerchant,
          ownerId: playerId,
          locationProvinceId: provOwn,
          tileKey: tileOwn,
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: RegionData(provinces: [pOwn, pMinor], units: [unit]),
          tileKeysByRegionAndProvince: {
            nw: {
              provOwn: [tileOwn],
              provMinor: [m0, m1],
            },
          },
          resourceByTileKey: {m1: 'grain'},
          playerVisibilityByTile: {
            playerId: {tileOwn: 'fullyVisible', m0: 'unknown', m1: 'fogged'},
          },
        );
        final game = Game(
          id: 'g1916pl2',
          worldState: world,
          players: [player],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'Minor 1'),
          ],
        );
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'own',
              regionId: nw,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'm1',
              regionId: nw,
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [TopologyEdge(id1: 'own', id2: 'm1')],
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
                o.target == kWorkTargetPurchaseLand &&
                Unit.provinceIdFromTileKey(o.targetTileKey) == provMinor,
          ),
          isEmpty,
        );
      },
    );
  });
}
