// Table-driven boycott / revokeBoycott validator scenarios (Refs #3949 wave 3).

import '../../scenario_runner.dart';
import 'boycott_validator_run_rows.dart';

/// One row in boycott validator scenario tables.
class BoycottValidatorScenario implements RefsScenario {
  const BoycottValidatorScenario({
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

void runBoycottValidatorScenario(BoycottValidatorScenario scenario) =>
    scenario.run();

List<BoycottValidatorScenario> boycottSubValidatorScenarios() => const [
      BoycottValidatorScenario(
        label: 'accepts when issuer holds a colony and target GP is at peace',
        run: bctRunBoycottAcceptsColonyHolderAtPeace,
        refs: '#3753 R6',
      ),
      BoycottValidatorScenario(
        label: 'rejects when the issuer holds no colony',
        run: bctRunBoycottRejectsNoColony,
        refs: '#3753 R6',
      ),
      BoycottValidatorScenario(
        label: 'rejects when at war with the target GP',
        run: bctRunBoycottRejectsAtWar,
        refs: '#3753 R6',
      ),
      BoycottValidatorScenario(
        label: 'rejects a duplicate boycott for the same pair',
        run: bctRunBoycottRejectsDuplicate,
        refs: '#3753 R6',
      ),
      BoycottValidatorScenario(
        label: 'rejects a non-Great-Power target',
        run: bctRunBoycottRejectsNonGpTarget,
        refs: '#3753 R6',
      ),
    ];

List<BoycottValidatorScenario> revokeBoycottSubValidatorScenarios() => const [
      BoycottValidatorScenario(
        label: 'accepts when an active boycott exists for the pair',
        run: bctRunRevokeAcceptsActiveBoycott,
        refs: '#3753 R6',
      ),
      BoycottValidatorScenario(
        label: 'rejects when no active boycott exists for the pair',
        run: bctRunRevokeRejectsNoActiveBoycott,
        refs: '#3753 R6',
      ),
    ];

List<BoycottValidatorScenario> diplomaticOrderValidatorBoycottScenarios() =>
    const [
      BoycottValidatorScenario(
        label: 'accepts a valid boycott order through the parent validator',
        run: bctRunParentValidatorAcceptsValidBoycott,
        refs: '#3753 R6',
      ),
    ];

/// All boycott validator scenarios (union of behavior-family tables).
List<BoycottValidatorScenario> boycottValidatorScenarios() => [
      ...boycottSubValidatorScenarios(),
      ...revokeBoycottSubValidatorScenarios(),
      ...diplomaticOrderValidatorBoycottScenarios(),
    ];
