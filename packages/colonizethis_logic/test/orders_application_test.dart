import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:test/test.dart';

void main() {
  group('applyBuildAndWorkOrders', () {
    test('builds military unit and consumes one peasant', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(
            provinces: [Province(id: 'P1', regionId: 'oldWorld', ownerId: 'p1')],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(
            id: 'p1',
            displayName: 'A',
            isHuman: true,
            workerPool: WorkerPool(peasants: 2),
          ),
        ],
      );

      final orders = Orders(
        buildUnitOrdersByPlayerId: {
          'p1': const [
            BuildUnitOrder(
              unitType: 'Regiment',
              isMilitary: true,
              spawnProvinceId: 'P1',
            ),
          ],
        },
      );

      final next = applyBuildAndWorkOrders(game, orders);
      expect(next.players.single.workerPool.peasants, 1);
      expect(next.worldState.oldWorld.units.length, 1);
      expect(next.worldState.oldWorld.units.single.type, 'Regiment');
      expect(next.worldState.oldWorld.units.single.ownerId, 'p1');
    });

    test('sets unit status to working for WorkOrder', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(
            provinces: [Province(id: 'P1', regionId: 'oldWorld', ownerId: 'p1')],
            units: [
              Unit(
                id: 'u1',
                type: 'Builder',
                ownerId: 'p1',
                provinceId: 'P1',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'p1', displayName: 'A', isHuman: true),
        ],
      );

      final orders = Orders(
        workOrdersByPlayerId: {
          'p1': const [
            WorkOrder(unitId: 'u1', target: 'build_mine'),
          ],
        },
      );

      final next = applyBuildAndWorkOrders(game, orders);
      final unit = next.worldState.oldWorld.units.single;
      expect(unit.status, UnitStatus.working);
    });
  });
}

