import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'incremental_candidate_validator.dart';
import 'order_suggestion_context.dart';
import 'order_suggestion_diplomatic_candidates.dart';
import 'validators/diplomatic/diplomatic_sub_validator.dart';

/// Per-target pass inputs shared by diplomatic suggestion orchestration (Refs
/// #3877 AC8).
final class DiplomaticSuggestionPassInputs {
  const DiplomaticSuggestionPassInputs({
    required this.subValidatorContext,
    required this.knownTargetIds,
    required this.knownFactionIds,
    required this.playerOverturesByTargetId,
    required this.playerHoldsColony,
    required this.player,
  });

  final DiplomaticSubValidatorContext subValidatorContext;
  final Set<String> knownTargetIds;
  final Set<String> knownFactionIds;
  final Map<String, OvertureState> playerOverturesByTargetId;
  final bool playerHoldsColony;
  final Player player;
}

/// Mutable per-pass validator and trial-order state while iterating targets.
final class DiplomaticSuggestionPassState {
  DiplomaticSuggestionPassState({
    required this.workingOrders,
    required this.passValidator,
    required this.suggestions,
  });

  Orders workingOrders;
  IncrementalCandidateValidator passValidator;
  final List<DiplomaticOrder> suggestions;
}

/// Independent diplomatic candidates are appended in their own pass and do not
/// consume (nor are consumed by) the single non-economic primary winner for a
/// target: economic transfers (`grantAid`, `setSubsidy`) and the `boycott`
/// colony trade embargo. SPEC/program/order-suggestions.md § Primary vs
/// independent suggestions per target.
bool isIndependentDiplomaticCandidate(DiplomaticOrderType type) =>
    type == DiplomaticOrderType.grantAid ||
    type == DiplomaticOrderType.setSubsidy ||
    type == DiplomaticOrderType.boycott;

Map<String, OvertureState> playerOverturesByTargetIdForPlayer(
  Game game,
  String playerId,
) {
  final playerOverturesByTargetId = <String, OvertureState>{};
  for (final o in game.overtureStates) {
    if (o.gpId != playerId) continue;
    playerOverturesByTargetId.putIfAbsent(o.targetId, () => o);
  }
  return playerOverturesByTargetId;
}

/// Runs the per-target primary-then-independent acceptance loop for one target.
void acceptDiplomaticCandidatesForTarget({
  required String targetId,
  required DiplomaticSuggestionPassInputs inputs,
  required DiplomaticSuggestionPassState state,
}) {
  final targetView = DiplomaticSuggestionTargetView(
    targetId: targetId,
    player: inputs.player,
    knownTargetIds: inputs.knownTargetIds,
    knownFactionIds: inputs.knownFactionIds,
    playerOverturesByTargetId: inputs.playerOverturesByTargetId,
    playerHoldsColony: inputs.playerHoldsColony,
  );
  final candidates = diplomaticCandidatesForTargetOrdered(
    inputs.subValidatorContext,
    targetView,
  );
  var trialOrders = state.workingOrders;

  final prefixPassValidator = state.passValidator.forBasePrefix(trialOrders);
  state.passValidator = prefixPassValidator;
  var prefixPassAcceptedOrder = false;
  for (final candidate in candidates) {
    if (isIndependentDiplomaticCandidate(candidate.type)) {
      continue;
    }
    if (!isDiplomaticOrderAcceptedWithValidator(
      prefixPassValidator,
      candidate,
    )) {
      continue;
    }
    state.suggestions.add(candidate);
    trialOrders = appendDiplomaticOrderForTrial(
      trialOrders,
      inputs.subValidatorContext.playerId,
      candidate,
    );
    prefixPassAcceptedOrder = true;
    break;
  }

  final economicPassValidator = prefixPassAcceptedOrder
      ? prefixPassValidator.forBasePrefix(trialOrders)
      : prefixPassValidator;
  if (prefixPassAcceptedOrder) {
    state.passValidator = economicPassValidator;
  }
  for (final candidate in candidates) {
    if (!isIndependentDiplomaticCandidate(candidate.type)) {
      continue;
    }
    if (!isDiplomaticOrderAcceptedWithValidator(
      economicPassValidator,
      candidate,
    )) {
      continue;
    }
    state.suggestions.add(candidate);
    trialOrders = appendDiplomaticOrderForTrial(
      trialOrders,
      inputs.subValidatorContext.playerId,
      candidate,
    );
  }

  state.workingOrders = trialOrders;
  state.passValidator = state.passValidator.forBasePrefix(state.workingOrders);
}

/// Declare-war-only pass: one [declareWar] candidate per target with no prefix
/// trial orders so establish-overture does not block war (Refs #2504, #3877).
void acceptDeclareWarCandidatesForTargets({
  required Iterable<String> sortedTargetIds,
  required String playerId,
  required DiplomaticSuggestionPassInputs inputs,
  required DiplomaticSuggestionPassState state,
}) {
  for (final targetId in sortedTargetIds) {
    if (targetId == playerId) continue;
    final candidate = declareWarSuggestionCandidate(
      inputs.subValidatorContext,
      DiplomaticSuggestionTargetView(
        targetId: targetId,
        player: inputs.player,
        knownTargetIds: inputs.knownTargetIds,
        knownFactionIds: inputs.knownFactionIds,
        playerOverturesByTargetId: inputs.playerOverturesByTargetId,
        playerHoldsColony: inputs.playerHoldsColony,
      ),
    );
    if (candidate == null) continue;
    if (!isDiplomaticOrderAcceptedWithValidator(
      state.passValidator,
      candidate,
    )) {
      continue;
    }
    state.suggestions.add(candidate);
  }
}
