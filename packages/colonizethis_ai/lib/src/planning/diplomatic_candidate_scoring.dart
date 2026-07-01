import 'dart:math' as math;

import '../perception/perception_snapshot.dart';
import '../util/faction_query.dart';
import 'army_conquest_prep.dart';
import 'planning_imports.dart';
import 'expand_phase_planner.dart';
import 'goal_manager.dart';
import 'observer_goal_phase.dart';
import 'phase_planner_diplomacy_filter.dart';
import 'phase_planner_dispatch.dart';
import 'planning_helpers.dart'
    show
        anyInvadableProvinceOwnedByGreatPower,
        anyInvadableProvinceOwnedByMinor,
        atWarGreatPowerOrderTarget,
        atWarPeaceTargetBonus,
        factionOwnsInvadableOldWorldProvince,
        gpFactionIdsAtWarWith,
        hasRecentDiplomaticEventWithinCooldown,
        isAtWarWithAnyGreatPower,
        isOwnOldWorldBelowConquestQuota,
        isOwnOldWorldExpansionStalled,
        kDiplomaticDefaultBaseScore,
        mutualExhaustedGpStalemateSideQualifies,
        orderTargetIsAtWarInvadableBlocker;
import 'war_desire_calculator.dart';

part 'diplomatic_candidate_scoring_offer_peace.dart';
part 'diplomatic_candidate_scoring_declare_war_context.dart';
part 'diplomatic_candidate_scoring_declare_war.dart';
part 'diplomatic_candidate_scoring_declare_war_bonuses.dart';
part 'diplomatic_candidate_scoring_establish_overture.dart';

final _log = packageLogger();

/// Pre-weighted-random scores for diplomatic order candidates (0 = suppressed).
/// Exposed for deterministic tests; [runDomainPlanners] uses the same values.
List<int> computeDiplomaticCandidateScores({
  required List<DiplomaticOrder> candidates,
  required String nationId,
  required Game game,
  required AIWorldSnapshot snapshot,
  required AIConfig config,
  StrategicGoal? primaryGoal,
  Orders? sameTurnPriorDiplomaticOrders,
  PhasePlanOutcome? phasePlan,
}) {
  final agendaId = config.hiddenAgendaId;
  final thresholds = resolveThresholds(
    config.personalityId,
    overrides: config.parameterOverrides,
  );
  var maxRelationForDeclareWar = getDeclareWarMaxRelationScore(agendaId);
  final behindVictoryPace =
      snapshot.conquest.provincesToVictory >
      kConquerScoreFloorProvincesToVictoryThreshold;
  final suppressGpDeclareWar =
      snapshot.conquest.provincesToVictory >
      kSuppressGpDeclareWarMinProvincesToVictory;
  final provinceOwner = getProvinceOwnerMap(game);
  final invadableOwners = <String>{
    for (final provinceId in snapshot.conquest.invadableProvinceIdsSorted)
      provinceOwner[provinceId] ?? '',
    for (final provinceId
        in snapshot.colonial.invadableNewWorldProvinceIdsSorted)
      provinceOwner[provinceId] ?? '',
  }..remove('');
  const warCooldownTurns = 4;
  const improveRelationsCooldownTurns = 2;
  final currentTurn = game.worldState.turnState.turnNumber;
  // Phase 6b (SPEC/program/worldstate-projection.md slice 7; Refs #3393):
  // replace the O(provinces x minors) nested old-world owner scan with the
  // memoised projection via the existing `_minorOwnsOldWorldProvinces` helper
  // (`ProvinceOwnerCache.ownsAnyInRegion(minorId, kRegionOldWorld)`).
  // Behaviour-preserving: the result is true iff some minor owns a non-empty
  // old-world province — exactly the prior `oldWorld.provinces.any` predicate
  // (minor ids are non-empty, and an empty/`null` owner never equals a minor id).
  final anyMinorOwnsOldWorld = game.minorNations.any(
    (m) => _minorOwnsOldWorldProvinces(game, m.id),
  );
  final warDesireByTarget = <String, int>{};
  int warDesireForTarget(String targetFactionId, num relationScore) {
    return warDesireByTarget.putIfAbsent(
      targetFactionId,
      () => computeWarDesireScore(
        game: game,
        nationId: nationId,
        targetFactionId: targetFactionId,
        relationScore: relationScore,
      ),
    );
  }

  return candidates.map((o) {
    var s = kDiplomaticDefaultBaseScore;
    switch (o.type) {
      case DiplomaticOrderType.offerPeace:
        s = _scoreOfferPeaceDiplomaticOrder(
          order: o,
          nationId: nationId,
          game: game,
          snapshot: snapshot,
          agendaId: agendaId,
          thresholds: thresholds,
          provinceOwner: provinceOwner,
          invadableOwners: invadableOwners,
          warDesireForTarget: warDesireForTarget,
        );
        break;
      case DiplomaticOrderType.alliance:
        s += getAgendaAllianceAcceptanceModifier(agendaId);
        s += (thresholds.allianceTendency - 50);
        break;
      case DiplomaticOrderType.breakAlliance:
        // Voluntary alliance break (Refs #3758 R6). Backstabber/warmonger lean
        // toward breaking (treaty-breaking modifier); the isolationist
        // "cancels alliances" so its negative alliance-acceptance modifier
        // inverts to a break boost, while peacemaker and high alliance-tendency
        // personalities resist. SPEC/ai/hidden-agendas.md § Treaty breaking.
        s += getAgendaTreatyBreakingModifier(agendaId);
        s -= getAgendaAllianceAcceptanceModifier(agendaId);
        s -= (thresholds.allianceTendency - 50);
        break;
      case DiplomaticOrderType.boycott:
        // Boycott colony trade embargo against another GP (Refs #3758 R5). A
        // hostile economic action: backstabber/warmonger agendas lean toward it
        // (treaty-breaking modifier), the peacemaker resists (peace-acceptance
        // +30 inverts to −30 while the warmonger −25 inverts to +25), and high
        // warLikelihood personalities lean toward it. Deeper trade-volume /
        // economic-damage weighting is a deferred follow-up (Refs #3758 R12).
        // SPEC/ai/hidden-agendas.md § Treaty breaking (Boycott scoring).
        s += getAgendaTreatyBreakingModifier(agendaId);
        s -= getAgendaPeaceAcceptanceModifier(agendaId);
        s += (thresholds.warLikelihood - 50);
        break;
      case DiplomaticOrderType.declareWar:
        s = _scoreDeclareWarDiplomaticOrder(
          order: o,
          nationId: nationId,
          game: game,
          snapshot: snapshot,
          agendaId: agendaId,
          thresholds: thresholds,
          maxRelationForDeclareWar: maxRelationForDeclareWar,
          behindVictoryPace: behindVictoryPace,
          suppressGpDeclareWar: suppressGpDeclareWar,
          invadableOwners: invadableOwners,
          provinceOwner: provinceOwner,
          warCooldownTurns: warCooldownTurns,
          currentTurn: currentTurn,
          anyMinorOwnsOldWorld: anyMinorOwnsOldWorld,
          primaryGoal: primaryGoal,
          warDesireForTarget: warDesireForTarget,
          sameTurnPriorDiplomaticOrders: sameTurnPriorDiplomaticOrders,
          phasePlan: phasePlan,
        );
        break;
      case DiplomaticOrderType.establishOverture:
        s = _scoreEstablishOvertureDiplomaticOrder(
          order: o,
          nationId: nationId,
          game: game,
          snapshot: snapshot,
          thresholds: thresholds,
          provinceOwner: provinceOwner,
          improveRelationsCooldownTurns: improveRelationsCooldownTurns,
          currentTurn: currentTurn,
          sameTurnPriorDiplomaticOrders: sameTurnPriorDiplomaticOrders,
          warDesireForTarget: warDesireForTarget,
        );
        break;
      default:
        break;
    }
    return s == 0 ? 0 : math.max(1, s);
  }).toList();
}

bool _minorOwnsOldWorldProvinces(Game game, String minorId) =>
    ProvinceOwnerCache.of(
      game.worldState,
    ).ownsAnyInRegion(minorId, kRegionOldWorld);

Set<String> _activeOldWorldMinorConflictIds({
  required Game game,
  required String nationId,
  required int currentTurn,
  required int warCooldownTurns,
}) {
  final conflicts = <String>{};
  for (final minor in game.minorNations) {
    if (!_minorOwnsOldWorldProvinces(game, minor.id)) {
      continue;
    }
    final rel = getRelation(game, nationId, minor.id);
    if (rel?.state == RelationState.atWar) {
      conflicts.add(minor.id);
      continue;
    }
    if (_isDecisionOnCooldown(
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
bool _pairHasScheduledRelationEventThisTurn({
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
bool _aiTrailsFavouredTradingPartner({
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
int _sellerSellableResourceTileCount({
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

bool _isDecisionOnCooldown({
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
