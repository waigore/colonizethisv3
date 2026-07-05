import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'incremental_candidate_validator.dart';
import 'order_suggestion_context.dart';
import 'order_suggestion_diplomatic_candidates.dart';
import 'order_suggestion_pass_context.dart';
import 'validators/diplomatic/diplomatic_sub_validator.dart';

/// Independent diplomatic candidates are appended in their own pass and do not
/// consume (nor are consumed by) the single non-economic primary winner for a
/// target: economic transfers (`grantAid`, `setSubsidy`) and the `boycott`
/// colony trade embargo. SPEC/program/order-suggestions.md § Primary vs
/// independent suggestions per target.
bool _isIndependentDiplomaticCandidate(DiplomaticOrderType type) =>
    type == DiplomaticOrderType.grantAid ||
    type == DiplomaticOrderType.setSubsidy ||
    type == DiplomaticOrderType.boycott;

/// Suggests candidate diplomatic orders that are valid and visible for [view.playerId].
/// SPEC/program/order-suggestions.md; SPEC/program/ai-systems-impl.md.
///
/// Throughput hook: when [sharedCandidateValidator] is supplied for the same
/// `(game, topology, playerId, currentOrders)` tuple, the pass-level validator
/// setup is skipped (Refs #2394).
List<DiplomaticOrder> suggestDiplomaticOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders, {
  Map<String, TileMapResult>? tileMapByRegion,
  IncrementalCandidateValidator? sharedCandidateValidator,
}) {
  final pass = SuggestionPassContext.forPlayerView(
    view: view,
    game: game,
    topology: topology,
    currentOrders: currentOrders,
    familyLabel: 'suggestDiplomaticOrders',
    tileMapByRegion: tileMapByRegion,
    sharedCandidateValidator: sharedCandidateValidator,
  );
  final playerId = pass.playerId;
  final suggestions = <DiplomaticOrder>[];
  final player = view.player;

  final targets = resolveDiplomaticSuggestionTargetIds(
    view: view,
    game: game,
    topology: topology,
    factionMembership: pass.factionMembership,
    playerId: playerId,
  );

  final playerOverturesByTargetId = <String, OvertureState>{};
  for (final o in game.overtureStates) {
    if (o.gpId != playerId) continue;
    playerOverturesByTargetId.putIfAbsent(o.targetId, () => o);
  }

  final playerHoldsColony = game.colonyStates.any(
    (c) => c.colonyOfGpId == playerId,
  );

  final subValidatorContext = DiplomaticSubValidatorContext(
    game: game,
    playerId: playerId,
    factionMembership: pass.factionMembership,
  );

  final unionTargets = <String>{
    ...targets.knownTargetIds,
    ...targets.otherGpIds,
    ...playerOverturesByTargetId.keys,
  };

  final sortedTargetIds = unionTargets.toList()..sort();
  var workingOrders = currentOrders;
  var passValidator = pass.candidateValidator;
  for (final targetId in sortedTargetIds) {
    if (targetId == playerId) continue;

    final targetView = DiplomaticSuggestionTargetView(
      targetId: targetId,
      player: player,
      knownTargetIds: targets.knownTargetIds,
      knownFactionIds: targets.knownFactionIds,
      playerOverturesByTargetId: playerOverturesByTargetId,
      playerHoldsColony: playerHoldsColony,
    );
    final candidates = diplomaticCandidatesForTargetOrdered(
      subValidatorContext,
      targetView,
    );
    var trialOrders = workingOrders;

    final prefixPassValidator = passValidator.forBasePrefix(trialOrders);
    passValidator = prefixPassValidator;
    var prefixPassAcceptedOrder = false;
    for (final candidate in candidates) {
      if (_isIndependentDiplomaticCandidate(candidate.type)) {
        continue;
      }
      if (!isDiplomaticOrderAcceptedWithValidator(
        prefixPassValidator,
        candidate,
      )) {
        continue;
      }
      suggestions.add(candidate);
      trialOrders = appendDiplomaticOrderForTrial(
        trialOrders,
        playerId,
        candidate,
      );
      prefixPassAcceptedOrder = true;
      break;
    }

    final economicPassValidator = prefixPassAcceptedOrder
        ? prefixPassValidator.forBasePrefix(trialOrders)
        : prefixPassValidator;
    if (prefixPassAcceptedOrder) {
      passValidator = economicPassValidator;
    }
    for (final candidate in candidates) {
      if (!_isIndependentDiplomaticCandidate(candidate.type)) {
        continue;
      }
      if (!isDiplomaticOrderAcceptedWithValidator(
        economicPassValidator,
        candidate,
      )) {
        continue;
      }
      suggestions.add(candidate);
      trialOrders = appendDiplomaticOrderForTrial(
        trialOrders,
        playerId,
        candidate,
      );
    }

    workingOrders = trialOrders;
    passValidator = passValidator.forBasePrefix(workingOrders);
  }

  suggestions.sort((a, b) {
    final t = a.type.index.compareTo(b.type.index);
    if (t != 0) return t;
    final idCmp = a.targetFactionId.compareTo(b.targetFactionId);
    if (idCmp != 0) return idCmp;
    final stageCmp = (a.overtureStage?.index ?? -1).compareTo(
      b.overtureStage?.index ?? -1,
    );
    if (stageCmp != 0) return stageCmp;
    return (a.amount ?? 0).compareTo(b.amount ?? 0);
  });
  pass.logExit(candidateCount: suggestions.length);
  return suggestions;
}

/// Declare-war candidates only. Used by Full AI `declareWarOnly` diplomacy pass
/// so `establishOverture` does not block war per target (Refs #2504).
/// SPEC/program/order-suggestions.md § Declare-war-only suggestions.
List<DiplomaticOrder> suggestDeclareWarOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders, {
  Map<String, TileMapResult>? tileMapByRegion,
  IncrementalCandidateValidator? sharedCandidateValidator,
}) {
  final pass = SuggestionPassContext.forPlayerView(
    view: view,
    game: game,
    topology: topology,
    currentOrders: currentOrders,
    familyLabel: 'suggestDeclareWarOrders',
    tileMapByRegion: tileMapByRegion,
    sharedCandidateValidator: sharedCandidateValidator,
  );
  final playerId = pass.playerId;
  final suggestions = <DiplomaticOrder>[];

  final targets = resolveDiplomaticSuggestionTargetIds(
    view: view,
    game: game,
    topology: topology,
    factionMembership: pass.factionMembership,
    playerId: playerId,
  );

  final subValidatorContext = DiplomaticSubValidatorContext(
    game: game,
    playerId: playerId,
    factionMembership: pass.factionMembership,
  );

  final sortedTargetIds = targets.knownTargetIds.toList()..sort();
  final passValidator = pass.candidateValidator;

  emitAcceptedCandidates<DiplomaticOrder>(
    candidates: [
      for (final targetId in sortedTargetIds)
        if (targetId != playerId)
          declareWarSuggestionCandidate(
            subValidatorContext,
            DiplomaticSuggestionTargetView(
              targetId: targetId,
              player: view.player,
              knownTargetIds: targets.knownTargetIds,
              knownFactionIds: targets.knownFactionIds,
              playerOverturesByTargetId: const {},
              playerHoldsColony: false,
            ),
          ),
    ].whereType<DiplomaticOrder>(),
    accept: (candidate) =>
        isDiplomaticOrderAcceptedWithValidator(passValidator, candidate),
    into: suggestions,
  );

  suggestions.sort((a, b) => a.targetFactionId.compareTo(b.targetFactionId));
  pass.logExit(candidateCount: suggestions.length);
  return suggestions;
}
