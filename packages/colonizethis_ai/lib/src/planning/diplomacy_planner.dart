import '../perception/perception_snapshot.dart';
import 'army_conquest_prep.dart';
import 'planning_imports.dart';
import 'colonial_pressure.dart';
export 'colonial_pressure.dart'
    show
        consolidateGainsSoleGpPeaceTarget,
        criticalOwHoldPeaceTargets,
        isOldWorldGpOnlyInvadableFrontier,
        isStalledOldWorldGpBlockerFocus,
        primaryInvadableOldWorldGpBlocker,
        quotaMetFutileBelowQuotaGpPeaceTargets,
        stalledBelowQuotaGpLeadPeaceTargets,
        unwinnableSoleGpFrontierPeaceTarget;
import 'planner_context.dart';
import '../util/ai_random_utils.dart';
import '../util/orders_extensions.dart';
import 'diplomatic_candidate_scoring.dart';
import 'diplomacy_planner_result.dart';

export 'diplomatic_candidate_scoring.dart' show computeDiplomaticCandidateScores;
export 'war_desire_calculator.dart' show computeWarDesireScore;
export 'diplomacy_planner_result.dart'
    show DiplomacyPlannerPass, DiplomacyPlannerResult;

final _log = packageLogger();

/// Strongest at-war GP that owns invadable OW provinces while this GP is stalled.
String? stalledStrongerGpBlockerPeaceTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned)) {
    return null;
  }
  if (snapshot.conquest.invadableProvinceIdsSorted.isEmpty) {
    return null;
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final minorsOwnInvadable = snapshot.conquest.invadableProvinceIdsSorted.any(
    (pid) {
      final owner = provinceOwner[pid];
      return owner != null && game.minorNations.any((m) => m.id == owner);
    },
  );
  final gpBlockerFocus = isStalledOldWorldGpBlockerFocus(
    game: game,
    snapshot: snapshot,
  );
  if (!minorsOwnInvadable && !gpBlockerFocus) {
    return null;
  }
  if (gpBlockerFocus) {
    final anyMinorOwnsOw = game.worldState.oldWorld.provinces.any(
      (p) =>
          p.ownerId != null &&
          p.ownerId!.isNotEmpty &&
          game.minorNations.any((m) => m.id == p.ownerId),
    );
    if (!anyMinorOwnsOw) {
      return null;
    }
  }
  final primaryBlocker = primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  String? bestFactionId;
  var bestLead = 0;
  for (final factionId in snapshot.threats.atWarWith) {
    if (game.playerById(factionId) == null) continue;
    if (factionId == primaryBlocker) continue;
    final ownsInvadable = snapshot.conquest.invadableProvinceIdsSorted.any(
      (pid) => provinceOwner[pid] == factionId,
    );
    if (!ownsInvadable) continue;
    final lead = provinceCountOwnedBy(game, factionId) -
        snapshot.conquest.oldWorldProvincesOwned;
    if (lead <= 0) continue;
    if (lead > bestLead) {
      bestLead = lead;
      bestFactionId = factionId;
    }
  }
  return bestFactionId;
}

/// Factions at war with this GP to peace while a single GP owns the invadable OW
/// frontier (minors, tribes, and other GPs are distractions; Refs #2509).
List<String> stalledGpBlockerFocusPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot)) {
    return const [];
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final minorsOwnInvadable = snapshot.conquest.invadableProvinceIdsSorted.any(
    (pid) {
      final owner = provinceOwner[pid];
      return owner != null && game.minorNations.any((m) => m.id == owner);
    },
  );
  final gpWars = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null) factionId,
  ];
  final blocker = primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  if (blocker == null) {
    return const [];
  }
  if (minorsOwnInvadable && gpWars.length <= 1) {
    // Sole GP war on a mixed frontier must still drop non-blocker fronts
    // (seed-42 gp4/gp5 vs gp3 blocker; Refs #2509).
    if (gpWars.length == 1 && gpWars.single != blocker) {
      return [gpWars.single];
    }
    return const [];
  }
  if (minorsOwnInvadable) {
    final targets = <String>[
      for (final factionId in gpWars)
        if (factionId != blocker) factionId,
    ]..sort();
    return targets;
  }
  final targets = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (factionId != blocker) factionId,
  ]..sort();
  return targets;
}

/// At-war Great Powers that own none of this GP's invadable Old World provinces
/// while minors still hold invadable land (distracting GP wars; Refs #2509).
List<String> stalledFutileGpPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned)) {
    return const [];
  }
  if (snapshot.conquest.invadableProvinceIdsSorted.isEmpty) {
    return const [];
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final minorsOwnInvadable = snapshot.conquest.invadableProvinceIdsSorted.any(
    (pid) {
      final owner = provinceOwner[pid];
      return owner != null && game.minorNations.any((m) => m.id == owner);
    },
  );
  if (!minorsOwnInvadable) {
    return const [];
  }
  final targets = <String>[];
  for (final factionId in snapshot.threats.atWarWith) {
    if (game.playerById(factionId) == null) continue;
    final ownsInvadable = snapshot.conquest.invadableProvinceIdsSorted.any(
      (pid) => provinceOwner[pid] == factionId,
    );
    if (ownsInvadable) continue;
    targets.add(factionId);
  }
  targets.sort();
  return targets;
}

bool _isMinorOrTribeFaction(Game game, String factionId) =>
    game.minorNations.any((m) => m.id == factionId) ||
    game.tribes.any((t) => t.id == factionId);

/// At-war minor with the most invadable Old World provinces (single-front focus).
String? stalledFocusMinorTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final provinceOwner = getProvinceOwnerMap(game);
  String? bestMinorId;
  var bestInvadableCount = 0;
  for (final minor in game.minorNations) {
    final rel = getRelation(game, snapshot.playerId, minor.id);
    if (rel?.state != RelationState.atWar) continue;
    final invadableCount = snapshot.conquest.invadableProvinceIdsSorted
        .where((pid) => provinceOwner[pid] == minor.id)
        .length;
    if (invadableCount > bestInvadableCount) {
      bestInvadableCount = invadableCount;
      bestMinorId = minor.id;
    }
  }
  return bestMinorId;
}

/// Peace tribe wars while fighting a Great Power (OW consolidation; Refs #2509).
List<String> atWarGpDistractionTribePeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned)) {
    return const [];
  }
  final atWarWithGp = snapshot.threats.atWarWith.any(
    (id) => game.playerById(id) != null,
  );
  if (!atWarWithGp) {
    return const [];
  }
  final targets = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.tribes.any((t) => t.id == factionId)) factionId,
  ]..sort();
  return targets;
}

/// Peace every at-war minor/tribe except the focused minor or GP blocker war.
List<String> stalledExpansionDistractionPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned)) {
    return const [];
  }
  if (snapshot.threats.atWarWith.isEmpty) {
    return const [];
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final minorsOwnInvadable = snapshot.conquest.invadableProvinceIdsSorted.any(
    (pid) {
      final owner = provinceOwner[pid];
      return owner != null && game.minorNations.any((m) => m.id == owner);
    },
  );
  final gpBlockerFocus = isStalledOldWorldGpBlockerFocus(
    game: game,
    snapshot: snapshot,
  );
  if (!minorsOwnInvadable && !gpBlockerFocus) {
    return const [];
  }
  final keepMinor = minorsOwnInvadable
      ? stalledFocusMinorTarget(game: game, snapshot: snapshot)
      : null;
  final keepGp = gpBlockerFocus
      ? primaryInvadableOldWorldGpBlocker(game: game, snapshot: snapshot)
      : null;
  final targets = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (factionId != keepMinor &&
          factionId != keepGp &&
          _isMinorOrTribeFaction(game, factionId))
        factionId,
  ]..sort();
  return targets;
}

/// When OW holdings are critically low (≤6), peace every stronger at-war GP (Refs #2509).
List<String> criticalWeakGpSurvivalPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (snapshot.conquest.oldWorldProvincesOwned >
      kStalledOldWorldProvinceThreshold) {
    return const [];
  }
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  final minLead = isBelowObserverConquestQuota(ownOw)
      ? kUnwinnableSoleGpMinProvinceDeficit
      : kDeclareWarAggressorSuppressWeakGpLeadThreshold;
  final targets = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null &&
          provinceCountOwnedBy(game, factionId) >= ownOw + minLead)
        factionId,
  ]..sort();
  return targets;
}

/// Peace the invadable OW frontier GP while critically weak and outmatched
/// (pivot to minors/tribes instead of unwinnable GP wars; Refs #2509).
List<String> weakHoldingsInvadableBlockerPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final zeroRegiments =
      regimentCountForPlayer(game, snapshot.playerId) == 0;
  final belowQuota = isBelowObserverConquestQuota(
    snapshot.conquest.oldWorldProvincesOwned,
  );
  if (snapshot.conquest.oldWorldProvincesOwned >
          kFewOldWorldProvincesDefendThreshold &&
      !belowQuota &&
      !(zeroRegiments &&
          isStalledOldWorldExpansion(
            snapshot.conquest.oldWorldProvincesOwned,
          ))) {
    return const [];
  }
  final blocker = primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  if (blocker == null ||
      !snapshot.threats.atWarWith.contains(blocker) ||
      game.playerById(blocker) == null) {
    return const [];
  }
  final lead = provinceCountOwnedBy(game, blocker) -
      snapshot.conquest.oldWorldProvincesOwned;
  final minLead = belowQuota
      ? kUnwinnableSoleGpMinProvinceDeficit
      : kDeclareWarAggressorSuppressWeakGpLeadThreshold;
  if (lead < minLead) {
    return const [];
  }
  return [blocker];
}

/// When OW holdings are critically low, peace non-blocker Great Power fronts only
/// (avoid total collapse from multi-front GP wars; Refs #2509).
List<String> criticalMultiFrontGpPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isObserverConquestExpansionPressure(
        snapshot.conquest.oldWorldProvincesOwned,
      ) &&
      !isAtObserverConquestQuotaBand(
        snapshot.conquest.oldWorldProvincesOwned,
      )) {
    return const [];
  }
  final gpWars = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null) factionId,
  ];
  if (gpWars.length < 2) {
    return const [];
  }
  return multiFrontNonBlockerGpPeaceTargets(game: game, snapshot: snapshot);
}

/// Peace every at-war Great Power when stalled with zero regiments (Refs #2509).
List<String> stalledZeroRegimentGpPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned)) {
    return const [];
  }
  if (regimentCountForPlayer(game, snapshot.playerId) > 0) {
    return const [];
  }
  final targets = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null) factionId,
  ]..sort();
  return targets;
}

/// Peace a sole GP enemy when both sides have zero regiments (stalemate reset).
List<String> mutualZeroRegimentGpStalematePeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned)) {
    return const [];
  }
  if (regimentCountForPlayer(game, snapshot.playerId) > 0) {
    return const [];
  }
  final gpWars = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null) factionId,
  ];
  if (gpWars.length != 1) {
    return const [];
  }
  final enemy = gpWars.single;
  if (regimentCountForPlayer(game, enemy) > 0) {
    return const [];
  }
  return [enemy];
}

/// First minor nation that owns invadable OW land but is not yet at war, while
/// this GP is critically weak and not fighting any Great Power (Refs #2509).
String? criticalWeakUninvadedMinorDeclareTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (snapshot.conquest.oldWorldProvincesOwned >
      kFewOldWorldProvincesDefendThreshold) {
    return null;
  }
  if (snapshot.threats.atWarWith.any((id) => game.playerById(id) != null)) {
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

bool stalledOwExpansionNeedsPeacePass({
  required Game game,
  required AIWorldSnapshot snapshot,
}) =>
    stalledStrongerGpBlockerPeaceTarget(game: game, snapshot: snapshot) !=
        null ||
    stalledFutileGpPeaceTargets(game: game, snapshot: snapshot).isNotEmpty ||
    stalledGpBlockerFocusPeaceTargets(game: game, snapshot: snapshot).isNotEmpty ||
    stalledExpansionDistractionPeaceTargets(game: game, snapshot: snapshot)
        .isNotEmpty ||
    atWarGpDistractionTribePeaceTargets(game: game, snapshot: snapshot)
        .isNotEmpty ||
    multiFrontNonBlockerGpPeaceTargets(game: game, snapshot: snapshot)
        .isNotEmpty ||
    criticalMultiFrontGpPeaceTargets(game: game, snapshot: snapshot).isNotEmpty ||
    criticalWeakGpSurvivalPeaceTargets(game: game, snapshot: snapshot)
        .isNotEmpty ||
    weakHoldingsInvadableBlockerPeaceTargets(game: game, snapshot: snapshot)
        .isNotEmpty ||
    mutualZeroRegimentGpStalematePeaceTargets(game: game, snapshot: snapshot)
        .isNotEmpty ||
    stalledZeroRegimentGpPeaceTargets(game: game, snapshot: snapshot)
        .isNotEmpty ||
    criticalOwHoldPeaceTargets(game: game, snapshot: snapshot).isNotEmpty ||
    stalledBelowQuotaGpLeadPeaceTargets(game: game, snapshot: snapshot)
        .isNotEmpty ||
    quotaMetFutileBelowQuotaGpPeaceTargets(game: game, snapshot: snapshot)
        .isNotEmpty ||
    unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot) !=
        null ||
    consolidateGainsSoleGpPeaceTarget(game: game, snapshot: snapshot) != null;

/// When fighting 2+ Great Powers, peace every non-blocker GP. Also peace a sole
/// non-blocker GP war while invadable OW remains (Refs #2509).
List<String> multiFrontNonBlockerGpPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final gpWars = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null) factionId,
  ];
  if (gpWars.isEmpty) {
    return const [];
  }
  if (!isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned) &&
      snapshot.conquest.invadableProvinceIdsSorted.isEmpty) {
    return const [];
  }
  var blocker = primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  if (blocker == null) {
    var bestOw = 0;
    for (final factionId in gpWars) {
      final ow = provinceCountOwnedBy(game, factionId);
      if (ow > bestOw) {
        bestOw = ow;
        blocker = factionId;
      }
    }
  }
  if (blocker == null) {
    return const [];
  }
  if (gpWars.length == 1 && gpWars.single != blocker) {
    return gpWars;
  }
  if (gpWars.length <= 1) {
    return const [];
  }
  final targets = <String>[
    for (final factionId in gpWars)
      if (factionId != blocker) factionId,
  ]..sort();
  return targets;
}

/// Great Power peace targets from stalled expansion helpers (Refs #2509).
Set<String> collectStalledGreatPowerPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final targets = <String>{
    ...stalledFutileGpPeaceTargets(game: game, snapshot: snapshot),
    ...stalledGpBlockerFocusPeaceTargets(game: game, snapshot: snapshot),
    ...stalledExpansionDistractionPeaceTargets(
      game: game,
      snapshot: snapshot,
    ),
    ...atWarGpDistractionTribePeaceTargets(game: game, snapshot: snapshot),
    ...multiFrontNonBlockerGpPeaceTargets(game: game, snapshot: snapshot),
    ...criticalMultiFrontGpPeaceTargets(game: game, snapshot: snapshot),
    ...criticalWeakGpSurvivalPeaceTargets(game: game, snapshot: snapshot),
    ...weakHoldingsInvadableBlockerPeaceTargets(game: game, snapshot: snapshot),
    ...mutualZeroRegimentGpStalematePeaceTargets(game: game, snapshot: snapshot),
    ...stalledZeroRegimentGpPeaceTargets(game: game, snapshot: snapshot),
    if (stalledStrongerGpBlockerPeaceTarget(game: game, snapshot: snapshot) !=
        null)
      stalledStrongerGpBlockerPeaceTarget(game: game, snapshot: snapshot)!,
    ...criticalOwHoldPeaceTargets(game: game, snapshot: snapshot),
    ...stalledBelowQuotaGpLeadPeaceTargets(game: game, snapshot: snapshot),
    ...quotaMetFutileBelowQuotaGpPeaceTargets(game: game, snapshot: snapshot),
    if (unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot)
        case final enemy?)
      enemy,
    if (consolidateGainsSoleGpPeaceTarget(game: game, snapshot: snapshot)
        case final enemy?)
      enemy,
  };
  return targets.where((id) => game.playerById(id) != null).toSet();
}

/// GP–GP peace requires both sides to [offerPeace] in the same phase; mirror existing offers.
Orders supplementMutualStalledGreatPowerPeaceOrders({
  required Game game,
  required MapTopology topology,
  required Orders orders,
}) {
  final diplo = Map<String, List<DiplomaticOrder>>.from(
    orders.diplomaticOrdersByPlayerId,
  );
  var changed = false;
  for (final entry in orders.diplomaticOrdersByPlayerId.entries) {
    final fromGp = entry.key;
    if (!isAiControlled(game, fromGp)) continue;
    for (final order in entry.value) {
      if (order.type != DiplomaticOrderType.offerPeace) continue;
      final toGp = order.targetFactionId;
      if (game.playerById(toGp) == null || !isAiControlled(game, toGp)) {
        continue;
      }
      final fromView = buildPlayerView(game, topology, fromGp);
      final fromSnapshot = AIWorldSnapshot.fromPlayerView(
        fromView,
        topology: topology,
      );
      final invadableBlocker = primaryInvadableOldWorldGpBlocker(
        game: game,
        snapshot: fromSnapshot,
      );
      final stalledPeaceTargets = collectStalledGreatPowerPeaceTargets(
        game: game,
        snapshot: fromSnapshot,
      );
      if (toGp == invadableBlocker && !stalledPeaceTargets.contains(toGp)) {
        continue;
      }
      final before = diplo[toGp]?.length ?? 0;
      _appendOfferPeaceIfMissing(diplo, toGp, fromGp);
      if ((diplo[toGp]?.length ?? 0) > before) {
        changed = true;
      }
    }
  }
  if (!changed) {
    return orders;
  }
  return orders.copyWith(diplomaticOrdersByPlayerId: diplo);
}

void _appendOfferPeaceIfMissing(
  Map<String, List<DiplomaticOrder>> diplo,
  String fromGp,
  String toGp,
) {
  final existing = diplo[fromGp] ?? const [];
  if (existing.any(
    (o) =>
        o.type == DiplomaticOrderType.offerPeace &&
        o.targetFactionId == toGp,
  )) {
    return;
  }
  diplo[fromGp] = [
    ...existing,
    DiplomaticOrder(
      type: DiplomaticOrderType.offerPeace,
      targetFactionId: toGp,
    ),
  ];
}

/// Declare war on the GP frontier blocker when invadable OW is GP-held only.
String? stalledGpBlockerDeclareWarTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot)) {
    return null;
  }
  if (!isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned) &&
      snapshot.conquest.oldWorldProvincesOwned >
          kStalledOldWorldProvinceThreshold + 3) {
    return null;
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final blocker = primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  if (blocker == null ||
      snapshot.threats.atWarWith.contains(blocker) ||
      snapshot.relations[blocker]?.atWar == true) {
    return null;
  }
  final turn = game.worldState.turnState.turnNumber;
  if (turn <= kDeclareWarEarlyAntiDogpileMaxTurn &&
      isBelowObserverConquestQuota(provinceCountOwnedBy(game, blocker))) {
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
    if (blocker != null && (consolidateGpFronts || gpOnlyFrontier)) {
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
  if (pass != DiplomacyPlannerPass.declareWarOnly) {
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
    final minorWarResult = _criticalWeakMinorDeclarePlannerResultIfNeeded(
      ctx: ctx,
      snapshot: snapshot,
      pass: pass,
    );
    if (minorWarResult != null) {
      return minorWarResult;
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
