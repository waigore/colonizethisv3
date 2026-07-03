import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  suppressLogsForTests();

  test(
    'suggestWorkOrders full-candidate snapshot remains stable (Refs #2133 AC8)',
    () {
      const playerId = 'gp1';
      const regionId = 'oldWorld';
      const homeProvince = '$regionId|p_home';
      const targetProvince = '$regionId|p_target';
      const homeVisible = '$regionId|p_home|0|0';
      const homeUnknown = '$regionId|p_home|1|0';
      const targetVisible = '$regionId|p_target|0|0';
      const targetUnknown = '$regionId|p_target|1|0';

      final explorer = Unit(
        id: 'explorer_1',
        type: kUnitTypeExplorer,
        ownerId: playerId,
        locationProvinceId: homeProvince,
        tileKey: homeVisible,
        status: UnitStatus.idle,
      );

      final game = Game(
        id: 'g_suggest_work_snapshot',
        players: const [
          Player(id: playerId, displayName: 'Human', isHuman: true),
        ],
        tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe')],
        // Refs #3753 R4: a Consulate is required to explore/prospect Tribe
        // provinces; without it the p_target candidates are gated out.
        overtureStates: const [
          OvertureState(
            gpId: playerId,
            targetId: 'tribe1',
            stage: OvertureStage.tradeConsulate,
          ),
        ],
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: homeProvince, regionId: regionId, ownerId: playerId),
              Province(
                id: targetProvince,
                regionId: regionId,
                ownerId: 'tribe1',
              ),
            ],
            units: [explorer],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: const {
            regionId: {
              homeProvince: [homeVisible, homeUnknown],
              targetProvince: [targetVisible, targetUnknown],
            },
          },
          playerVisibilityByTile: const {
            playerId: {
              homeVisible: 'fullyVisible',
              homeUnknown: 'unknown',
              targetVisible: 'fogged',
              targetUnknown: 'unknown',
            },
          },
          resourceByTileKey: const {homeVisible: 'iron', targetVisible: 'iron'},
        ),
      );
      final topology = const MapTopology(
        nodes: [
          TopologyNode(
            id: 'p_home',
            regionId: regionId,
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'p_target',
            regionId: regionId,
            type: TopologyNodeType.province,
          ),
        ],
        edges: [TopologyEdge(id1: 'p_home', id2: 'p_target')],
      );
      final view = buildPlayerView(game, topology, playerId);

      final suggestionsFirst = suggestWorkOrders(
        view,
        game,
        topology,
        const Orders(),
      );
      final suggestionsSecond = suggestWorkOrders(
        view,
        game,
        topology,
        const Orders(),
      );

      final snapshotRows = [
        for (final order in suggestionsFirst)
          '${order.unitId}|${order.target}|${order.targetTileKey}',
      ];

      expect(
        snapshotRows,
        const [
          'explorer_1|explore|oldWorld|p_home|0|0',
          'explorer_1|explore|oldWorld|p_target|0|0',
          'explorer_1|prospect|oldWorld|p_home|0|0',
          'explorer_1|prospect|oldWorld|p_target|0|0',
        ],
        reason:
            'Broad suggestWorkOrders full-candidate semantics must remain stable '
            'for deterministic explorer fixtures.',
      );
      expect(
        suggestionsSecond,
        suggestionsFirst,
        reason:
            'Repeated invocations should keep deterministic order and content.',
      );
    },
  );
}
