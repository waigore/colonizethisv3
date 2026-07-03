import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('OrderEngine', () {
    test('work order prospect rejected when tile already prospected', () {
      const ow = 'oldWorld';
      const tileKey = 'oldWorld|P1|0|0';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'P1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'tribe1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: kUnitTypeExplorer,
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
                tileKey: tileKey,
              ),
            ],
          ),
          newWorld: const RegionData(),
          resourceByTileKey: const {tileKey: 'iron'},
          playerProspectedTiles: const {
            'p1': {tileKey},
          },
          playerVisibilityByTile: const {
            'p1': {tileKey: 'fogged'},
          },
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe 1')],
        // Refs #3753 R4: hold a Consulate so this test exercises the
        // already-prospected gate rather than the new consulate gate.
        overtureStates: const [
          OvertureState(
            gpId: 'p1',
            targetId: 'tribe1',
            stage: OvertureStage.tradeConsulate,
          ),
        ],
      );

      final engine = OrderEngine();
      engine.addWorkOrder(
        'p1',
        const WorkOrder(
          unitId: 'u1',
          target: kWorkTargetProspect,
          targetTileKey: tileKey,
        ),
      );
      final results = engine.validatePlayerOrdersWithContext(
        game,
        topology,
        'p1',
      );
      expect(results.length, 1);
      expect(results[0].status, OrderValidationStatus.rejected);
      expect(results[0].reason, contains('already prospected'));
    });
  });
}
