import 'package:colonizethis_logic/debug_console_api.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('debug console supported id lists', () {
    test('sorted commodity ids match lexicographic sort of id set', () {
      final unsorted = debugConsoleSupportedCommodityIds.toList()
        ..sort();
      expect(debugConsoleSupportedCommodityIdsSorted, unsorted);
    });

    test('sorted regiment type ids match lexicographic sort of id set', () {
      final unsorted = debugConsoleSupportedRegimentTypeIds.toList()
        ..sort();
      expect(debugConsoleSupportedRegimentTypeIdsSorted, unsorted);
    });

    test('sorted ship type ids match lexicographic sort of id set', () {
      final unsorted = debugConsoleSupportedShipTypeIds.toList()..sort();
      expect(debugConsoleSupportedShipTypeIdsSorted, unsorted);
    });

    test('sorted lists are non-empty when catalogs have entries', () {
      expect(debugConsoleSupportedCommodityIdsSorted, isNotEmpty);
      expect(debugConsoleSupportedRegimentTypeIdsSorted, isNotEmpty);
      expect(debugConsoleSupportedShipTypeIdsSorted, isNotEmpty);
    });
  });
}
