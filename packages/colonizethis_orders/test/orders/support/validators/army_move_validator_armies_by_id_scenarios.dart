// Table-driven ArmyMoveValidator armiesById scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'army_move_validator_armies_by_id_expectations.dart';

/// One row in [armyMoveValidatorArmiesByIdScenarios].
class ArmyMoveValidatorArmiesByIdScenario implements RefsScenario {
  const ArmyMoveValidatorArmiesByIdScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final ArmyMoveValidatorArmiesByIdTarget target;
  @override
  final String? refs;
}

void runArmyMoveValidatorArmiesByIdScenario(
  ArmyMoveValidatorArmiesByIdScenario scenario,
) {
  runArmyMoveValidatorArmiesByIdExpectation(scenario.target);
}

List<ArmyMoveValidatorArmiesByIdScenario> armyMoveValidatorArmiesByIdScenarios() =>
    const [
      ArmyMoveValidatorArmiesByIdScenario(
        label: 'accepted result is identical with and without supplied armiesById',
        target: ArmyMoveValidatorArmiesByIdTarget.acceptedIdenticalWithAndWithout,
        refs: '#2394',
      ),
      ArmyMoveValidatorArmiesByIdScenario(
        label: 'rejected result is identical with and without supplied armiesById',
        target: ArmyMoveValidatorArmiesByIdTarget.rejectedIdenticalWithAndWithout,
        refs: '#2394',
      ),
      ArmyMoveValidatorArmiesByIdScenario(
        label: 'armiesById missing the target army id is rejected as Invalid army move',
        target: ArmyMoveValidatorArmiesByIdTarget.missingArmyIdRejected,
        refs: '#2394',
      ),
      ArmyMoveValidatorArmiesByIdScenario(
        label: 'IncrementalCandidateValidator.isArmyMoveAccepted matches ArmyMoveValidator.validate (Refs #2394 incremental hot path)',
        target: ArmyMoveValidatorArmiesByIdTarget.incrementalMatchesDirectValidate,
        refs: '#2394',
      ),
      ArmyMoveValidatorArmiesByIdScenario(
        label: 'factionMembership path matches legacy GP declare-war guard (Refs #2394)',
        target: ArmyMoveValidatorArmiesByIdTarget.factionMembershipDeclareWarGuard,
        refs: '#2394',
      ),
    ];
