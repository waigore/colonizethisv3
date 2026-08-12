/// Human Development Counsel ranking API.
/// SPEC/program/development-counsel-ranking.md (Refs #4332).
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'connectivity_dev_snapshot.dart';
import 'development_counsel_types.dart';
import 'engineer_work_scoring.dart';
import 'order_suggestion_work.dart';
import 'order_work_constants.dart';

const int _kMaxRecommendations = 3;

String developmentCounselStablePortId(String targetTileKey) =>
    'build_port:$targetTileKey';

DevelopmentCounselReasonKey developmentCounselReasonForPort({
  required Game game,
  required WorkOrder order,
  ConnectivityDevSnapshot? connectivityDev,
}) {
  final resourceId = game.worldState.resourceByTileKey[order.targetTileKey];
  final hasResource = resourceId != null && resourceId.isNotEmpty;
  final provinceId = Unit.provinceIdFromTileKey(order.targetTileKey);
  final inNewWorld =
      Unit.regionIdFromTileKey(order.targetTileKey) == kNewWorldRegionId;
  final overseas =
      connectivityDev != null &&
      connectivityDev.hasUnconnectedDevTargets &&
      provinceId != null &&
      connectivityDev.provincesWithUnconnectedDevTargets.contains(provinceId);
  if (overseas) return DevelopmentCounselReasonKey.overseasLinkage;
  if (hasResource) return DevelopmentCounselReasonKey.resourceCoast;
  if (inNewWorld) return DevelopmentCounselReasonKey.newWorldCoast;
  return DevelopmentCounselReasonKey.coastalPort;
}

/// Ranks Build port advice from Engineer work suggestions (AI-aligned).
List<DevelopmentCounselRecommendation>
rankDevelopmentCounselRecommendationsFromSuggestions({
  required Game game,
  required String playerId,
  required List<WorkOrder> workSuggestions,
  ConnectivityDevSnapshot? connectivityDev,
}) {
  final byUnit = <String, List<WorkOrder>>{};
  for (final order in workSuggestions) {
    if (!isEngineerWorkTarget(order.target)) continue;
    byUnit.putIfAbsent(order.unitId, () => <WorkOrder>[]).add(order);
  }

  final unitIds = byUnit.keys.toList()..sort();
  final bestByTile = <String, DevelopmentCounselRecommendation>{};

  for (final unitId in unitIds) {
    final candidates = byUnit[unitId]!;
    final best = bestEngineerWorkOrder(
      candidates,
      game,
      playerId: playerId,
      connectivityDev: connectivityDev,
    );
    if (best == null || best.target != kWorkTargetBuildPort) continue;

    final score = engineerWorkScore(
      best,
      game,
      playerId: playerId,
      connectivityDev: connectivityDev,
    ).toDouble();
    final provinceId =
        Unit.provinceIdFromTileKey(best.targetTileKey) ?? best.targetTileKey;
    final province = game.worldState.tryGetProvince(provinceId);
    final reason = developmentCounselReasonForPort(
      game: game,
      order: best,
      connectivityDev: connectivityDev,
    );
    final rec = DevelopmentCounselRecommendation(
      recommendationId: developmentCounselStablePortId(best.targetTileKey),
      kind: DevelopmentCounselRecommendationKind.buildPort,
      rankScore: score,
      briefReasonKey: reason,
      detailReasonKeys: [reason],
      isHighlight: true,
      targetTileKey: best.targetTileKey,
      provinceId: provinceId,
      provinceDisplayName: province?.displayName,
      unitId: unitId,
    );
    final existing = bestByTile[best.targetTileKey];
    if (existing == null ||
        rec.rankScore > existing.rankScore ||
        (rec.rankScore == existing.rankScore &&
            (rec.unitId ?? '').compareTo(existing.unitId ?? '') < 0)) {
      bestByTile[best.targetTileKey] = rec;
    }
  }

  final ranked = bestByTile.values.toList()
    ..sort((a, b) {
      final scoreCmp = b.rankScore.compareTo(a.rankScore);
      if (scoreCmp != 0) return scoreCmp;
      return a.targetTileKey.compareTo(b.targetTileKey);
    });
  if (ranked.length <= _kMaxRecommendations) return ranked;
  return ranked.sublist(0, _kMaxRecommendations);
}

/// Ranks Build port advice when the shared Engineer ranker would select port.
List<DevelopmentCounselRecommendation> rankDevelopmentCounselRecommendations({
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required MapTopology topology,
  Map<String, TileMapResult> tileMapByRegion = const {},
}) {
  final player = game.playerById(playerId);
  if (player == null) return const [];

  final view = buildPlayerView(game, topology, playerId);
  final mapsOrNull = tileMapByRegion.isEmpty ? null : tileMapByRegion;
  final suggestions = suggestWorkOrders(
    view,
    game,
    topology,
    currentOrders,
    tileMapByRegion: mapsOrNull,
  );
  final connectivityDev = buildConnectivityDevSnapshot(
    game: game,
    playerId: playerId,
    topology: topology,
    tileMapByRegion: mapsOrNull,
  );
  return rankDevelopmentCounselRecommendationsFromSuggestions(
    game: game,
    playerId: playerId,
    workSuggestions: suggestions,
    connectivityDev: connectivityDev,
  );
}
