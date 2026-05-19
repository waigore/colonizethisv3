import '../perception/perception_snapshot.dart';
import 'army_conquest_prep.dart';
import 'planning_imports.dart';
import 'colonial_pressure.dart';
export 'colonial_pressure.dart'
    show
        consolidateGainsSoleGpPeaceTarget,
        criticalOwHoldPeaceTargets,
        hasUninvadedOldWorldMinor,
        isOldWorldGpOnlyInvadableFrontier,
        isStalledOldWorldGpBlockerFocus,
        primaryInvadableOldWorldGpBlocker,
        plateauMutualInvadableBlockerPeaceTargets,
        shouldSkipBelowQuotaGpOnlyBlockerPeacePass,
        quotaMetBelowQuotaAtWarPeaceTargets,
        quotaMetFutileBelowQuotaGpPeaceTargets,
        stalledBelowQuotaGpLeadPeaceTargets,
        belowQuotaPeerGpPeaceTargets,
        defaultStartGpPeaceTargets,
        defaultStartFutileMinorPeaceTargets,
        nearQuotaHoldPeaceTargets,
        unwinnableSoleGpFrontierPeaceTarget;
import 'planner_context.dart';
import '../util/ai_random_utils.dart';
import '../util/orders_extensions.dart';
import 'diplomatic_candidate_scoring.dart';
import 'diplomacy_planner_peace_targets.dart';
import 'diplomacy_planner_result.dart';

export 'diplomacy_planner_peace_targets.dart';
export 'diplomatic_candidate_scoring.dart' show computeDiplomaticCandidateScores;
export 'war_desire_calculator.dart' show computeWarDesireScore;
export 'diplomacy_planner_result.dart'
    show DiplomacyPlannerPass, DiplomacyPlannerResult;

final _log = packageLogger();

/// First minor nation that owns invadable OW land but is not yet at war, while
/// this GP is below the observer quota and not fighting any Great Power (Refs #2509).
///
/// Also fires during an unwinnable sole-GP war so the GP can pivot to minors.
String? criticalWeakUninvadedMinorDeclareTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isBelowObserverConquestQuota(
    snapshot.conquest.oldWorldProvincesOwned,
  )) {
    return null;
  }
  final atWarWithGp = snapshot.threats.atWarWith
      .where((id) => game.playerById(id) != null)
      .toList();
  if (atWarWithGp.length > 1 &&
      snapshot.conquest.oldWorldProvincesOwned >
          kObserverDefaultStartOldWorldProvincesPerGp) {
    return null;
  }
  if (snapshot.conquest.invadableProvinceIdsSorted.isEmpty) {
    return null;
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final candidates = <String>{};
  for (final pid in snapshot.conquest.invadableProvinceIdsSorted) {
    final owner = provinceOwner[pid];
    if (owner == null ||
        !game.minorNations.any((m) => m.id == owner) ||
        snapshot.threats.atWarWith.contains(owner)) {
      continue;
    }
    candidates.add(owner);
  }
  if (candidates.isEmpty) {
    return null;
  }
  final sorted = candidates.toList()..sort();
  return sorted.first;
}

/// Any OW minor not yet at war while stalled below the observer quota (Refs #2509).
String? belowQuotaUninvadedMinorDeclareTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  if (!isBelowObserverConquestQuota(ownOw) ||
      ownOw > kStalledOldWorldProvinceThreshold) {
    return null;
  }
  if (belowQuotaActiveMinorWarTarget(game: game, snapshot: snapshot) != null) {
    return null;
  }
  if (isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot)) {
    return null;
  }
  final candidates = <String>{
    for (final minor in game.minorNations)
      if (!snapshot.threats.atWarWith.contains(minor.id) &&
          game.worldState.oldWorld.provinces.any((p) => p.ownerId == minor.id))
        minor.id,
  };
  if (candidates.isEmpty) {
    return null;
  }
  final sorted = candidates.toList()..sort();
  return sorted.first;
}

/// Adjacent minor not yet at war while at 8–9 OW with no GP fronts (Refs #2509).
String? plateauOwMinorDeclareTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  if (!isStalledOldWorldExpansion(ownOw) ||
      !isBelowObserverConquestQuota(ownOw)) {
    return null;
  }
  if (isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot)) {
    return null;
  }
  final gpWars = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null) factionId,
  ];
  if (gpWars.isNotEmpty) {
    final allowMutualPlateauPivot = gpWars.length == 1 &&
        isMutualBelowQuotaPlateauPeer(
          ownOw: ownOw,
          partnerOw: provinceCountOwnedBy(game, gpWars.single),
        );
    if (!allowMutualPlateauPivot) {
      return null;
    }
  }
  final candidates = <String>{
    for (final factionId in snapshot.conquest.adjacentOwnerFactionIdsSorted)
      if (game.minorNations.any((m) => m.id == factionId) &&
          !snapshot.threats.atWarWith.contains(factionId))
        factionId,
  };
  if (candidates.isEmpty &&
      snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty) {
    final provinceOwner = getProvinceOwnerMap(game);
    for (final pid in snapshot.conquest.invadableProvinceIdsSorted) {
      final owner = provinceOwner[pid];
      if (owner == null ||
          !game.minorNations.any((m) => m.id == owner) ||
          snapshot.threats.atWarWith.contains(owner)) {
        continue;
      }
      candidates.add(owner);
    }
  }
  if (candidates.isEmpty) {
    return null;
  }
  final sorted = candidates.toList()..sort();
  return sorted.first;
}

/// Any OW minor not yet at war while still at default observer start size (seed-42
/// gp4 minor-frontier starvation; Refs #2509).
String? defaultStartOwMinorDeclareTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  if (!isBelowObserverConquestQuota(ownOw) ||
      ownOw > kObserverDefaultStartOldWorldProvincesPerGp + 1) {
    return null;
  }
  final gpWars = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null) factionId,
  ];
  if (gpWars.length > 1) {
    return null;
  }
  if (gpWars.length == 1 &&
      !isMutualBelowQuotaPlateauPeer(
        ownOw: ownOw,
        partnerOw: provinceCountOwnedBy(game, gpWars.single),
      ) &&
      !hasUninvadedOldWorldMinor(game: game, snapshot: snapshot)) {
    return null;
  }
  if (isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot)) {
    return null;
  }
  final candidates = <String>{};
  final provinceOwner = getProvinceOwnerMap(game);
  if (snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty) {
    for (final pid in snapshot.conquest.invadableProvinceIdsSorted) {
      final owner = provinceOwner[pid];
      if (owner == null ||
          !game.minorNations.any((m) => m.id == owner) ||
          snapshot.threats.atWarWith.contains(owner)) {
        continue;
      }
      candidates.add(owner);
    }
  }
  if (candidates.isEmpty) {
    for (final minor in game.minorNations) {
      if (snapshot.threats.atWarWith.contains(minor.id)) {
        continue;
      }
      final ownsOw = game.worldState.oldWorld.provinces.any(
        (p) => p.ownerId == minor.id,
      );
      if (ownsOw) {
        candidates.add(minor.id);
      }
    }
  }
  if (candidates.isEmpty) {
    return null;
  }
  final sorted = candidates.toList()..sort();
  return sorted.first;
}

/// Declare on an invadable OW Great Power while stalled below the observer quota.
String? stalledInvadableGpOwnerDeclareTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  if (!isStalledOldWorldExpansion(ownOw) ||
      !isBelowObserverConquestQuota(ownOw)) {
    return null;
  }
  if (snapshot.conquest.invadableProvinceIdsSorted.isEmpty) {
    return null;
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final candidates = <String>{};
  for (final pid in snapshot.conquest.invadableProvinceIdsSorted) {
    final owner = provinceOwner[pid];
    if (owner == null || game.playerById(owner) == null) {
      continue;
    }
    if (snapshot.threats.atWarWith.contains(owner)) {
      continue;
    }
    if (isMutualBelowQuotaPlateauPeer(
      ownOw: ownOw,
      partnerOw: provinceCountOwnedBy(game, owner),
    )) {
      final blocker = primaryInvadableOldWorldGpBlocker(
        game: game,
        snapshot: snapshot,
      );
      if (owner != blocker) {
        continue;
      }
    }
    candidates.add(owner);
  }
  if (candidates.isEmpty) {
    return null;
  }
  final sorted = candidates.toList()..sort();
  return sorted.first;
}

/// Declare war on the GP frontier blocker when invadable OW is GP-held only.
String? stalledGpBlockerDeclareWarTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (regimentCountForPlayer(game, snapshot.playerId) == 0) {
    return null;
  }
  if (!isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot)) {
    return null;
  }
  if (!isBelowObserverConquestQuota(
        snapshot.conquest.oldWorldProvincesOwned,
      ) &&
      !isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned)) {
    return null;
  }
  final blocker = primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  if (blocker == null ||
      snapshot.threats.atWarWith.contains(blocker) ||
      snapshot.relations[blocker]?.atWar == true) {
    return null;
  }
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  final blockerOw = provinceCountOwnedBy(game, blocker);
  if (isMutualBelowQuotaPlateauPeer(
    ownOw: ownOw,
    partnerOw: blockerOw,
  )) {
    if (regimentCountForPlayer(game, blocker) == 0) {
      return null;
    }
    // Already at war with the mutual plateau blocker (gp3/gp4 seed-42 fronts).
    if (snapshot.threats.atWarWith.contains(blocker) ||
        snapshot.relations[blocker]?.atWar == true) {
      return null;
    }
    // Open the front from the weaker peer only (gp5 vs gp6 at peace).
    if (ownOw > blockerOw ||
        (ownOw == blockerOw && snapshot.playerId.compareTo(blocker) > 0)) {
      return null;
    }
  }
  if (unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot) ==
      blocker) {
    return null;
  }
  final turn = game.worldState.turnState.turnNumber;
  if (turn <= kDeclareWarEarlyAntiDogpileMaxTurn &&
      isBelowObserverConquestQuota(provinceCountOwnedBy(game, blocker)) &&
      !isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot)) {
    return null;
  }
  return blocker;
}

Orders runDiplomacyPlanner({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
}) =>
    runDiplomacyPlannerWithResult(ctx: ctx, snapshot: snapshot).orders;

int _resolveDiplomacyPlannerWeight({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required DiplomacyPlannerPass pass,
}) {
  var weight = ctx.resolveDiplomacyBaseWeight();
  if (pass == DiplomacyPlannerPass.declareWarOnly &&
      snapshot.conquest.provincesToVictory >
          kConquerScoreFloorProvincesToVictoryThreshold &&
      weight < 25) {
    weight = 25;
  }
  if (pass == DiplomacyPlannerPass.declareWarOnly &&
      isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned) &&
      weight < kDiplomacyDeclareWarMinWeightWhenStalled) {
    weight = kDiplomacyDeclareWarMinWeightWhenStalled;
  }
  if (pass == DiplomacyPlannerPass.declareWarOnly &&
      snapshot.conquest.oldWorldProvincesOwned <=
          kFewOldWorldProvincesDefendThreshold &&
      snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty &&
      weight < kDiplomacyDeclareWarMinWeightWhenStalled + 20) {
    weight = kDiplomacyDeclareWarMinWeightWhenStalled + 20;
  }
  if (pass == DiplomacyPlannerPass.declareWarOnly &&
      snapshot.conquest.oldWorldProvincesOwned <=
          kStalledOldWorldProvinceThreshold &&
      snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty &&
      weight < kDiplomacyDeclareWarMinWeightWhenStalled + 15) {
    weight = kDiplomacyDeclareWarMinWeightWhenStalled + 15;
  }
  if (pass == DiplomacyPlannerPass.declareWarOnly &&
      isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned) &&
      snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty &&
      weight < kDiplomacyDeclareWarMinWeightWhenStalled + 20) {
    weight = kDiplomacyDeclareWarMinWeightWhenStalled + 20;
  }
  if (pass == DiplomacyPlannerPass.declareWarOnly &&
      hasColonialAcquisitionTargets(snapshot.colonial) &&
      weight < kDiplomacyDeclareWarMinWeightWhenColonialPressure) {
    weight = kDiplomacyDeclareWarMinWeightWhenColonialPressure;
  }
  if (pass != DiplomacyPlannerPass.declareWarOnly &&
      (stalledOwExpansionNeedsPeacePass(game: ctx.game, snapshot: snapshot) ||
          multiFrontNonBlockerGpPeaceTargets(
            game: ctx.game,
            snapshot: snapshot,
          ).isNotEmpty) &&
      weight < 25) {
    weight = 25;
  }
  return weight;
}

List<DiplomaticOrder> _suggestDiplomacyCandidates({
  required PlannerContext ctx,
  required DiplomacyPlannerPass pass,
}) =>
    pass == DiplomacyPlannerPass.declareWarOnly
        ? ctx.suggestionAPI.suggestDeclareWarOrders(
            ctx.view,
            ctx.game,
            ctx.topology,
            ctx.orders,
          )
        : ctx.suggestionAPI.suggestDiplomaticOrders(
            ctx.view,
            ctx.game,
            ctx.topology,
            ctx.orders,
          );

List<DiplomaticOrder> _filterDiplomacyCandidatesForPass({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required DiplomacyPlannerPass pass,
  required List<DiplomaticOrder> candidates,
}) {
  var filtered = candidates;
  if (pass == DiplomacyPlannerPass.declareWarOnly) {
    final atWarWithGp = snapshot.threats.atWarWith.any(
      (id) => ctx.game.playerById(id) != null,
    );
    if (atWarWithGp) {
      filtered = filtered
          .where(
            (o) =>
                o.type != DiplomaticOrderType.declareWar ||
                !ctx.game.tribes.any((t) => t.id == o.targetFactionId),
          )
          .toList();
    }
  }
  if (pass == DiplomacyPlannerPass.declareWarOnly &&
      isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned)) {
    final provinceOwner = getProvinceOwnerMap(ctx.game);
    final minorsOwnInvadable =
        snapshot.conquest.invadableProvinceIdsSorted.any((pid) {
      final owner = provinceOwner[pid];
      return owner != null &&
          ctx.game.minorNations.any((m) => m.id == owner);
    });
    if (minorsOwnInvadable) {
      filtered = filtered
          .where(
            (o) =>
                o.type != DiplomaticOrderType.declareWar ||
                !ctx.game.tribes.any((t) => t.id == o.targetFactionId),
          )
          .toList();
    }
  }
  if (pass == DiplomacyPlannerPass.declareWarOnly) {
    final gpWars = snapshot.threats.atWarWith
        .where((id) => ctx.game.playerById(id) != null)
        .toList();
    final blocker = primaryInvadableOldWorldGpBlocker(
      game: ctx.game,
      snapshot: snapshot,
    );
    final consolidateGpFronts =
        gpWars.length > 1 ||
        (isStalledOldWorldExpansion(
              snapshot.conquest.oldWorldProvincesOwned,
            ) &&
            gpWars.isNotEmpty);
    final gpOnlyFrontier = isOldWorldGpOnlyInvadableFrontier(
      game: ctx.game,
      snapshot: snapshot,
    );
    if (blocker != null && gpOnlyFrontier) {
      final mutualPlateauBlocker = isMutualBelowQuotaPlateauPeer(
        ownOw: snapshot.conquest.oldWorldProvincesOwned,
        partnerOw: provinceCountOwnedBy(ctx.game, blocker),
      );
      if (!mutualPlateauBlocker) {
        filtered = filtered
            .where(
              (o) =>
                  o.type != DiplomaticOrderType.declareWar ||
                  o.targetFactionId == blocker,
            )
            .toList();
      }
    } else if (blocker != null && consolidateGpFronts) {
      filtered = filtered
          .where(
            (o) =>
                o.type != DiplomaticOrderType.declareWar ||
                ctx.game.playerById(o.targetFactionId) == null ||
                o.targetFactionId == blocker,
          )
          .toList();
    }
  }
  if (pass == DiplomacyPlannerPass.nonDeclareWarOnly &&
      isBelowObserverConquestQuota(
        snapshot.conquest.oldWorldProvincesOwned,
      ) &&
      isOldWorldGpOnlyInvadableFrontier(game: ctx.game, snapshot: snapshot)) {
    final blocker = primaryInvadableOldWorldGpBlocker(
      game: ctx.game,
      snapshot: snapshot,
    );
    final allowBlockerPeace = blocker != null &&
        (plateauMutualInvadableBlockerPeaceTargets(
              game: ctx.game,
              snapshot: snapshot,
            ).contains(blocker) ||
            unwinnableSoleGpFrontierPeaceTarget(
                  game: ctx.game,
                  snapshot: snapshot,
                ) ==
                blocker);
    filtered = filtered
        .where(
          (o) =>
              o.type != DiplomaticOrderType.alliance &&
              !(o.type == DiplomaticOrderType.offerPeace &&
                  o.targetFactionId == blocker &&
                  !allowBlockerPeace),
        )
        .toList();
  }
  final existingThisTurn =
      ctx.orders.diplomaticOrdersByPlayerId[ctx.nationId] ?? const [];
  final declaredThisTurn = <String>{
    for (final o in existingThisTurn)
      if (o.type == DiplomaticOrderType.declareWar) o.targetFactionId,
  };
  switch (pass) {
    case DiplomacyPlannerPass.declareWarOnly:
    case DiplomacyPlannerPass.all:
      return filtered;
    case DiplomacyPlannerPass.nonDeclareWarOnly:
      return filtered
          .where(
            (o) =>
                o.type != DiplomaticOrderType.declareWar &&
                !declaredThisTurn.contains(o.targetFactionId) &&
                !existingThisTurn.any(
                  (existing) =>
                      existing.type == o.type &&
                      existing.targetFactionId == o.targetFactionId,
                ),
          )
          .toList();
  }
}

DiplomacyPlannerResult? _forcedInvadableGpDeclarePlannerResultIfNeeded({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required DiplomacyPlannerPass pass,
  required String? Function({
    required Game game,
    required AIWorldSnapshot snapshot,
  }) targetFor,
  required String logLabel,
}) {
  if (pass != DiplomacyPlannerPass.declareWarOnly) {
    return null;
  }
  final target = targetFor(game: ctx.game, snapshot: snapshot);
  if (target == null) {
    return null;
  }
  _log.i(
    'diplomacy forced declareWar nationId=${ctx.nationId} '
    '$logLabel=$target',
  );
  return DiplomacyPlannerResult(
    orders: ctx.orders.appendDiplomaticOrders(
      ctx.nationId,
      [
        DiplomaticOrder(
          type: DiplomaticOrderType.declareWar,
          targetFactionId: target,
        ),
      ],
    ),
    declaredWarTargetFactionId: target,
  );
}

DiplomacyPlannerResult? _plateauGpBlockerDeclarePlannerResultIfNeeded({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required DiplomacyPlannerPass pass,
}) {
  if (!isBelowObserverConquestQuota(
    snapshot.conquest.oldWorldProvincesOwned,
  )) {
    return null;
  }
  if (!isOldWorldGpOnlyInvadableFrontier(game: ctx.game, snapshot: snapshot)) {
    return null;
  }
  return _forcedInvadableGpDeclarePlannerResultIfNeeded(
    ctx: ctx,
    snapshot: snapshot,
    pass: pass,
    targetFor: stalledGpBlockerDeclareWarTarget,
    logLabel: 'gpBlocker',
  );
}

DiplomacyPlannerResult? _stalledInvadableGpOwnerDeclarePlannerResultIfNeeded({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required DiplomacyPlannerPass pass,
}) =>
    _forcedInvadableGpDeclarePlannerResultIfNeeded(
      ctx: ctx,
      snapshot: snapshot,
      pass: pass,
      targetFor: stalledInvadableGpOwnerDeclareTarget,
      logLabel: 'stalledInvadableGp',
    );

DiplomacyPlannerResult? _defaultStartOwMinorDeclarePlannerResultIfNeeded({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required DiplomacyPlannerPass pass,
}) {
  if (pass != DiplomacyPlannerPass.declareWarOnly) {
    return null;
  }
  final minorTarget = defaultStartOwMinorDeclareTarget(
    game: ctx.game,
    snapshot: snapshot,
  );
  if (minorTarget == null) {
    return null;
  }
  _log.i(
    'diplomacy forced declareWar nationId=${ctx.nationId} '
    'defaultStartMinor=$minorTarget',
  );
  return DiplomacyPlannerResult(
    orders: ctx.orders.appendDiplomaticOrders(
      ctx.nationId,
      [
        DiplomaticOrder(
          type: DiplomaticOrderType.declareWar,
          targetFactionId: minorTarget,
        ),
      ],
    ),
    declaredWarTargetFactionId: minorTarget,
  );
}

DiplomacyPlannerResult? _belowQuotaUninvadedMinorDeclarePlannerResultIfNeeded({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required DiplomacyPlannerPass pass,
}) {
  if (pass != DiplomacyPlannerPass.declareWarOnly) {
    return null;
  }
  final minorTarget = belowQuotaUninvadedMinorDeclareTarget(
    game: ctx.game,
    snapshot: snapshot,
  );
  if (minorTarget == null) {
    return null;
  }
  _log.i(
    'diplomacy forced declareWar nationId=${ctx.nationId} '
    'belowQuotaMinor=$minorTarget',
  );
  return DiplomacyPlannerResult(
    orders: ctx.orders.appendDiplomaticOrders(
      ctx.nationId,
      [
        DiplomaticOrder(
          type: DiplomaticOrderType.declareWar,
          targetFactionId: minorTarget,
        ),
      ],
    ),
    declaredWarTargetFactionId: minorTarget,
  );
}

DiplomacyPlannerResult? _plateauOwMinorDeclarePlannerResultIfNeeded({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required DiplomacyPlannerPass pass,
}) {
  if (pass != DiplomacyPlannerPass.declareWarOnly) {
    return null;
  }
  final minorTarget = plateauOwMinorDeclareTarget(
    game: ctx.game,
    snapshot: snapshot,
  );
  if (minorTarget == null) {
    return null;
  }
  _log.i(
    'diplomacy forced declareWar nationId=${ctx.nationId} '
    'plateauMinor=$minorTarget',
  );
  return DiplomacyPlannerResult(
    orders: ctx.orders.appendDiplomaticOrders(
      ctx.nationId,
      [
        DiplomaticOrder(
          type: DiplomaticOrderType.declareWar,
          targetFactionId: minorTarget,
        ),
      ],
    ),
    declaredWarTargetFactionId: minorTarget,
  );
}

DiplomacyPlannerResult? _criticalWeakMinorDeclarePlannerResultIfNeeded({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required DiplomacyPlannerPass pass,
}) {
  if (pass != DiplomacyPlannerPass.declareWarOnly) {
    return null;
  }
  final minorTarget = criticalWeakUninvadedMinorDeclareTarget(
    game: ctx.game,
    snapshot: snapshot,
  );
  if (minorTarget == null) {
    return null;
  }
  _log.i(
    'diplomacy forced declareWar nationId=${ctx.nationId} target=$minorTarget',
  );
  return DiplomacyPlannerResult(
    orders: ctx.orders.appendDiplomaticOrders(
      ctx.nationId,
      [
        DiplomaticOrder(
          type: DiplomaticOrderType.declareWar,
          targetFactionId: minorTarget,
        ),
      ],
    ),
    declaredWarTargetFactionId: minorTarget,
  );
}

DiplomacyPlannerResult? _stalledPeacePlannerResultIfNeeded({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required DiplomacyPlannerPass pass,
}) {
  if (pass == DiplomacyPlannerPass.declareWarOnly) {
    return null;
  }
  final peaceTargets = collectStalledGreatPowerPeaceTargets(
    game: ctx.game,
    snapshot: snapshot,
  );
  if (peaceTargets.isEmpty) {
    return null;
  }
  final peaceOrders = [
    for (final peaceTarget in peaceTargets)
      DiplomaticOrder(
        type: DiplomaticOrderType.offerPeace,
        targetFactionId: peaceTarget,
      ),
  ];
  _log.i(
    'diplomacy forced offerPeace nationId=${ctx.nationId} '
    'targets=${peaceOrders.map((o) => o.targetFactionId).toList()}',
  );
  return DiplomacyPlannerResult(
    orders: ctx.orders.appendDiplomaticOrders(ctx.nationId, peaceOrders),
  );
}

DiplomaticOrder? _chooseDiplomaticOrder({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required DiplomacyPlannerPass pass,
  required List<DiplomaticOrder> candidates,
  required List<int> scores,
}) {
  if (pass == DiplomacyPlannerPass.declareWarOnly) {
    final forcedBlocker = stalledGpBlockerDeclareWarTarget(
      game: ctx.game,
      snapshot: snapshot,
    );
    if (forcedBlocker != null) {
      return DiplomaticOrder(
        type: DiplomaticOrderType.declareWar,
        targetFactionId: forcedBlocker,
      );
    }
    if (isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned) &&
        snapshot.conquest.provincesToVictory >
            kConquerScoreFloorProvincesToVictoryThreshold) {
      final idx = _pickHighestScoreIndex(scores);
      return idx == null ? null : candidates[idx];
    }
  }
  return selectWeightedCandidate(
    candidates: candidates,
    scores: scores,
    seed: ctx.seeds.diplomacySeed,
  );
}

DiplomacyPlannerResult runDiplomacyPlannerWithResult({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  DiplomacyPlannerPass pass = DiplomacyPlannerPass.all,
}) {
  // Survival peace must run even when diplomacy weight is low or suggestion
  // APIs return no candidates (observer seed-42 gp3/gp6; Refs #2509).
  if (pass != DiplomacyPlannerPass.declareWarOnly &&
      !shouldSkipBelowQuotaGpOnlyBlockerPeacePass(
        game: ctx.game,
        snapshot: snapshot,
      )) {
    final peaceResult = _stalledPeacePlannerResultIfNeeded(
      ctx: ctx,
      snapshot: snapshot,
      pass: pass,
    );
    if (peaceResult != null) {
      return peaceResult;
    }
  }
  if (pass == DiplomacyPlannerPass.declareWarOnly) {
    // GP-only invadable frontier: declare on the blocker before minor pivots.
    if (isOldWorldGpOnlyInvadableFrontier(game: ctx.game, snapshot: snapshot)) {
      final blockerDeclareResult = _plateauGpBlockerDeclarePlannerResultIfNeeded(
        ctx: ctx,
        snapshot: snapshot,
        pass: pass,
      );
      if (blockerDeclareResult != null) {
        return blockerDeclareResult;
      }
    }
    // EXPAND phase: minors before other invadable-GP declare (Refs #2509).
    final defaultStartMinorResult =
        _defaultStartOwMinorDeclarePlannerResultIfNeeded(
      ctx: ctx,
      snapshot: snapshot,
      pass: pass,
    );
    if (defaultStartMinorResult != null) {
      return defaultStartMinorResult;
    }
    final plateauMinorResult = _plateauOwMinorDeclarePlannerResultIfNeeded(
      ctx: ctx,
      snapshot: snapshot,
      pass: pass,
    );
    if (plateauMinorResult != null) {
      return plateauMinorResult;
    }
    final blockerDeclareResult = _plateauGpBlockerDeclarePlannerResultIfNeeded(
      ctx: ctx,
      snapshot: snapshot,
      pass: pass,
    );
    if (blockerDeclareResult != null) {
      return blockerDeclareResult;
    }
    final belowQuotaMinorResult =
        _belowQuotaUninvadedMinorDeclarePlannerResultIfNeeded(
      ctx: ctx,
      snapshot: snapshot,
      pass: pass,
    );
    if (belowQuotaMinorResult != null) {
      return belowQuotaMinorResult;
    }
    final minorWarResult = _criticalWeakMinorDeclarePlannerResultIfNeeded(
      ctx: ctx,
      snapshot: snapshot,
      pass: pass,
    );
    if (minorWarResult != null) {
      return minorWarResult;
    }
    final stalledGpDeclareResult =
        _stalledInvadableGpOwnerDeclarePlannerResultIfNeeded(
      ctx: ctx,
      snapshot: snapshot,
      pass: pass,
    );
    if (stalledGpDeclareResult != null) {
      return stalledGpDeclareResult;
    }
  }
  final weight = _resolveDiplomacyPlannerWeight(
    ctx: ctx,
    snapshot: snapshot,
    pass: pass,
  );
  if (weight < 25) {
    _log.d('diplomacy skipped nationId=${ctx.nationId} weight=$weight < 25');
    return DiplomacyPlannerResult(orders: ctx.orders);
  }

  final filtered = _filterDiplomacyCandidatesForPass(
    ctx: ctx,
    snapshot: snapshot,
    pass: pass,
    candidates: _suggestDiplomacyCandidates(ctx: ctx, pass: pass),
  );
  if (filtered.isEmpty) {
    return DiplomacyPlannerResult(orders: ctx.orders);
  }

  final scores = computeDiplomaticCandidateScores(
    candidates: filtered,
    nationId: ctx.nationId,
    game: ctx.game,
    snapshot: snapshot,
    config: ctx.config,
    primaryGoal: ctx.primaryGoal,
    sameTurnPriorDiplomaticOrders: ctx.sameTurnPriorDiplomaticOrders,
  );

  final candidateDesc = filtered
      .map(
        (o) =>
            '${o.type.name}${o.type == DiplomaticOrderType.declareWar ? ":${o.targetFactionId}" : ""}',
      )
      .toList();
  _log.d(
    'diplomacy eval nationId=${ctx.nationId} hiddenAgendaId=${ctx.config.hiddenAgendaId} '
    'candidates=$candidateDesc scores=$scores',
  );

  final chosen = _chooseDiplomaticOrder(
    ctx: ctx,
    snapshot: snapshot,
    pass: pass,
    candidates: filtered,
    scores: scores,
  );
  if (chosen == null) return DiplomacyPlannerResult(orders: ctx.orders);
  _log.i(
    'diplomacy chosen nationId=${ctx.nationId} '
    'type=${chosen.type}${chosen.type == DiplomaticOrderType.declareWar ? " targetFactionId=${chosen.targetFactionId}" : ""}',
  );
  final nextOrders = ctx.orders.appendDiplomaticOrders(ctx.nationId, [chosen]);
  final declaredTarget = chosen.type == DiplomaticOrderType.declareWar
      ? chosen.targetFactionId
      : null;
  return DiplomacyPlannerResult(
    orders: nextOrders,
    declaredWarTargetFactionId: declaredTarget,
  );
}

/// Deterministic tie-break: lowest candidate index wins equal scores.
int? _pickHighestScoreIndex(List<int> scores) {
  var bestIdx = -1;
  var bestScore = 0;
  for (var i = 0; i < scores.length; i++) {
    final score = scores[i];
    if (score <= 0) continue;
    if (score > bestScore || bestIdx < 0) {
      bestScore = score;
      bestIdx = i;
    }
  }
  return bestIdx < 0 ? null : bestIdx;
}
