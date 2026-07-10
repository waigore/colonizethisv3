// Table-driven relation-based diplomatic sub-validator scenarios (Refs #3949 wave 3).

import '../../scenario_runner.dart';
import 'diplomatic_sub_validators_relations_expectations.dart';

/// One row in relation-based diplomatic sub-validator scenario tables.
class DiplomaticSubValidatorsRelationsScenario implements RefsScenario {
  const DiplomaticSubValidatorsRelationsScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final DiplomaticSubValidatorsRelationsTarget target;
  @override
  final String? refs;
}

void runDiplomaticSubValidatorsRelationsScenario(
  DiplomaticSubValidatorsRelationsScenario scenario,
) {
  runDiplomaticSubValidatorsRelationsExpectation(scenario.target);
}

List<DiplomaticSubValidatorsRelationsScenario> declareWarSubValidatorScenarios() =>
    const [
      DiplomaticSubValidatorsRelationsScenario(
        label: 'accepts when at peace and leaves treasury unchanged',
        target: DiplomaticSubValidatorsRelationsTarget.declareWarAcceptsAtPeace,
        refs: '#2391 AC10',
      ),
      DiplomaticSubValidatorsRelationsScenario(
        label: 'rejects when already at war and preserves treasury',
        target: DiplomaticSubValidatorsRelationsTarget.declareWarRejectsAlreadyAtWar,
        refs: '#2391 AC10',
      ),
    ];

List<DiplomaticSubValidatorsRelationsScenario> offerPeaceSubValidatorScenarios() =>
    const [
      DiplomaticSubValidatorsRelationsScenario(
        label: 'accepts when at war and leaves treasury unchanged',
        target: DiplomaticSubValidatorsRelationsTarget.offerPeaceAcceptsAtWar,
        refs: '#2391 AC10',
      ),
      DiplomaticSubValidatorsRelationsScenario(
        label: 'rejects when not at war',
        target: DiplomaticSubValidatorsRelationsTarget.offerPeaceRejectsNotAtWar,
        refs: '#2391 AC10',
      ),
    ];

List<DiplomaticSubValidatorsRelationsScenario> allianceSubValidatorScenarios() =>
    const [
      DiplomaticSubValidatorsRelationsScenario(
        label: 'rejects when target is not a Great Power',
        target: DiplomaticSubValidatorsRelationsTarget.allianceRejectsNonGpTarget,
        refs: '#2391 AC10',
      ),
      DiplomaticSubValidatorsRelationsScenario(
        label: 'rejects when at war with the target Great Power',
        target: DiplomaticSubValidatorsRelationsTarget.allianceRejectsAtWarWithTarget,
        refs: '#2391 AC10',
      ),
      DiplomaticSubValidatorsRelationsScenario(
        label: 'accepts when target is a Great Power and at peace',
        target: DiplomaticSubValidatorsRelationsTarget.allianceAcceptsGpAtPeace,
        refs: '#2391 AC10',
      ),
      DiplomaticSubValidatorsRelationsScenario(
        label: 'rejects a duplicate alliance when a formal alliance already exists',
        target:
            DiplomaticSubValidatorsRelationsTarget.allianceRejectsDuplicateFormalAlliance,
        refs: '#2391 AC10',
      ),
    ];

List<DiplomaticSubValidatorsRelationsScenario>
postBreakBilateralCooldownScenarios() => const [
      DiplomaticSubValidatorsRelationsScenario(
        label: 'blocks alliance toward the cooled-down GP',
        target: DiplomaticSubValidatorsRelationsTarget.cooldownBlocksAlliance,
        refs: '#3811 AC10',
      ),
      DiplomaticSubValidatorsRelationsScenario(
        label: 'blocks establishOverture toward the cooled-down GP',
        target: DiplomaticSubValidatorsRelationsTarget.cooldownBlocksEstablishOverture,
        refs: '#3811 AC10',
      ),
      DiplomaticSubValidatorsRelationsScenario(
        label: 'blocks establishFtp toward the cooled-down GP',
        target: DiplomaticSubValidatorsRelationsTarget.cooldownBlocksEstablishFtp,
        refs: '#3811 AC10',
      ),
      DiplomaticSubValidatorsRelationsScenario(
        label: 'blocks grantAid toward the cooled-down GP',
        target: DiplomaticSubValidatorsRelationsTarget.cooldownBlocksGrantAid,
        refs: '#3811 AC10',
      ),
      DiplomaticSubValidatorsRelationsScenario(
        label: 'blocks setSubsidy toward the cooled-down GP',
        target: DiplomaticSubValidatorsRelationsTarget.cooldownBlocksSetSubsidy,
        refs: '#3811 AC10',
      ),
      DiplomaticSubValidatorsRelationsScenario(
        label: 'declareWar remains allowed during cooldown',
        target: DiplomaticSubValidatorsRelationsTarget.cooldownDeclareWarRemainsAllowed,
        refs: '#3811 AC10',
      ),
    ];

/// All relation-based diplomatic sub-validator scenarios (union of families).
List<DiplomaticSubValidatorsRelationsScenario>
diplomaticSubValidatorsRelationsScenarios() => [
      ...declareWarSubValidatorScenarios(),
      ...offerPeaceSubValidatorScenarios(),
      ...allianceSubValidatorScenarios(),
      ...postBreakBilateralCooldownScenarios(),
    ];
