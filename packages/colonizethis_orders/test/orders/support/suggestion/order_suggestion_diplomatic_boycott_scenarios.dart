// Table-driven diplomatic boycott suggestion scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_diplomatic_boycott_expectations.dart';

/// One row in diplomatic boycott suggestion scenario tables.
class OrderSuggestionDiplomaticBoycottScenario implements RefsScenario {
  const OrderSuggestionDiplomaticBoycottScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderSuggestionDiplomaticBoycottTarget target;
  @override
  final String? refs;
}

void runOrderSuggestionDiplomaticBoycottScenario(
  OrderSuggestionDiplomaticBoycottScenario scenario,
) {
  runOrderSuggestionDiplomaticBoycottExpectation(scenario.target);
}

List<OrderSuggestionDiplomaticBoycottScenario>
    suggestDiplomaticOrdersBoycottCandidateScenarios() => const [
          OrderSuggestionDiplomaticBoycottScenario(
            label: 'emits a boycott toward another GP at peace when the issuer holds a colony',
            target: OrderSuggestionDiplomaticBoycottTarget
                .emitsBoycottTowardGpAtPeaceWhenIssuerHoldsColony,
            refs: '#3758 R8',
          ),
          OrderSuggestionDiplomaticBoycottScenario(
            label: 'boycott coexists with the single non-economic candidate for the same GP',
            target: OrderSuggestionDiplomaticBoycottTarget
                .boycottCoexistsWithSingleNonEconomicCandidateForSameGp,
            refs: '#3758 R8',
          ),
          OrderSuggestionDiplomaticBoycottScenario(
            label: 'does not emit a boycott when the issuer holds no colony',
            target: OrderSuggestionDiplomaticBoycottTarget
                .doesNotEmitBoycottWhenIssuerHoldsNoColony,
            refs: '#3758 R8',
          ),
          OrderSuggestionDiplomaticBoycottScenario(
            label: 'does not emit a duplicate boycott when one already exists',
            target: OrderSuggestionDiplomaticBoycottTarget
                .doesNotEmitDuplicateBoycottWhenOneAlreadyExists,
            refs: '#3758 R8',
          ),
          OrderSuggestionDiplomaticBoycottScenario(
            label: 'does not emit a boycott toward a Minor/Tribe target',
            target: OrderSuggestionDiplomaticBoycottTarget
                .doesNotEmitBoycottTowardMinorTribeTarget,
            refs: '#3758 R8',
          ),
          OrderSuggestionDiplomaticBoycottScenario(
            label: 'does not emit a boycott when at war with the target GP',
            target: OrderSuggestionDiplomaticBoycottTarget
                .doesNotEmitBoycottWhenAtWarWithTargetGp,
            refs: '#3758 R8',
          ),
        ];
