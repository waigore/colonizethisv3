import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';

/// Per-target inputs shared by diplomatic suggestion candidate builders.
final class DiplomaticSuggestionTargetContext {
  const DiplomaticSuggestionTargetContext({
    required this.game,
    required this.playerId,
    required this.player,
    required this.targetId,
    required this.knownTargetIds,
    required this.knownFactionIds,
    required this.factionMembership,
    required this.playerOverturesByTargetId,
    required this.playerHoldsColony,
  });

  final Game game;
  final String playerId;
  final Player player;
  final String targetId;
  final Set<String> knownTargetIds;
  final Set<String> knownFactionIds;
  final DiplomacyFactionMembership factionMembership;
  final Map<String, OvertureState> playerOverturesByTargetId;
  final bool playerHoldsColony;

  int get treasury => player.treasury;

  DiplomacyRelation? get relation =>
      getRelation(game, playerId, targetId);

  bool get atWar => relation?.atWar ?? false;

  bool get atPeace => relation == null || relation!.atPeace;

  bool get isGpTarget => game.playerById(targetId) != null;

  bool get targetIsMinorOrTribe => isMinorOrTribe(
    game,
    targetId,
    factionMembership: factionMembership,
  );
}

DiplomaticOrder? offerPeaceSuggestionCandidate(
  DiplomaticSuggestionTargetContext ctx,
) {
  if (!ctx.knownTargetIds.contains(ctx.targetId) || !ctx.atWar) {
    return null;
  }
  return DiplomaticOrder(
    type: DiplomaticOrderType.offerPeace,
    targetFactionId: ctx.targetId,
  );
}

DiplomaticOrder? breakAllianceSuggestionCandidate(
  DiplomaticSuggestionTargetContext ctx,
) {
  final rel = ctx.relation;
  if (!ctx.isGpTarget || rel == null || !rel.formalAlliance || !rel.atPeace) {
    return null;
  }
  return DiplomaticOrder(
    type: DiplomaticOrderType.breakAlliance,
    targetFactionId: ctx.targetId,
  );
}

DiplomaticOrder? allianceSuggestionCandidate(
  DiplomaticSuggestionTargetContext ctx,
) {
  final rel = ctx.relation;
  if (!ctx.isGpTarget ||
      rel == null ||
      !rel.atPeace ||
      rel.formalAlliance ||
      rel.level == RelationLevel.allied) {
    return null;
  }
  return DiplomaticOrder(
    type: DiplomaticOrderType.alliance,
    targetFactionId: ctx.targetId,
  );
}

DiplomaticOrder? establishOvertureSuggestionCandidate(
  DiplomaticSuggestionTargetContext ctx,
) {
  if (!ctx.targetIsMinorOrTribe ||
      !ctx.knownFactionIds.contains(ctx.targetId)) {
    return null;
  }
  return _establishOvertureSuggestionOrder(
    game: ctx.game,
    playerId: ctx.playerId,
    targetId: ctx.targetId,
    treasury: ctx.treasury,
  );
}

List<DiplomaticOrder> economicDiplomaticSuggestionCandidates(
  DiplomaticSuggestionTargetContext ctx,
) {
  final out = <DiplomaticOrder>[];
  final overtureRow = ctx.playerOverturesByTargetId[ctx.targetId];
  if (overtureRow == null) return out;

  if (overtureRow.hasEmbassy && ctx.treasury >= grantAidDefaultAmount) {
    out.add(
      DiplomaticOrder(
        type: DiplomaticOrderType.grantAid,
        targetFactionId: ctx.targetId,
        amount: grantAidDefaultAmount,
      ),
    );
  }
  if (ctx.targetIsMinorOrTribe && overtureRow.hasEmbassy) {
    out.add(
      DiplomaticOrder(
        type: DiplomaticOrderType.setSubsidy,
        targetFactionId: ctx.targetId,
        amount: kSubsidyPercentDefault,
      ),
    );
  }
  return out;
}

DiplomaticOrder? boycottSuggestionCandidate(
  DiplomaticSuggestionTargetContext ctx,
) {
  final rel = ctx.relation;
  if (!ctx.playerHoldsColony ||
      !ctx.isGpTarget ||
      rel == null ||
      !rel.atPeace ||
      ctx.game.boycottStates.any(
        (b) => b.gpId == ctx.playerId && b.targetGpId == ctx.targetId,
      )) {
    return null;
  }
  return DiplomaticOrder(
    type: DiplomaticOrderType.boycott,
    targetFactionId: ctx.targetId,
  );
}

DiplomaticOrder? declareWarSuggestionCandidate(
  DiplomaticSuggestionTargetContext ctx,
) {
  if (!ctx.knownTargetIds.contains(ctx.targetId) || !ctx.atPeace) {
    return null;
  }
  return DiplomaticOrder(
    type: DiplomaticOrderType.declareWar,
    targetFactionId: ctx.targetId,
  );
}

/// Per-target suggestion order: first candidate that passes the order engine wins.
/// SPEC/program/order-suggestions.md § Diplomatic orders.
List<DiplomaticOrder> diplomaticCandidatesForTargetOrdered(
  DiplomaticSuggestionTargetContext ctx,
) {
  if (ctx.targetId == ctx.playerId) return const <DiplomaticOrder>[];

  final out = <DiplomaticOrder>[];
  for (final candidate in <DiplomaticOrder?>[
    offerPeaceSuggestionCandidate(ctx),
    breakAllianceSuggestionCandidate(ctx),
    allianceSuggestionCandidate(ctx),
    establishOvertureSuggestionCandidate(ctx),
    ...economicDiplomaticSuggestionCandidates(ctx),
    boycottSuggestionCandidate(ctx),
    declareWarSuggestionCandidate(ctx),
  ]) {
    if (candidate != null) out.add(candidate);
  }
  return out;
}

DiplomaticOrder? _establishOvertureSuggestionOrder({
  required Game game,
  required String playerId,
  required String targetId,
  required int treasury,
}) {
  final rel = getRelation(game, playerId, targetId);
  final atWar = rel?.atWar ?? false;
  if (atWar) return null;

  final existing = getOverture(game, playerId, targetId);
  final current = existing?.stage ?? OvertureStage.none;
  final next = current.next;
  if (next == null) return null;
  if (next == OvertureStage.tradeConsulate || next == OvertureStage.embassy) {
    final cost = next == OvertureStage.tradeConsulate
        ? overtureConsulateCost
        : overtureEmbassyCost;
    if (treasury < cost) return null;
  }
  if (next == OvertureStage.tradeConsulate ||
      next == OvertureStage.embassy ||
      next == OvertureStage.nap) {
    final submitter = game.playerById(playerId);
    if (submitter?.techUnlocked?[kTechIdDiplomaticExpertise] != true) {
      return null;
    }
  }
  if (next == OvertureStage.joinEmpire) {
    final score = rel?.score ?? relationScoreNeutral;
    if (score < relationScoreMinFriendly) return null;
    final cost = joinEmpireCostForMinorOrTribe(game, targetId);
    if (treasury < cost) return null;
  }
  return DiplomaticOrder(
    type: DiplomaticOrderType.establishOverture,
    targetFactionId: targetId,
    overtureStage: next,
  );
}
