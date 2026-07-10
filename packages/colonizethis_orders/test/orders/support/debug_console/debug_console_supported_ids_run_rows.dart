// Scenario run tear-offs for debug console supported ids (Refs #3949 wave 3).

import 'package:colonizethis_logic/debug_console_api.dart';
import 'package:colonizethis_test/test.dart';

void dcsiRunSortedCommodityIdsMatchLexicographicSort() {
  final unsorted = debugConsoleSupportedCommodityIds.toList()..sort();
  expect(debugConsoleSupportedCommodityIdsSorted, unsorted);
}

void dcsiRunSortedRegimentTypeIdsMatchLexicographicSort() {
  final unsorted = debugConsoleSupportedRegimentTypeIds.toList()..sort();
  expect(debugConsoleSupportedRegimentTypeIdsSorted, unsorted);
}

void dcsiRunSortedShipTypeIdsMatchLexicographicSort() {
  final unsorted = debugConsoleSupportedShipTypeIds.toList()..sort();
  expect(debugConsoleSupportedShipTypeIdsSorted, unsorted);
}

void dcsiRunSortedListsNonEmptyWhenCatalogsHaveEntries() {
  expect(debugConsoleSupportedCommodityIdsSorted, isNotEmpty);
  expect(debugConsoleSupportedRegimentTypeIdsSorted, isNotEmpty);
  expect(debugConsoleSupportedShipTypeIdsSorted, isNotEmpty);
}
