import 'package:colonizethis_app/features/game/widgets/train_unit_dialog_helper.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

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
                unitType: kUnitTypeBuilder,
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
      expect(counts.containsKey(kUnitTypeBuilder), isFalse);
    });

    test('returns zeroed map when capital is missing', () {
      final counts = initialTrainDialogCountsFromOrders(
        unitTypeIds: const [kUnitTypeBuilder, kUnitTypeExplorer],
        currentOrders: const Orders(),
        humanPlayerId: 'p1',
        capitalProvinceId: null,
        isMilitary: false,
      );

      expect(counts, equals(const {kUnitTypeBuilder: 0, kUnitTypeExplorer: 0}));
    });
  });

  group('materializeTrainDialogOrdersFromCounts', () {
    test('creates train orders with expected type, flag, and capital', () {
      final orders = materializeTrainDialogOrdersFromCounts(
        orderedUnitTypeIds: const [kUnitTypeBuilder, kUnitTypeExplorer],
        counts: const {kUnitTypeBuilder: 2, kUnitTypeExplorer: 1},
        capitalProvinceId: 'r1|cap',
        isMilitary: false,
      );

      expect(orders.length, 3);
      expect(orders.where((o) => o.unitType == kUnitTypeBuilder).length, 2);
      expect(orders.where((o) => o.unitType == kUnitTypeExplorer).length, 1);
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
      final initial = <String, int>{kUnitTypeBuilder: 1, kUnitTypeExplorer: 0};
      final incremented = incrementTrainDialogCount(initial, kUnitTypeBuilder);
      final decremented = decrementTrainDialogCount(incremented, kUnitTypeBuilder);
      final unchanged = decrementTrainDialogCount(decremented, kUnitTypeExplorer);
      final reset = resetTrainDialogCounts(unchanged);

      expect(initial[kUnitTypeBuilder], 1, reason: 'helpers should be immutable');
      expect(incremented[kUnitTypeBuilder], 2);
      expect(decremented[kUnitTypeBuilder], 1);
      expect(unchanged[kUnitTypeExplorer], 0);
      expect(reset, equals(const {kUnitTypeBuilder: 0, kUnitTypeExplorer: 0}));
    });
  });
}
