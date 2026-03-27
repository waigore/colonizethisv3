import 'package:colonizethis_app/features/game/widgets/train_unit_dialog_helper.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('initialTrainDialogCountsFromOrders', () {
    test('counts only managed train-at-capital military orders', () {
      const playerId = 'p1';
      const capital = 'r1|cap';
      final counts = initialTrainDialogCountsFromOrders(
        unitTypeIds: const ['Infantry', 'Cavalry'],
        currentOrders: const Orders(
          buildUnitOrdersByPlayerId: {
            playerId: [
              BuildUnitOrder(
                unitType: 'Infantry',
                isMilitary: true,
                spawnProvinceId: capital,
              ),
              BuildUnitOrder(
                unitType: 'Infantry',
                isMilitary: true,
                spawnProvinceId: capital,
              ),
              BuildUnitOrder(
                unitType: 'Infantry',
                isMilitary: true,
                spawnProvinceId: 'r2|elsewhere',
              ),
              BuildUnitOrder(
                unitType: 'Builder',
                isMilitary: false,
                spawnProvinceId: capital,
              ),
            ],
          },
        ),
        humanPlayerId: playerId,
        capitalProvinceId: capital,
        isMilitary: true,
      );

      expect(counts['Infantry'], 2);
      expect(counts['Cavalry'], 0);
      expect(counts.containsKey('Builder'), isFalse);
    });

    test('returns zeroed map when capital is missing', () {
      final counts = initialTrainDialogCountsFromOrders(
        unitTypeIds: const ['Builder', 'Explorer'],
        currentOrders: const Orders(),
        humanPlayerId: 'p1',
        capitalProvinceId: null,
        isMilitary: false,
      );

      expect(counts, equals(const {'Builder': 0, 'Explorer': 0}));
    });
  });

  group('materializeTrainDialogOrdersFromCounts', () {
    test('creates train orders with expected type, flag, and capital', () {
      final orders = materializeTrainDialogOrdersFromCounts(
        orderedUnitTypeIds: const ['Builder', 'Explorer'],
        counts: const {'Builder': 2, 'Explorer': 1},
        capitalProvinceId: 'r1|cap',
        isMilitary: false,
      );

      expect(orders.length, 3);
      expect(orders.where((o) => o.unitType == 'Builder').length, 2);
      expect(orders.where((o) => o.unitType == 'Explorer').length, 1);
      expect(orders.every((o) => o.isMilitary == false), isTrue);
      expect(orders.every((o) => o.spawnProvinceId == 'r1|cap'), isTrue);
    });

    test('returns empty when capital is missing', () {
      final orders = materializeTrainDialogOrdersFromCounts(
        orderedUnitTypeIds: const ['Infantry'],
        counts: const {'Infantry': 3},
        capitalProvinceId: null,
        isMilitary: true,
      );

      expect(orders, isEmpty);
    });
  });

  group('count mutation helpers', () {
    test('increment/decrement/reset helpers are consistent', () {
      final initial = <String, int>{'Builder': 1, 'Explorer': 0};
      final incremented = incrementTrainDialogCount(initial, 'Builder');
      final decremented = decrementTrainDialogCount(incremented, 'Builder');
      final unchanged = decrementTrainDialogCount(decremented, 'Explorer');
      final reset = resetTrainDialogCounts(unchanged);

      expect(initial['Builder'], 1, reason: 'helpers should be immutable');
      expect(incremented['Builder'], 2);
      expect(decremented['Builder'], 1);
      expect(unchanged['Explorer'], 0);
      expect(reset, equals(const {'Builder': 0, 'Explorer': 0}));
    });
  });
}
