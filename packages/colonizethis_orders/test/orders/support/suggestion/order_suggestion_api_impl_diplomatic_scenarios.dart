// Table-driven diplomatic GP API impl suggestion scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_api_impl_diplomatic_run_rows.dart';

/// One row in [orderSuggestionApiImplDiplomaticScenarios].
class OrderSuggestionApiImplDiplomaticScenario implements RefsScenario {
  const OrderSuggestionApiImplDiplomaticScenario({
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

void runOrderSuggestionApiImplDiplomaticScenario(
  OrderSuggestionApiImplDiplomaticScenario scenario,
) {
  scenario.run();
}

List<OrderSuggestionApiImplDiplomaticScenario>
orderSuggestionApiImplDiplomaticScenarios() => const [
  OrderSuggestionApiImplDiplomaticScenario(
    label:
        'returns alliance (single diplo per target) for other GP when at peace and not allied',
    run: osaidRunReturnsAllianceSingleDiploPerTarget,
    refs: '#3949',
  ),
  OrderSuggestionApiImplDiplomaticScenario(
    label: 'returns declareWar toward GP when at peace and already allied',
    run: osaidRunReturnsDeclareWarWhenAllied,
    refs: '#3949',
  ),
  OrderSuggestionApiImplDiplomaticScenario(
    label:
        'returns breakAlliance toward GP when a formal alliance exists at peace',
    run: osaidRunReturnsBreakAllianceWhenFormalAllianceExists,
    refs: '#3949',
  ),
  OrderSuggestionApiImplDiplomaticScenario(
    label: 'does not return alliance toward a GP when a formal alliance exists',
    run: osaidRunDoesNotReturnAllianceWhenFormalAllianceExists,
    refs: '#3949',
  ),
  OrderSuggestionApiImplDiplomaticScenario(
    label:
        'does not return breakAlliance when relation level is allied but no formal alliance',
    run: osaidRunDoesNotReturnBreakAllianceWithoutFormalAlliance,
    refs: '#3949',
  ),
  OrderSuggestionApiImplDiplomaticScenario(
    label: 'returns offerPeace when at war with another GP',
    run: osaidRunReturnsOfferPeaceWhenAtWar,
    refs: '#3949',
  ),
  OrderSuggestionApiImplDiplomaticScenario(
    label: 'returns alliance candidate when at peace and not allied',
    run: osaidRunReturnsAllianceCandidateWhenAtPeace,
    refs: '#3949',
  ),
];
