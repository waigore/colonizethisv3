// Table-driven breakAlliance validator scenarios (Refs #3949 wave 3).

import '../../scenario_runner.dart';
import 'break_alliance_validator_expectations.dart';

/// One row in breakAlliance validator scenario tables.
class BreakAllianceValidatorScenario implements RefsScenario {
  const BreakAllianceValidatorScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final BreakAllianceValidatorTarget target;
  @override
  final String? refs;
}

void runBreakAllianceValidatorScenario(BreakAllianceValidatorScenario scenario) {
  runBreakAllianceValidatorExpectation(scenario.target);
}

List<BreakAllianceValidatorScenario> breakAllianceSubValidatorScenarios() =>
    const [
      BreakAllianceValidatorScenario(
        label: 'accepts when a formal alliance exists with the GP target',
        target: BreakAllianceValidatorTarget.acceptsFormalAllianceWithGpTarget,
        refs: '#3753 R11',
      ),
      BreakAllianceValidatorScenario(
        label: 'rejects while at war (war invariant cleared the alliance)',
        target: BreakAllianceValidatorTarget.rejectsWhileAtWar,
        refs: '#3753 R11',
      ),
      BreakAllianceValidatorScenario(
        label: 'rejects when no formal alliance exists with the target',
        target: BreakAllianceValidatorTarget.rejectsNoFormalAlliance,
        refs: '#3753 R11',
      ),
      BreakAllianceValidatorScenario(
        label: 'rejects a non-Great-Power target',
        target: BreakAllianceValidatorTarget.rejectsNonGpTarget,
        refs: '#3753 R11',
      ),
    ];

List<BreakAllianceValidatorScenario>
diplomaticOrderValidatorBreakAllianceScenarios() => const [
      BreakAllianceValidatorScenario(
        label: 'accepts a valid breakAlliance order through the parent validator',
        target:
            BreakAllianceValidatorTarget.parentValidatorAcceptsValidBreakAlliance,
        refs: '#3753 R11',
      ),
    ];

/// All breakAlliance validator scenarios (union of behavior-family tables).
List<BreakAllianceValidatorScenario> breakAllianceValidatorScenarios() => [
      ...breakAllianceSubValidatorScenarios(),
      ...diplomaticOrderValidatorBreakAllianceScenarios(),
    ];
