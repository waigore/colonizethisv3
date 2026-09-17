import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Post-work Build-improvement `payoffKind` from capital-link connectivity.
///
/// SPEC/program/game-events.md (Refs #4778). Callers pass [connectivity]
/// captured from `stateAfter`; omit it only when tile maps are unavailable.
String buildImprovementPayoffKind({
  required Game stateAfter,
  required String tileKey,
  required String? resourceId,
  required String? playerId,
  ConnectivityResult? connectivity,
}) {
  if (connectivity == null) {
    return WorkOrderPayoffKind.yieldRaise;
  }
  if (!connectivity.connected.contains(tileKey)) {
    return WorkOrderPayoffKind.unbound;
  }
  final production = _production(
    stateAfter: stateAfter,
    tileKey: tileKey,
    resourceId: resourceId,
    playerId: playerId,
  );
  final pathCap = _pathCap(
    stateAfter: stateAfter,
    tileKey: tileKey,
    connectivity: connectivity,
  );
  if (production > pathCap) {
    return WorkOrderPayoffKind.roadLimit;
  }
  final afterPath = production < pathCap ? production : pathCap;
  final townCap = _townDevelopmentCap(stateAfter, tileKey);
  if (_townCapApplies(
        stateAfter: stateAfter,
        tileKey: tileKey,
        playerId: playerId,
        connectivity: connectivity,
      ) &&
      afterPath > townCap) {
    return WorkOrderPayoffKind.townLimit;
  }
  return WorkOrderPayoffKind.yieldRaise;
}

int _production({
  required Game stateAfter,
  required String tileKey,
  required String? resourceId,
  required String? playerId,
}) {
  final level = stateAfter.worldState.tileState.improvementLevel(tileKey);
  final player = playerId == null ? null : stateAfter.playerById(playerId);
  final cap = extractionCapForResourceForUnlocked(
    player?.techUnlocked,
    resourceId ?? '',
  );
  return (level < cap ? level : cap).clamp(0, 4);
}

int _pathCap({
  required Game stateAfter,
  required String tileKey,
  required ConnectivityResult connectivity,
}) {
  final ports = collectPortTileKeys(stateAfter);
  final roadLevel = stateAfter.worldState.tileState.roadLevel(tileKey);
  final tileTransport = ports.contains(tileKey)
      ? 4
      : (roadLevel > 0 ? roadLevel : 0);
  return connectivity.pathTransportCap[tileKey] ?? tileTransport;
}

int _townDevelopmentCap(Game stateAfter, String tileKey) {
  final provinceId = Unit.provinceIdFromTileKey(tileKey);
  if (provinceId == null) return 0;
  return stateAfter.worldState
          .tryGetProvince(provinceId)
          ?.townDevelopmentLevel ??
      0;
}

bool _townCapApplies({
  required Game stateAfter,
  required String tileKey,
  required String? playerId,
  required ConnectivityResult connectivity,
}) {
  final provinceId = Unit.provinceIdFromTileKey(tileKey);
  final player = playerId == null ? null : stateAfter.playerById(playerId);
  if (player?.capitalProvinceId == provinceId) {
    return true;
  }
  if (connectivity.connectedByRoadRule.contains(tileKey)) {
    return false;
  }
  final province = provinceId == null
      ? null
      : stateAfter.worldState.tryGetProvince(provinceId);
  final townTileKey = province?.townTileKey;
  if (townTileKey == null) return false;
  return collectPortTileKeys(stateAfter).contains(townTileKey);
}
