// Pure-logic tests for train dialog peasant reservation (Refs #4566).
// SPEC/ui/train-military-dialog.md, SPEC/game/workers-and-population.md.

import 'package:colonizethis_app/features/game/widgets/train/train_peasant_reservation.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

const _playerId = 'gp_human';
const _capital = 'oldWorld|cap';

Orders _orders({
  List<WorkerTier> recruits = const [],
  List<BuildUnitOrder> builds = const [],
}) {
  return Orders(
    recruitWorkerOrdersByPlayerId: {
      _playerId: [
        for (final tier in recruits) RecruitWorkerOrder(targetTier: tier),
      ],
    },
    buildUnitOrdersByPlayerId: {_playerId: builds},
  );
}

void main() {
  suppressLogsForTests();

  final regimentIds = RegimentEconomyCatalog.byId.keys.toSet();
  final shipIds = ShipEconomyCatalog.byId.keys.toSet();

  group('trainOtherFamilyPeasantReservation', () {
    test('counts worker trains and excludes managed military capital builds', () {
      final orders = _orders(
        recruits: [
          WorkerTier.peasant,
          WorkerTier.apprentice,
          WorkerTier.apprentice,
          WorkerTier.apprentice,
        ],
        builds: [
          BuildUnitOrder(
            unitType: 'peasant_levies',
            isMilitary: true,
            spawnProvinceId: _capital,
          ),
          BuildUnitOrder(
            unitType: 'peasant_levies',
            isMilitary: true,
            spawnProvinceId: _capital,
          ),
          BuildUnitOrder(
            unitType: 'carrack',
            isMilitary: false,
            spawnProvinceId: _capital,
          ),
        ],
      );
      final other = trainOtherFamilyPeasantReservation(
        currentOrders: orders,
        playerId: _playerId,
        capitalProvinceId: _capital,
        managedUnitTypeIds: regimentIds,
        managedOrdersAreMilitary: true,
      );
      expect(other.workerTraining, 3);
      expect(other.ships, 1);
      expect(other.regiments, 0);
      expect(other.total, 4);
      expect(trainAvailablePeasants(poolPeasants: 8, otherFamily: other), 4);
    });

    test('naval dialog excludes managed ships and counts regiments', () {
      final orders = _orders(
        recruits: [WorkerTier.journeyman],
        builds: [
          BuildUnitOrder(
            unitType: 'carrack',
            isMilitary: false,
            spawnProvinceId: _capital,
          ),
          BuildUnitOrder(
            unitType: 'peasant_levies',
            isMilitary: true,
            spawnProvinceId: _capital,
          ),
          BuildUnitOrder(
            unitType: 'peasant_levies',
            isMilitary: true,
            spawnProvinceId: _capital,
          ),
        ],
      );
      final other = trainOtherFamilyPeasantReservation(
        currentOrders: orders,
        playerId: _playerId,
        capitalProvinceId: _capital,
        managedUnitTypeIds: shipIds,
        managedOrdersAreMilitary: false,
      );
      expect(other.workerTraining, 1);
      expect(other.ships, 0);
      expect(other.regiments, 2);
      expect(other.total, 3);
    });

    test('zero when only this dialog managed orders are queued', () {
      final orders = _orders(
        builds: [
          BuildUnitOrder(
            unitType: 'peasant_levies',
            isMilitary: true,
            spawnProvinceId: _capital,
          ),
        ],
      );
      final other = trainOtherFamilyPeasantReservation(
        currentOrders: orders,
        playerId: _playerId,
        capitalProvinceId: _capital,
        managedUnitTypeIds: regimentIds,
        managedOrdersAreMilitary: true,
      );
      expect(other.isEmpty, isTrue);
      expect(trainAvailablePeasants(poolPeasants: 8, otherFamily: other), 8);
    });
  });
}
