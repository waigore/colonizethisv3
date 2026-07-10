// Table-driven army-move picker destination scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_army_move_picker_run_rows.dart';

/// One row in [orderSuggestionArmyMovePickerScenarios].
class OrderSuggestionArmyMovePickerScenario implements RefsScenario {
  const OrderSuggestionArmyMovePickerScenario({
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

void runOrderSuggestionArmyMovePickerScenario(
  OrderSuggestionArmyMovePickerScenario scenario,
) {
  scenario.run();
}

List<OrderSuggestionArmyMovePickerScenario>
orderSuggestionArmyMovePickerScenarios() => const [
  OrderSuggestionArmyMovePickerScenario(
    label: 'cached player-owned set matches default destination picker path',
    run: osampRunCachedPlayerOwnedMatchesDefaultDestinationPickerPath,
  ),
  OrderSuggestionArmyMovePickerScenario(
    label:
        'shared playerView and unitsById matches default armyMovePickerDestinations',
    run: osampRunSharedPlayerViewMatchesDefaultArmyMovePickerDestinations,
  ),
  OrderSuggestionArmyMovePickerScenario(
    label:
        'shared factionMembership matches default armyMovePickerDestinations',
    run:
        osampRunSharedFactionMembershipMatchesDefaultArmyMovePickerDestinations,
  ),
  OrderSuggestionArmyMovePickerScenario(
    label:
        'sharedCandidateValidator matches default and skips forPlayer rebuild',
    run: osampRunSharedCandidateValidatorMatchesDefaultAndSkipsForPlayerRebuild,
  ),
];
