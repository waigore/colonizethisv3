// Table-driven explorer Consulate-gate predicate scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'explorer_consulate_gate_predicate_run_rows.dart';

/// One row in [explorerConsulateGatePredicateScenarios].
class ExplorerConsulateGatePredicateScenario implements RefsScenario {
  const ExplorerConsulateGatePredicateScenario({
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

void runExplorerConsulateGatePredicateScenario(
  ExplorerConsulateGatePredicateScenario scenario,
) {
  scenario.run();
}

/// Canonical scenarios for explorer_consulate_gate_predicate family tests.
List<ExplorerConsulateGatePredicateScenario>
explorerConsulateGatePredicateScenarios() => const [
  ExplorerConsulateGatePredicateScenario(
    label: 'blocks a Minor/Tribe province when no overture exists',
    run: ecgpRunBlocksMinorTribeWhenNoOverture,
    refs: '#3753 R4',
  ),
  ExplorerConsulateGatePredicateScenario(
    label: 'blocks when the overture is below Consulate (none)',
    run: ecgpRunBlocksWhenOvertureBelowConsulate,
    refs: '#3753 R4',
  ),
  ExplorerConsulateGatePredicateScenario(
    label: 'does not block when a Consulate is held',
    run: ecgpRunDoesNotBlockWhenConsulateHeld,
    refs: '#3753 R4',
  ),
  ExplorerConsulateGatePredicateScenario(
    label: 'does not block when an Embassy (above Consulate) is held',
    run: ecgpRunDoesNotBlockWhenEmbassyHeld,
    refs: '#3753 R4b',
  ),
  ExplorerConsulateGatePredicateScenario(
    label: 'does not gate a Great Power-owned province',
    run: ecgpRunDoesNotGateGpOwnedProvince,
    refs: '#3753 R4',
  ),
  ExplorerConsulateGatePredicateScenario(
    label: 'does not gate the player own province or a null owner',
    run: ecgpRunDoesNotGateOwnProvinceOrNullOwner,
    refs: '#3753 R4',
  ),
];
