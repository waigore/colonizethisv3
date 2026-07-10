// Table-driven debug console supported-id scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'debug_console_supported_ids_expectations.dart';

class DebugConsoleSupportedIdsScenario implements RefsScenario {
  const DebugConsoleSupportedIdsScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final DebugConsoleSupportedIdsTarget target;
  @override
  final String? refs;
}

void runDebugConsoleSupportedIdsScenario(DebugConsoleSupportedIdsScenario scenario) {
  runDebugConsoleSupportedIdsExpectation(scenario.target);
}

List<DebugConsoleSupportedIdsScenario> debugConsoleSupportedIdsScenarios() =>
    const [
      DebugConsoleSupportedIdsScenario(
        label: 'sorted commodity ids match lexicographic sort of id set',
        target: DebugConsoleSupportedIdsTarget
            .sortedCommodityIdsMatchLexicographicSort,
      ),
      DebugConsoleSupportedIdsScenario(
        label: 'sorted regiment type ids match lexicographic sort of id set',
        target: DebugConsoleSupportedIdsTarget
            .sortedRegimentTypeIdsMatchLexicographicSort,
      ),
      DebugConsoleSupportedIdsScenario(
        label: 'sorted ship type ids match lexicographic sort of id set',
        target: DebugConsoleSupportedIdsTarget.sortedShipTypeIdsMatchLexicographicSort,
      ),
      DebugConsoleSupportedIdsScenario(
        label: 'sorted lists are non-empty when catalogs have entries',
        target: DebugConsoleSupportedIdsTarget
            .sortedListsNonEmptyWhenCatalogsHaveEntries,
      ),
    ];
