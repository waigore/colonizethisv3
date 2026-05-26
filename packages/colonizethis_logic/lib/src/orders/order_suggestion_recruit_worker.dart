import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../diplomacy/diplomacy_resolver.dart';
import '../world/player_view.dart';
import '../world/unit_lookup.dart';
import 'incremental_candidate_validator.dart';
import 'order_resolution_context.dart';
import 'order_suggestion_context.dart';

/// Suggests `RecruitWorkerOrder` candidates that are affordable and valid
/// for [view.playerId] against the prefix in [currentOrders] (Refs #2692 S7,
/// SPEC/program/order-suggestions.md § Recruit worker orders).
///
/// One candidate is probed per [WorkerTier]; the order engine validation
/// chain (`RecruitWorkerOrderValidator`) decides per tier whether the cost
/// row, peasant reservation, and tech gates per
/// SPEC/game/workers-and-population.md § Recruiting, Training, and
/// Disbanding pass against the projected economy after every accepted
/// recruit worker order in [currentOrders]. Disband is **not** a queued
/// order and is not enumerated here (SPEC/game/workers-and-population.md
/// § Disband).
///
/// Throughput hook: callers that enumerate multiple suggestion families
/// against the same `(game, view.playerId, currentOrders)` may supply
/// [sharedCandidateValidator] to amortize `PlayerView` / units-by-id
/// construction across families (Refs #2394). The shared instance must be
/// built with the same inputs; observable suggestions must match the
/// default path.
List<RecruitWorkerOrder> suggestRecruitWorkerOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders, {
  IncrementalCandidateValidator? sharedCandidateValidator,
}) {
  orderSuggestionLog.d('suggestRecruitWorkerOrders player=${view.playerId}');
  final playerId = view.playerId;
  final suggestions = <RecruitWorkerOrder>[];

  assert(
    sharedCandidateValidator == null ||
        sharedCandidateValidator.playerId == playerId,
    'sharedCandidateValidator playerId must match view.playerId',
  );
  final effectiveResolution = sharedCandidateValidator != null
      ? (
          view: sharedCandidateValidator.view,
          unitsById: sharedCandidateValidator.unitsById,
          provinceById: sharedCandidateValidator.view.provincesById,
        )
      : orderResolutionContextFromView(view, game);
  final candidateValidator =
      sharedCandidateValidator ??
      buildIncrementalCandidateValidator(
        game: game,
        topology: topology,
        playerId: playerId,
        baseOrders: currentOrders,
        resolution: effectiveResolution,
        factionMembership: DiplomacyFactionMembership.from(game),
      );

  for (final tier in WorkerTier.values) {
    final candidate = RecruitWorkerOrder(targetTier: tier);
    if (isRecruitWorkerOrderAcceptedWithValidator(
      candidateValidator,
      candidate,
    )) {
      suggestions.add(candidate);
    }
  }

  suggestions.sort((a, b) => a.targetTier.index.compareTo(b.targetTier.index));

  orderSuggestionLog.d(
    'suggestRecruitWorkerOrders player=$playerId candidates=${suggestions.length}',
  );
  if (suggestions.isEmpty) {
    orderSuggestionLog.d(
      'suggestRecruitWorkerOrders no candidates player=$playerId',
    );
  }
  return suggestions;
}

/// Validates a [RecruitWorkerOrder] candidate using a pre-built
/// [IncrementalCandidateValidator]. Mirrors the per-type
/// `is*OrderAcceptedWithValidator` helpers exposed by other suggestion
/// families (Refs #2692 S7, `SPEC/program/order-suggestions.md`).
bool isRecruitWorkerOrderAcceptedWithValidator(
  IncrementalCandidateValidator validator,
  RecruitWorkerOrder candidate,
) {
  return validator.isRecruitWorkerAccepted(candidate);
}

/// Stateless candidate-probe helper for `RecruitWorkerOrder`. Builds an
/// [IncrementalCandidateValidator] when one is not supplied and returns the
/// same accept/reject decision as `validatePlayerOrdersWithContext` for the
/// candidate against [baseOrders] (SPEC/program/order-suggestions.md
/// § Incremental candidate validation).
bool isRecruitWorkerOrderAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders baseOrders,
  RecruitWorkerOrder candidate, {
  IncrementalCandidateValidator? sharedCandidateValidator,
  OrderResolutionContext? resolution,
  DiplomacyFactionMembership? factionMembership,
}) {
  final validator = incrementalValidatorForCandidateProbe(
    game: game,
    topology: topology,
    playerId: playerId,
    baseOrders: baseOrders,
    resolution: resolution,
    factionMembership: factionMembership,
    sharedCandidateValidator: sharedCandidateValidator,
  );
  return isRecruitWorkerOrderAcceptedWithValidator(validator, candidate);
}
