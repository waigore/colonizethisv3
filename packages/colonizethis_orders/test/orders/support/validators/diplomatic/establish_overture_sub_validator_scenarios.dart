// Table-driven establishOverture sub-validator scenarios (Refs #3949 wave 3).

import '../../scenario_runner.dart';
import 'establish_overture_sub_validator_run_rows.dart';

/// One row in establishOverture sub-validator scenario tables.
class EstablishOvertureSubValidatorScenario implements RefsScenario {
  const EstablishOvertureSubValidatorScenario({
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

void runEstablishOvertureSubValidatorScenario(
  EstablishOvertureSubValidatorScenario scenario,
) =>
    scenario.run();

List<EstablishOvertureSubValidatorScenario> establishOvertureSubValidatorScenarios() =>
    const [
      EstablishOvertureSubValidatorScenario(
        label: 'rejects when stage is missing',
        run: eosvRunRejectsWhenStageMissing,
        refs: '#2391 AC10',
      ),
      EstablishOvertureSubValidatorScenario(
        label: 'trade consulate debits treasury on accept',
        run: eosvRunTradeConsulateDebitsTreasuryOnAccept,
        refs: '#2391 AC10',
      ),
      EstablishOvertureSubValidatorScenario(
        label: 'trade consulate rejects without diplomatic_expertise',
        run: eosvRunTradeConsulateRejectsWithoutDiplomaticExpertise,
        refs: '#2391 AC10',
      ),
      EstablishOvertureSubValidatorScenario(
        label: 'trade consulate rejects when treasury too low (no debit)',
        run: eosvRunTradeConsulateRejectsTreasuryTooLow,
        refs: '#2391 AC10',
      ),
      EstablishOvertureSubValidatorScenario(
        label: 'embassy requires existing trade consulate',
        run: eosvRunEmbassyRequiresExistingTradeConsulate,
        refs: '#2391 AC10',
      ),
      EstablishOvertureSubValidatorScenario(
        label: 'embassy accepts and debits treasury when consulate exists',
        run: eosvRunEmbassyAcceptsAndDebitsWhenConsulateExists,
        refs: '#2391 AC10',
      ),
      EstablishOvertureSubValidatorScenario(
        label: 'nap requires existing embassy and does not debit treasury',
        run: eosvRunNapRequiresExistingEmbassyNoDebit,
        refs: '#2391 AC10',
      ),
      EstablishOvertureSubValidatorScenario(
        label: 'joinEmpire rejects when relations below friendly threshold',
        run: eosvRunJoinEmpireRejectsRelationsBelowFriendly,
        refs: '#2391 AC10',
      ),
    ];
