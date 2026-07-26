import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetExplore;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_app/features/game/turn_resolution/civilians_missing_work_orders.dart';

import '../../../civilian_units_panel_test_support.dart';

void main() {
  group('findCiviliansMissingWorkOrders', () {
    const humanId = 'h1';

    test('lists idle civilians with no pending work order', () {
      final game = buildCivilianOwUnitsGame(
        id: 'g1',
        humanId: humanId,
        units: [
          civilianIdleUnit(
            id: 'e1',
            type: kUnitTypeExplorer,
            ownerId: humanId,
            provinceId: 'oldWorld|p1',
            tileKey: 'oldWorld|p1|0|0',
          ),
          civilianIdleUnit(
            id: 'e2',
            type: kUnitTypeBuilder,
            ownerId: humanId,
            provinceId: 'oldWorld|p1',
            tileKey: 'oldWorld|p1|1|0',
          ),
        ],
      );
      final missing = findCiviliansMissingWorkOrders(
        game: game,
        orders: const Orders(),
        humanPlayerId: humanId,
      );
      expect(missing.map((e) => e.unitId), ['e2', 'e1']);
      expect(missing.first.locationLabel, contains('Alpha'));
    });

    test('excludes civilians with pending work orders', () {
      final game = buildCivilianSingleUnitOwGame(
        id: 'g1',
        unitId: 'e1',
        unitType: kUnitTypeExplorer,
        humanId: humanId,
      );
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
      final game = buildCivilianOwUnitsGame(
        id: 'g1',
        humanId: humanId,
        units: [
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
        ],
      );
      final missing = findCiviliansMissingWorkOrders(
        game: game,
        orders: const Orders(),
        humanPlayerId: humanId,
      );
      expect(missing, isEmpty);
    });
  });
}
