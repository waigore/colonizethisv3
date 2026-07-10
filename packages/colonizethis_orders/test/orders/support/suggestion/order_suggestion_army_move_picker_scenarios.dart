// Table-driven army-move picker destination scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_army_move_picker_expectations.dart';

/// One row in [orderSuggestionArmyMovePickerScenarios].
class OrderSuggestionArmyMovePickerScenario implements RefsScenario {
  const OrderSuggestionArmyMovePickerScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderSuggestionArmyMovePickerTarget target;
  @override
  final String? refs;
}

void runOrderSuggestionArmyMovePickerScenario(
  OrderSuggestionArmyMovePickerScenario scenario,
) {
  runOrderSuggestionArmyMovePickerExpectation(scenario.target);
}

List<OrderSuggestionArmyMovePickerScenario>
    orderSuggestionArmyMovePickerScenarios() => const [
          OrderSuggestionArmyMovePickerScenario(
            label: 'cached player-owned set matches default destination picker path',
            target: OrderSuggestionArmyMovePickerTarget
                .cachedPlayerOwnedMatchesDefaultDestinationPickerPath,
          ),
          OrderSuggestionArmyMovePickerScenario(
            label: 'shared playerView and unitsById matches default armyMovePickerDestinations',
            target: OrderSuggestionArmyMovePickerTarget
                .sharedPlayerViewMatchesDefaultArmyMovePickerDestinations,
          ),
          OrderSuggestionArmyMovePickerScenario(
            label: 'shared factionMembership matches default armyMovePickerDestinations',
            target: OrderSuggestionArmyMovePickerTarget
                .sharedFactionMembershipMatchesDefaultArmyMovePickerDestinations,
          ),
          OrderSuggestionArmyMovePickerScenario(
            label: 'sharedCandidateValidator matches default and skips forPlayer rebuild',
            target: OrderSuggestionArmyMovePickerTarget
                .sharedCandidateValidatorMatchesDefaultAndSkipsForPlayerRebuild,
          ),
        ];
