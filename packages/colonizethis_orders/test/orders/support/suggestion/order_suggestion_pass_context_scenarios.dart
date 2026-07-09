// Table-driven order suggestion pass context scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_pass_context_expectations.dart';

/// One row in order suggestion pass context scenario tables.
class OrderSuggestionPassContextScenario implements RefsScenario {
  const OrderSuggestionPassContextScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderSuggestionPassContextTarget target;
  @override
  final String? refs;
}

void runOrderSuggestionPassContextScenario(
  OrderSuggestionPassContextScenario scenario,
) {
  runOrderSuggestionPassContextExpectation(scenario.target);
}

/// Scenarios for indexExistingTargetsByEntityId.
List<OrderSuggestionPassContextScenario>
    indexExistingTargetsByEntityIdScenarios() => const [
          OrderSuggestionPassContextScenario(
            label: 'indexExistingTargetsByEntityId skips empty targets when requested',
            target: OrderSuggestionPassContextTarget.indexSkipsEmptyTargets,
            refs: '#3500',
          ),
        ];

/// Scenarios for emitAcceptedCandidates.
List<OrderSuggestionPassContextScenario> emitAcceptedCandidatesScenarios() =>
    const [
      OrderSuggestionPassContextScenario(
        label: 'emitAcceptedCandidates collects accepted in iteration order',
        target: OrderSuggestionPassContextTarget.emitCollectsInOrder,
        refs: '#3500',
      ),
      OrderSuggestionPassContextScenario(
        label: 'emitAcceptedCandidates skips candidates already targeted',
        target: OrderSuggestionPassContextTarget.emitSkipsAlreadyTargeted,
        refs: '#3500',
      ),
      OrderSuggestionPassContextScenario(
        label: 'emitAcceptedCandidates probes every candidate without dedup args',
        target: OrderSuggestionPassContextTarget.emitProbesWithoutDedupArgs,
        refs: '#3500',
      ),
    ];

/// Scenarios for runCappedSuggestionProbeLoop.
List<OrderSuggestionPassContextScenario>
    runCappedSuggestionProbeLoopScenarios() => const [
          OrderSuggestionPassContextScenario(
            label: 'runCappedSuggestionProbeLoop respects acceptance and probe caps',
            target: OrderSuggestionPassContextTarget.cappedProbeLoopRespectsCaps,
            refs: '#3500',
          ),
        ];

/// Scenarios for ownedProvinceIdsFromView.
List<OrderSuggestionPassContextScenario> ownedProvinceIdsFromViewScenarios() =>
    const [
      OrderSuggestionPassContextScenario(
        label: 'ownedProvinceIdsFromView returns full province ids for owner',
        target: OrderSuggestionPassContextTarget.ownedProvinceIdsFromView,
        refs: '#3500',
      ),
    ];
