// Shared helpers for the diplomatic candidate scoring family (offer-peace,
// establish-overture, declare-war context/bonuses/ladder). Extracted from the
// former `diplomatic_candidate_scoring.dart` `part` cluster so each scoring
// module can import a single narrow dependency instead of sharing a `part of`
// namespace (Refs #4079 Slice A). Behaviour-preserving: bodies are unchanged
// from the prior library-private helpers, only the leading `_` was dropped so
// sibling libraries can import them.

import 'planning_helpers.dart' show hasRecentDiplomaticEventWithinCooldown;
import 'planning_imports.dart';

bool minorOwnsOldWorldProvinces(Game game, String minorId) =>
    ProvinceOwnerCache.of(
      game.worldState,
    ).ownsAnyInRegion(minorId, kRegionOldWorld);

Set<String> activeOldWorldMinorConflictIds({
  required Game game,
  required String nationId,
  required int currentTurn,
  required int warCooldownTurns,
}) {
  final conflicts = <String>{};
  for (final minor in game.minorNations) {
    if (!minorOwnsOldWorldProvinces(game, minor.id)) {
      continue;
    }
    final rel = getRelation(game, nationId, minor.id);
    if (rel?.state == RelationState.atWar) {
      conflicts.add(minor.id);
      continue;
    }
    if (isDecisionOnCooldown(
      game: game,
      actorFactionId: nationId,
      targetFactionId: minor.id,
      eventTypes: const [DiplomaticEventType.declareWar],
      cooldownTurns: warCooldownTurns,
      currentTurn: currentTurn,
    )) {
      conflicts.add(minor.id);
    }
  }
  return conflicts;
}

/// Predicts whether the (`nationId`, `targetFactionId`) relation pair will
/// receive a same-turn relation-delta event that blocks per-turn decay (Refs
/// #3753 R9.4). Uses the only deterministic planning-time signal available:
/// diplomatic orders earlier Full-AI players already committed this turn
/// ([sameTurnPriorDiplomaticOrders], keyed by acting player id). A prior order
/// from the target faction directed back at this AI lands an event on the
/// shared pair, so decay is skipped and the AI keeps full improve-relations
/// urgency. The predicate is intentionally conservative — any prior order from
/// the target toward this AI counts — so a false positive only preserves the
/// pre-existing (non-decay-aware) urgency. Returns false when no prior orders
/// are available.
bool pairHasScheduledRelationEventThisTurn({
  required Orders? sameTurnPriorDiplomaticOrders,
  required String nationId,
  required String targetFactionId,
}) {
  if (sameTurnPriorDiplomaticOrders == null) return false;
  final targetOrders =
      sameTurnPriorDiplomaticOrders
          .diplomaticOrdersByPlayerId[targetFactionId] ??
      const <DiplomaticOrder>[];
  for (final order in targetOrders) {
    if (order.targetFactionId == nationId) return true;
  }
  return false;
}

/// Whether some other Great Power currently outranks [nationId] in hidden
/// relation score with the Minor/Tribe [targetFactionId] — i.e. [nationId] is
/// not (yet) the favoured trading partner for that seller (Refs #3758 S10/R11;
/// #3753 R7). The favoured trading partner (highest GP→seller relation) wins
/// the world-market sell-priority tiebreaker among consulate-holding buyers
/// (`SPEC/game/world-market.md` § Favored Trading Partner), so a trailing AI
/// has an incentive to invest in the relationship.
///
/// The active AI's own score defaults to [relationScoreNeutral] (50) when no
/// relation row exists. Each other Great Power contributes a competing score
/// **only** when it holds an existing relation row with the target (a GP with
/// no contact contributes none). Returns `false` when [nationId]'s score is
/// greater than or equal to every other Great Power's score (the AI is already
/// the favoured partner, ties included). Pure and deterministic over [Game].
bool aiTrailsFavouredTradingPartner({
  required Game game,
  required String nationId,
  required String targetFactionId,
}) {
  final favoured = favouredTradingPartner(game, targetFactionId);
  if (favoured == null) return false;
  return favoured != nationId;
}

/// Count of **non-empty resource tiles owned by [sellerId]** — a deterministic
/// proxy for the Minor/Tribe seller's world-market sales volume (`Q × P`) used
/// by the embassy-kickback overture valuation (Refs #3758 R7/R8 / S6; #3753
/// R8.3). Iterates [WorldState.resourceByTileKey] (bounded by the count of
/// resource-bearing tiles, far smaller than the global tile count), maps each
/// tile to its province via [Unit.provinceIdFromTileKey], and counts tiles whose
/// province is owned by [sellerId] per [provinceOwner]. Purchased tiles are
/// **included** because their goods still sell on the world market and still
/// pay the kickback to every embassy holder. Pure and deterministic over
/// [Game]. SPEC/ai/phase-planner-architecture.md § Embassy-kickback overture.
int sellerSellableResourceTileCount({
  required Game game,
  required String sellerId,
  required Map<String, String> provinceOwner,
}) {
  var count = 0;
  for (final entry in game.worldState.resourceByTileKey.entries) {
    if (entry.value.isEmpty) continue;
    final provinceId = Unit.provinceIdFromTileKey(entry.key);
    if (provinceOwner[provinceId] == sellerId) count++;
  }
  return count;
}

bool isDecisionOnCooldown({
  required Game game,
  required String actorFactionId,
  required String targetFactionId,
  required List<DiplomaticEventType> eventTypes,
  required int cooldownTurns,
  required int currentTurn,
}) => hasRecentDiplomaticEventWithinCooldown(
  game: game,
  currentTurn: currentTurn,
  cooldownTurns: cooldownTurns,
  matches: (event) =>
      eventTypes.contains(event.type) &&
      event.fromFactionId == actorFactionId &&
      event.toFactionId == targetFactionId,
);
