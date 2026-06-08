part of 'full_ai_civilian_work_selection.dart';

// Builder (`build_improvement`) and Merchant (`purchase_land`) candidate
// scoring / row selection, plus the Old World feedstock unit reservation that
// keeps an idle Builder / Explorer available for H8 feedstock work. Split out
// of full_ai_civilian_work_selection.dart by concern to keep each library file
// small; shares the parent library's private scope via `part`.

/// Planner-internal score boost applied to an unimproved feedstock resource
/// tile when the [regimentBuildInputFeedstockExtractionResourceIds] gate is
/// active (Refs #2847 § H8-extraction). Sized above
/// [kBuildImprovementExtractableResourceScore] plus the New World resource
/// bonuses so a lock-recovery seller routes its Builder onto the feedstock
/// tile ahead of any other extractable improvement. Planner-internal — not an
/// `ai_victory_config.dart` constant — mirroring the economy-planner H8
/// production boost and the #2847 "no new config constants" scope constraint.
const int kRegimentBuildInputFeedstockExtractionScoreBoost = 600;

int _buildImprovementWorkScore(
  WorkOrder w,
  Game game, {
  required String playerId,
  Set<String> feedstockExtractionResourceIds = const <String>{},
}) {
  if (w.target != kWorkTargetBuildImprovement) return 0;
  final level = game.worldState.tileState.improvementLevel(w.targetTileKey);
  if (level >= 1) return 1;
  final resourceId = game.worldState.resourceByTileKey[w.targetTileKey];
  if (resourceId == null || resourceId.isEmpty) return 2;
  var score = kBuildImprovementExtractableResourceScore;
  if (Unit.regionIdFromTileKey(w.targetTileKey) == kNewWorldRegionId) {
    score += kBuildImprovementNewWorldResourceBonus;
    final provId = Unit.provinceIdFromTileKey(w.targetTileKey);
    if (provId != null &&
        tryGetProvince(game.worldState, provId)?.ownerId == playerId) {
      score += kBuildImprovementOwnedNewWorldResourceBonus;
    }
  }
  if (feedstockExtractionResourceIds.contains(resourceId)) {
    score += kRegimentBuildInputFeedstockExtractionScoreBoost;
  }
  return score;
}

/// The (at most) one idle Builder and one idle Explorer the active player must
/// keep in the Old World for H8 feedstock prospecting + extraction, instead of
/// letting them migrate to New World colonial work (Refs #2847 § H8-extraction
/// supplier Old World feedstock unit reservation).
///
/// The seed-42 affluent suppliers own an unimproved Old World `iron` / `timber`
/// feedstock tile on every gate-active turn, yet every idle Builder / Explorer
/// is routed to higher-scoring **New World** owned-resource work (the New World
/// bonuses in [_buildImprovementWorkScore] / [_eScore]), so the now-correct
/// prospecting / co-availability ordering chain never gets a unit positioned on
/// the Old World feedstock tile. Holding one idle Builder and one idle Explorer
/// out of New World work keeps them available for the Old World feedstock
/// `prospect` + `build_improvement` the existing
/// [kFeedstockMineralProspectScoreBoost] /
/// [kRegimentBuildInputFeedstockExtractionScoreBoost] boosts then select.
class _OwFeedstockReservation {
  const _OwFeedstockReservation({this.builderUnitId, this.explorerUnitId});

  final String? builderUnitId;
  final String? explorerUnitId;

  static const none = _OwFeedstockReservation();

  bool reserves(String unitId) =>
      unitId == builderUnitId || unitId == explorerUnitId;
}

/// Resolves the [_OwFeedstockReservation] for the active player.
///
/// Returns [_OwFeedstockReservation.none] unless the feedstock-extraction gate
/// is active ([feedstockExtractionResourceIds] non-empty). When active, reserves
/// the lexicographically-smallest idle (`currentWork == null`) Builder iff the
/// player owns an unimproved Old World feedstock tile, and the
/// lexicographically-smallest idle Explorer iff the player owns an unprospected
/// Old World mineral feedstock tile. Deterministic over
/// `(view.ownUnits, game, feedstockExtractionResourceIds)`.
_OwFeedstockReservation _resolveOwFeedstockReservation(
  PlayerView view,
  Game game,
  Set<String> feedstockExtractionResourceIds,
) {
  if (feedstockExtractionResourceIds.isEmpty) {
    return _OwFeedstockReservation.none;
  }
  final playerId = view.playerId;
  final reserveBuilder = _ownsUnimprovedOldWorldFeedstockTile(
    game,
    playerId,
    feedstockExtractionResourceIds,
  );
  final reserveExplorer = _ownsUnprospectedOldWorldMineralFeedstockTile(
    game,
    playerId,
    feedstockExtractionResourceIds,
  );
  if (!reserveBuilder && !reserveExplorer) return _OwFeedstockReservation.none;
  final idleBuilders = <String>[];
  final idleExplorers = <String>[];
  for (final unit in view.ownUnits) {
    if (unit.currentWork != null) continue;
    if (reserveBuilder && unit.type == kUnitTypeBuilder) {
      idleBuilders.add(unit.id);
    }
    if (reserveExplorer && isExplorerUnit(unit.type)) {
      idleExplorers.add(unit.id);
    }
  }
  idleBuilders.sort();
  idleExplorers.sort();
  return _OwFeedstockReservation(
    builderUnitId: idleBuilders.isEmpty ? null : idleBuilders.first,
    explorerUnitId: idleExplorers.isEmpty ? null : idleExplorers.first,
  );
}

/// Drops every New World `targetTileKey` work order from [orders] so a reserved
/// Old World feedstock unit is not routed to New World colonial work. Leaves the
/// unit with only its Old World candidates (or none, in which case it stays idle
/// in the Old World). Refs #2847 § H8-extraction supplier Old World feedstock
/// unit reservation.
void _dropNewWorldWorkOrders(List<WorkOrder> orders) {
  orders.removeWhere(
    (w) => Unit.regionIdFromTileKey(w.targetTileKey) == kNewWorldRegionId,
  );
}

WorkOrder? _bestBuildImprovementRow(
  List<WorkOrder> candidates,
  Game game, {
  required String playerId,
  Set<String> feedstockExtractionResourceIds = const <String>{},
}) {
  final improvements = candidates
      .where((w) => w.target == kWorkTargetBuildImprovement)
      .toList();
  if (improvements.isEmpty) return null;
  var best = improvements.first;
  var bestScore = _buildImprovementWorkScore(
    best,
    game,
    playerId: playerId,
    feedstockExtractionResourceIds: feedstockExtractionResourceIds,
  );
  for (var i = 1; i < improvements.length; i++) {
    final w = improvements[i];
    final s = _buildImprovementWorkScore(
      w,
      game,
      playerId: playerId,
      feedstockExtractionResourceIds: feedstockExtractionResourceIds,
    );
    if (s > bestScore) {
      bestScore = s;
      best = w;
      continue;
    }
    if (s == bestScore && _compareWorkOrderLex(w, best) < 0) {
      best = w;
    }
  }
  return best;
}

int _purchaseLandWorkScore(
  WorkOrder w,
  Game game,
  DiplomacyFactionMembership factionMembership,
) {
  if (w.target != kWorkTargetPurchaseLand) return 0;
  final provId = Unit.provinceIdFromTileKey(w.targetTileKey);
  if (provId == null || provId.isEmpty) return 1;
  if (ProvinceId.regionIdFrom(provId) == kNewWorldRegionId) {
    final ownerId = tryGetProvince(game.worldState, provId)?.ownerId;
    if (ownerId != null &&
        isMinorOrTribe(game, ownerId, factionMembership: factionMembership)) {
      return kPurchaseLandNewWorldTribeWorkScore;
    }
    return kPurchaseLandNewWorldOtherWorkScore;
  }
  return 60;
}

WorkOrder? _bestPurchaseLandRow(
  List<WorkOrder> candidates,
  Game game,
  DiplomacyFactionMembership factionMembership,
) {
  final purchases = candidates
      .where((w) => w.target == kWorkTargetPurchaseLand)
      .toList();
  if (purchases.isEmpty) return null;
  var best = purchases.first;
  var bestScore = _purchaseLandWorkScore(best, game, factionMembership);
  for (var i = 1; i < purchases.length; i++) {
    final w = purchases[i];
    final s = _purchaseLandWorkScore(w, game, factionMembership);
    if (s > bestScore) {
      bestScore = s;
      best = w;
      continue;
    }
    if (s == bestScore && _compareWorkOrderLex(w, best) < 0) {
      best = w;
    }
  }
  return best;
}
