// Table-driven boycott / revokeBoycott validator scenarios (Refs #3949 wave 3).

import '../../scenario_runner.dart';
import 'boycott_validator_expectations.dart';

/// One row in boycott validator scenario tables.
class BoycottValidatorScenario implements RefsScenario {
  const BoycottValidatorScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final BoycottValidatorTarget target;
  @override
  final String? refs;
}

void runBoycottValidatorScenario(BoycottValidatorScenario scenario) {
  runBoycottValidatorExpectation(scenario.target);
}

List<BoycottValidatorScenario> boycottSubValidatorScenarios() => const [
      BoycottValidatorScenario(
        label: 'accepts when issuer holds a colony and target GP is at peace',
        target: BoycottValidatorTarget.boycottAcceptsColonyHolderAtPeace,
        refs: '#3753 R6',
      ),
      BoycottValidatorScenario(
        label: 'rejects when the issuer holds no colony',
        target: BoycottValidatorTarget.boycottRejectsNoColony,
        refs: '#3753 R6',
      ),
      BoycottValidatorScenario(
        label: 'rejects when at war with the target GP',
        target: BoycottValidatorTarget.boycottRejectsAtWar,
        refs: '#3753 R6',
      ),
      BoycottValidatorScenario(
        label: 'rejects a duplicate boycott for the same pair',
        target: BoycottValidatorTarget.boycottRejectsDuplicate,
        refs: '#3753 R6',
      ),
      BoycottValidatorScenario(
        label: 'rejects a non-Great-Power target',
        target: BoycottValidatorTarget.boycottRejectsNonGpTarget,
        refs: '#3753 R6',
      ),
    ];

List<BoycottValidatorScenario> revokeBoycottSubValidatorScenarios() => const [
      BoycottValidatorScenario(
        label: 'accepts when an active boycott exists for the pair',
        target: BoycottValidatorTarget.revokeAcceptsActiveBoycott,
        refs: '#3753 R6',
      ),
      BoycottValidatorScenario(
        label: 'rejects when no active boycott exists for the pair',
        target: BoycottValidatorTarget.revokeRejectsNoActiveBoycott,
        refs: '#3753 R6',
      ),
    ];

List<BoycottValidatorScenario> diplomaticOrderValidatorBoycottScenarios() =>
    const [
      BoycottValidatorScenario(
        label: 'accepts a valid boycott order through the parent validator',
        target: BoycottValidatorTarget.parentValidatorAcceptsValidBoycott,
        refs: '#3753 R6',
      ),
    ];

/// All boycott validator scenarios (union of behavior-family tables).
List<BoycottValidatorScenario> boycottValidatorScenarios() => [
      ...boycottSubValidatorScenarios(),
      ...revokeBoycottSubValidatorScenarios(),
      ...diplomaticOrderValidatorBoycottScenarios(),
    ];
