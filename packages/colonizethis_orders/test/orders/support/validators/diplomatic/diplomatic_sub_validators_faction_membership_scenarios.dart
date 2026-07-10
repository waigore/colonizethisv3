// Table-driven faction-membership diplomatic sub-validator scenarios (Refs #3949 wave 3).

import '../../scenario_runner.dart';
import 'diplomatic_sub_validators_faction_membership_expectations.dart';

/// One row in faction-membership diplomatic sub-validator scenario tables.
class DiplomaticSubValidatorsFactionMembershipScenario implements RefsScenario {
  const DiplomaticSubValidatorsFactionMembershipScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final DiplomaticSubValidatorsFactionMembershipTarget target;
  @override
  final String? refs;
}

void runDiplomaticSubValidatorsFactionMembershipScenario(
  DiplomaticSubValidatorsFactionMembershipScenario scenario,
) {
  runDiplomaticSubValidatorsFactionMembershipExpectation(scenario.target);
}

List<DiplomaticSubValidatorsFactionMembershipScenario>
allianceSubValidatorFactionMembershipScenarios() => const [
      DiplomaticSubValidatorsFactionMembershipScenario(
        label: 'accepts known GP target identically with and without snapshot',
        target: DiplomaticSubValidatorsFactionMembershipTarget
            .allianceAcceptsKnownGpIdenticallyWithAndWithoutSnapshot,
        refs: '#2394',
      ),
      DiplomaticSubValidatorsFactionMembershipScenario(
        label:
            'rejects non-GP target identically when snapshot has no GP membership',
        target: DiplomaticSubValidatorsFactionMembershipTarget
            .allianceRejectsNonGpTargetIdenticallyWithSnapshot,
        refs: '#2394',
      ),
      DiplomaticSubValidatorsFactionMembershipScenario(
        label:
            'snapshot is consulted on active path: rejects target listed only in Game.players',
        target: DiplomaticSubValidatorsFactionMembershipTarget
            .allianceSnapshotRejectsTargetListedOnlyInGamePlayers,
        refs: '#2394',
      ),
    ];

List<DiplomaticSubValidatorsFactionMembershipScenario>
establishOvertureSubValidatorFactionMembershipScenarios() => const [
      DiplomaticSubValidatorsFactionMembershipScenario(
        label: 'accepts Trade Consulate toward Minor identically with snapshot',
        target: DiplomaticSubValidatorsFactionMembershipTarget
            .establishOvertureAcceptsTradeConsulateTowardMinorIdenticallyWithSnapshot,
        refs: '#2394',
      ),
      DiplomaticSubValidatorsFactionMembershipScenario(
        label:
            'snapshot is consulted: rejects overture toward target absent from snapshot',
        target: DiplomaticSubValidatorsFactionMembershipTarget
            .establishOvertureSnapshotRejectsTargetAbsentFromSnapshot,
        refs: '#2394',
      ),
    ];

List<DiplomaticSubValidatorsFactionMembershipScenario>
diplomaticOrderValidatorFactionMembershipScenarios() => const [
      DiplomaticSubValidatorsFactionMembershipScenario(
        label:
            'accepts equivalent classification with snapshot snapshot present',
        target: DiplomaticSubValidatorsFactionMembershipTarget
            .parentValidatorAcceptsEquivalentClassificationWithSnapshot,
        refs: '#2394',
      ),
      DiplomaticSubValidatorsFactionMembershipScenario(
        label: 'snapshot is consulted on active path: rejects unknown target id',
        target: DiplomaticSubValidatorsFactionMembershipTarget
            .parentValidatorSnapshotRejectsUnknownTargetId,
        refs: '#2394',
      ),
    ];

/// All faction-membership diplomatic sub-validator scenarios (union of families).
List<DiplomaticSubValidatorsFactionMembershipScenario>
diplomaticSubValidatorsFactionMembershipScenarios() => [
      ...allianceSubValidatorFactionMembershipScenarios(),
      ...establishOvertureSubValidatorFactionMembershipScenarios(),
      ...diplomaticOrderValidatorFactionMembershipScenarios(),
    ];
