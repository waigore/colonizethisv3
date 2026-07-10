// Table-driven establishOverture sub-validator scenarios (Refs #3949 wave 3).

import '../../scenario_runner.dart';
import 'establish_overture_sub_validator_expectations.dart';

/// One row in establishOverture sub-validator scenario tables.
class EstablishOvertureSubValidatorScenario implements RefsScenario {
  const EstablishOvertureSubValidatorScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final EstablishOvertureSubValidatorTarget target;
  @override
  final String? refs;
}

void runEstablishOvertureSubValidatorScenario(
  EstablishOvertureSubValidatorScenario scenario,
) {
  runEstablishOvertureSubValidatorExpectation(scenario.target);
}

List<EstablishOvertureSubValidatorScenario> establishOvertureSubValidatorScenarios() =>
    const [
      EstablishOvertureSubValidatorScenario(
        label: 'rejects when stage is missing',
        target: EstablishOvertureSubValidatorTarget.rejectsWhenStageMissing,
        refs: '#2391 AC10',
      ),
      EstablishOvertureSubValidatorScenario(
        label: 'trade consulate debits treasury on accept',
        target:
            EstablishOvertureSubValidatorTarget.tradeConsulateDebitsTreasuryOnAccept,
        refs: '#2391 AC10',
      ),
      EstablishOvertureSubValidatorScenario(
        label: 'trade consulate rejects without diplomatic_expertise',
        target: EstablishOvertureSubValidatorTarget
            .tradeConsulateRejectsWithoutDiplomaticExpertise,
        refs: '#2391 AC10',
      ),
      EstablishOvertureSubValidatorScenario(
        label: 'trade consulate rejects when treasury too low (no debit)',
        target: EstablishOvertureSubValidatorTarget.tradeConsulateRejectsTreasuryTooLow,
        refs: '#2391 AC10',
      ),
      EstablishOvertureSubValidatorScenario(
        label: 'embassy requires existing trade consulate',
        target:
            EstablishOvertureSubValidatorTarget.embassyRequiresExistingTradeConsulate,
        refs: '#2391 AC10',
      ),
      EstablishOvertureSubValidatorScenario(
        label: 'embassy accepts and debits treasury when consulate exists',
        target: EstablishOvertureSubValidatorTarget
            .embassyAcceptsAndDebitsWhenConsulateExists,
        refs: '#2391 AC10',
      ),
      EstablishOvertureSubValidatorScenario(
        label: 'nap requires existing embassy and does not debit treasury',
        target: EstablishOvertureSubValidatorTarget.napRequiresExistingEmbassyNoDebit,
        refs: '#2391 AC10',
      ),
      EstablishOvertureSubValidatorScenario(
        label: 'joinEmpire rejects when relations below friendly threshold',
        target:
            EstablishOvertureSubValidatorTarget.joinEmpireRejectsRelationsBelowFriendly,
        refs: '#2391 AC10',
      ),
    ];
