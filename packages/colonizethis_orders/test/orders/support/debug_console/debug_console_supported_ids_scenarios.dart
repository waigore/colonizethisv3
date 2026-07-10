// Table-driven debug console supported-id scenarios (Refs #3949 wave 3).

import 'package:colonizethis_logic/debug_console_api.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';
// dart format off

void dcsiRunSortedCommodityIdsMatchLexicographicSort() {final unsorted = debugConsoleSupportedCommodityIds.toList()..sort(); expect(debugConsoleSupportedCommodityIdsSorted,unsorted);}

void dcsiRunSortedRegimentTypeIdsMatchLexicographicSort() {final unsorted = debugConsoleSupportedRegimentTypeIds.toList()..sort(); expect(debugConsoleSupportedRegimentTypeIdsSorted,unsorted);}

void dcsiRunSortedShipTypeIdsMatchLexicographicSort() {final unsorted = debugConsoleSupportedShipTypeIds.toList()..sort(); expect(debugConsoleSupportedShipTypeIdsSorted,unsorted);}

void dcsiRunSortedListsNonEmptyWhenCatalogsHaveEntries() {expect(debugConsoleSupportedCommodityIdsSorted,isNotEmpty); expect(debugConsoleSupportedRegimentTypeIdsSorted,isNotEmpty); expect(debugConsoleSupportedShipTypeIdsSorted,isNotEmpty);}

List<RunnableScenario> debugConsoleSupportedIdsScenarios() => [
  rs('sorted commodity ids match lexicographic sort of id set', dcsiRunSortedCommodityIdsMatchLexicographicSort),
  rs('sorted regiment type ids match lexicographic sort of id set', dcsiRunSortedRegimentTypeIdsMatchLexicographicSort),
  rs('sorted ship type ids match lexicographic sort of id set', dcsiRunSortedShipTypeIdsMatchLexicographicSort),
  rs('sorted lists are non-empty when catalogs have entries', dcsiRunSortedListsNonEmptyWhenCatalogsHaveEntries),
];
