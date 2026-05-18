import 'dart:math' as math;

import '../perception/perception_snapshot.dart';
import 'planning_imports.dart';
import 'colonial_pressure.dart';
import 'goal_manager.dart';
import 'war_desire_calculator.dart';

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
}) {
  final agendaId = config.hiddenAgendaId;
  final thresholds = getThresholdsForLeader(config.personalityId);
  var maxRelationForDeclareWar = getDeclareWarMaxRelationScore(agendaId);
  final behindVictoryPace = snapshot.conquest.provincesToVictory >
      kConquerScoreFloorProvincesToVictoryThreshold;
  final suppressGpDeclareWar = snapshot.conquest.provincesToVictory >
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
  final anyMinorOwnsOldWorld = game.worldState.oldWorld.provinces.any(
    (p) =>
        p.ownerId != null &&
        p.ownerId!.isNotEmpty &&
        game.minorNations.any((m) => m.id == p.ownerId),
  );
  final warDesireByTarget = <String, int>{};
  int warDesireForTarget(String targetFactionId, int relationScore) {
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
    var s = 50;
    switch (o.type) {
      case DiplomaticOrderType.offerPeace:
        {
          final rel = snapshot.relations[o.targetFactionId];
          final warDesire = warDesireForTarget(
            o.targetFactionId,
            rel?.score ?? 50,
          );
          // Lower peace desire when current war desire remains high.
          s -= (warDesire - 50);
          if (_isMinorOrTribeFaction(game, o.targetFactionId) &&
              snapshot.threats.atWarWith.contains(o.targetFactionId) &&
              (!_minorOwnsOldWorldProvinces(game, o.targetFactionId) ||
                  !invadableOwners.contains(o.targetFactionId))) {
            s += kOfferPeaceFutileMinorWarBonus;
          }
          final targetGp = game.playerById(o.targetFactionId);
          if (targetGp != null &&
              snapshot.threats.atWarWith.contains(o.targetFactionId) &&
              isStalledOldWorldExpansion(
                snapshot.conquest.oldWorldProvincesOwned,
              ) &&
              provinceCountOwnedBy(game, o.targetFactionId) >
                  snapshot.conquest.oldWorldProvincesOwned &&
              snapshot.conquest.invadableProvinceIdsSorted.any(
                (pid) => provinceOwner[pid] == o.targetFactionId,
              )) {
            s += kOfferPeaceStalledStrongerGpBlockerBonus;
          }
          if (targetGp != null &&
              snapshot.threats.atWarWith.contains(o.targetFactionId) &&
              isStalledOldWorldExpansion(
                snapshot.conquest.oldWorldProvincesOwned,
              ) &&
              !snapshot.conquest.invadableProvinceIdsSorted.any(
                (pid) => provinceOwner[pid] == o.targetFactionId,
              ) &&
              snapshot.conquest.invadableProvinceIdsSorted.any((pid) {
                final owner = provinceOwner[pid];
                return owner != null &&
                    (game.minorNations.any((m) => m.id == owner) ||
                        game.playerById(owner) != null);
              })) {
            s += kOfferPeaceStalledFutileGpWarBonus;
          }
          final gpBlocker = primaryInvadableOldWorldGpBlocker(
            game: game,
            snapshot: snapshot,
          );
          if (targetGp != null &&
              gpBlocker != null &&
              o.targetFactionId != gpBlocker &&
              snapshot.threats.atWarWith.contains(o.targetFactionId) &&
              isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot)) {
            s += kOfferPeaceStalledFutileGpWarBonus;
          }
          if (targetGp != null &&
              snapshot.threats.atWarWith.contains(o.targetFactionId) &&
              unwinnableSoleGpFrontierPeaceTarget(
                    game: game,
                    snapshot: snapshot,
                  ) ==
                  o.targetFactionId) {
            s += kOfferPeaceUnwinnableSoleGpWarBonus;
          }
          if (targetGp != null &&
              snapshot.threats.atWarWith.contains(o.targetFactionId) &&
              consolidateGainsSoleGpPeaceTarget(
                    game: game,
                    snapshot: snapshot,
                  ) ==
                  o.targetFactionId) {
            s += kOfferPeaceConsolidateGainsSoleGpWarBonus;
          }
          if (targetGp != null &&
              gpBlocker != null &&
              o.targetFactionId == gpBlocker &&
              snapshot.threats.atWarWith.contains(gpBlocker) &&
              snapshot.conquest.oldWorldProvincesOwned <=
                  kFewOldWorldProvincesDefendThreshold &&
              provinceCountOwnedBy(game, gpBlocker) >=
                  snapshot.conquest.oldWorldProvincesOwned +
                      kDeclareWarAggressorSuppressWeakGpLeadThreshold) {
            s += kOfferPeaceWeakVsInvadableBlockerBonus;
          }
        }
        s += getAgendaPeaceAcceptanceModifier(agendaId);
        s += (thresholds.peaceTendency - 50);
        break;
      case DiplomaticOrderType.alliance:
        s += getAgendaAllianceAcceptanceModifier(agendaId);
        s += (thresholds.allianceTendency - 50);
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
        );
        break;
      case DiplomaticOrderType.establishOverture:
        {
          if (_isDecisionOnCooldown(
            game: game,
            actorFactionId: nationId,
            targetFactionId: o.targetFactionId,
            eventTypes: const [
              DiplomaticEventType.overtureAccepted,
              DiplomaticEventType.overtureRejected,
            ],
            cooldownTurns: improveRelationsCooldownTurns,
            currentTurn: currentTurn,
          )) {
            s = 0;
            break;
          }
          final rel = snapshot.relations[o.targetFactionId];
          final warDesire = warDesireForTarget(
            o.targetFactionId,
            rel?.score ?? 50,
          );
          final improveRelationsDesire = 100 - warDesire;
          s += (improveRelationsDesire - 50);
          if (snapshot.colonial.preferredColonialTargetFactionIdsSorted
              .contains(o.targetFactionId)) {
            s += kEstablishOvertureColonialTribeBonus;
          }
          final ownsInvadableNw = snapshot
              .colonial
              .invadableNewWorldProvinceIdsSorted
              .any((pid) => provinceOwner[pid] == o.targetFactionId);
          if (ownsInvadableNw && _isTribeFaction(game, o.targetFactionId)) {
            s += kEstablishOvertureColonialInvadableOwnerBonus;
          }
          break;
        }
      default:
        break;
    }
    return s == 0 ? 0 : math.max(1, s);
  }).toList();
}

int _scoreDeclareWarDiplomaticOrder({
  required DiplomaticOrder order,
  required String nationId,
  required Game game,
  required AIWorldSnapshot snapshot,
  required String agendaId,
  required PersonalityThresholds thresholds,
  required int maxRelationForDeclareWar,
  required bool behindVictoryPace,
  required bool suppressGpDeclareWar,
  required Set<String> invadableOwners,
  required Map<String, String> provinceOwner,
  required int warCooldownTurns,
  required int currentTurn,
  required bool anyMinorOwnsOldWorld,
  required StrategicGoal? primaryGoal,
  required int Function(String targetFactionId, int relationScore)
  warDesireForTarget,
}) {
  final ctx = _DeclareWarTargetContext.build(
    order: order,
    nationId: nationId,
    game: game,
    snapshot: snapshot,
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
    agendaId: agendaId,
  );
  final suppressed = _declareWarSuppressedScore(ctx);
  if (suppressed != null) {
    return suppressed;
  }
  return _scoreDeclareWarBonuses(ctx);
}

final class _DeclareWarTargetContext {
  _DeclareWarTargetContext._({
    required this.order,
    required this.nationId,
    required this.game,
    required this.snapshot,
    required this.agendaId,
    required this.thresholds,
    required this.maxRelationForDeclareWar,
    required this.behindVictoryPace,
    required this.suppressGpDeclareWar,
    required this.invadableOwners,
    required this.provinceOwner,
    required this.warCooldownTurns,
    required this.currentTurn,
    required this.anyMinorOwnsOldWorld,
    required this.primaryGoal,
    required this.warDesireForTarget,
    required this.relation,
    required this.relationScore,
    required this.adjacentOwners,
    required this.isAdjacentOwner,
    required this.isColonialAdjacentOwner,
    required this.isMinorTarget,
    required this.ownsInvadableNw,
    required this.colonialPressure,
    required this.isTribeTarget,
    required this.stalledOwExpansion,
    required this.ownsInvadableOwMinor,
    required this.weakerDistantMinor,
    required this.hasInvadableMinorOwner,
    required this.minorsHoldOldWorldProvinces,
    required this.atWarInvadableOwMinor,
    required this.activeMinorConflicts,
    required this.hasAdjacentInvadableMinorOwner,
    required this.isAdjacentGp,
    required this.invadableGpBlocker,
    required this.invadableGpBlockerWeaker,
    required this.invadableOwOwnedByGp,
    required this.tribeOwnsOwInvadable,
  });

  final DiplomaticOrder order;
  final String nationId;
  final Game game;
  final AIWorldSnapshot snapshot;
  final String agendaId;
  final PersonalityThresholds thresholds;
  final int maxRelationForDeclareWar;
  final bool behindVictoryPace;
  final bool suppressGpDeclareWar;
  final Set<String> invadableOwners;
  final Map<String, String> provinceOwner;
  final int warCooldownTurns;
  final int currentTurn;
  final bool anyMinorOwnsOldWorld;
  final StrategicGoal? primaryGoal;
  final int Function(String targetFactionId, int relationScore) warDesireForTarget;
  final DiplomacyRelation? relation;
  final int relationScore;
  final List<String> adjacentOwners;
  final bool isAdjacentOwner;
  final bool isColonialAdjacentOwner;
  final bool isMinorTarget;
  final bool ownsInvadableNw;
  final bool colonialPressure;
  final bool isTribeTarget;
  final bool stalledOwExpansion;
  final bool ownsInvadableOwMinor;
  final bool weakerDistantMinor;
  final bool hasInvadableMinorOwner;
  final bool minorsHoldOldWorldProvinces;
  final bool atWarInvadableOwMinor;
  final Set<String> activeMinorConflicts;
  final bool hasAdjacentInvadableMinorOwner;
  final bool isAdjacentGp;
  final bool invadableGpBlocker;
  final bool invadableGpBlockerWeaker;
  final bool invadableOwOwnedByGp;
  final bool tribeOwnsOwInvadable;

  factory _DeclareWarTargetContext.build({
    required DiplomaticOrder order,
    required String nationId,
    required Game game,
    required AIWorldSnapshot snapshot,
    required String agendaId,
    required PersonalityThresholds thresholds,
    required int maxRelationForDeclareWar,
    required bool behindVictoryPace,
    required bool suppressGpDeclareWar,
    required Set<String> invadableOwners,
    required Map<String, String> provinceOwner,
    required int warCooldownTurns,
    required int currentTurn,
    required bool anyMinorOwnsOldWorld,
    required StrategicGoal? primaryGoal,
    required int Function(String targetFactionId, int relationScore)
    warDesireForTarget,
  }) {
    final relation = snapshot.relations[order.targetFactionId];
    final relationScore = relation?.score ?? 50;
    final adjacentOwners = snapshot.conquest.adjacentOwnerFactionIdsSorted;
    final colonialAdjacent =
        snapshot.colonial.adjacentNewWorldOwnerFactionIdsSorted;
    final isAdjacentOwner = adjacentOwners.contains(order.targetFactionId);
    final isColonialAdjacentOwner =
        colonialAdjacent.contains(order.targetFactionId);
    final isMinorTarget = _isMinorOrTribeFaction(game, order.targetFactionId);
    final ownsInvadableNw = snapshot.colonial.invadableNewWorldProvinceIdsSorted
        .any((pid) => provinceOwner[pid] == order.targetFactionId);
    final colonialPressure = hasColonialAcquisitionTargets(snapshot.colonial) &&
        !isStalledOldWorldGpBlockerFocus(game: game, snapshot: snapshot);
    final isTribeTarget = _isTribeFaction(game, order.targetFactionId);
    final stalledOwExpansion = isObserverConquestExpansionPressure(
      snapshot.conquest.oldWorldProvincesOwned,
    );
    final ownsInvadableOwMinor = isMinorTarget &&
        !isTribeTarget &&
        invadableOwners.contains(order.targetFactionId);
    final minorProvinces = isMinorTarget && !isTribeTarget
        ? provinceCountOwnedBy(game, order.targetFactionId)
        : 0;
    final weakerDistantMinor = stalledOwExpansion &&
        behindVictoryPace &&
        isMinorTarget &&
        !isTribeTarget &&
        !isAdjacentOwner &&
        !invadableOwners.contains(order.targetFactionId) &&
        !isColonialAdjacentOwner &&
        !ownsInvadableNw &&
        minorProvinces > 0 &&
        minorProvinces < snapshot.conquest.oldWorldProvincesOwned;
    final hasInvadableMinorOwner = invadableOwners.any(
      (id) => game.minorNations.any((m) => m.id == id),
    );
    final minorsHoldOldWorldProvinces = game.minorNations.any(
      (m) => game.worldState.oldWorld.provinces.any((p) => p.ownerId == m.id),
    );
    final atWarInvadableOwMinor = snapshot.threats.atWarWith.any(
      (factionId) =>
          game.minorNations.any((m) => m.id == factionId) &&
          invadableOwners.contains(factionId),
    );
    final activeMinorConflicts = _activeOldWorldMinorConflictIds(
      game: game,
      nationId: nationId,
      currentTurn: currentTurn,
      warCooldownTurns: warCooldownTurns,
    );
    final hasAdjacentInvadableMinorOwner = adjacentOwners.any(
      (id) =>
          game.minorNations.any((m) => m.id == id) &&
          invadableOwners.contains(id),
    );
    final isAdjacentGp =
        isAdjacentOwner && game.playerById(order.targetFactionId) != null;
    final invadableGpBlocker = game.playerById(order.targetFactionId) != null &&
        snapshot.conquest.invadableProvinceIdsSorted.any(
          (pid) => provinceOwner[pid] == order.targetFactionId,
        );
    final invadableGpBlockerWeaker = invadableGpBlocker &&
        provinceCountOwnedBy(game, order.targetFactionId) <=
            snapshot.conquest.oldWorldProvincesOwned;
    final invadableOwOwnedByGp =
        snapshot.conquest.invadableProvinceIdsSorted.any(
      (pid) => game.playerById(provinceOwner[pid] ?? '') != null,
    );
    final tribeOwnsOwInvadable = isTribeTarget &&
        snapshot.conquest.invadableProvinceIdsSorted.any(
          (pid) => provinceOwner[pid] == order.targetFactionId,
        );
    return _DeclareWarTargetContext._(
      order: order,
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
      relation: relation,
      relationScore: relationScore,
      adjacentOwners: adjacentOwners,
      isAdjacentOwner: isAdjacentOwner,
      isColonialAdjacentOwner: isColonialAdjacentOwner,
      isMinorTarget: isMinorTarget,
      ownsInvadableNw: ownsInvadableNw,
      colonialPressure: colonialPressure,
      isTribeTarget: isTribeTarget,
      stalledOwExpansion: stalledOwExpansion,
      ownsInvadableOwMinor: ownsInvadableOwMinor,
      weakerDistantMinor: weakerDistantMinor,
      hasInvadableMinorOwner: hasInvadableMinorOwner,
      minorsHoldOldWorldProvinces: minorsHoldOldWorldProvinces,
      atWarInvadableOwMinor: atWarInvadableOwMinor,
      activeMinorConflicts: activeMinorConflicts,
      hasAdjacentInvadableMinorOwner: hasAdjacentInvadableMinorOwner,
      isAdjacentGp: isAdjacentGp,
      invadableGpBlocker: invadableGpBlocker,
      invadableGpBlockerWeaker: invadableGpBlockerWeaker,
      invadableOwOwnedByGp: invadableOwOwnedByGp,
      tribeOwnsOwInvadable: tribeOwnsOwInvadable,
    );
  }
}

/// Returns a suppressed score when declare-war should not proceed; null = score.
int? _declareWarSuppressedScore(_DeclareWarTargetContext ctx) {
  if (ctx.isTribeTarget &&
      ctx.stalledOwExpansion &&
      (ctx.minorsHoldOldWorldProvinces ||
          ctx.activeMinorConflicts.isNotEmpty ||
          ctx.invadableOwOwnedByGp)) {
    return 0;
  }
  if (ctx.stalledOwExpansion &&
      ctx.invadableOwOwnedByGp &&
      !ctx.hasInvadableMinorOwner &&
      (ctx.isTribeTarget ||
          (ctx.game.playerById(ctx.order.targetFactionId) != null &&
              !ctx.invadableGpBlocker) ||
          (ctx.isMinorTarget && !ctx.isTribeTarget && !ctx.weakerDistantMinor))) {
    return 0;
  }
  if (ctx.stalledOwExpansion && ctx.isMinorTarget && !ctx.isTribeTarget) {
    final continuingMinorConflict =
        ctx.activeMinorConflicts.contains(ctx.order.targetFactionId);
    final adjacentInvadableMinor = ctx.isAdjacentOwner &&
        ctx.invadableOwners.contains(ctx.order.targetFactionId);
    final distantInvadableMinorOwner =
        ctx.invadableOwners.contains(ctx.order.targetFactionId);
    if (ctx.activeMinorConflicts.isNotEmpty) {
      if (!continuingMinorConflict) {
        return 0;
      }
    } else if (ctx.hasAdjacentInvadableMinorOwner) {
      if (!adjacentInvadableMinor) {
        return 0;
      }
    } else if (!adjacentInvadableMinor &&
        !ctx.weakerDistantMinor &&
        !distantInvadableMinorOwner &&
        !(ctx.behindVictoryPace &&
            ctx.anyMinorOwnsOldWorld &&
            _minorOwnsOldWorldProvinces(
              ctx.game,
              ctx.order.targetFactionId,
            ))) {
      return 0;
    }
  }
  if (ctx.behindVictoryPace &&
      ctx.adjacentOwners.isNotEmpty &&
      !ctx.isAdjacentOwner &&
      !ctx.isColonialAdjacentOwner &&
      !(ctx.ownsInvadableNw && ctx.isMinorTarget) &&
      !(ctx.stalledOwExpansion && ctx.ownsInvadableOwMinor) &&
      !ctx.weakerDistantMinor) {
    return kDeclareWarNonAdjacentSuppressedScore;
  }
  if (ctx.stalledOwExpansion &&
      ctx.isAdjacentGp &&
      !ctx.invadableGpBlockerWeaker &&
      !ctx.invadableGpBlocker) {
    return 0;
  }
  if (ctx.order.type == DiplomaticOrderType.declareWar &&
      ctx.isAdjacentGp &&
      ctx.snapshot.conquest.oldWorldProvincesOwned <=
          kFewOldWorldProvincesDefendThreshold &&
      provinceCountOwnedBy(ctx.game, ctx.order.targetFactionId) >
          ctx.snapshot.conquest.oldWorldProvincesOwned) {
    return 0;
  }
  if (ctx.order.type == DiplomaticOrderType.declareWar &&
      ctx.isAdjacentGp &&
      ctx.game.playerById(ctx.order.targetFactionId) != null &&
      ctx.snapshot.conquest.oldWorldProvincesOwned <=
          kFewOldWorldProvincesDefendThreshold &&
      ctx.snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty &&
      !ctx.snapshot.threats.atWarWith.contains(ctx.order.targetFactionId)) {
    return 0;
  }
  if (ctx.order.type == DiplomaticOrderType.declareWar &&
      ctx.isAdjacentGp &&
      ctx.game.playerById(ctx.order.targetFactionId) != null &&
      isObserverConquestExpansionPressure(
        ctx.snapshot.conquest.oldWorldProvincesOwned,
      )) {
    final targetOw = provinceCountOwnedBy(ctx.game, ctx.order.targetFactionId);
    if (targetOw <= kFewOldWorldProvincesDefendThreshold &&
        ctx.snapshot.conquest.oldWorldProvincesOwned >=
            targetOw + kDeclareWarAggressorSuppressWeakGpLeadThreshold) {
      return 0;
    }
  }
  final atWarWithGp = ctx.snapshot.threats.atWarWith.any(
    (id) => ctx.game.playerById(id) != null,
  );
  if (ctx.stalledOwExpansion &&
      atWarWithGp &&
      ctx.isAdjacentGp &&
      ctx.game.playerById(ctx.order.targetFactionId) != null &&
      !ctx.snapshot.threats.atWarWith.contains(ctx.order.targetFactionId)) {
    return 0;
  }
  if (ctx.stalledOwExpansion &&
      ctx.invadableGpBlocker &&
      provinceCountOwnedBy(ctx.game, ctx.order.targetFactionId) >
          ctx.snapshot.conquest.oldWorldProvincesOwned &&
      ctx.hasInvadableMinorOwner) {
    return 0;
  }
  if (ctx.stalledOwExpansion &&
      ctx.isTribeTarget &&
      !ctx.tribeOwnsOwInvadable &&
      !(ctx.colonialPressure && ctx.ownsInvadableNw) &&
      (ctx.behindVictoryPace ||
          ctx.hasInvadableMinorOwner ||
          ctx.atWarInvadableOwMinor)) {
    return kDeclareWarNonAdjacentSuppressedScore;
  }
  if (ctx.suppressGpDeclareWar &&
      ctx.isAdjacentGp &&
      !(ctx.stalledOwExpansion && ctx.invadableGpBlockerWeaker)) {
    return kDeclareWarNonAdjacentSuppressedScore;
  }
  if (ctx.suppressGpDeclareWar &&
      ctx.isAdjacentGp &&
      ctx.stalledOwExpansion &&
      ctx.behindVictoryPace &&
      ctx.hasInvadableMinorOwner &&
      !ctx.invadableGpBlocker &&
      !ctx.invadableGpBlockerWeaker &&
      ctx.thresholds.warLikelihood <= kDeclareWarLowWarLikelihoodThreshold) {
    return kDeclareWarNonAdjacentSuppressedScore;
  }
  final effectiveMaxRelation = ctx.behindVictoryPace && ctx.isMinorTarget
      ? kDeclareWarMinorMaxRelationWhenFarFromVictory
      : ctx.behindVictoryPace && ctx.isAdjacentGp
      ? kDeclareWarGpMaxRelationWhenFarFromVictory
      : ctx.maxRelationForDeclareWar;
  if (ctx.relationScore > effectiveMaxRelation) {
    return 0;
  }
  if (_isDecisionOnCooldown(
    game: ctx.game,
    actorFactionId: ctx.nationId,
    targetFactionId: ctx.order.targetFactionId,
    eventTypes: const [DiplomaticEventType.declareWar],
    cooldownTurns: ctx.warCooldownTurns,
    currentTurn: ctx.currentTurn,
  )) {
    return 0;
  }
  return null;
}

int _scoreDeclareWarBonuses(_DeclareWarTargetContext ctx) {
  var s = _declareWarCoreBonuses(ctx);
  s = _declareWarExpansionAndColonialBonuses(ctx, s);
  s = _declareWarAdjacencyAndStalledBonuses(ctx, s);
  return _declareWarFinalizeBonuses(ctx, s);
}

int _declareWarCoreBonuses(_DeclareWarTargetContext ctx) {
  final warDesire =
      ctx.warDesireForTarget(ctx.order.targetFactionId, ctx.relationScore);
  final targetProvinceCount =
      provinceCountOwnedBy(ctx.game, ctx.order.targetFactionId);
  final desiredTerritory = targetProvinceCount <= 0
      ? 1
      : ((warDesire / 25).round()).clamp(1, targetProvinceCount);
  var s = 50;
  s += getAgendaConquerModifier(ctx.agendaId);
  s += getAgendaTreatyBreakingModifier(ctx.agendaId);
  s += (ctx.thresholds.warLikelihood - 50);
  s += (warDesire - 50);
  if (!ctx.suppressGpDeclareWar &&
      ctx.snapshot.opportunities.weakNeighbors
          .contains(ctx.order.targetFactionId)) {
    s += getDeclareWarTargetBonusWeakerNeighbor(ctx.agendaId);
    if (ctx.game.playerById(ctx.order.targetFactionId) != null &&
        warDesire >= kDeclareWarGpWeakNeighborMinWarDesire) {
      s += kDeclareWarGpWeakNeighborBonus;
    }
  }
  if (ctx.snapshot.conquest.preferredConquestTargetFactionIdsSorted
      .contains(ctx.order.targetFactionId)) {
    s += 15;
  }
  _log.d(
    'diplomacy warDesire nationId=${ctx.nationId} '
    'targetFactionId=${ctx.order.targetFactionId} '
    'warDesire=$warDesire desiredTerritory=$desiredTerritory',
  );
  return s;
}

int _declareWarExpansionAndColonialBonuses(
  _DeclareWarTargetContext ctx,
  int s,
) {
  if (ctx.ownsInvadableNw && ctx.isMinorTarget && !ctx.stalledOwExpansion) {
    s += kDeclareWarColonialInvadableOwnerBonus;
  }
  if (ctx.colonialPressure && ctx.ownsInvadableNw && ctx.isTribeTarget) {
    s += kDeclareWarColonialNwTribeDominanceBonus;
    if (ctx.stalledOwExpansion &&
        !ctx.hasInvadableMinorOwner &&
        !ctx.atWarInvadableOwMinor) {
      s += kDeclareWarColonialNwTribePriorityOverOwMinorBonus;
    }
  }
  final stalledOldWorldExpansion =
      ctx.snapshot.conquest.oldWorldProvincesOwned <=
      kStalledOldWorldProvinceThreshold;
  final hasInvadableOldWorld =
      ctx.snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty;
  if (stalledOldWorldExpansion && hasInvadableOldWorld) {
    if (ctx.isMinorTarget &&
        !ctx.isTribeTarget &&
        ctx.isAdjacentOwner &&
        ctx.invadableOwners.contains(ctx.order.targetFactionId)) {
      s += kDeclareWarStalledOwMinorPriorityBonus;
      if (ctx.snapshot.conquest.oldWorldProvincesOwned <=
          kFewOldWorldProvincesDefendThreshold) {
        s += kDeclareWarWeakGpOwMinorRecoveryBonus;
      }
      if (ctx.thresholds.warLikelihood <= kDeclareWarLowWarLikelihoodThreshold) {
        s += kDeclareWarLowWarLikelihoodAdjacentBonus;
      }
    }
    if (ctx.isTribeTarget && !ctx.ownsInvadableNw) {
      s -= kDeclareWarStalledExpansionTribePenalty;
    }
  }
  if (ctx.currentTurn <= kDeclareWarEarlyExpansionMaxTurn &&
      ctx.anyMinorOwnsOldWorld &&
      stalledOldWorldExpansion &&
      hasInvadableOldWorld) {
    if (ctx.isMinorTarget &&
        !ctx.isTribeTarget &&
        ctx.isAdjacentOwner &&
        ctx.invadableOwners.contains(ctx.order.targetFactionId)) {
      s += kDeclareWarEarlyExpansionMinorBonus;
    }
    if (ctx.isTribeTarget && !ctx.ownsInvadableNw) {
      s -= kDeclareWarEarlyExpansionTribePenalty;
    }
  }
  if (ctx.colonialPressure &&
      ctx.isMinorTarget &&
      !ctx.isTribeTarget &&
      !ctx.ownsInvadableNw) {
    s -= kDeclareWarColonialPressureOwMinorPenalty;
    if (ctx.stalledOwExpansion && ctx.ownsInvadableOwMinor) {
      s -= kDeclareWarColonialPressureOwMinorPenalty;
    }
  }
  if (ctx.isColonialAdjacentOwner && ctx.isTribeTarget) {
    s += kDeclareWarColonialAdjacentTribeBonus;
  }
  return s;
}

int _declareWarAdjacencyAndStalledBonuses(
  _DeclareWarTargetContext ctx,
  int s,
) {
  if (ctx.isAdjacentOwner) {
    s += kDeclareWarAdjacentOwnerBonus;
    if (ctx.behindVictoryPace && ctx.isMinorTarget) {
      s += kDeclareWarAdjacentMinorBonusWhenFarFromVictory;
    }
    if (ctx.isMinorTarget &&
        ctx.invadableOwners.contains(ctx.order.targetFactionId)) {
      s += kDeclareWarMinorWithInvadableProvinceBonus;
    }
    if (ctx.isMinorTarget && ctx.stalledOwExpansion) {
      s += kDeclareWarStalledExpansionMinorBonus;
    }
    if (ctx.stalledOwExpansion &&
        ctx.isMinorTarget &&
        !ctx.isTribeTarget &&
        ctx.isAdjacentOwner &&
        ctx.invadableOwners.contains(ctx.order.targetFactionId) &&
        ctx.thresholds.warLikelihood <= kDeclareWarLowWarLikelihoodThreshold) {
      s += kDeclareWarStalledLowWarLikelihoodMinorBonus;
    }
    if (ctx.isMinorTarget &&
        !ctx.stalledOwExpansion &&
        ctx.snapshot.conquest.oldWorldProvincesOwned >=
            kDeclareWarSatedExpansionMinorThreshold) {
      s -= kDeclareWarSatedExpansionMinorPenalty;
    }
    if (!ctx.suppressGpDeclareWar &&
        ctx.behindVictoryPace &&
        ctx.isAdjacentGp) {
      s += kDeclareWarAdjacentGpBonusWhenFarFromVictory;
    }
    if (ctx.thresholds.warLikelihood <= kDeclareWarLowWarLikelihoodThreshold) {
      s += kDeclareWarLowWarLikelihoodAdjacentBonus;
    }
  }
  if (!ctx.isAdjacentOwner && ctx.stalledOwExpansion && ctx.ownsInvadableOwMinor) {
    s += kDeclareWarAdjacentMinorBonusWhenFarFromVictory;
    s += kDeclareWarMinorWithInvadableProvinceBonus;
    s += kDeclareWarStalledExpansionMinorBonus;
    if (ctx.thresholds.warLikelihood <= kDeclareWarLowWarLikelihoodThreshold) {
      s += kDeclareWarLowWarLikelihoodAdjacentBonus;
    }
  }
  if (ctx.stalledOwExpansion && ctx.isMinorTarget && !ctx.isTribeTarget) {
    final targetMinorProvinces =
        provinceCountOwnedBy(ctx.game, ctx.order.targetFactionId);
    if (targetMinorProvinces > 0 &&
        targetMinorProvinces < ctx.snapshot.conquest.oldWorldProvincesOwned) {
      s += kDeclareWarStalledWeakerMinorBonus;
    }
    if (ctx.behindVictoryPace && targetMinorProvinces > 0) {
      s += kDeclareWarStalledActiveOwMinorBonus;
    }
  }
  if (ctx.weakerDistantMinor && ctx.activeMinorConflicts.isEmpty) {
    s += kDeclareWarStalledWeakerMinorBonus;
    s += kDeclareWarStalledActiveOwMinorBonus;
  }
  if (ctx.stalledOwExpansion &&
      ctx.invadableOwOwnedByGp &&
      ctx.isMinorTarget &&
      !ctx.isTribeTarget &&
      !ctx.isAdjacentOwner &&
      !ctx.invadableOwners.contains(ctx.order.targetFactionId)) {
    s += kDeclareWarStalledGpBlockerDistantMinorBonus;
  }
  if (ctx.stalledOwExpansion &&
      ctx.behindVictoryPace &&
      ctx.invadableOwOwnedByGp &&
      ctx.isMinorTarget &&
      !ctx.isTribeTarget &&
      _minorOwnsOldWorldProvinces(ctx.game, ctx.order.targetFactionId)) {
    s += kDeclareWarStalledAnyOwMinorBonus;
  }
  if (ctx.stalledOwExpansion && ctx.invadableGpBlockerWeaker) {
    s += kDeclareWarStalledWeakestInvadableGpBonus;
    if (ctx.behindVictoryPace) {
      s += kDeclareWarAdjacentGpBonusWhenFarFromVictory;
    }
  }
  if (ctx.stalledOwExpansion &&
      ctx.behindVictoryPace &&
      ctx.invadableGpBlockerWeaker) {
    s += kDeclareWarStalledInvadableGpBlockerBonus;
    s += kDeclareWarStalledWeakestInvadableGpBonus;
  }
  if (ctx.stalledOwExpansion &&
      ctx.behindVictoryPace &&
      ctx.invadableGpBlocker &&
      ctx.invadableOwOwnedByGp &&
      !ctx.hasInvadableMinorOwner) {
    s += kDeclareWarStalledInvadableGpBlockerBonus;
    s = math.max(s, kDeclareWarStalledGpInvadableBlockerFloor);
  }
  if (ctx.suppressGpDeclareWar &&
      ctx.isAdjacentGp &&
      ctx.stalledOwExpansion &&
      ctx.behindVictoryPace &&
      ctx.hasInvadableMinorOwner &&
      !ctx.invadableGpBlocker) {
    s -= kDeclareWarStalledGpWhenMinorsRemainPenalty;
  }
  final targetOw = provinceCountOwnedBy(ctx.game, ctx.order.targetFactionId);
  if (ctx.isAdjacentGp &&
      targetOw > 0 &&
      targetOw < ctx.snapshot.conquest.oldWorldProvincesOwned &&
      isStalledOldWorldExpansion(targetOw)) {
    s -= kDeclareWarOnStalledWeakerNeighborPenalty;
  }
  final atWarWithGp = ctx.snapshot.threats.atWarWith.any(
    (id) => ctx.game.playerById(id) != null,
  );
  if (!atWarWithGp &&
      ctx.isMinorTarget &&
      !ctx.isTribeTarget &&
      ctx.snapshot.conquest.oldWorldProvincesOwned <=
          kFewOldWorldProvincesDefendThreshold &&
      ctx.snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty) {
    s += kDeclareWarCriticalWeakNoGpWarMinorBonus;
    if (ctx.isAdjacentOwner &&
        ctx.invadableOwners.contains(ctx.order.targetFactionId)) {
      s = math.max(s, kDeclareWarWeakGpAdjacentInvadableMinorFloor);
    }
  }
  return s;
}

int _declareWarFinalizeBonuses(_DeclareWarTargetContext ctx, int s) {
  if (ctx.primaryGoal == StrategicGoal.conquer) {
    s += 20;
  }
  s += ctx.behindVictoryPace
      ? conquerScoreBonusForProvincesToVictory(
          ctx.snapshot.conquest.provincesToVictory,
        )
      : conquerScoreBonusForProvincesToVictory(
              ctx.snapshot.conquest.provincesToVictory,
            ) ~/
          4;
  if (ctx.relation?.level == RelationLevel.allied) {
    s += getDeclareWarTargetBonusAlly(ctx.agendaId);
  }
  final adjacentWeakMinor = ctx.isMinorTarget &&
      !ctx.isTribeTarget &&
      ctx.isAdjacentOwner &&
      ctx.snapshot.opportunities.weakNeighbors
          .contains(ctx.order.targetFactionId);
  if (ctx.stalledOwExpansion &&
      ctx.isMinorTarget &&
      !ctx.isTribeTarget &&
      ctx.isAdjacentOwner &&
      ctx.invadableOwners.contains(ctx.order.targetFactionId)) {
    final floor = ctx.snapshot.conquest.oldWorldProvincesOwned <=
            kFewOldWorldProvincesDefendThreshold
        ? kDeclareWarWeakGpAdjacentInvadableMinorFloor
        : kDeclareWarStalledAdjacentInvadableMinorFloor;
    s = math.max(s, floor);
  }
  if (ctx.stalledOwExpansion &&
      ctx.behindVictoryPace &&
      adjacentWeakMinor &&
      (ctx.invadableOwners.contains(ctx.order.targetFactionId) ||
          ctx.game.minorNations.any((m) => m.id == ctx.order.targetFactionId))) {
    s = math.max(s, kDeclareWarStalledAdjacentInvadableMinorFloor);
  }
  if (ctx.stalledOwExpansion && ctx.isTribeTarget && ctx.hasInvadableMinorOwner) {
    s = math.min(s, kDeclareWarStalledTribeWhenOwMinorCap);
  }
  if (ctx.stalledOwExpansion &&
      ctx.behindVictoryPace &&
      ctx.isTribeTarget &&
      ctx.thresholds.warLikelihood <= kDeclareWarLowWarLikelihoodThreshold &&
      ctx.invadableOwners.any((id) => ctx.game.minorNations.any((m) => m.id == id))) {
    s = math.min(s, kDeclareWarStalledLowWarLikelihoodTribeCap);
  }
  if (ctx.stalledOwExpansion &&
      ctx.behindVictoryPace &&
      ctx.isMinorTarget &&
      !ctx.isTribeTarget &&
      ctx.isAdjacentOwner &&
      ctx.invadableOwners.contains(ctx.order.targetFactionId) &&
      ctx.thresholds.warLikelihood <= kDeclareWarLowWarLikelihoodThreshold) {
    s = math.max(s, kDeclareWarStalledLowWarLikelihoodMinorFloor);
  }
  return s;
}

bool _isMinorOrTribeFaction(Game game, String factionId) {
  return game.minorNations.any((m) => m.id == factionId) ||
      game.tribes.any((t) => t.id == factionId);
}

bool _isTribeFaction(Game game, String factionId) {
  return game.tribes.any((t) => t.id == factionId);
}

bool _minorOwnsOldWorldProvinces(Game game, String minorId) =>
    game.worldState.oldWorld.provinces.any((p) => p.ownerId == minorId);

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

bool _isDecisionOnCooldown({
  required Game game,
  required String actorFactionId,
  required String targetFactionId,
  required List<DiplomaticEventType> eventTypes,
  required int cooldownTurns,
  required int currentTurn,
}) {
  for (final event in game.diplomaticHistoryEvents.reversed) {
    if (!eventTypes.contains(event.type)) continue;
    if (event.fromFactionId != actorFactionId) continue;
    if (event.toFactionId != targetFactionId) continue;
    return (currentTurn - event.turn) < cooldownTurns;
  }
  return false;
}
