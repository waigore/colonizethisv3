// Table-driven order suggestion context helper scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_context_helpers_expectations.dart';

/// One row in order suggestion context helper scenario tables.
class OrderSuggestionContextHelpersScenario implements RefsScenario {
  const OrderSuggestionContextHelpersScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderSuggestionContextHelpersTarget target;
  @override
  final String? refs;
}

void runOrderSuggestionContextHelpersScenario(
  OrderSuggestionContextHelpersScenario scenario,
) {
  runOrderSuggestionContextHelpersExpectation(scenario.target);
}

/// Scenarios for appendDiplomaticOrderForTrial.
List<OrderSuggestionContextHelpersScenario>
    appendDiplomaticOrderForTrialScenarios() => const [
          OrderSuggestionContextHelpersScenario(
            label: 'appends order for existing player list',
            target: OrderSuggestionContextHelpersTarget
                .appendDiplomaticOrderForTrialExisting,
          ),
          OrderSuggestionContextHelpersScenario(
            label: 'creates new player list when absent',
            target:
                OrderSuggestionContextHelpersTarget.appendDiplomaticOrderForTrialAbsent,
          ),
        ];

/// Scenarios for OvertureStageChain.next.
List<OrderSuggestionContextHelpersScenario> overtureStageChainNextScenarios() =>
    const [
      OrderSuggestionContextHelpersScenario(
        label: 'follows expected progression',
        target: OrderSuggestionContextHelpersTarget.overtureNextProgression,
      ),
      OrderSuggestionContextHelpersScenario(
        label: 'returns null when already at final stage',
        target: OrderSuggestionContextHelpersTarget.overtureNextFinalNull,
      ),
    ];

/// Scenarios for OvertureStageChain.previous.
List<OrderSuggestionContextHelpersScenario>
    overtureStageChainPreviousScenarios() => const [
          OrderSuggestionContextHelpersScenario(
            label: 'next is left inverse of previous for every non-terminal stage',
            target: OrderSuggestionContextHelpersTarget.overturePreviousLeftInverse,
          ),
          OrderSuggestionContextHelpersScenario(
            label: 'previous then next restores stage for every stage past none',
            target: OrderSuggestionContextHelpersTarget.overturePreviousThenNext,
          ),
          OrderSuggestionContextHelpersScenario(
            label: 'reverses next for progression chain',
            target: OrderSuggestionContextHelpersTarget.overturePreviousReversesNext,
          ),
          OrderSuggestionContextHelpersScenario(
            label: 'none maps to itself',
            target: OrderSuggestionContextHelpersTarget.overturePreviousNoneSelf,
          ),
          OrderSuggestionContextHelpersScenario(
            label: 'joinEmpire previous is nap',
            target:
                OrderSuggestionContextHelpersTarget.overturePreviousJoinEmpireNap,
          ),
        ];

/// Scenarios for acceptance wrapper helpers.
List<OrderSuggestionContextHelpersScenario>
    orderSuggestionContextAcceptanceWrapperScenarios() => const [
          OrderSuggestionContextHelpersScenario(
            label: 'isNavalMoveOrderAccepted returns a boolean result',
            target: OrderSuggestionContextHelpersTarget.navalMoveAcceptedBoolean,
          ),
          OrderSuggestionContextHelpersScenario(
            label: 'isNavalMissionOrderAccepted returns a boolean result',
            target:
                OrderSuggestionContextHelpersTarget.navalMissionAcceptedBoolean,
          ),
          OrderSuggestionContextHelpersScenario(
            label: 'isDiplomaticOrderAccepted returns a boolean result',
            target:
                OrderSuggestionContextHelpersTarget.diplomaticAcceptedBoolean,
          ),
          OrderSuggestionContextHelpersScenario(
            label:
                'isDiplomaticOrderAccepted matches default path when view/units shared',
            target: OrderSuggestionContextHelpersTarget
                .diplomaticAcceptedMatchesDefaultPath,
          ),
          OrderSuggestionContextHelpersScenario(
            label:
                'stateless accept helpers reuse sharedCandidateValidator without rebuild',
            target:
                OrderSuggestionContextHelpersTarget.statelessAcceptHelpersReuseValidator,
            refs: '#2394',
          ),
          OrderSuggestionContextHelpersScenario(
            label:
                'isDiplomaticOrderAcceptedWithValidator matches isDiplomaticOrderAccepted',
            target: OrderSuggestionContextHelpersTarget
                .diplomaticAcceptedWithValidatorMatches,
          ),
        ];
