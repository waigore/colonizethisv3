import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'incremental_candidate_validator.dart';
import 'order_suggestion_diplomatic_pass.dart';

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
  final resolved = resolveDiplomaticSuggestionPassContext(
    view: view,
    game: game,
    topology: topology,
    currentOrders: currentOrders,
    familyLabel: 'suggestDiplomaticOrders',
    tileMapByRegion: tileMapByRegion,
    sharedCandidateValidator: sharedCandidateValidator,
  );
  final pass = resolved.pass;
  final targets = resolved.targets;
  final playerId = pass.playerId;
  final suggestions = <DiplomaticOrder>[];

  final passInputs = buildDiplomaticSuggestionPassInputs(
    game: game,
    playerId: playerId,
    factionMembership: pass.factionMembership,
    player: view.player,
    knownTargetIds: targets.knownTargetIds,
    knownFactionIds: targets.knownFactionIds,
  );

  final unionTargets = <String>{
    ...targets.knownTargetIds,
    ...targets.otherGpIds,
    ...passInputs.playerOverturesByTargetId.keys,
  };

  final sortedTargetIds = unionTargets.toList()..sort();
  final passState = DiplomaticSuggestionPassState(
    workingOrders: currentOrders,
    passValidator: pass.candidateValidator,
    suggestions: suggestions,
  );
  for (final targetId in sortedTargetIds) {
    if (targetId == playerId) continue;
    acceptDiplomaticCandidatesForTarget(
      targetId: targetId,
      inputs: passInputs,
      state: passState,
    );
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
  final resolved = resolveDiplomaticSuggestionPassContext(
    view: view,
    game: game,
    topology: topology,
    currentOrders: currentOrders,
    familyLabel: 'suggestDeclareWarOrders',
    tileMapByRegion: tileMapByRegion,
    sharedCandidateValidator: sharedCandidateValidator,
  );
  final pass = resolved.pass;
  final targets = resolved.targets;
  final playerId = pass.playerId;
  final suggestions = <DiplomaticOrder>[];

  final passInputs = buildDiplomaticSuggestionPassInputs(
    game: game,
    playerId: playerId,
    factionMembership: pass.factionMembership,
    player: view.player,
    knownTargetIds: targets.knownTargetIds,
    knownFactionIds: targets.knownFactionIds,
    playerOverturesByTargetId: const {},
    playerHoldsColony: false,
  );

  final sortedTargetIds = targets.knownTargetIds.toList()..sort();
  final passState = DiplomaticSuggestionPassState(
    workingOrders: currentOrders,
    passValidator: pass.candidateValidator,
    suggestions: suggestions,
  );
  acceptDeclareWarCandidatesForTargets(
    sortedTargetIds: sortedTargetIds,
    playerId: playerId,
    inputs: passInputs,
    state: passState,
  );

  suggestions.sort((a, b) => a.targetFactionId.compareTo(b.targetFactionId));
  pass.logExit(candidateCount: suggestions.length);
  return suggestions;
}
