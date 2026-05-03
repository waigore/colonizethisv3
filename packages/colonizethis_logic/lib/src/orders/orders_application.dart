import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../dossier/event_dialogue.dart';
import '../dossier/evidence_rules.dart';
import '../world/player_view.dart';
import '../world/province_lookup.dart';
import '../world/tile_control.dart';
import '../world/unit_lookup.dart';
import 'orders_application_build_phase.dart';
import 'orders_application_completed_work.dart';
import 'orders_application_context.dart';
import 'orders_application_work_phase.dart';

/// Order application helpers for build and work phases.
/// SPEC/program/orders.md

/// Returns a new [Game] with [unitId]'s in-progress work cleared (currentWork
/// null, status idle). No material refund. SPEC/program/development-resolution.md
/// § Player-initiated cancel. Returns [game] unchanged if unit not found or
/// has no currentWork.
Game clearUnitCurrentWork(Game game, String unitId) {
  final ws = game.worldState;
  final oldIdx = ws.oldWorld.units.indexWhere((u) => u.id == unitId);
  late final Unit unit;
  late final bool inOldWorld;
  if (oldIdx >= 0) {
    unit = ws.oldWorld.units[oldIdx];
    inOldWorld = true;
  } else {
    final newIdx = ws.newWorld.units.indexWhere((u) => u.id == unitId);
    if (newIdx < 0) return game;
    unit = ws.newWorld.units[newIdx];
    inOldWorld = false;
  }
  if (unit.currentWork == null) return game;
  final restoredTile = unit.originTileKey ?? unit.tileKey;
  final cleared = unit.copyWith(
    clearCurrentWork: true,
    status: UnitStatus.idle,
    tileKey: restoredTile,
    clearOriginTileKey: true,
    clearAssignedTileKey: true,
  );
  if (inOldWorld) {
    final list = ws.oldWorld.units
        .map((u) => u.id == unitId ? cleared : u)
        .toList();
    final newOldWorld = RegionData(
      provinces: ws.oldWorld.provinces,
      units: list,
    );
    return game.copyWith(worldState: ws.copyWith(oldWorld: newOldWorld));
  }
  final list = ws.newWorld.units
      .map((u) => u.id == unitId ? cleared : u)
      .toList();
  final newNewWorld = RegionData(provinces: ws.newWorld.provinces, units: list);
  return game.copyWith(worldState: ws.copyWith(newWorld: newNewWorld));
}

/// Applies BuildUnitOrder and WorkOrder for all players in [game].
///
/// When [topology] is provided, ship builds spawn in home fleet.
/// When [onDialogue] is provided, reactive dialogue (e.g. forts_on_border) may be emitted for AI leaders.
/// BuildUnitOrder is applied by unit type category (civilian / military / naval) per buildUnitCategoryForUnitType.
/// - Civilian: deduct treasury + paper, add unit with tileKey.
/// - Military: deduct cost + worker, add unit.
/// - Naval: deduct cost + one peasant, add ship to home fleet at capital port.
/// - WorkOrder: sets the unit status to working; no terrain change yet.
Game applyBuildAndWorkOrders(
  Game game,
  Orders orders, {
  MapTopology? topology,
  Map<String, TileMapResult>? tileMapByRegion,
  void Function(DialogueEvent)? onDialogue,
}) {
  final buildOrders = orders.buildUnitOrdersByPlayerId;
  final workOrders = orders.workOrdersByPlayerId;
  if (buildOrders.isEmpty && workOrders.isEmpty) {
    return game;
  }

  final work = WorkOrderState(
    oldUnitsById: Map<String, Unit>.from(
      unitsByIdFromRegion(game.worldState.oldWorld),
    ),
    newUnitsById: Map<String, Unit>.from(
      unitsByIdFromRegion(game.worldState.newWorld),
    ),
    tileState: game.worldState.tileState,
    visibilityByTile: Map<String, Map<String, String>>.from(
      game.worldState.playerVisibilityByTile.map(
        (k, v) => MapEntry(k, Map<String, String>.from(v)),
      ),
    ),
    portsByProvinceSeaboard: Map<String, String>.from(
      game.worldState.portsByProvinceSeaboard,
    ),
    purchasedTilesByTileKey: Map<String, String>.from(
      game.worldState.purchasedTilesByTileKey,
    ),
    oldProvinces: List<Province>.from(game.worldState.oldWorld.provinces),
    newProvinces: List<Province>.from(game.worldState.newWorld.provinces),
  );
  var state = BuildWorkState(
    game: game,
    buildOrders: buildOrders,
    workOrders: workOrders,
    topology: topology,
    tileMapByRegion: tileMapByRegion,
    onDialogue: onDialogue,
    work: work,
  );

  state = runBuildPhase(state);
  state = runWorkPhase(
    state,
    _applyExploreCompletion,
    _applyCompletedWorkTarget,
  );

  state = _processWorkUnits(
    state,
    true,
    () => state.work.oldProvinces,
    (w, p) => w.copyWith(oldProvinces: p),
  );
  state = _processWorkUnits(
    state,
    false,
    () => state.work.newProvinces,
    (w, p) => w.copyWith(newProvinces: p),
  );

  final withWorld = state.game.copyWith(
    worldState: state.game.worldState.copyWith(
      tileState: state.work.tileState,
      playerVisibilityByTile: state.work.visibilityByTile,
      portsByProvinceSeaboard: state.work.portsByProvinceSeaboard,
      purchasedTilesByTileKey: state.work.purchasedTilesByTileKey,
      oldWorld: RegionData(
        provinces: state.work.oldProvinces,
        units: state.work.oldUnitsById.values.toList(),
      ),
      newWorld: RegionData(
        provinces: state.work.newProvinces,
        units: state.work.newUnitsById.values.toList(),
      ),
    ),
  );

  return withWorld.copyWith(
    players: state.work.updatedPlayers,
    worldState: withWorld.worldState.copyWith(
      purchasedTilesByTileKey: state.work.purchasedTilesByTileKey,
      oldWorld: RegionData(
        provinces: withWorld.worldState.oldWorld.provinces,
        units: state.work.oldUnitsById.values.toList(),
      ),
      newWorld: RegionData(
        provinces: withWorld.worldState.newWorld.provinces,
        units: state.work.newUnitsById.values.toList(),
      ),
    ),
  );
}

BuildWorkState _applyExploreCompletion(
  BuildWorkState s,
  Unit u,
  String regionId,
) {
  final cw = u.currentWork!;
  final parts = cw.tileKey.split('|');
  final regionIdFromWork = parts.isNotEmpty ? parts[0] : regionId;
  final provinceId = parts.length > 1
      ? parts[1]
      : ProvinceId.localIdFrom(u.locationProvinceId);
  final fullProvinceId = parts.length > 1
      ? ProvinceId.full(regionIdFromWork, provinceId)
      : u.locationProvinceId;
  final tileKeys = landTileKeysForProvinceBucket(
    s.game.worldState,
    regionIdFromWork,
    fullProvinceId,
  );
  final playerId = u.ownerId;
  final vis = Map<String, String>.from(s.work.visibilityByTile[playerId] ?? {});
  for (final tk in tileKeys) {
    vis[tk] = VisibilityLevel.fullyVisible.name;
  }
  final visibilityByTile = Map<String, Map<String, String>>.from(
    s.work.visibilityByTile,
  )..[playerId] = vis;
  return s.copyWith(work: s.work.copyWith(visibilityByTile: visibilityByTile));
}

BuildWorkState _applyCompletedWorkTarget(
  BuildWorkState s,
  Unit u,
  CurrentWork cw,
  List<Province> Function() getProvinces,
  WorkOrderState Function(WorkOrderState, List<Province>) replaceProvinces,
) {
  return dispatchCompletedWorkTarget(
    s,
    u,
    cw,
    getProvinces,
    replaceProvinces,
    _applyExploreCompletion,
  );
}

BuildWorkState _processWorkUnits(
  BuildWorkState s,
  bool oldWorldUnits,
  List<Province> Function() getProvinces,
  WorkOrderState Function(WorkOrderState, List<Province>) replaceProvinces,
) {
  final unitsById = oldWorldUnits
      ? Map<String, Unit>.from(s.work.oldUnitsById)
      : Map<String, Unit>.from(s.work.newUnitsById);
  var current = oldWorldUnits
      ? s.copyWith(work: s.work.copyWith(oldUnitsById: unitsById))
      : s.copyWith(work: s.work.copyWith(newUnitsById: unitsById));
  final rand = s.game.globalGameSeed != null
      ? Random(
          s.game.globalGameSeed! +
              (s.game.worldState.turnState.turnNumber * 1000),
        )
      : Random();
  for (final entry in unitsById.entries.toList()) {
    final u = entry.value;
    if (u.currentWork == null) continue;
    final cw = u.currentWork!;
    final purchasedByTile = current.game.worldState.purchasedTilesByTileKey;
    if (purchasedByTile.containsKey(cw.tileKey) &&
        purchasedByTile[cw.tileKey] != u.ownerId) {
      final restoredTile = u.originTileKey ?? u.tileKey;
      unitsById[entry.key] = u.copyWith(
        status: UnitStatus.idle,
        tileKey: restoredTile,
        clearCurrentWork: true,
        clearOriginTileKey: true,
        clearAssignedTileKey: true,
      );
      ordersApplicationLog.d(
        'work cancelled unit=${u.id} reason=tile no longer owned tileKey=${cw.tileKey}',
      );
      continue;
    }
    if (cw.workTarget != kWorkTargetCounterSpy &&
        cw.workTarget != kWorkTargetStealTech &&
        cw.workTarget != kWorkTargetExplore &&
        cw.workTarget != kWorkTargetPurchaseLand &&
        !isTileControlledByPlayer(current.game, u.ownerId, cw.tileKey)) {
      final restoredTile = u.originTileKey ?? u.tileKey;
      unitsById[entry.key] = u.copyWith(
        status: UnitStatus.idle,
        tileKey: restoredTile,
        clearCurrentWork: true,
        clearOriginTileKey: true,
        clearAssignedTileKey: true,
      );
      ordersApplicationLog.d(
        'work cancelled unit=${u.id} reason=tile no longer under control tileKey=${cw.tileKey}',
      );
      continue;
    }
    if (cw.workTarget == kWorkTargetCounterSpy) {
      current = _resolveCounterSpyTick(
        current,
        unitsById,
        u,
        rand,
        oldWorldUnits: oldWorldUnits,
      );
      continue;
    }
    current = _advanceWorkUnitTick(
      current,
      unitsById,
      entry.key,
      u,
      cw,
      rand,
      getProvinces,
      replaceProvinces,
      oldWorldUnits: oldWorldUnits,
    );
  }
  return oldWorldUnits
      ? current.copyWith(work: current.work.copyWith(oldUnitsById: unitsById))
      : current.copyWith(work: current.work.copyWith(newUnitsById: unitsById));
}

BuildWorkState _resolveCounterSpyTick(
  BuildWorkState s,
  Map<String, Unit> unitsById,
  Unit u,
  Random rand, {
  required bool oldWorldUnits,
}) {
  final provinceId = u.locationProvinceId;
  final friendlySpies = unitsById.values
      .where(
        (x) =>
            x.ownerId == u.ownerId &&
            isSpyUnit(x.type) &&
            x.currentWork?.workTarget == kWorkTargetCounterSpy &&
            x.locationProvinceId == provinceId,
      )
      .length;
  final killChance =
      (friendlySpies * counterSpyKillChancePercentPerSpy).clamp(
        0,
        counterSpyKillChanceCapPercent,
      ) /
      100.0;
  final enemySpies = unitsById.entries.where((e) {
    final x = e.value;
    return x.ownerId != u.ownerId &&
        isSpyUnit(x.type) &&
        x.locationProvinceId == provinceId;
  }).toList();
  if (enemySpies.isEmpty || rand.nextDouble() >= killChance) {
    return s;
  }
  final toRemove = enemySpies.first.key;
  final removed = unitsById[toRemove];
  if (s.onDialogue != null && removed != null) {
    final events = dialogueEventsForReactiveSpiesCaught(
      s.game,
      speakerId: u.ownerId,
      caughtSpyOwnerId: removed.ownerId,
      provinceId: provinceId,
      turnNumber: s.game.worldState.turnState.turnNumber,
      seed: s.game.globalGameSeed ?? 0,
    );
    for (final e in events) {
      s.onDialogue!(e);
    }
  }
  if (removed?.currentWork != null) {
    ordersApplicationLog.d('work cancelled unit=$toRemove reason=unit dead');
  }
  unitsById.remove(toRemove);
  return oldWorldUnits
      ? s.copyWith(work: s.work.copyWith(oldUnitsById: unitsById))
      : s.copyWith(work: s.work.copyWith(newUnitsById: unitsById));
}

BuildWorkState _advanceWorkUnitTick(
  BuildWorkState s,
  Map<String, Unit> unitsById,
  String unitKey,
  Unit u,
  CurrentWork cw,
  Random rand,
  List<Province> Function() getProvinces,
  WorkOrderState Function(WorkOrderState, List<Province>) replaceProvinces, {
  required bool oldWorldUnits,
}) {
  final nextRemaining = cw.remainingTurns - 1;
  if (nextRemaining <= 0) {
    var next = s;
    if (cw.workTarget == kWorkTargetStealTech) {
      next = _resolveStealTechCompletion(next, u, cw, rand);
    } else {
      next = _applyCompletedWorkTarget(
        next,
        u,
        cw,
        getProvinces,
        replaceProvinces,
      );
    }
    unitsById[unitKey] = u.copyWith(
      status: UnitStatus.idle,
      clearOriginTileKey: true,
      clearAssignedTileKey: true,
      clearCurrentWork: true,
    );
    return oldWorldUnits
        ? next.copyWith(work: next.work.copyWith(oldUnitsById: unitsById))
        : next.copyWith(work: next.work.copyWith(newUnitsById: unitsById));
  }
  unitsById[unitKey] = u.copyWith(
    currentWork: cw.copyWith(remainingTurns: nextRemaining),
  );
  return oldWorldUnits
      ? s.copyWith(work: s.work.copyWith(oldUnitsById: unitsById))
      : s.copyWith(work: s.work.copyWith(newUnitsById: unitsById));
}

BuildWorkState _resolveStealTechCompletion(
  BuildWorkState s,
  Unit u,
  CurrentWork cw,
  Random rand,
) {
  final targetProvinceId = Unit.provinceIdFromTileKey(cw.tileKey);
  final otherPlayer = s.game.players
      .where(
        (p) => p.id != u.ownerId && p.capitalProvinceId == targetProvinceId,
      )
      .firstOrNull;
  var stealSuccess = false;
  var game = s.game;
  if (otherPlayer != null) {
    final ourTech = game.playerById(u.ownerId)?.techUnlocked ?? {};
    final theirTech = otherPlayer.techUnlocked ?? {};
    final missing = theirTech.entries
        .where((e) => e.value == true && ourTech[e.key] != true)
        .map((e) => e.key)
        .toList();
    if (missing.isNotEmpty && rand.nextDouble() < spyTechStealChance) {
      stealSuccess = true;
      final granted = missing[rand.nextInt(missing.length)];
      final player = game.playerById(u.ownerId);
      if (player != null) {
        final updated = Map<String, bool>.from(player.techUnlocked ?? {})
          ..[granted] = true;
        game = game.copyWith(
          players: game.players
              .map(
                (p) =>
                    p.id == u.ownerId ? p.copyWith(techUnlocked: updated) : p,
              )
              .toList(),
        );
      }
    }
  }
  final turn = game.worldState.turnState.turnNumber;
  final spyEvidence = evidenceForAiStealTechResolved(
    game,
    u.ownerId,
    turn,
    success: stealSuccess,
  );
  if (spyEvidence.isNotEmpty) {
    game = game.copyWith(
      dossierEvidenceEntries: [...game.dossierEvidenceEntries, ...spyEvidence],
    );
  }
  return s.copyWith(game: game);
}
