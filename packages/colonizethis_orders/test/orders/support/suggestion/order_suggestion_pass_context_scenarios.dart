// Table-driven order suggestion pass context scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_pass_context_run_rows.dart';

/// One row in order suggestion pass context scenario tables.
class OrderSuggestionPassContextScenario implements RefsScenario {
  const OrderSuggestionPassContextScenario({
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

void runOrderSuggestionPassContextScenario(
  OrderSuggestionPassContextScenario scenario,
) {
  scenario.run();
}

/// Scenarios for indexExistingTargetsByEntityId.
List<OrderSuggestionPassContextScenario>
indexExistingTargetsByEntityIdScenarios() => const [
  OrderSuggestionPassContextScenario(
    label: 'indexExistingTargetsByEntityId skips empty targets when requested',
    run: ospcRunIndexSkipsEmptyTargets,
    refs: '#3500',
  ),
];

/// Scenarios for emitAcceptedCandidates.
List<OrderSuggestionPassContextScenario> emitAcceptedCandidatesScenarios() =>
    const [
      OrderSuggestionPassContextScenario(
        label: 'emitAcceptedCandidates collects accepted in iteration order',
        run: ospcRunEmitCollectsInOrder,
        refs: '#3500',
      ),
      OrderSuggestionPassContextScenario(
        label: 'emitAcceptedCandidates skips candidates already targeted',
        run: ospcRunEmitSkipsAlreadyTargeted,
        refs: '#3500',
      ),
      OrderSuggestionPassContextScenario(
        label:
            'emitAcceptedCandidates probes every candidate without dedup args',
        run: ospcRunEmitProbesWithoutDedupArgs,
        refs: '#3500',
      ),
    ];

/// Scenarios for runCappedSuggestionProbeLoop.
List<OrderSuggestionPassContextScenario>
runCappedSuggestionProbeLoopScenarios() => const [
  OrderSuggestionPassContextScenario(
    label: 'runCappedSuggestionProbeLoop respects acceptance and probe caps',
    run: ospcRunCappedProbeLoopRespectsCaps,
    refs: '#3500',
  ),
];

/// Scenarios for ownedProvinceIdsFromView.
List<OrderSuggestionPassContextScenario> ownedProvinceIdsFromViewScenarios() =>
    const [
      OrderSuggestionPassContextScenario(
        label: 'ownedProvinceIdsFromView returns full province ids for owner',
        run: ospcRunOwnedProvinceIdsFromView,
        refs: '#3500',
      ),
    ];
