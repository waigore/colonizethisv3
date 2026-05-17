import '../perception/perception_snapshot.dart';
import 'planning_imports.dart';
import 'colonial_pressure.dart';
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
  final provinceOwner = getProvinceOwnerMap(game);
  final minorsOwnInvadable = snapshot.conquest.invadableProvinceIdsSorted.any(
    (pid) {
      final owner = provinceOwner[pid];
      return owner != null && game.minorNations.any((m) => m.id == owner);
    },
  );
  if (!minorsOwnInvadable) {
    return null;
  }
  String? bestFactionId;
  var bestLead = 0;
  for (final factionId in snapshot.threats.atWarWith) {
    if (game.playerById(factionId) == null) continue;
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
  if (minorsOwnInvadable) {
    return const [];
  }
  final blocker = primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  if (blocker == null) {
    return const [];
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

bool stalledOwExpansionNeedsPeacePass({
  required Game game,
  required AIWorldSnapshot snapshot,
}) =>
    stalledStrongerGpBlockerPeaceTarget(game: game, snapshot: snapshot) !=
        null ||
    stalledFutileGpPeaceTargets(game: game, snapshot: snapshot).isNotEmpty ||
    stalledGpBlockerFocusPeaceTargets(game: game, snapshot: snapshot).isNotEmpty;

/// GP owning the most invadable Old World provinces (frontier blocker).
String? primaryInvadableOldWorldGpBlocker({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final provinceOwner = getProvinceOwnerMap(game);
  String? bestGpId;
  var bestCount = 0;
  for (final provinceId in snapshot.conquest.invadableProvinceIdsSorted) {
    final owner = provinceOwner[provinceId];
    if (owner == null || game.playerById(owner) == null) continue;
    var count = 0;
    for (final pid in snapshot.conquest.invadableProvinceIdsSorted) {
      if (provinceOwner[pid] == owner) count++;
    }
    if (count > bestCount) {
      bestCount = count;
      bestGpId = owner;
    }
  }
  return bestGpId;
}

/// Declare war on the GP frontier blocker when invadable OW is GP-held only.
String? stalledGpBlockerDeclareWarTarget({
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
  if (minorsOwnInvadable) {
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
  return blocker;
}

Orders runDiplomacyPlanner({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
}) =>
    runDiplomacyPlannerWithResult(ctx: ctx, snapshot: snapshot).orders;

DiplomacyPlannerResult runDiplomacyPlannerWithResult({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  DiplomacyPlannerPass pass = DiplomacyPlannerPass.all,
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
          kStalledOldWorldProvinceThreshold &&
      snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty &&
      weight < kDiplomacyDeclareWarMinWeightWhenStalled + 15) {
    weight = kDiplomacyDeclareWarMinWeightWhenStalled + 15;
  }
  if (pass == DiplomacyPlannerPass.declareWarOnly &&
      hasColonialAcquisitionTargets(snapshot.colonial) &&
      weight < kDiplomacyDeclareWarMinWeightWhenColonialPressure) {
    weight = kDiplomacyDeclareWarMinWeightWhenColonialPressure;
  }
  if (pass != DiplomacyPlannerPass.declareWarOnly &&
      stalledOwExpansionNeedsPeacePass(game: ctx.game, snapshot: snapshot) &&
      weight < 25) {
    weight = 25;
  }
  if (weight < 25) {
    _log.d('diplomacy skipped nationId=${ctx.nationId} weight=$weight < 25');
    return DiplomacyPlannerResult(orders: ctx.orders);
  }

  var diploCandidates = pass == DiplomacyPlannerPass.declareWarOnly
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
  if (diploCandidates.isEmpty) {
    return DiplomacyPlannerResult(orders: ctx.orders);
  }

  final declaredThisTurn = <String>{
    for (final o
        in ctx.orders.diplomaticOrdersByPlayerId[ctx.nationId] ?? const [])
      if (o.type == DiplomaticOrderType.declareWar) o.targetFactionId,
  };

  switch (pass) {
    case DiplomacyPlannerPass.declareWarOnly:
      break;
    case DiplomacyPlannerPass.nonDeclareWarOnly:
      diploCandidates = diploCandidates
          .where(
            (o) =>
                o.type != DiplomaticOrderType.declareWar &&
                !declaredThisTurn.contains(o.targetFactionId),
          )
          .toList();
      break;
    case DiplomacyPlannerPass.all:
      break;
  }
  if (diploCandidates.isEmpty) {
    return DiplomacyPlannerResult(orders: ctx.orders);
  }

  if (pass != DiplomacyPlannerPass.declareWarOnly) {
    final peaceOrders = <DiplomaticOrder>[];
    final peaceTargets = <String>{
      if (stalledStrongerGpBlockerPeaceTarget(
            game: ctx.game,
            snapshot: snapshot,
          ) !=
          null)
        stalledStrongerGpBlockerPeaceTarget(
          game: ctx.game,
          snapshot: snapshot,
        )!,
      ...stalledFutileGpPeaceTargets(game: ctx.game, snapshot: snapshot),
      ...stalledGpBlockerFocusPeaceTargets(game: ctx.game, snapshot: snapshot),
    };
    for (final peaceTarget in peaceTargets) {
      peaceOrders.add(
        DiplomaticOrder(
          type: DiplomaticOrderType.offerPeace,
          targetFactionId: peaceTarget,
        ),
      );
    }
    if (peaceOrders.isNotEmpty) {
      _log.i(
        'diplomacy forced offerPeace nationId=${ctx.nationId} '
        'targets=${peaceOrders.map((o) => o.targetFactionId).toList()}',
      );
      return DiplomacyPlannerResult(
        orders: ctx.orders.appendDiplomaticOrders(ctx.nationId, peaceOrders),
      );
    }
  }

  final scores = computeDiplomaticCandidateScores(
    candidates: diploCandidates,
    nationId: ctx.nationId,
    game: ctx.game,
    snapshot: snapshot,
    config: ctx.config,
    primaryGoal: ctx.primaryGoal,
  );

  final candidateDesc = diploCandidates
      .map(
        (o) =>
            '${o.type.name}${o.type == DiplomaticOrderType.declareWar ? ":${o.targetFactionId}" : ""}',
      )
      .toList();
  _log.d(
    'diplomacy eval nationId=${ctx.nationId} hiddenAgendaId=${ctx.config.hiddenAgendaId} '
    'candidates=$candidateDesc scores=$scores',
  );

  final DiplomaticOrder? chosen;
  if (pass == DiplomacyPlannerPass.declareWarOnly &&
      isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned) &&
      snapshot.conquest.provincesToVictory >
          kConquerScoreFloorProvincesToVictoryThreshold) {
    final forcedBlocker = stalledGpBlockerDeclareWarTarget(
      game: ctx.game,
      snapshot: snapshot,
    );
    if (forcedBlocker != null) {
      chosen = DiplomaticOrder(
        type: DiplomaticOrderType.declareWar,
        targetFactionId: forcedBlocker,
      );
    } else {
      final idx = _pickHighestScoreIndex(scores);
      chosen = idx == null ? null : diploCandidates[idx];
    }
  } else {
    chosen = selectWeightedCandidate(
      candidates: diploCandidates,
      scores: scores,
      seed: ctx.seeds.diplomacySeed,
    );
  }
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
