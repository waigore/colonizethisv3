import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

Game _gameWithUnits(List<Unit> units) {
  return Game(
    id: 'g1',
    players: const [
      Player(id: 'h1', displayName: 'Human', isHuman: true),
    ],
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            displayName: 'Alpha',
          ),
        ],
        units: units,
      ),
      newWorld: const RegionData(),
    ),
  );
}

void main() {
  group('findCiviliansMissingWorkOrders', () {
    const humanId = 'h1';

    test('lists idle civilians with no pending work order', () {
      final game = _gameWithUnits([
        Unit(
          id: 'e1',
          type: kUnitTypeExplorer,
          ownerId: humanId,
          locationProvinceId: 'oldWorld|p1',
          tileKey: 'oldWorld|p1|0|0',
        ),
        Unit(
          id: 'e2',
          type: kUnitTypeBuilder,
          ownerId: humanId,
          locationProvinceId: 'oldWorld|p1',
          tileKey: 'oldWorld|p1|1|0',
        ),
      ]);
      final missing = findCiviliansMissingWorkOrders(
        game: game,
        orders: const Orders(),
        humanPlayerId: humanId,
      );
      expect(missing.map((e) => e.unitId), ['e2', 'e1']);
      expect(missing.first.locationLabel, contains('Alpha'));
    });

    test('excludes civilians with pending work orders', () {
      final game = _gameWithUnits([
        Unit(
          id: 'e1',
          type: kUnitTypeExplorer,
          ownerId: humanId,
          locationProvinceId: 'oldWorld|p1',
          tileKey: 'oldWorld|p1|0|0',
        ),
      ]);
      final orders = Orders(
        workOrdersByPlayerId: {
          humanId: [
            WorkOrder(
              unitId: 'e1',
              target: kWorkTargetExplore,
              targetTileKey: 'oldWorld|p1|0|0',
            ),
          ],
        },
      );
      final missing = findCiviliansMissingWorkOrders(
        game: game,
        orders: orders,
        humanPlayerId: humanId,
      );
      expect(missing, isEmpty);
    });

    test('excludes working civilians and military units', () {
      final game = _gameWithUnits([
        Unit(
          id: 'w1',
          type: kUnitTypeExplorer,
          ownerId: humanId,
          locationProvinceId: 'oldWorld|p1',
          tileKey: 'oldWorld|p1|0|0',
          status: UnitStatus.working,
          currentWork: const CurrentWork(
            workTarget: kWorkTargetExplore,
            tileKey: 'oldWorld|p1|0|0',
            remainingTurns: 1,
            totalTurns: 1,
          ),
        ),
        Unit(
          id: 'm1',
          type: 'grenadiers',
          ownerId: humanId,
          locationProvinceId: 'oldWorld|p1',
          tileKey: 'oldWorld|p1|2|0',
        ),
      ]);
      final missing = findCiviliansMissingWorkOrders(
        game: game,
        orders: const Orders(),
        humanPlayerId: humanId,
      );
      expect(missing, isEmpty);
    });
    test('excludes idle Spies per UXD-002', () {
      final game = _gameWithUnits([
        Unit(
          id: 's1',
          type: kUnitTypeSpy,
          ownerId: humanId,
          locationProvinceId: 'oldWorld|p1',
          tileKey: 'oldWorld|p1|0|0',
        ),
        Unit(
          id: 'e1',
          type: kUnitTypeExplorer,
          ownerId: humanId,
          locationProvinceId: 'oldWorld|p1',
          tileKey: 'oldWorld|p1|1|0',
        ),
      ]);
      final missing = findCiviliansMissingWorkOrders(
        game: game,
        orders: const Orders(),
        humanPlayerId: humanId,
      );
      expect(missing.map((e) => e.unitId), ['e1']);
    });
  });
}
