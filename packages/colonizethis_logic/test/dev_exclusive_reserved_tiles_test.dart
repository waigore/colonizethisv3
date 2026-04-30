import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_logic/colonizethis_logic.dart';

void main() {
  group('devExclusiveReservedTileKeysForPlayer', () {
    test('includes in-progress dev work tile from world state', () {
      const playerId = 'gp1';
      const tk = 'oldWorld|p1|0|0';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [],
            units: [
              Unit(
                id: 'b1',
                type: kUnitTypeBuilder,
                ownerId: playerId,
                locationProvinceId: 'oldWorld|p1',
                status: UnitStatus.working,
                currentWork: CurrentWork(
                  workTarget: kWorkTargetBuildImprovement,
                  tileKey: tk,
                  totalTurns: 2,
                  remainingTurns: 1,
                ),
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: playerId, displayName: 'GP', isHuman: true)],
      );

      final reserved = devExclusiveReservedTileKeysForPlayer(
        game,
        const Orders(),
        playerId,
      );
      expect(reserved, contains(tk));
    });

    test('includes pending dev-exclusive work order target tiles', () {
      const playerId = 'gp1';
      const tk = 'oldWorld|p1|0|0';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: playerId, displayName: 'GP', isHuman: true)],
      );
      final orders = Orders(
        workOrdersByPlayerId: {
          playerId: [
            WorkOrder(
              unitId: 'b1',
              target: kWorkTargetBuildImprovement,
              targetTileKey: tk,
            ),
          ],
        },
      );

      final reserved = devExclusiveReservedTileKeysForPlayer(
        game,
        orders,
        playerId,
      );
      expect(reserved, contains(tk));
    });

    test('ignorePendingWorkOrderUnitId omits that unit pending only', () {
      const playerId = 'gp1';
      const tk = 'oldWorld|p1|0|0';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: playerId, displayName: 'GP', isHuman: true)],
      );
      final orders = Orders(
        workOrdersByPlayerId: {
          playerId: [
            WorkOrder(
              unitId: 'b1',
              target: kWorkTargetBuildImprovement,
              targetTileKey: tk,
            ),
          ],
        },
      );

      final forB1 = devExclusiveReservedTileKeysForPlayer(
        game,
        orders,
        playerId,
        ignorePendingWorkOrderUnitId: 'b1',
      );
      expect(forB1, isNot(contains(tk)));

      final forB2 = devExclusiveReservedTileKeysForPlayer(
        game,
        orders,
        playerId,
        ignorePendingWorkOrderUnitId: 'b2',
      );
      expect(forB2, contains(tk));
    });
  });
}
