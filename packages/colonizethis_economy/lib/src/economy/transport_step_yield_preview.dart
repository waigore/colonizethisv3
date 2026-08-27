/// Display-only extraction preview for Build road / port / railroad steps.
///
/// SPEC: SPEC/game/extraction-and-improvements.md § Transport Level;
/// SPEC/program/province-extraction-snapshot.md. Hypothesizes this tile's next
/// stored transport only; callers pass cached connectivity (no BFS here).
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'tile_extraction_pipeline.dart';
import 'tile_extraction_yield.dart';

/// Why the next transport step does or does not raise what arrives.
enum TransportStepYieldKind {
  raise,
  roadPathLimit,
  townDevelopmentLimit,
  disconnected,
  bindsToCapital,
  portOnCoast,
}

/// Current vs hypothetical next effective yield after one transport work step.
class TransportStepYieldPreview {
  const TransportStepYieldPreview({
    this.commodityId,
    required this.currentEffective,
    required this.nextEffective,
    required this.kind,
  });

  final String? commodityId;
  final int currentEffective;
  final int nextEffective;
  final TransportStepYieldKind kind;
}

/// Work-target ids matching [colonizethis_orders] (passed as strings to avoid
/// an orders dependency in this package).
abstract final class TransportStepWorkTargets {
  static const buildRoad = 'build_road';
  static const buildPort = 'build_port';
  static const buildRail = 'build_rail';
}

int _storedTransportLevel({
  required TileMapState tileState,
  required String tileKey,
  required Set<String> portTileKeys,
}) {
  if (portTileKeys.contains(tileKey)) {
    return 4;
  }
  final roadLevel = tileState.roadLevel(tileKey);
  return roadLevel > 0 ? roadLevel : 0;
}

/// Next stored transport after [workTarget] on [currentTransport], or null when
/// the step does not apply.
int? nextStoredTransportLevel({
  required String workTarget,
  required int currentTransport,
  required bool hasRoadConstructionTech,
}) {
  return switch (workTarget) {
    TransportStepWorkTargets.buildRoad => switch (currentTransport) {
      0 => 1,
      1 when hasRoadConstructionTech => 2,
      _ => null,
    },
    TransportStepWorkTargets.buildPort => currentTransport < 4 ? 4 : null,
    TransportStepWorkTargets.buildRail => switch (currentTransport) {
      1 || 2 => 4,
      _ => null,
    },
    _ => null,
  };
}

Map<String, int> _pathCapWithTileTransport({
  required Map<String, int> pathTransportCap,
  required String tileKey,
  required int tileTransportLevel,
}) {
  final bumped = Map<String, int>.from(pathTransportCap);
  final existing = bumped[tileKey] ?? tileTransportLevel;
  bumped[tileKey] =
      existing < tileTransportLevel ? tileTransportLevel : existing;
  return bumped;
}

int _yieldAtTransport({
  required Game game,
  required String tileKey,
  required int tileTransportLevel,
  required bool tileIsPort,
  required int techCap,
  required Province province,
  required bool connected,
  required bool isCapitalProvince,
  required bool usesRoadRule,
  required Set<String> portTileKeys,
  required Map<String, int> pathTransportCap,
}) {
  if (!connected) {
    return 0;
  }
  final townTileKey = province.townTileKey;
  final townTileIsPort =
      townTileKey != null && portTileKeys.contains(townTileKey);
  final effectivePathCap = _pathCapWithTileTransport(
    pathTransportCap: pathTransportCap,
    tileKey: tileKey,
    tileTransportLevel: tileTransportLevel,
  );
  final portKeys = tileIsPort
      ? {...portTileKeys, tileKey}
      : portTileKeys.difference({tileKey});
  return computeEffectiveTileYield(
    tileState: game.worldState.tileState,
    tileKey: tileKey,
    techCap: techCap,
    townDevelopmentCap: province.townDevelopmentLevel,
    townTileIsPort: townTileIsPort,
    isCapitalProvince: isCapitalProvince,
    usesRoadRule: usesRoadRule,
    portTileKeys: portKeys,
    pathTransportCap: effectivePathCap,
  );
}

/// Hypothetical next transport step for one extractable owned tile.
///
/// Returns null when [workTarget] does not bump stored transport on this tile.
TransportStepYieldPreview? computeTransportStepYieldPreview({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required String tileKey,
  required String workTarget,
  required Set<String> connectedTileKeys,
  required Map<String, int> pathTransportCap,
  required Set<String> connectedByRoadRule,
  required Set<String> portTileKeys,
  required String? capitalProvinceId,
  required int Function(CommodityId commodityId) techCapForCommodity,
  required bool Function(String tileKey, CommodityId commodityId)
      isCommodityExtractable,
  required bool hasRoadConstructionTech,
  Map<String, Province>? provincesByFullId,
}) {
  final tileState = game.worldState.tileState;
  final currentTransport = _storedTransportLevel(
    tileState: tileState,
    tileKey: tileKey,
    portTileKeys: portTileKeys,
  );
  final nextTransport = nextStoredTransportLevel(
    workTarget: workTarget,
    currentTransport: currentTransport,
    hasRoadConstructionTech: hasRoadConstructionTech,
  );
  if (nextTransport == null) {
    return null;
  }

  final connected = connectedTileKeys.contains(tileKey);
  final prelude = resolveImprovedTileProductionPrelude(
    game: game,
    tileMapByRegion: tileMapByRegion,
    tileKey: tileKey,
    logContext: 'transportStepYieldPreview',
    techCapForCommodity: techCapForCommodity,
    isCommodityExtractable: isCommodityExtractable,
    provincesByFullId: provincesByFullId,
  );

  if (prelude == null) {
    if (workTarget == TransportStepWorkTargets.buildPort) {
      return const TransportStepYieldPreview(
        kind: TransportStepYieldKind.portOnCoast,
        currentEffective: 0,
        nextEffective: 0,
      );
    }
    if (connected &&
        (workTarget == TransportStepWorkTargets.buildRoad ||
            workTarget == TransportStepWorkTargets.buildRail)) {
      return const TransportStepYieldPreview(
        kind: TransportStepYieldKind.bindsToCapital,
        currentEffective: 0,
        nextEffective: 0,
      );
    }
    if (!connected) {
      return const TransportStepYieldPreview(
        kind: TransportStepYieldKind.disconnected,
        currentEffective: 0,
        nextEffective: 0,
      );
    }
    return null;
  }

  final province = prelude.province;
  final isCapitalProvince = prelude.provinceId == capitalProvinceId;
  final usesRoadRule = connectedByRoadRule.contains(tileKey);
  final currentIsPort = portTileKeys.contains(tileKey);
  final nextIsPort =
      currentIsPort || workTarget == TransportStepWorkTargets.buildPort;

  final currentEffective = _yieldAtTransport(
    game: game,
    tileKey: tileKey,
    tileTransportLevel: currentTransport,
    tileIsPort: currentIsPort,
    techCap: prelude.techCap,
    province: province,
    connected: connected,
    isCapitalProvince: isCapitalProvince,
    usesRoadRule: usesRoadRule,
    portTileKeys: portTileKeys,
    pathTransportCap: pathTransportCap,
  );
  final nextEffective = _yieldAtTransport(
    game: game,
    tileKey: tileKey,
    tileTransportLevel: nextTransport,
    tileIsPort: nextIsPort,
    techCap: prelude.techCap,
    province: province,
    connected: connected,
    isCapitalProvince: isCapitalProvince,
    usesRoadRule: usesRoadRule,
    portTileKeys: portTileKeys,
    pathTransportCap: pathTransportCap,
  );

  if (!connected) {
    return TransportStepYieldPreview(
      commodityId: prelude.commodityId,
      currentEffective: 0,
      nextEffective: 0,
      kind: TransportStepYieldKind.disconnected,
    );
  }
  if (nextEffective > currentEffective) {
    return TransportStepYieldPreview(
      commodityId: prelude.commodityId,
      currentEffective: currentEffective,
      nextEffective: nextEffective,
      kind: TransportStepYieldKind.raise,
    );
  }

  final nextPathCap = _pathCapWithTileTransport(
    pathTransportCap: pathTransportCap,
    tileKey: tileKey,
    tileTransportLevel: nextTransport,
  );
  final pathCap = nextPathCap[tileKey] ?? nextTransport;
  final production = prelude.production;
  final afterPath = production < pathCap ? production : pathCap;
  final kind = afterPath < production
      ? TransportStepYieldKind.roadPathLimit
      : TransportStepYieldKind.townDevelopmentLimit;
  return TransportStepYieldPreview(
    commodityId: prelude.commodityId,
    currentEffective: currentEffective,
    nextEffective: nextEffective,
    kind: kind,
  );
}
