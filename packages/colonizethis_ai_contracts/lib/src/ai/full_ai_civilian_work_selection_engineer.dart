part of 'full_ai_civilian_work_selection.dart';

// Engineer (`build_road` / `build_port` / `build_fort`) candidate scoring / row
// selection and the Engineer path appender. Replaces the lexicographic fallback
// (which always picked `build_fort` first because it sorts alphabetically before
// `build_port`/`build_road`) with a unified scored pool over all three Engineer
// targets. Split out of full_ai_civilian_work_selection.dart by concern to keep
// each library file small; shares the parent library's private scope via `part`.
//
// Normative SPEC: SPEC/ai/civilian-work-planner.md § Engineer (Refs #3794).
// Per-target base weights express the relative priority of the three targets;
// contextual bonuses (all GA-tunable via ai_victory_config.dart) then
// differentiate candidates of the same target using cheap per-tile proxies
// (resource on tile, tile in capital province, tile in New World region) rather
// than per-tile path-finding, mirroring the Rail Builder scorer.

/// Deterministic Full AI score for an Engineer `build_road` / `build_port` /
/// `build_fort` [w] candidate.
///
/// Returns `0` for any non-Engineer target so a mixed candidate list never
/// scores a foreign target. Every valid Engineer candidate scores at least its
/// per-target baseline (non-zero) so it is selected over the lexicographic
/// fallback; contextual bonuses then differentiate candidates.
int _engineerWorkScore(
  WorkOrder w,
  Game game, {
  required String playerId,
}) {
  final resourceId = game.worldState.resourceByTileKey[w.targetTileKey];
  final hasResource = resourceId != null && resourceId.isNotEmpty;
  final capitalProvinceId = game.playerById(playerId)?.capitalProvinceId;
  final provinceId = Unit.provinceIdFromTileKey(w.targetTileKey);
  final inCapital =
      capitalProvinceId != null &&
      provinceId != null &&
      provinceId == capitalProvinceId;
  final inNewWorld =
      Unit.regionIdFromTileKey(w.targetTileKey) == kNewWorldRegionId;
  switch (w.target) {
    case kWorkTargetBuildRoad:
      var score = kEngineerBuildRoadBaseWorkScore;
      if (hasResource) score += kEngineerRoadResourceConnectivityBonus;
      if (inCapital) score += kEngineerRoadCapitalLogisticsBonus;
      return score;
    case kWorkTargetBuildPort:
      var score = kEngineerBuildPortBaseWorkScore;
      if (hasResource) score += kEngineerPortResourceExtractionBonus;
      if (inNewWorld) score += kEngineerPortNewWorldCoastalBonus;
      return score;
    case kWorkTargetBuildFort:
      var score = kEngineerBuildFortBaseWorkScore;
      if (inCapital) score += kEngineerFortCapitalDefenseBonus;
      if (inNewWorld) score += kEngineerFortNewWorldBorderBonus;
      return score;
  }
  return 0;
}

bool _isEngineerWorkTarget(String target) =>
    target == kWorkTargetBuildRoad ||
    target == kWorkTargetBuildPort ||
    target == kWorkTargetBuildFort;

/// Stable, non-alphabetical-on-target secondary ordering for equally-scored
/// Engineer candidates: province id first, then full tile key, then target
/// (Refs #3794). Score, not target alphabetisation, drives the primary choice;
/// this only breaks exact ties deterministically.
int _compareEngineerCandidate(WorkOrder a, WorkOrder b) {
  final pa = Unit.provinceIdFromTileKey(a.targetTileKey) ?? '';
  final pb = Unit.provinceIdFromTileKey(b.targetTileKey) ?? '';
  final p = pa.compareTo(pb);
  if (p != 0) return p;
  final t = a.targetTileKey.compareTo(b.targetTileKey);
  if (t != 0) return t;
  return a.target.compareTo(b.target);
}

WorkOrder? _bestEngineerRow(
  List<WorkOrder> candidates,
  Game game, {
  required String playerId,
}) {
  final engineerCandidates = candidates
      .where((w) => _isEngineerWorkTarget(w.target))
      .toList();
  if (engineerCandidates.isEmpty) return null;
  var best = engineerCandidates.first;
  var bestScore = _engineerWorkScore(best, game, playerId: playerId);
  for (var i = 1; i < engineerCandidates.length; i++) {
    final w = engineerCandidates[i];
    final s = _engineerWorkScore(w, game, playerId: playerId);
    if (s > bestScore) {
      bestScore = s;
      best = w;
      continue;
    }
    if (s == bestScore && _compareEngineerCandidate(w, best) < 0) {
      best = w;
    }
  }
  return best;
}

void _appendEngineerPathResult({
  required Unit? unit,
  required List<WorkOrder> w,
  required Game game,
  required String playerId,
  required List<WorkOrder> workOrders,
  required List<FullAiCivilianWorkIdle> idleEvents,
}) {
  final chosen =
      _bestEngineerRow(w, game, playerId: playerId) ?? _pickLexicographic(w);
  if (chosen != null) {
    workOrders.add(chosen);
    return;
  }
  if (unit == null) return;
  idleEvents.add(
    FullAiCivilianWorkIdle(
      unitId: unit.id,
      unitType: unit.type,
      reason: 'no_suggestions',
    ),
  );
}
