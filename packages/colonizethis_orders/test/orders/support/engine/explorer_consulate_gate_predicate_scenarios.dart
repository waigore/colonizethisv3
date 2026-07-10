// Table-driven explorer Consulate-gate predicate scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'explorer_consulate_gate_predicate_expectations.dart';

/// One row in [explorerConsulateGatePredicateScenarios].
class ExplorerConsulateGatePredicateScenario implements RefsScenario {
  const ExplorerConsulateGatePredicateScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final ExplorerConsulateGatePredicateTarget target;
  @override
  final String? refs;
}

void runExplorerConsulateGatePredicateScenario(
  ExplorerConsulateGatePredicateScenario scenario,
) {
  runExplorerConsulateGatePredicateExpectation(scenario.target);
}

/// Canonical scenarios for explorer_consulate_gate_predicate family tests.
List<ExplorerConsulateGatePredicateScenario>
    explorerConsulateGatePredicateScenarios() => const [
          ExplorerConsulateGatePredicateScenario(
            label: 'blocks a Minor/Tribe province when no overture exists',
            target: ExplorerConsulateGatePredicateTarget
                .blocksMinorTribeWhenNoOverture,
            refs: '#3753 R4',
          ),
          ExplorerConsulateGatePredicateScenario(
            label: 'blocks when the overture is below Consulate (none)',
            target: ExplorerConsulateGatePredicateTarget
                .blocksWhenOvertureBelowConsulate,
            refs: '#3753 R4',
          ),
          ExplorerConsulateGatePredicateScenario(
            label: 'does not block when a Consulate is held',
            target:
                ExplorerConsulateGatePredicateTarget.doesNotBlockWhenConsulateHeld,
            refs: '#3753 R4',
          ),
          ExplorerConsulateGatePredicateScenario(
            label: 'does not block when an Embassy (above Consulate) is held',
            target: ExplorerConsulateGatePredicateTarget.doesNotBlockWhenEmbassyHeld,
            refs: '#3753 R4b',
          ),
          ExplorerConsulateGatePredicateScenario(
            label: 'does not gate a Great Power-owned province',
            target:
                ExplorerConsulateGatePredicateTarget.doesNotGateGpOwnedProvince,
            refs: '#3753 R4',
          ),
          ExplorerConsulateGatePredicateScenario(
            label: 'does not gate the player own province or a null owner',
            target: ExplorerConsulateGatePredicateTarget
                .doesNotGateOwnProvinceOrNullOwner,
            refs: '#3753 R4',
          ),
        ];
