// Table-driven grantAid / setSubsidy sub-validator scenarios (Refs #3949 wave 3).

import '../../scenario_runner.dart';
import 'diplomatic_sub_validators_aid_run_rows.dart';

/// One row in diplomatic economic sub-validator scenario tables.
class DiplomaticSubValidatorsAidScenario implements RefsScenario {
  const DiplomaticSubValidatorsAidScenario({
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

void runDiplomaticSubValidatorsAidScenario(
  DiplomaticSubValidatorsAidScenario scenario,
) =>
    scenario.run();

List<DiplomaticSubValidatorsAidScenario> grantAidSubValidatorScenarios() =>
    const [
      DiplomaticSubValidatorsAidScenario(
        label: 'rejects non-positive amount',
        run: dsaRunGrantAidRejectsNonPositiveAmount,
        refs: '#2391 AC10',
      ),
      DiplomaticSubValidatorsAidScenario(
        label: 'rejects when amount is below the step',
        run: dsaRunGrantAidRejectsAmountBelowStep,
        refs: '#2391 AC10',
      ),
      DiplomaticSubValidatorsAidScenario(
        label: 'rejects amount that is not a multiple of the step',
        run: dsaRunGrantAidRejectsAmountNotMultipleOfStep,
        refs: '#2391 AC10',
      ),
      DiplomaticSubValidatorsAidScenario(
        label: 'rejects without embassy',
        run: dsaRunGrantAidRejectsWithoutEmbassy,
        refs: '#2391 AC10',
      ),
      DiplomaticSubValidatorsAidScenario(
        label: 'rejects when treasury below amount and preserves treasury',
        run: dsaRunGrantAidRejectsTreasuryBelowAmount,
        refs: '#2391 AC10',
      ),
      DiplomaticSubValidatorsAidScenario(
        label: 'accepts and debits treasury by the amount',
        run: dsaRunGrantAidAcceptsAndDebitsTreasury,
        refs: '#2391 AC10',
      ),
    ];

List<DiplomaticSubValidatorsAidScenario> setSubsidySubValidatorScenarios() =>
    const [
      DiplomaticSubValidatorsAidScenario(
        label: 'rejects a zero percent',
        run: dsaRunSetSubsidyRejectsZeroPercent,
        refs: '#3753 R3',
      ),
      DiplomaticSubValidatorsAidScenario(
        label: 'rejects a percent not a multiple of the step',
        run: dsaRunSetSubsidyRejectsPercentNotMultipleOfStep,
        refs: '#3753 R3',
      ),
      DiplomaticSubValidatorsAidScenario(
        label: 'rejects a percent above the maximum',
        run: dsaRunSetSubsidyRejectsPercentAboveMaximum,
        refs: '#3753 R3',
      ),
      DiplomaticSubValidatorsAidScenario(
        label: 'rejects without any overture',
        run: dsaRunSetSubsidyRejectsWithoutOverture,
        refs: '#3753 R3',
      ),
      DiplomaticSubValidatorsAidScenario(
        label: 'rejects with a Trade Consulate only (Refs #3753 R2)',
        run: dsaRunSetSubsidyRejectsTradeConsulateOnly,
        refs: '#3753 R2',
      ),
      DiplomaticSubValidatorsAidScenario(
        label: 'accepts with an embassy and leaves treasury unchanged',
        run: dsaRunSetSubsidyAcceptsWithEmbassyLeavesTreasuryUnchanged,
        refs: '#3753 R3',
      ),
      DiplomaticSubValidatorsAidScenario(
        label: 'accepts with an embassy even when treasury is low (no upfront cost)',
        run: dsaRunSetSubsidyAcceptsWithEmbassyEvenWhenTreasuryLow,
        refs: '#3753 R3',
      ),
    ];

/// All grantAid / setSubsidy sub-validator scenarios (union of behavior families).
List<DiplomaticSubValidatorsAidScenario> diplomaticSubValidatorsAidScenarios() =>
    [
      ...grantAidSubValidatorScenarios(),
      ...setSubsidySubValidatorScenarios(),
    ];
