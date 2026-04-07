part of 'orders_application.dart';

String _buildUnitId(
  String playerId,
  BuildUnitOrder order,
  String spawnProvinceId,
) {
  return '${playerId}_${order.unitType}_$spawnProvinceId';
}

/// Propagates road transport level to adjacent capital/port tiles.
///
/// Per SPEC/program/development-resolution.md: "build_road: set or upgrade
/// transport level for tileKey ... and, if applicable, adjacent capital/port
/// tiles per capital-and-connectivity.md."
///
/// When a road is built adjacent to the player's capital or a port, the
/// transport level is also applied to those adjacent tiles.
void _propagateRoadToAdjacentCapitalOrPort({
  required String tileKey,
  required int nextLevel,
  Player? player,
  required WorldState worldState,
  required Map<String, TileMapResult> tileMapByRegion,
  required TileMapState tileState,
  required void Function(TileMapState) setTileState,
}) {
  if (player == null) return;

  // Parse the target tile key: regionId|provinceId|x|y
  final parts = tileKey.split('|');
  if (parts.length != 4) return;
  final targetRegionId = parts[0];
  final targetX = int.tryParse(parts[2]);
  final targetY = int.tryParse(parts[3]);
  if (targetX == null || targetY == null) return;

  // Get player's capital tile key
  final capitalTileKey = player.capitalTile?.toTileKey();

  // Get all port tile keys
  final portTileKeys = worldState.portsByProvinceSeaboard.values.toSet();

  // Get the tile map for the region to check bounds
  final tileMap = tileMapByRegion[targetRegionId];
  if (tileMap == null) return;

  // Check 4 neighbours (north, east, south, west)
  final neighbours = [
    (targetX, targetY - 1),
    (targetX + 1, targetY),
    (targetX, targetY + 1),
    (targetX - 1, targetY),
  ];

  for (final (nx, ny) in neighbours) {
    // Check bounds
    if (nx < 0 || nx >= tileMap.width || ny < 0 || ny >= tileMap.height) {
      continue;
    }

    // Get the cell (province) at this position
    final cellId = tileMap.cell(nx, ny);

    // Build the adjacent tile key
    final adjacentTileKey = CapitalTile.tileKey(
      targetRegionId,
      '$targetRegionId|$cellId',
      nx,
      ny,
    );

    // Check if adjacent tile is the player's capital or a port
    final isCapital = adjacentTileKey == capitalTileKey;
    final isPort = portTileKeys.contains(adjacentTileKey);

    if (isCapital || isPort) {
      _log.d(
        'build_road propagating level $nextLevel to adjacent ${isCapital ? "capital" : "port"} tile $adjacentTileKey',
      );
      final currentLevel = tileState.roadLevel(adjacentTileKey);
      // Only upgrade, never downgrade.
      if (nextLevel > currentLevel) {
        setTileState(tileState.setRoadLevel(adjacentTileKey, nextLevel));
      }
    }
  }
}

typedef _CompletedWorkHandler =
    void Function(
      _BuildWorkState s,
      Unit u,
      CurrentWork cw,
      List<Province> Function() getProvinces,
      void Function(List<Province>) setProvinces,
      void Function(_BuildWorkState, Unit, String) applyExploreCompletion,
    );

void _dispatchCompletedWorkTarget(
  _BuildWorkState s,
  Unit u,
  CurrentWork cw,
  List<Province> Function() getProvinces,
  void Function(List<Province>) setProvinces,
  void Function(_BuildWorkState, Unit, String) applyExploreCompletion,
) {
  _log.d(
    'work completed unit=${u.id} workTarget=${cw.workTarget} tileKey=${cw.tileKey}',
  );
  final handler = _completedWorkTargetHandlers[cw.workTarget];
  handler?.call(s, u, cw, getProvinces, setProvinces, applyExploreCompletion);
}

void _completedWorkBuildImprovement(
  _BuildWorkState s,
  Unit u,
  CurrentWork cw,
  List<Province> Function() getProvinces,
  void Function(List<Province>) setProvinces,
  void Function(_BuildWorkState, Unit, String) applyExploreCompletion,
) {
  final level = s.tileState.improvementLevel(cw.tileKey);
  s.tileState = s.tileState.setImprovement(cw.tileKey, (level + 1).clamp(0, 4));
}

void _completedWorkUpgradeTown(
  _BuildWorkState s,
  Unit u,
  CurrentWork cw,
  List<Province> Function() getProvinces,
  void Function(List<Province>) setProvinces,
  void Function(_BuildWorkState, Unit, String) applyExploreCompletion,
) {
  final provinces = getProvinces();
  final idx = provinces.indexWhere((p) => p.id == u.locationProvinceId);
  if (idx >= 0) {
    final p = provinces[idx];
    setProvinces(
      List<Province>.from(provinces)
        ..[idx] = p.copyWith(
          townDevelopmentLevel: (p.townDevelopmentLevel + 1).clamp(0, 4),
        ),
    );
  }
}

void _completedWorkExplore(
  _BuildWorkState s,
  Unit u,
  CurrentWork cw,
  List<Province> Function() getProvinces,
  void Function(List<Province>) setProvinces,
  void Function(_BuildWorkState, Unit, String) applyExploreCompletion,
) {
  applyExploreCompletion(s, u, ProvinceId.regionIdFrom(u.locationProvinceId));
}

void _completedWorkBuildRoad(
  _BuildWorkState s,
  Unit u,
  CurrentWork cw,
  List<Province> Function() getProvinces,
  void Function(List<Province>) setProvinces,
  void Function(_BuildWorkState, Unit, String) applyExploreCompletion,
) {
  final roadLevel = s.tileState.roadLevel(cw.tileKey);
  final player = s.game.playerById(u.ownerId);
  final hasRoadConstruction =
      player?.techUnlocked?['road_construction'] == true;
  final nextLevel = (roadLevel + 1).clamp(0, hasRoadConstruction ? 2 : 1);
  s.tileState = s.tileState.setRoadLevel(cw.tileKey, nextLevel);

  final tileMap = s.tileMapByRegion;
  if (tileMap != null) {
    _propagateRoadToAdjacentCapitalOrPort(
      tileKey: cw.tileKey,
      nextLevel: nextLevel,
      player: player,
      worldState: s.game.worldState,
      tileMapByRegion: tileMap,
      tileState: s.tileState,
      setTileState: (newTileState) => s.tileState = newTileState,
    );
  }
}

void _completedWorkBuildPort(
  _BuildWorkState s,
  Unit u,
  CurrentWork cw,
  List<Province> Function() getProvinces,
  void Function(List<Province>) setProvinces,
  void Function(_BuildWorkState, Unit, String) applyExploreCompletion,
) {
  if (s.topology == null) {
    return;
  }
  final parts = cw.tileKey.split('|');
  final regionIdFromTile = parts.isNotEmpty
      ? parts[0]
      : ProvinceId.regionIdFrom(u.locationProvinceId);
  final localId = parts.length > 1
      ? parts[1]
      : ProvinceId.localIdFrom(u.locationProvinceId);
  final fullProvinceId = ProvinceId.full(regionIdFromTile, localId);
  final seaZoneId = seaZoneIdForProvince(
    s.topology!,
    localId,
    regionId: regionIdFromTile,
  );
  if (seaZoneId != null) {
    s.portsByProvinceSeaboard['$fullProvinceId|$seaZoneId'] = cw.tileKey;
    s.tileState = s.tileState.setRoadLevel(cw.tileKey, 4);
  }
}

void _completedWorkBuildFort(
  _BuildWorkState s,
  Unit u,
  CurrentWork cw,
  List<Province> Function() getProvinces,
  void Function(List<Province>) setProvinces,
  void Function(_BuildWorkState, Unit, String) applyExploreCompletion,
) {
  final provinces = getProvinces();
  final idx = provinces.indexWhere((p) => p.id == u.locationProvinceId);
  if (idx >= 0) {
    final p = provinces[idx];
    setProvinces(
      List<Province>.from(provinces)
        ..[idx] = p.copyWith(fortLevel: (p.fortLevel + 1).clamp(0, 3)),
    );
  }
  if (s.topology != null && s.onDialogue != null) {
    final seed =
        ((s.game.globalGameSeed ?? 0) ^
                (s.game.worldState.turnState.turnNumber * 0x9E3779B1))
            .toInt();
    final events = dialogueEventsForReactiveFortsOnBorder(
      s.game,
      s.topology!,
      u.ownerId,
      u.locationProvinceId,
      seed,
    );
    for (final e in events) {
      s.onDialogue!(e);
    }
  }
}

void _completedWorkBuildRail(
  _BuildWorkState s,
  Unit u,
  CurrentWork cw,
  List<Province> Function() getProvinces,
  void Function(List<Province>) setProvinces,
  void Function(_BuildWorkState, Unit, String) applyExploreCompletion,
) {
  final player = s.game.playerById(u.ownerId);
  final roadLevel = s.tileState.roadLevel(cw.tileKey);
  final terrain = terrainTypeForTileKey(s.tileMapByRegion, cw.tileKey);
  final reason = rejectionReasonForBuildRailOrder(
    techUnlocked: player?.techUnlocked,
    roadLevel: roadLevel,
    terrain: terrain,
  );
  if (reason == null) {
    s.tileState = s.tileState.setRoadLevel(cw.tileKey, 4);
  } else {
    _log.d('build_rail completion skipped unit=${u.id} reason=$reason');
  }
}

void _completedWorkNoop(
  _BuildWorkState s,
  Unit u,
  CurrentWork cw,
  List<Province> Function() getProvinces,
  void Function(List<Province>) setProvinces,
  void Function(_BuildWorkState, Unit, String) applyExploreCompletion,
) {}

/// Map-based work completion (Refs #1531). Unknown targets no-op.
final Map<String, _CompletedWorkHandler> _completedWorkTargetHandlers =
    <String, _CompletedWorkHandler>{
      kWorkTargetBuildImprovement: _completedWorkBuildImprovement,
      kWorkTargetUpgradeTown: _completedWorkUpgradeTown,
      kWorkTargetExplore: _completedWorkExplore,
      kWorkTargetBuildRoad: _completedWorkBuildRoad,
      kWorkTargetBuildPort: _completedWorkBuildPort,
      kWorkTargetBuildFort: _completedWorkBuildFort,
      'build_rail': _completedWorkBuildRail,
      kWorkTargetStealTech: _completedWorkNoop,
      kWorkTargetCounterSpy: _completedWorkNoop,
    };
