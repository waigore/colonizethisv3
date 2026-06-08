import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_orders/src/orders/order_validation_result.dart';
import 'package:colonizethis_orders/src/orders/validators/naval_order_validator.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';


void main() {
  group('NavalOrderValidator', () {
    const ow = 'oldWorld';

    test('validateNavalMission rejects when previousRejected', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'p1',
              seaZoneId: 'sea1',
              regionId: ow,
              shipTypeIds: const ['carrack'],
            ),
          ],
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final topology = MapTopology(nodes: const [], edges: const []);
      final validator = NavalOrderValidator(
        game: game,
        topology: topology,
        playerId: 'p1',
      );
      final result = validator.validateNavalMission(
        const NavalMissionOrder(fleetId: 'f1', mission: 'patrol'),
        previousRejected: true,
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, 'Previous invalid');
    });

    test('validateNavalMission blockade requires target province', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'sea1',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'p1',
              seaZoneId: 'sea1',
              regionId: ow,
              shipTypeIds: const ['carrack'],
            ),
          ],
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final validator = NavalOrderValidator(
        game: game,
        topology: topology,
        playerId: 'p1',
      );
      final result = validator.validateNavalMission(
        NavalMissionOrder(
          fleetId: 'f1',
          mission: FleetMission.blockade.name,
          targetProvinceId: null,
        ),
        previousRejected: false,
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, 'Blockade requires a target province');
    });

    test('validateNavalMission blockade reject when target not prefixed', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'sea1',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'p1',
              seaZoneId: 'sea1',
              regionId: ow,
              shipTypeIds: const ['carrack'],
            ),
          ],
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final validator = NavalOrderValidator(
        game: game,
        topology: topology,
        playerId: 'p1',
      );
      final result = validator.validateNavalMission(
        NavalMissionOrder(
          fleetId: 'f1',
          mission: FleetMission.blockade.name,
          targetProvinceId: 'P2',
        ),
        previousRejected: false,
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, 'Blockade requires a target province');
    });

    test(
      'validateNavalMission blockade reject when blockading own province',
      () {
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'sea1',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [],
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [Province(id: '$ow|P1', regionId: ow, ownerId: 'p1')],
            ),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'f1',
                ownerId: 'p1',
                seaZoneId: 'sea1',
                regionId: ow,
                shipTypeIds: const ['carrack'],
              ),
            ],
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        );
        final validator = NavalOrderValidator(
          game: game,
          topology: topology,
          playerId: 'p1',
        );
        final result = validator.validateNavalMission(
          NavalMissionOrder(
            fleetId: 'f1',
            mission: FleetMission.blockade.name,
            targetProvinceId: '$ow|P1',
          ),
          previousRejected: false,
        );
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, 'Cannot blockade own province');
      },
    );

    test(
      'validateNavalMission accept non-blockade mission when fleet at sea',
      () {
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'sea1',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [],
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'f1',
                ownerId: 'p1',
                seaZoneId: 'sea1',
                regionId: ow,
                shipTypeIds: const ['carrack'],
              ),
            ],
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        );
        final validator = NavalOrderValidator(
          game: game,
          topology: topology,
          playerId: 'p1',
        );
        final result = validator.validateNavalMission(
          const NavalMissionOrder(fleetId: 'f1', mission: 'patrol'),
          previousRejected: false,
        );
        expect(result.status, OrderValidationStatus.accepted);
        expect(result.reason, isNull);
      },
    );

  });
}
