// Compact debug console supported-id assertions (Refs #3949 wave 3).

import 'package:colonizethis_logic/debug_console_api.dart';
import 'package:colonizethis_test/test.dart';

/// Pins for [debugConsoleSupportedIdsScenarios] rows.
enum DebugConsoleSupportedIdsTarget {
  sortedCommodityIdsMatchLexicographicSort,
  sortedRegimentTypeIdsMatchLexicographicSort,
  sortedShipTypeIdsMatchLexicographicSort,
  sortedListsNonEmptyWhenCatalogsHaveEntries,
}

void runDebugConsoleSupportedIdsExpectation(DebugConsoleSupportedIdsTarget target) {
  switch (target) {
    case DebugConsoleSupportedIdsTarget.sortedCommodityIdsMatchLexicographicSort:
      final unsorted = debugConsoleSupportedCommodityIds.toList()..sort();
      expect(debugConsoleSupportedCommodityIdsSorted, unsorted);

    case DebugConsoleSupportedIdsTarget.sortedRegimentTypeIdsMatchLexicographicSort:
      final unsorted = debugConsoleSupportedRegimentTypeIds.toList()..sort();
      expect(debugConsoleSupportedRegimentTypeIdsSorted, unsorted);

    case DebugConsoleSupportedIdsTarget.sortedShipTypeIdsMatchLexicographicSort:
      final unsorted = debugConsoleSupportedShipTypeIds.toList()..sort();
      expect(debugConsoleSupportedShipTypeIdsSorted, unsorted);

    case DebugConsoleSupportedIdsTarget.sortedListsNonEmptyWhenCatalogsHaveEntries:
      expect(debugConsoleSupportedCommodityIdsSorted, isNotEmpty);
      expect(debugConsoleSupportedRegimentTypeIdsSorted, isNotEmpty);
      expect(debugConsoleSupportedShipTypeIdsSorted, isNotEmpty);
  }
}
