import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../dossier/event_dialogue.dart';
import '../dossier/evidence_rules.dart';
import '../economy/build_cost.dart';
import '../world/naval.dart';
import 'build_rail_work_rules.dart';
import 'orders_application_context.dart';

/// Propagates road transport level to adjacent capital/port tiles.
///
/// Per SPEC/program/development-resolution.md: "build_road: set or upgrade
/// transport level for tileKey ... and, if applicable, adjacent capital/port
/// tiles per capital-and-connectivity.md."
///
/// When a road is built adjacent to the player's capital or a port, the
/// transport level is also applied to those adjacent tiles.
TileMapState propagateRoadToAdjacentCapitalOrPort({
  required String tileKey,
  required int nextLevel,
  Player? player,
  required WorldState worldState,
  required Map<String, TileMapResult> tileMapByRegion,
  required TileMapState tileState,
}) {
  var current = tileState;
  if (player == null) return current;

  // Parse the target tile key: regionId|provinceId|x|y
  final parts = tileKey.split('|');
  if (parts.length != 4) return current;
  final targetRegionId = parts[0];
  final targetX = int.tryParse(parts[2]);
  final targetY = int.tryParse(parts[3]);
  if (targetX == null || targetY == null) return current;

  // Get player's capital tile key
  final capitalTileKey = player.capitalTile?.toTileKey();

  // Get all port tile keys
  final portTileKeys = worldState.portsByProvinceSeaboard.values.toSet();

  // Get the tile map for the region to check bounds
  final tileMap = tileMapByRegion[targetRegionId];
  if (tileMap == null) return current;

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
      ordersApplicationLog.d(
        'build_road propagating level $nextLevel to adjacent ${isCapital ? "capital" : "port"} tile $adjacentTileKey',
      );
      final roadLevel = current.roadLevel(adjacentTileKey);
      // Only upgrade, never downgrade.
      if (nextLevel > roadLevel) {
        current = current.setRoadLevel(adjacentTileKey, nextLevel);
      }
    }
  }
  return current;
}

typedef _CompletedWorkHandler =
    BuildWorkState Function(
      BuildWorkState s,
      Unit u,
      CurrentWork cw,
      List<Province> Function() getProvinces,
      WorkOrderState Function(WorkOrderState, List<Province>) replaceProvinces,
      BuildWorkState Function(BuildWorkState, Unit, String) applyExploreCompletion,
    );

BuildWorkState dispatchCompletedWorkTarget(
  BuildWorkState s,
  Unit u,
  CurrentWork cw,
  List<Province> Function() getProvinces,
  WorkOrderState Function(WorkOrderState, List<Province>) replaceProvinces,
  BuildWorkState Function(BuildWorkState, Unit, String) applyExploreCompletion,
) {
  ordersApplicationLog.d(
    'work completed unit=${u.id} workTarget=${cw.workTarget} tileKey=${cw.tileKey}',
  );
  final handler = _completedWorkTargetHandlers[cw.workTarget];
  if (handler == null) return s;
  return handler(s, u, cw, getProvinces, replaceProvinces, applyExploreCompletion);
}

BuildWorkState _completedWorkBuildImprovement(
  BuildWorkState s,
  Unit u,
  CurrentWork cw,
  List<Province> Function() getProvinces,
  WorkOrderState Function(WorkOrderState, List<Province>) replaceProvinces,
  BuildWorkState Function(BuildWorkState, Unit, String) applyExploreCompletion,
) {
  final level = s.work.tileState.improvementLevel(cw.tileKey);
  var work = s.work.copyWith(
    tileState: s.work.tileState.setImprovement(
      cw.tileKey,
      (level + 1).clamp(0, 4),
    ),
  );
  var game = s.game;

  final resourceId = game.worldState.resourceByTileKey[cw.tileKey];
  final mirrorCat = envyMirrorTechCategoryForExtractionResource(resourceId);
  if (mirrorCat == null) {
    return s.copyWith(work: work);
  }
  final turn = game.worldState.turnState.turnNumber;
  final owner = game.playerById(u.ownerId);
  if (owner != null && owner.isHuman) {
    game = game.copyWith(
      lastHumanCompletedResearchCategory: mirrorCat,
      lastHumanResearchCategoryCompletionTurn: turn,
    );
    return s.copyWith(game: game, work: work);
  }
  if (isAiControlledForEvidence(game, u.ownerId)) {
    final ev = evidenceForEnvyResearchMirror(
      game,
      u.ownerId,
      mirrorCat,
      turn,
      const [],
    );
    if (ev.isNotEmpty) {
      game = game.copyWith(
        dossierEvidenceEntries: [...game.dossierEvidenceEntries, ...ev],
      );
    }
  }
  return s.copyWith(game: game, work: work);
}

BuildWorkState _completedWorkUpgradeTown(
  BuildWorkState s,
  Unit u,
  CurrentWork cw,
  List<Province> Function() getProvinces,
  WorkOrderState Function(WorkOrderState, List<Province>) replaceProvinces,
  BuildWorkState Function(BuildWorkState, Unit, String) applyExploreCompletion,
) {
  final provinces = getProvinces();
  final idx = provinces.indexWhere((p) => p.id == u.locationProvinceId);
  if (idx < 0) return s;
  final p = provinces[idx];
  final next = List<Province>.from(provinces)
    ..[idx] = p.copyWith(
      townDevelopmentLevel: (p.townDevelopmentLevel + 1).clamp(0, 4),
    );
  return s.copyWith(work: replaceProvinces(s.work, next));
}

BuildWorkState _completedWorkExplore(
  BuildWorkState s,
  Unit u,
  CurrentWork cw,
  List<Province> Function() getProvinces,
  WorkOrderState Function(WorkOrderState, List<Province>) replaceProvinces,
  BuildWorkState Function(BuildWorkState, Unit, String) applyExploreCompletion,
) {
  return applyExploreCompletion(
    s,
    u,
    ProvinceId.regionIdFrom(u.locationProvinceId),
  );
}

BuildWorkState _completedWorkBuildRoad(
  BuildWorkState s,
  Unit u,
  CurrentWork cw,
  List<Province> Function() getProvinces,
  WorkOrderState Function(WorkOrderState, List<Province>) replaceProvinces,
  BuildWorkState Function(BuildWorkState, Unit, String) applyExploreCompletion,
) {
  final roadLevel = s.work.tileState.roadLevel(cw.tileKey);
  final player = s.game.playerById(u.ownerId);
  final hasRoadConstruction =
      player?.techUnlocked?[kTechIdRoadConstruction] == true;
  final nextLevel = (roadLevel + 1).clamp(0, hasRoadConstruction ? 2 : 1);
  var tileState = s.work.tileState.setRoadLevel(cw.tileKey, nextLevel);

  final tileMap = s.tileMapByRegion;
  if (tileMap != null) {
    tileState = propagateRoadToAdjacentCapitalOrPort(
      tileKey: cw.tileKey,
      nextLevel: nextLevel,
      player: player,
      worldState: s.game.worldState,
      tileMapByRegion: tileMap,
      tileState: tileState,
    );
  }
  return s.copyWith(work: s.work.copyWith(tileState: tileState));
}

BuildWorkState _completedWorkBuildPort(
  BuildWorkState s,
  Unit u,
  CurrentWork cw,
  List<Province> Function() getProvinces,
  WorkOrderState Function(WorkOrderState, List<Province>) replaceProvinces,
  BuildWorkState Function(BuildWorkState, Unit, String) applyExploreCompletion,
) {
  if (s.topology == null) {
    return s;
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
  if (seaZoneId == null) return s;
  final ports = Map<String, String>.from(s.work.portsByProvinceSeaboard)
    ..['$fullProvinceId|$seaZoneId'] = cw.tileKey;
  final tileState = s.work.tileState.setRoadLevel(cw.tileKey, 4);
  return s.copyWith(
    work: s.work.copyWith(
      portsByProvinceSeaboard: ports,
      tileState: tileState,
    ),
  );
}

BuildWorkState _completedWorkBuildFort(
  BuildWorkState s,
  Unit u,
  CurrentWork cw,
  List<Province> Function() getProvinces,
  WorkOrderState Function(WorkOrderState, List<Province>) replaceProvinces,
  BuildWorkState Function(BuildWorkState, Unit, String) applyExploreCompletion,
) {
  final provinces = getProvinces();
  final idx = provinces.indexWhere((p) => p.id == u.locationProvinceId);
  WorkOrderState work = s.work;
  if (idx >= 0) {
    final p = provinces[idx];
    final next = List<Province>.from(provinces)
      ..[idx] = p.copyWith(fortLevel: (p.fortLevel + 1).clamp(0, 3));
    work = replaceProvinces(work, next);
  }
  if (s.topology != null && s.onDialogue != null) {
    final seed =
        ((s.game.globalGameSeed ?? 0) ^
                (s.game.worldState.turnState.turnNumber *
                    kDeterministicHashMixPrime32))
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
  return s.copyWith(work: work);
}

BuildWorkState _completedWorkBuildRail(
  BuildWorkState s,
  Unit u,
  CurrentWork cw,
  List<Province> Function() getProvinces,
  WorkOrderState Function(WorkOrderState, List<Province>) replaceProvinces,
  BuildWorkState Function(BuildWorkState, Unit, String) applyExploreCompletion,
) {
  final player = s.game.playerById(u.ownerId);
  final roadLevel = s.work.tileState.roadLevel(cw.tileKey);
  final terrain = terrainTypeForTileKey(s.tileMapByRegion, cw.tileKey);
  final reason = rejectionReasonForBuildRailOrder(
    techUnlocked: player?.techUnlocked,
    roadLevel: roadLevel,
    terrain: terrain,
  );
  if (reason == null) {
    return s.copyWith(
      work: s.work.copyWith(
        tileState: s.work.tileState.setRoadLevel(cw.tileKey, 4),
      ),
    );
  }
  ordersApplicationLog.d('build_rail completion skipped unit=${u.id} reason=$reason');
  return s;
}

BuildWorkState _completedWorkNoop(
  BuildWorkState s,
  Unit u,
  CurrentWork cw,
  List<Province> Function() getProvinces,
  WorkOrderState Function(WorkOrderState, List<Province>) replaceProvinces,
  BuildWorkState Function(BuildWorkState, Unit, String) applyExploreCompletion,
) => s;

/// Map-based work completion (Refs #1531). Unknown targets no-op.
final Map<String, _CompletedWorkHandler> _completedWorkTargetHandlers =
    <String, _CompletedWorkHandler>{
      kWorkTargetBuildImprovement: _completedWorkBuildImprovement,
      kWorkTargetUpgradeTown: _completedWorkUpgradeTown,
      kWorkTargetExplore: _completedWorkExplore,
      kWorkTargetBuildRoad: _completedWorkBuildRoad,
      kWorkTargetBuildPort: _completedWorkBuildPort,
      kWorkTargetBuildFort: _completedWorkBuildFort,
      kWorkTargetBuildRail: _completedWorkBuildRail,
      kWorkTargetStealTech: _completedWorkNoop,
      kWorkTargetCounterSpy: _completedWorkNoop,
    };
