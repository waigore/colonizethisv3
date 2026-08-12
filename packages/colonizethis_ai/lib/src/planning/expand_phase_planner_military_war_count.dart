import 'planning_imports.dart';

/// Returns the existing GP-vs-GP war partner targeting [targetGpId] in the
/// supplied [DiplomacyRelation], or `null` when the relation does not encode
/// such a war.
///
/// Relocated from `colonial_pressure.dart` (Refs #2509 S1) as a private
/// helper for [greatPowerWarCountOnTarget]: a same-turn declare-war scoring
/// helper consumed by `diplomatic_candidate_scoring_declare_war.dart` to
/// suppress dogpiles on GPs that are already at war with at least one other
/// GP, including same-turn declarations from earlier Full-AI players. The
/// private helper survives the planned deletion of `colonial_pressure.dart`
/// alongside its public callers (Refs #2509 § S1).
///
/// Returns:
///   - `null` when [rel] is not in `RelationState.atWar`.
///   - `null` when neither faction in the relation is [targetGpId].
///   - `null` when the non-target faction is not a Great Power
///     ([Game.playerById] returns `null`).
///   - The non-target faction's id when the relation pairs [targetGpId]
///     against a different Great Power in the at-war state.
String? expandGpWarPartnerAgainstTarget(
  DiplomacyRelation rel,
  String targetGpId,
  Game game,
) {
  if (rel.state != RelationState.atWar) {
    return null;
  }
  if (rel.factionId1 == targetGpId && game.playerById(rel.factionId2) != null) {
    return rel.factionId2;
  }
  if (rel.factionId2 == targetGpId && game.playerById(rel.factionId1) != null) {
    return rel.factionId1;
  }
  return null;
}

/// True when [orders] contains a same-turn `declareWar` diplomatic order
/// pointing at [targetGpId].
///
/// Relocated from `colonial_pressure.dart` (Refs #2509 S1) as a private
/// helper for the same-turn declare-war fan-out walked by
/// [expandAddSameTurnDeclareWarGpTargets]. Survives the planned deletion of
/// `colonial_pressure.dart` alongside its public callers.
bool expandHasDeclareWarOnTarget(
  Iterable<DiplomaticOrder> orders,
  String targetGpId,
) {
  for (final order in orders) {
    if (order.type == DiplomaticOrderType.declareWar &&
        order.targetFactionId == targetGpId) {
      return true;
    }
  }
  return false;
}

/// Adds every Great Power declarer in [orders] that has a same-turn
/// `declareWar` order pointing at [targetGpId] into [atWarGpIds].
///
/// Relocated from `colonial_pressure.dart` (Refs #2509 S1) as a private
/// helper for [greatPowerWarCountOnTarget]. Walks
/// [Orders.diplomaticOrdersByPlayerId] in deterministic iteration order
/// over a per-player map; the helper only mutates [atWarGpIds] (a set,
/// so duplicates from resolved relations are folded in without altering
/// the public count).
///
/// Minor nations and tribes are skipped via [Game.playerById]; only
/// Great Power declarers contribute to the same-turn dogpile signal that
/// `diplomatic_candidate_scoring_declare_war.dart` uses to score
/// candidate declarations.
void expandAddSameTurnDeclareWarGpTargets({
  required Game game,
  required String targetGpId,
  required Orders orders,
  required Set<String> atWarGpIds,
}) {
  for (final entry in orders.diplomaticOrdersByPlayerId.entries) {
    final declarerId = entry.key;
    if (game.playerById(declarerId) == null) {
      continue;
    }
    if (!expandHasDeclareWarOnTarget(entry.value, targetGpId)) {
      continue;
    }
    atWarGpIds.add(declarerId);
  }
}

/// Returns the count of Great Powers currently warring against [targetGpId],
/// including same-turn declare-war orders from earlier Full-AI players in
/// [sameTurnPriorDiplomaticOrders] when supplied.
///
/// Same-turn declarers and resolved-relation partners are folded into a
/// shared [Set] so a GP that both declared this turn and already had an
/// at-war relation against [targetGpId] is counted only once. The set is
/// then collapsed to its length.
///
/// Consumers (`diplomatic_candidate_scoring_declare_war.dart` § war
/// concentration scoring) use the count to suppress dogpile-style
/// declarations when [targetGpId] is already engaged in multiple GP-vs-GP
/// wars (deterministic anti-dogpile gate; Refs #2509 § EXPAND phase
/// planner § declare-war suppression).
///
/// Relocated from `colonial_pressure.dart` (Refs #2509 S1) so the
/// declare-war coordination helper survives the planned deletion of
/// `colonial_pressure.dart`. Linear in
/// `(diplomacyRelations.length + sameTurnPriorDiplomaticOrders entries)`,
/// matching `colonizethis-turn-resolution-budget.mdc` § hot-loop
/// guidance (no global province / tile scans introduced by the move).
///
/// The function is pure and deterministic — identical inputs always yield
/// identical counts (Refs #2509 Must-have #7).
int greatPowerWarCountOnTarget({
  required Game game,
  required String targetGpId,
  Orders? sameTurnPriorDiplomaticOrders,
}) {
  final atWarGpIds = <String>{};
  for (final rel in game.diplomacyRelations) {
    final partner = expandGpWarPartnerAgainstTarget(rel, targetGpId, game);
    if (partner != null) {
      atWarGpIds.add(partner);
    }
  }
  if (sameTurnPriorDiplomaticOrders != null) {
    expandAddSameTurnDeclareWarGpTargets(
      game: game,
      targetGpId: targetGpId,
      orders: sameTurnPriorDiplomaticOrders,
      atWarGpIds: atWarGpIds,
    );
  }
  return atWarGpIds.length;
}

/// True when [declarerFactionId] has a same-turn `declareWar` diplomatic
/// order pointing at [targetFactionId] in [sameTurnPriorDiplomaticOrders].
///
/// Returns `false` when [sameTurnPriorDiplomaticOrders] is `null` (no
/// earlier Full-AI player has committed orders yet this turn) so callers
/// can skip the same-turn check without a separate guard.
///
/// Relocated from `colonial_pressure.dart` (Refs #2509 S1) so the
/// declare-war ordering helper survives the planned deletion of
/// `colonial_pressure.dart`. The single live consumer is
/// `diplomatic_candidate_scoring_declare_war.dart` § same-turn
/// declare-war suppression, which uses the predicate to drop a
/// candidate when the prospective target has already declared back
/// against the active player earlier in the same turn (mutual
/// declarations are not re-issued).
///
/// The function is pure and deterministic — identical inputs always yield
/// identical results (Refs #2509 Must-have #7).
bool pendingDeclareWarFrom({
  required Orders? sameTurnPriorDiplomaticOrders,
  required String declarerFactionId,
  required String targetFactionId,
}) {
  if (sameTurnPriorDiplomaticOrders == null) {
    return false;
  }
  for (final order
      in sameTurnPriorDiplomaticOrders
              .diplomaticOrdersByPlayerId[declarerFactionId] ??
          const []) {
    if (order.type == DiplomaticOrderType.declareWar &&
        order.targetFactionId == targetFactionId) {
      return true;
    }
  }
  return false;
}
