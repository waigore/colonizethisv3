// Table-driven grantAid / setSubsidy sub-validator scenarios (Refs #3949 wave 3).

import '../../scenario_runner.dart';
import 'diplomatic_sub_validators_aid_expectations.dart';

/// One row in diplomatic economic sub-validator scenario tables.
class DiplomaticSubValidatorsAidScenario implements RefsScenario {
  const DiplomaticSubValidatorsAidScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final DiplomaticSubValidatorsAidTarget target;
  @override
  final String? refs;
}

void runDiplomaticSubValidatorsAidScenario(
  DiplomaticSubValidatorsAidScenario scenario,
) {
  runDiplomaticSubValidatorsAidExpectation(scenario.target);
}

List<DiplomaticSubValidatorsAidScenario> grantAidSubValidatorScenarios() =>
    const [
      DiplomaticSubValidatorsAidScenario(
        label: 'rejects non-positive amount',
        target: DiplomaticSubValidatorsAidTarget.grantAidRejectsNonPositiveAmount,
        refs: '#2391 AC10',
      ),
      DiplomaticSubValidatorsAidScenario(
        label: 'rejects when amount is below the step',
        target: DiplomaticSubValidatorsAidTarget.grantAidRejectsAmountBelowStep,
        refs: '#2391 AC10',
      ),
      DiplomaticSubValidatorsAidScenario(
        label: 'rejects amount that is not a multiple of the step',
        target:
            DiplomaticSubValidatorsAidTarget.grantAidRejectsAmountNotMultipleOfStep,
        refs: '#2391 AC10',
      ),
      DiplomaticSubValidatorsAidScenario(
        label: 'rejects without embassy',
        target: DiplomaticSubValidatorsAidTarget.grantAidRejectsWithoutEmbassy,
        refs: '#2391 AC10',
      ),
      DiplomaticSubValidatorsAidScenario(
        label: 'rejects when treasury below amount and preserves treasury',
        target: DiplomaticSubValidatorsAidTarget.grantAidRejectsTreasuryBelowAmount,
        refs: '#2391 AC10',
      ),
      DiplomaticSubValidatorsAidScenario(
        label: 'accepts and debits treasury by the amount',
        target: DiplomaticSubValidatorsAidTarget.grantAidAcceptsAndDebitsTreasury,
        refs: '#2391 AC10',
      ),
    ];

List<DiplomaticSubValidatorsAidScenario> setSubsidySubValidatorScenarios() =>
    const [
      DiplomaticSubValidatorsAidScenario(
        label: 'rejects a zero percent',
        target: DiplomaticSubValidatorsAidTarget.setSubsidyRejectsZeroPercent,
        refs: '#3753 R3',
      ),
      DiplomaticSubValidatorsAidScenario(
        label: 'rejects a percent not a multiple of the step',
        target: DiplomaticSubValidatorsAidTarget
            .setSubsidyRejectsPercentNotMultipleOfStep,
        refs: '#3753 R3',
      ),
      DiplomaticSubValidatorsAidScenario(
        label: 'rejects a percent above the maximum',
        target: DiplomaticSubValidatorsAidTarget.setSubsidyRejectsPercentAboveMaximum,
        refs: '#3753 R3',
      ),
      DiplomaticSubValidatorsAidScenario(
        label: 'rejects without any overture',
        target: DiplomaticSubValidatorsAidTarget.setSubsidyRejectsWithoutOverture,
        refs: '#3753 R3',
      ),
      DiplomaticSubValidatorsAidScenario(
        label: 'rejects with a Trade Consulate only (Refs #3753 R2)',
        target: DiplomaticSubValidatorsAidTarget.setSubsidyRejectsTradeConsulateOnly,
        refs: '#3753 R2',
      ),
      DiplomaticSubValidatorsAidScenario(
        label: 'accepts with an embassy and leaves treasury unchanged',
        target: DiplomaticSubValidatorsAidTarget
            .setSubsidyAcceptsWithEmbassyLeavesTreasuryUnchanged,
        refs: '#3753 R3',
      ),
      DiplomaticSubValidatorsAidScenario(
        label: 'accepts with an embassy even when treasury is low (no upfront cost)',
        target: DiplomaticSubValidatorsAidTarget
            .setSubsidyAcceptsWithEmbassyEvenWhenTreasuryLow,
        refs: '#3753 R3',
      ),
    ];

/// All grantAid / setSubsidy sub-validator scenarios (union of behavior families).
List<DiplomaticSubValidatorsAidScenario> diplomaticSubValidatorsAidScenarios() =>
    [
      ...grantAidSubValidatorScenarios(),
      ...setSubsidySubValidatorScenarios(),
    ];
