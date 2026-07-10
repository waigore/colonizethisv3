// Table-driven debug console supported-id scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'debug_console_supported_ids_run_rows.dart';

class DebugConsoleSupportedIdsScenario implements RefsScenario {
  const DebugConsoleSupportedIdsScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

void runDebugConsoleSupportedIdsScenario(
  DebugConsoleSupportedIdsScenario scenario,
) {
  scenario.run();
}

List<DebugConsoleSupportedIdsScenario> debugConsoleSupportedIdsScenarios() =>
    const [
      DebugConsoleSupportedIdsScenario(
        label: 'sorted commodity ids match lexicographic sort of id set',
        run: dcsiRunSortedCommodityIdsMatchLexicographicSort,
      ),
      DebugConsoleSupportedIdsScenario(
        label: 'sorted regiment type ids match lexicographic sort of id set',
        run: dcsiRunSortedRegimentTypeIdsMatchLexicographicSort,
      ),
      DebugConsoleSupportedIdsScenario(
        label: 'sorted ship type ids match lexicographic sort of id set',
        run: dcsiRunSortedShipTypeIdsMatchLexicographicSort,
      ),
      DebugConsoleSupportedIdsScenario(
        label: 'sorted lists are non-empty when catalogs have entries',
        run: dcsiRunSortedListsNonEmptyWhenCatalogsHaveEntries,
      ),
    ];
