// Table-driven order suggestion context helper scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_context_helpers_run_rows.dart';

/// One row in order suggestion context helper scenario tables.
class OrderSuggestionContextHelpersScenario implements RefsScenario {
  const OrderSuggestionContextHelpersScenario({
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

void runOrderSuggestionContextHelpersScenario(
  OrderSuggestionContextHelpersScenario scenario,
) {
  scenario.run();
}

/// Scenarios for appendDiplomaticOrderForTrial.
List<OrderSuggestionContextHelpersScenario>
appendDiplomaticOrderForTrialScenarios() => const [
  OrderSuggestionContextHelpersScenario(
    label: 'appends order for existing player list',
    run: oschRunAppendDiplomaticOrderForTrialExisting,
  ),
  OrderSuggestionContextHelpersScenario(
    label: 'creates new player list when absent',
    run: oschRunAppendDiplomaticOrderForTrialAbsent,
  ),
];

/// Scenarios for OvertureStageChain.next.
List<OrderSuggestionContextHelpersScenario> overtureStageChainNextScenarios() =>
    const [
      OrderSuggestionContextHelpersScenario(
        label: 'follows expected progression',
        run: oschRunOvertureNextProgression,
      ),
      OrderSuggestionContextHelpersScenario(
        label: 'returns null when already at final stage',
        run: oschRunOvertureNextFinalNull,
      ),
    ];

/// Scenarios for OvertureStageChain.previous.
List<OrderSuggestionContextHelpersScenario>
overtureStageChainPreviousScenarios() => const [
  OrderSuggestionContextHelpersScenario(
    label: 'next is left inverse of previous for every non-terminal stage',
    run: oschRunOverturePreviousLeftInverse,
  ),
  OrderSuggestionContextHelpersScenario(
    label: 'previous then next restores stage for every stage past none',
    run: oschRunOverturePreviousThenNext,
  ),
  OrderSuggestionContextHelpersScenario(
    label: 'reverses next for progression chain',
    run: oschRunOverturePreviousReversesNext,
  ),
  OrderSuggestionContextHelpersScenario(
    label: 'none maps to itself',
    run: oschRunOverturePreviousNoneSelf,
  ),
  OrderSuggestionContextHelpersScenario(
    label: 'joinEmpire previous is nap',
    run: oschRunOverturePreviousJoinEmpireNap,
  ),
];

/// Scenarios for acceptance wrapper helpers.
List<OrderSuggestionContextHelpersScenario>
orderSuggestionContextAcceptanceWrapperScenarios() => const [
  OrderSuggestionContextHelpersScenario(
    label: 'isNavalMoveOrderAccepted returns a boolean result',
    run: oschRunNavalMoveAcceptedBoolean,
  ),
  OrderSuggestionContextHelpersScenario(
    label: 'isNavalMissionOrderAccepted returns a boolean result',
    run: oschRunNavalMissionAcceptedBoolean,
  ),
  OrderSuggestionContextHelpersScenario(
    label: 'isDiplomaticOrderAccepted returns a boolean result',
    run: oschRunDiplomaticAcceptedBoolean,
  ),
  OrderSuggestionContextHelpersScenario(
    label:
        'isDiplomaticOrderAccepted matches default path when view/units shared',
    run: oschRunDiplomaticAcceptedMatchesDefaultPath,
  ),
  OrderSuggestionContextHelpersScenario(
    label:
        'stateless accept helpers reuse sharedCandidateValidator without rebuild',
    run: oschRunStatelessAcceptHelpersReuseValidator,
    refs: '#2394',
  ),
  OrderSuggestionContextHelpersScenario(
    label:
        'isDiplomaticOrderAcceptedWithValidator matches isDiplomaticOrderAccepted',
    run: oschRunDiplomaticAcceptedWithValidatorMatches,
  ),
];
