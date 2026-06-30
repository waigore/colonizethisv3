part of 'full_ai_civilian_work_selection.dart';

// Rail Builder (`build_rail`) candidate scoring / row selection and the Rail
// Builder path appender. Replaces the lexicographic fallback (which always
// picked the alphabetically-smallest tile) with a unified scored pool over the
// unit's `build_rail` candidates. Split out of
// full_ai_civilian_work_selection.dart by concern to keep each library file
// small; shares the parent library's private scope via `part`.
//
// Normative SPEC: SPEC/ai/civilian-work-planner.md § Rail Builder (Refs #3794
// AC6). Scoring factors (all GA-tunable via ai_victory_config.dart):
//   - resource output: cheap per-tile proxy (the rail tile carries a resource)
//   - capital-connector: the rail tile lies in the player's capital province
//   - New World: colonial rail bias for NW road tiles

/// Deterministic Full AI score for a Rail Builder `build_rail` [w] candidate.
///
/// Returns `0` for non-`build_rail` orders so a mixed candidate list never
/// scores a foreign target. Every valid `build_rail` candidate scores at least
/// [kBuildRailBaseWorkScore] (non-zero) so it is selected over the lexicographic
/// fallback; contextual bonuses then differentiate candidates.
int _buildRailWorkScore(
  WorkOrder w,
  Game game, {
  required String playerId,
}) {
  if (w.target != kWorkTargetBuildRail) return 0;
  var score = kBuildRailBaseWorkScore;
  final resourceId = game.worldState.resourceByTileKey[w.targetTileKey];
  if (resourceId != null && resourceId.isNotEmpty) {
    score += kBuildRailResourceOutputBonus;
  }
  final capitalProvinceId = game.playerById(playerId)?.capitalProvinceId;
  final provinceId = Unit.provinceIdFromTileKey(w.targetTileKey);
  if (capitalProvinceId != null &&
      provinceId != null &&
      provinceId == capitalProvinceId) {
    score += kBuildRailCapitalConnectorBonus;
  }
  if (Unit.regionIdFromTileKey(w.targetTileKey) == kNewWorldRegionId) {
    score += kBuildRailNewWorldBonus;
  }
  return score;
}

/// Stable, non-alphabetical secondary ordering for equally-scored `build_rail`
/// candidates: province id first, then full tile key (Refs #3794 AC16). All
/// candidates share the `build_rail` target, so this never depends on the
/// target string's alphabetical position.
int _compareRailCandidate(WorkOrder a, WorkOrder b) {
  final pa = Unit.provinceIdFromTileKey(a.targetTileKey) ?? '';
  final pb = Unit.provinceIdFromTileKey(b.targetTileKey) ?? '';
  final p = pa.compareTo(pb);
  if (p != 0) return p;
  return a.targetTileKey.compareTo(b.targetTileKey);
}

WorkOrder? _bestBuildRailRow(
  List<WorkOrder> candidates,
  Game game, {
  required String playerId,
}) {
  final rails = candidates
      .where((w) => w.target == kWorkTargetBuildRail)
      .toList();
  if (rails.isEmpty) return null;
  var best = rails.first;
  var bestScore = _buildRailWorkScore(best, game, playerId: playerId);
  for (var i = 1; i < rails.length; i++) {
    final w = rails[i];
    final s = _buildRailWorkScore(w, game, playerId: playerId);
    if (s > bestScore) {
      bestScore = s;
      best = w;
      continue;
    }
    if (s == bestScore && _compareRailCandidate(w, best) < 0) {
      best = w;
    }
  }
  return best;
}

void _appendRailBuilderPathResult({
  required Unit? unit,
  required List<WorkOrder> w,
  required Game game,
  required String playerId,
  required List<WorkOrder> workOrders,
  required List<FullAiCivilianWorkIdle> idleEvents,
}) {
  final chosen =
      _bestBuildRailRow(w, game, playerId: playerId) ?? _pickLexicographic(w);
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
