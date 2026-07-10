// Table-driven breakAlliance validator scenarios (Refs #3949 wave 3).

import '../../scenario_runner.dart';
import 'break_alliance_validator_run_rows.dart';

/// One row in breakAlliance validator scenario tables.
class BreakAllianceValidatorScenario implements RefsScenario {
  const BreakAllianceValidatorScenario({
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

void runBreakAllianceValidatorScenario(BreakAllianceValidatorScenario scenario) =>
    scenario.run();

List<BreakAllianceValidatorScenario> breakAllianceSubValidatorScenarios() =>
    const [
      BreakAllianceValidatorScenario(
        label: 'accepts when a formal alliance exists with the GP target',
        run: balRunAcceptsFormalAllianceWithGpTarget,
        refs: '#3753 R11',
      ),
      BreakAllianceValidatorScenario(
        label: 'rejects while at war (war invariant cleared the alliance)',
        run: balRunRejectsWhileAtWar,
        refs: '#3753 R11',
      ),
      BreakAllianceValidatorScenario(
        label: 'rejects when no formal alliance exists with the target',
        run: balRunRejectsNoFormalAlliance,
        refs: '#3753 R11',
      ),
      BreakAllianceValidatorScenario(
        label: 'rejects a non-Great-Power target',
        run: balRunRejectsNonGpTarget,
        refs: '#3753 R11',
      ),
    ];

List<BreakAllianceValidatorScenario>
diplomaticOrderValidatorBreakAllianceScenarios() => const [
      BreakAllianceValidatorScenario(
        label: 'accepts a valid breakAlliance order through the parent validator',
        run: balRunParentValidatorAcceptsValidBreakAlliance,
        refs: '#3753 R11',
      ),
    ];

/// All breakAlliance validator scenarios (union of behavior-family tables).
List<BreakAllianceValidatorScenario> breakAllianceValidatorScenarios() => [
      ...breakAllianceSubValidatorScenarios(),
      ...diplomaticOrderValidatorBreakAllianceScenarios(),
    ];
