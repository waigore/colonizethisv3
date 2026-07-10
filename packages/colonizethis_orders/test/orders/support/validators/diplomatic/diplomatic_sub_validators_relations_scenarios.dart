// Table-driven relation-based diplomatic sub-validator scenarios (Refs #3949 wave 3).

import '../../scenario_runner.dart';
import 'diplomatic_sub_validators_relations_run_rows.dart';

/// One row in relation-based diplomatic sub-validator scenario tables.
class DiplomaticSubValidatorsRelationsScenario implements RefsScenario {
  const DiplomaticSubValidatorsRelationsScenario({
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

void runDiplomaticSubValidatorsRelationsScenario(
  DiplomaticSubValidatorsRelationsScenario scenario,
) =>
    scenario.run();

List<DiplomaticSubValidatorsRelationsScenario> declareWarSubValidatorScenarios() =>
    const [
      DiplomaticSubValidatorsRelationsScenario(
        label: 'accepts when at peace and leaves treasury unchanged',
        run: dsrRunDeclareWarAcceptsAtPeace,
        refs: '#2391 AC10',
      ),
      DiplomaticSubValidatorsRelationsScenario(
        label: 'rejects when already at war and preserves treasury',
        run: dsrRunDeclareWarRejectsAlreadyAtWar,
        refs: '#2391 AC10',
      ),
    ];

List<DiplomaticSubValidatorsRelationsScenario> offerPeaceSubValidatorScenarios() =>
    const [
      DiplomaticSubValidatorsRelationsScenario(
        label: 'accepts when at war and leaves treasury unchanged',
        run: dsrRunOfferPeaceAcceptsAtWar,
        refs: '#2391 AC10',
      ),
      DiplomaticSubValidatorsRelationsScenario(
        label: 'rejects when not at war',
        run: dsrRunOfferPeaceRejectsNotAtWar,
        refs: '#2391 AC10',
      ),
    ];

List<DiplomaticSubValidatorsRelationsScenario> allianceSubValidatorScenarios() =>
    const [
      DiplomaticSubValidatorsRelationsScenario(
        label: 'rejects when target is not a Great Power',
        run: dsrRunAllianceRejectsNonGpTarget,
        refs: '#2391 AC10',
      ),
      DiplomaticSubValidatorsRelationsScenario(
        label: 'rejects when at war with the target Great Power',
        run: dsrRunAllianceRejectsAtWarWithTarget,
        refs: '#2391 AC10',
      ),
      DiplomaticSubValidatorsRelationsScenario(
        label: 'accepts when target is a Great Power and at peace',
        run: dsrRunAllianceAcceptsGpAtPeace,
        refs: '#2391 AC10',
      ),
      DiplomaticSubValidatorsRelationsScenario(
        label: 'rejects a duplicate alliance when a formal alliance already exists',
        run: dsrRunAllianceRejectsDuplicateFormalAlliance,
        refs: '#2391 AC10',
      ),
    ];

List<DiplomaticSubValidatorsRelationsScenario>
postBreakBilateralCooldownScenarios() => const [
      DiplomaticSubValidatorsRelationsScenario(
        label: 'blocks alliance toward the cooled-down GP',
        run: dsrRunCooldownBlocksAlliance,
        refs: '#3811 AC10',
      ),
      DiplomaticSubValidatorsRelationsScenario(
        label: 'blocks establishOverture toward the cooled-down GP',
        run: dsrRunCooldownBlocksEstablishOverture,
        refs: '#3811 AC10',
      ),
      DiplomaticSubValidatorsRelationsScenario(
        label: 'blocks establishFtp toward the cooled-down GP',
        run: dsrRunCooldownBlocksEstablishFtp,
        refs: '#3811 AC10',
      ),
      DiplomaticSubValidatorsRelationsScenario(
        label: 'blocks grantAid toward the cooled-down GP',
        run: dsrRunCooldownBlocksGrantAid,
        refs: '#3811 AC10',
      ),
      DiplomaticSubValidatorsRelationsScenario(
        label: 'blocks setSubsidy toward the cooled-down GP',
        run: dsrRunCooldownBlocksSetSubsidy,
        refs: '#3811 AC10',
      ),
      DiplomaticSubValidatorsRelationsScenario(
        label: 'declareWar remains allowed during cooldown',
        run: dsrRunCooldownDeclareWarRemainsAllowed,
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
