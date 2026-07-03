part of 'full_ai_civilian_work_selection.dart';

// Builder `upgrade_town` candidate scoring / row selection. Adds the
// `upgrade_town` target to the Builder's scored pool so town upgrades compete
// with `build_improvement` candidates instead of being reachable only through
// the lexicographic fallback (which picked an `upgrade_town` candidate only when
// no `build_improvement` candidate existed). Split out of
// full_ai_civilian_work_selection.dart by concern to keep each library file
// small; shares the parent library's private scope via `part`.
//
// Normative SPEC: SPEC/ai/civilian-work-planner.md § Builder (Refs #3794).
// `upgrade_town` scoring is a GA-tunable baseline plus context bonuses using the
// same cheap per-tile proxies as the Rail Builder / Engineer scorers (resource
// on tile, New World region, tile improvement level) rather than per-province
// aggregation or path-finding.

/// Deterministic Full AI score for a Builder `upgrade_town` [w] candidate.
///
/// Returns `0` for any non-`upgrade_town` order so a mixed candidate list never
/// scores a foreign target. Every valid `upgrade_town` candidate scores at least
/// [kUpgradeTownBaseWorkScore] (non-zero); contextual bonuses (town resource
/// value, New World front-line proximity, lowest current development level) then
/// differentiate candidates.
int _upgradeTownWorkScore(
  WorkOrder w,
  Game game, {
  required String playerId,
}) {
  if (w.target != kWorkTargetUpgradeTown) return 0;
  var score = kUpgradeTownBaseWorkScore;
  final resourceId = game.worldState.resourceByTileKey[w.targetTileKey];
  if (resourceId != null && resourceId.isNotEmpty) {
    score += kUpgradeTownResourceValueBonus;
  }
  if (Unit.regionIdFromTileKey(w.targetTileKey) == kNewWorldRegionId) {
    score += kUpgradeTownFrontlineBonus;
  }
  if (game.worldState.tileState.improvementLevel(w.targetTileKey) == 0) {
    score += kUpgradeTownLowDevBonus;
  }
  return score;
}

/// Stable, non-alphabetical secondary ordering for equally-scored
/// `upgrade_town` candidates: province id first, then full tile key (Refs #3794
/// § Builder). All candidates share the `upgrade_town` target, so this never
/// depends on the target string's alphabetical position.
int _compareUpgradeTownCandidate(WorkOrder a, WorkOrder b) {
  final pa = Unit.provinceIdFromTileKey(a.targetTileKey) ?? '';
  final pb = Unit.provinceIdFromTileKey(b.targetTileKey) ?? '';
  final p = pa.compareTo(pb);
  if (p != 0) return p;
  return a.targetTileKey.compareTo(b.targetTileKey);
}

WorkOrder? _bestUpgradeTownRow(
  List<WorkOrder> candidates,
  Game game, {
  required String playerId,
}) {
  final towns = candidates
      .where((w) => w.target == kWorkTargetUpgradeTown)
      .toList();
  if (towns.isEmpty) return null;
  var best = towns.first;
  var bestScore = _upgradeTownWorkScore(best, game, playerId: playerId);
  for (var i = 1; i < towns.length; i++) {
    final w = towns[i];
    final s = _upgradeTownWorkScore(w, game, playerId: playerId);
    if (s > bestScore) {
      bestScore = s;
      best = w;
      continue;
    }
    if (s == bestScore && _compareUpgradeTownCandidate(w, best) < 0) {
      best = w;
    }
  }
  return best;
}

/// Stable, non-alphabetical-on-target tie-break between the best
/// `build_improvement` row and the best `upgrade_town` row when their unified
/// scores are exactly equal: province id first, then full tile key, then target
/// (Refs #3794 § Builder). Score, not target alphabetisation, drives the primary
/// cross-type choice; this only breaks exact ties deterministically.
int _compareBuilderCrossType(WorkOrder a, WorkOrder b) {
  final pa = Unit.provinceIdFromTileKey(a.targetTileKey) ?? '';
  final pb = Unit.provinceIdFromTileKey(b.targetTileKey) ?? '';
  final p = pa.compareTo(pb);
  if (p != 0) return p;
  final t = a.targetTileKey.compareTo(b.targetTileKey);
  if (t != 0) return t;
  return a.target.compareTo(b.target);
}

/// Unified Builder row selection over the `build_improvement` + `upgrade_town`
/// scored pool. The highest-scoring candidate across **both** target types wins;
/// when no `upgrade_town` candidate exists the result is byte-identical to the
/// `build_improvement`-only selection (Refs #3794 § Builder, no-regression).
WorkOrder? _bestBuilderRow(
  List<WorkOrder> candidates,
  Game game, {
  required String playerId,
  Set<String> feedstockExtractionResourceIds = const <String>{},
  Set<String> growthStageFabricFeedstockResourceIds = const <String>{},
  Set<String> growthStageInfraFeedstockResourceIds = const <String>{},
}) {
  final improvement = _bestBuildImprovementRow(
    candidates,
    game,
    playerId: playerId,
    feedstockExtractionResourceIds: feedstockExtractionResourceIds,
    growthStageFabricFeedstockResourceIds: growthStageFabricFeedstockResourceIds,
    growthStageInfraFeedstockResourceIds: growthStageInfraFeedstockResourceIds,
  );
  final upgrade = _bestUpgradeTownRow(candidates, game, playerId: playerId);
  if (improvement == null) return upgrade;
  if (upgrade == null) return improvement;
  final iScore = _buildImprovementWorkScore(
    improvement,
    game,
    playerId: playerId,
    feedstockExtractionResourceIds: feedstockExtractionResourceIds,
    growthStageFabricFeedstockResourceIds: growthStageFabricFeedstockResourceIds,
    growthStageInfraFeedstockResourceIds: growthStageInfraFeedstockResourceIds,
  );
  final uScore = _upgradeTownWorkScore(upgrade, game, playerId: playerId);
  if (uScore > iScore) return upgrade;
  if (iScore > uScore) return improvement;
  return _compareBuilderCrossType(improvement, upgrade) <= 0
      ? improvement
      : upgrade;
}
