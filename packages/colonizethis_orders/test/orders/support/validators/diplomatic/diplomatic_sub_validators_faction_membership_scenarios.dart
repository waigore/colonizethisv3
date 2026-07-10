// Table-driven faction-membership diplomatic sub-validator scenarios (Refs #3949 wave 3).

import '../../scenario_runner.dart';
import 'diplomatic_sub_validators_faction_membership_run_rows.dart';

/// One row in faction-membership diplomatic sub-validator scenario tables.
class DiplomaticSubValidatorsFactionMembershipScenario implements RefsScenario {
  const DiplomaticSubValidatorsFactionMembershipScenario({
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

void runDiplomaticSubValidatorsFactionMembershipScenario(
  DiplomaticSubValidatorsFactionMembershipScenario scenario,
) =>
    scenario.run();

List<DiplomaticSubValidatorsFactionMembershipScenario>
allianceSubValidatorFactionMembershipScenarios() => const [
      DiplomaticSubValidatorsFactionMembershipScenario(
        label: 'accepts known GP target identically with and without snapshot',
        run: dsfmRunAllianceAcceptsKnownGpIdenticallyWithAndWithoutSnapshot,
        refs: '#2394',
      ),
      DiplomaticSubValidatorsFactionMembershipScenario(
        label:
            'rejects non-GP target identically when snapshot has no GP membership',
        run: dsfmRunAllianceRejectsNonGpTargetIdenticallyWithSnapshot,
        refs: '#2394',
      ),
      DiplomaticSubValidatorsFactionMembershipScenario(
        label:
            'snapshot is consulted on active path: rejects target listed only in Game.players',
        run: dsfmRunAllianceSnapshotRejectsTargetListedOnlyInGamePlayers,
        refs: '#2394',
      ),
    ];

List<DiplomaticSubValidatorsFactionMembershipScenario>
establishOvertureSubValidatorFactionMembershipScenarios() => const [
      DiplomaticSubValidatorsFactionMembershipScenario(
        label: 'accepts Trade Consulate toward Minor identically with snapshot',
        run: dsfmRunEstablishOvertureAcceptsTradeConsulateTowardMinorIdenticallyWithSnapshot,
        refs: '#2394',
      ),
      DiplomaticSubValidatorsFactionMembershipScenario(
        label:
            'snapshot is consulted: rejects overture toward target absent from snapshot',
        run: dsfmRunEstablishOvertureSnapshotRejectsTargetAbsentFromSnapshot,
        refs: '#2394',
      ),
    ];

List<DiplomaticSubValidatorsFactionMembershipScenario>
diplomaticOrderValidatorFactionMembershipScenarios() => const [
      DiplomaticSubValidatorsFactionMembershipScenario(
        label:
            'accepts equivalent classification with snapshot snapshot present',
        run: dsfmRunParentValidatorAcceptsEquivalentClassificationWithSnapshot,
        refs: '#2394',
      ),
      DiplomaticSubValidatorsFactionMembershipScenario(
        label: 'snapshot is consulted on active path: rejects unknown target id',
        run: dsfmRunParentValidatorSnapshotRejectsUnknownTargetId,
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
