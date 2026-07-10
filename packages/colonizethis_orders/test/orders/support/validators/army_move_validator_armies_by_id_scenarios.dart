// Table-driven ArmyMoveValidator armiesById scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'army_move_validator_armies_by_id_run_rows.dart';

/// One row in [armyMoveValidatorArmiesByIdScenarios].
class ArmyMoveValidatorArmiesByIdScenario implements RefsScenario {
  const ArmyMoveValidatorArmiesByIdScenario({
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

void runArmyMoveValidatorArmiesByIdScenario(
  ArmyMoveValidatorArmiesByIdScenario scenario,
) =>
    scenario.run();

List<ArmyMoveValidatorArmiesByIdScenario> armyMoveValidatorArmiesByIdScenarios() =>
    const [
      ArmyMoveValidatorArmiesByIdScenario(
        label: 'accepted result is identical with and without supplied armiesById',
        run: amvabiRunAcceptedIdenticalWithAndWithout,
        refs: '#2394',
      ),
      ArmyMoveValidatorArmiesByIdScenario(
        label: 'rejected result is identical with and without supplied armiesById',
        run: amvabiRunRejectedIdenticalWithAndWithout,
        refs: '#2394',
      ),
      ArmyMoveValidatorArmiesByIdScenario(
        label: 'armiesById missing the target army id is rejected as Invalid army move',
        run: amvabiRunMissingArmyIdRejected,
        refs: '#2394',
      ),
      ArmyMoveValidatorArmiesByIdScenario(
        label: 'IncrementalCandidateValidator.isArmyMoveAccepted matches ArmyMoveValidator.validate (Refs #2394 incremental hot path)',
        run: amvabiRunIncrementalMatchesDirectValidate,
        refs: '#2394',
      ),
      ArmyMoveValidatorArmiesByIdScenario(
        label: 'factionMembership path matches legacy GP declare-war guard (Refs #2394)',
        run: amvabiRunFactionMembershipDeclareWarGuard,
        refs: '#2394',
      ),
    ];
