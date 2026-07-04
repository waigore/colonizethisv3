import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';

import 'validators/diplomatic/diplomatic_sub_validator.dart';

/// Per-target view inputs for diplomatic suggestion candidate builders.
final class DiplomaticSuggestionTargetView {
  const DiplomaticSuggestionTargetView({
    required this.targetId,
    required this.player,
    required this.knownTargetIds,
    required this.knownFactionIds,
    required this.playerOverturesByTargetId,
    required this.playerHoldsColony,
  });

  final String targetId;
  final Player player;
  final Set<String> knownTargetIds;
  final Set<String> knownFactionIds;
  final Map<String, OvertureState> playerOverturesByTargetId;
  final bool playerHoldsColony;

  int get treasury => player.treasury;
}

DiplomaticOrder? offerPeaceSuggestionCandidate(
  DiplomaticSubValidatorContext ctx,
  DiplomaticSuggestionTargetView target,
) {
  final rel = getRelation(ctx.game, ctx.playerId, target.targetId);
  if (!target.knownTargetIds.contains(target.targetId) ||
      rel?.atWar != true) {
    return null;
  }
  return DiplomaticOrder(
    type: DiplomaticOrderType.offerPeace,
    targetFactionId: target.targetId,
  );
}

DiplomaticOrder? breakAllianceSuggestionCandidate(
  DiplomaticSubValidatorContext ctx,
  DiplomaticSuggestionTargetView target,
) {
  final rel = getRelation(ctx.game, ctx.playerId, target.targetId);
  final isGpTarget = ctx.game.playerById(target.targetId) != null;
  if (!isGpTarget || rel == null || !rel.formalAlliance || !rel.atPeace) {
    return null;
  }
  return DiplomaticOrder(
    type: DiplomaticOrderType.breakAlliance,
    targetFactionId: target.targetId,
  );
}

DiplomaticOrder? allianceSuggestionCandidate(
  DiplomaticSubValidatorContext ctx,
  DiplomaticSuggestionTargetView target,
) {
  final rel = getRelation(ctx.game, ctx.playerId, target.targetId);
  final isGpTarget = ctx.game.playerById(target.targetId) != null;
  if (!isGpTarget ||
      rel == null ||
      !rel.atPeace ||
      rel.formalAlliance ||
      rel.level == RelationLevel.allied) {
    return null;
  }
  return DiplomaticOrder(
    type: DiplomaticOrderType.alliance,
    targetFactionId: target.targetId,
  );
}

DiplomaticOrder? establishOvertureSuggestionCandidate(
  DiplomaticSubValidatorContext ctx,
  DiplomaticSuggestionTargetView target,
) {
  final factionMembership =
      ctx.factionMembership ?? DiplomacyFactionMembership.from(ctx.game);
  final targetIsMinorOrTribe = isMinorOrTribe(
    ctx.game,
    target.targetId,
    factionMembership: factionMembership,
  );
  if (!targetIsMinorOrTribe ||
      !target.knownFactionIds.contains(target.targetId)) {
    return null;
  }
  return _establishOvertureSuggestionOrder(
    ctx: ctx,
    targetId: target.targetId,
    treasury: target.treasury,
  );
}

List<DiplomaticOrder> grantAidSuggestionCandidates(
  DiplomaticSubValidatorContext ctx,
  DiplomaticSuggestionTargetView target,
) {
  final overtureRow = target.playerOverturesByTargetId[target.targetId];
  if (overtureRow == null ||
      !overtureRow.hasEmbassy ||
      target.treasury < grantAidDefaultAmount) {
    return const [];
  }
  return [
    DiplomaticOrder(
      type: DiplomaticOrderType.grantAid,
      targetFactionId: target.targetId,
      amount: grantAidDefaultAmount,
    ),
  ];
}

List<DiplomaticOrder> setSubsidySuggestionCandidates(
  DiplomaticSubValidatorContext ctx,
  DiplomaticSuggestionTargetView target,
) {
  final factionMembership =
      ctx.factionMembership ?? DiplomacyFactionMembership.from(ctx.game);
  final targetIsMinorOrTribe = isMinorOrTribe(
    ctx.game,
    target.targetId,
    factionMembership: factionMembership,
  );
  final overtureRow = target.playerOverturesByTargetId[target.targetId];
  if (!targetIsMinorOrTribe ||
      overtureRow == null ||
      !overtureRow.hasEmbassy) {
    return const [];
  }
  return [
    DiplomaticOrder(
      type: DiplomaticOrderType.setSubsidy,
      targetFactionId: target.targetId,
      amount: kSubsidyPercentDefault,
    ),
  ];
}

DiplomaticOrder? boycottSuggestionCandidate(
  DiplomaticSubValidatorContext ctx,
  DiplomaticSuggestionTargetView target,
) {
  final rel = getRelation(ctx.game, ctx.playerId, target.targetId);
  final isGpTarget = ctx.game.playerById(target.targetId) != null;
  if (!target.playerHoldsColony ||
      !isGpTarget ||
      rel == null ||
      !rel.atPeace ||
      ctx.game.boycottStates.any(
        (b) => b.gpId == ctx.playerId && b.targetGpId == target.targetId,
      )) {
    return null;
  }
  return DiplomaticOrder(
    type: DiplomaticOrderType.boycott,
    targetFactionId: target.targetId,
  );
}

DiplomaticOrder? declareWarSuggestionCandidate(
  DiplomaticSubValidatorContext ctx,
  DiplomaticSuggestionTargetView target,
) {
  final rel = getRelation(ctx.game, ctx.playerId, target.targetId);
  final atPeace = rel == null || rel.atPeace;
  if (!target.knownTargetIds.contains(target.targetId) || !atPeace) {
    return null;
  }
  return DiplomaticOrder(
    type: DiplomaticOrderType.declareWar,
    targetFactionId: target.targetId,
  );
}

/// Per-target suggestion order: first candidate that passes the order engine wins.
/// SPEC/program/order-suggestions.md § Diplomatic orders.
List<DiplomaticOrder> diplomaticCandidatesForTargetOrdered(
  DiplomaticSubValidatorContext ctx,
  DiplomaticSuggestionTargetView target,
) {
  if (target.targetId == ctx.playerId) return const <DiplomaticOrder>[];

  final out = <DiplomaticOrder>[];
  for (final candidate in <DiplomaticOrder?>[
    offerPeaceSuggestionCandidate(ctx, target),
    breakAllianceSuggestionCandidate(ctx, target),
    allianceSuggestionCandidate(ctx, target),
    establishOvertureSuggestionCandidate(ctx, target),
    ...grantAidSuggestionCandidates(ctx, target),
    ...setSubsidySuggestionCandidates(ctx, target),
    boycottSuggestionCandidate(ctx, target),
    declareWarSuggestionCandidate(ctx, target),
  ]) {
    if (candidate != null) out.add(candidate);
  }
  return out;
}

DiplomaticOrder? _establishOvertureSuggestionOrder({
  required DiplomaticSubValidatorContext ctx,
  required String targetId,
  required int treasury,
}) {
  final game = ctx.game;
  final playerId = ctx.playerId;
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
    if (!ctx.hasDiplomaticExpertise) return null;
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
