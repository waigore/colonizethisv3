// Table-driven diplomatic boycott suggestion scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_diplomatic_boycott_run_rows.dart';

/// One row in diplomatic boycott suggestion scenario tables.
class OrderSuggestionDiplomaticBoycottScenario implements RefsScenario {
  const OrderSuggestionDiplomaticBoycottScenario({
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

void runOrderSuggestionDiplomaticBoycottScenario(
  OrderSuggestionDiplomaticBoycottScenario scenario,
) {
  scenario.run();
}

List<OrderSuggestionDiplomaticBoycottScenario>
suggestDiplomaticOrdersBoycottCandidateScenarios() => const [
  OrderSuggestionDiplomaticBoycottScenario(
    label:
        'emits a boycott toward another GP at peace when the issuer holds a colony',
    run: osdbRunEmitsBoycottTowardGpAtPeaceWhenIssuerHoldsColony,
    refs: '#3758 R8',
  ),
  OrderSuggestionDiplomaticBoycottScenario(
    label:
        'boycott coexists with the single non-economic candidate for the same GP',
    run: osdbRunBoycottCoexistsWithSingleNonEconomicCandidateForSameGp,
    refs: '#3758 R8',
  ),
  OrderSuggestionDiplomaticBoycottScenario(
    label: 'does not emit a boycott when the issuer holds no colony',
    run: osdbRunDoesNotEmitBoycottWhenIssuerHoldsNoColony,
    refs: '#3758 R8',
  ),
  OrderSuggestionDiplomaticBoycottScenario(
    label: 'does not emit a duplicate boycott when one already exists',
    run: osdbRunDoesNotEmitDuplicateBoycottWhenOneAlreadyExists,
    refs: '#3758 R8',
  ),
  OrderSuggestionDiplomaticBoycottScenario(
    label: 'does not emit a boycott toward a Minor/Tribe target',
    run: osdbRunDoesNotEmitBoycottTowardMinorTribeTarget,
    refs: '#3758 R8',
  ),
  OrderSuggestionDiplomaticBoycottScenario(
    label: 'does not emit a boycott when at war with the target GP',
    run: osdbRunDoesNotEmitBoycottWhenAtWarWithTargetGp,
    refs: '#3758 R8',
  ),
];
