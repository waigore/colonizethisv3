import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../world/army_ids.dart';
import '../dossier/event_dialogue.dart';
import '../economy/build_cost.dart';
import 'build_rail_work_rules.dart';
import 'build_spawn_province.dart';
import 'orders_application_helpers.dart';
import '../world/naval.dart';
import '../world/ship_instance_allocate.dart';
import '../world/player_view.dart';
import '../world/province_lookup.dart';
import '../world/tile_control.dart';
import '../world/unit_lookup.dart';

part 'orders_application_work_phase.dart';
part 'orders_application_completed_work.dart';
part 'orders_application_build_phase.dart';

final _log = logicLogger();

void _appendMilitaryRegimentToArmy(
  _BuildWorkState state,
  Player player,
  String spawnProvinceId,
  String newUnitId,
) {
  final cap = player.capitalProvinceId;
  final atHome =
      cap != null &&
      (spawnProvinceId == cap ||
          (ProvinceId.regionIdFrom(spawnProvinceId) ==
                  ProvinceId.regionIdFrom(cap) &&
              ProvinceId.localIdFrom(spawnProvinceId) ==
                  ProvinceId.localIdFrom(cap)));
  final armyId = atHome
      ? homeArmyIdFor(player.id)
      : fieldArmyIdFor(player.id, spawnProvinceId);
  final ws = state.game.worldState;
  final regionId = ProvinceId.regionIdFrom(spawnProvinceId);
  final idx = ws.armies.indexWhere(
    (a) => a.id == armyId && a.ownerId == player.id,
  );
  if (idx >= 0) {
    final a = ws.armies[idx];
    final updated = a.copyWith(
      regimentUnitIds: [...a.regimentUnitIds, newUnitId],
    );
    final next = List<Army>.from(ws.armies)..[idx] = updated;
    state.game = state.game.copyWith(worldState: ws.copyWith(armies: next));
    return;
  }
  final stationed = atHome ? cap : spawnProvinceId;
  final newArmy = Army(
    id: armyId,
    ownerId: player.id,
    regionId: regionId,
    stationedProvinceId: stationed,
    regimentUnitIds: [newUnitId],
    isHomeArmy: atHome,
  );
  final next = [...ws.armies, newArmy]..sort((a, b) => a.id.compareTo(b.id));
  state.game = state.game.copyWith(worldState: ws.copyWith(armies: next));
}

/// Counter-spy: per-turn kill chance = (friendlySpies * [counterSpyKillChancePercentPerSpy])%,
/// capped at [counterSpyKillChanceCapPercent]%. SPEC: work order resolution.
const int counterSpyKillChancePercentPerSpy = 5;
const int counterSpyKillChanceCapPercent = 30;

/// Per-turn chance (0–1) that a spy on steal_tech work successfully steals one tech from target.
const double spyTechStealChance = 0.08;

/// Order application helpers for build and work phases.
/// SPEC/program/orders.md

/// Returns a new [Game] with [unitId]'s in-progress work cleared (currentWork
/// null, status idle). No material refund. SPEC/program/development-resolution.md
/// § Player-initiated cancel. Returns [game] unchanged if unit not found or
/// has no currentWork.
Game clearUnitCurrentWork(Game game, String unitId) {
  final oldUnits = game.worldState.oldWorld.units;
  final newUnits = game.worldState.newWorld.units;
  final inOld = oldUnits.where((u) => u.id == unitId).firstOrNull;
  final inNew = newUnits.where((u) => u.id == unitId).firstOrNull;
  final unit = inOld ?? inNew;
  if (unit == null || unit.currentWork == null) return game;
  final restoredTile = unit.originTileKey ?? unit.tileKey;
  final cleared = unit.copyWith(
    clearCurrentWork: true,
    status: UnitStatus.idle,
    tileKey: restoredTile,
    clearOriginTileKey: true,
    clearAssignedTileKey: true,
  );
  if (inOld != null) {
    final list = oldUnits.map((u) => u.id == unitId ? cleared : u).toList();
    final newOldWorld = RegionData(
      provinces: game.worldState.oldWorld.provinces,
      units: list,
    );
    return game.copyWith(
      worldState: game.worldState.copyWith(oldWorld: newOldWorld),
    );
  } else {
    final list = newUnits.map((u) => u.id == unitId ? cleared : u).toList();
    final newNewWorld = RegionData(
      provinces: game.worldState.newWorld.provinces,
      units: list,
    );
    return game.copyWith(
      worldState: game.worldState.copyWith(newWorld: newNewWorld),
    );
  }
}

/// Mutable work-phase and per-turn scratch maps/lists (WorkState per #1618).
class _WorkOrderState {
  _WorkOrderState({
    required this.oldUnitsById,
    required this.newUnitsById,
    required this.tileState,
    required this.visibilityByTile,
    required this.portsByProvinceSeaboard,
    required this.purchasedTilesByTileKey,
    required this.oldProvinces,
    required this.newProvinces,
  });

  final Map<String, Unit> oldUnitsById;
  final Map<String, Unit> newUnitsById;
  TileMapState tileState;
  Map<String, Map<String, String>> visibilityByTile;
  final Map<String, String> portsByProvinceSeaboard;
  final Map<String, String> purchasedTilesByTileKey;
  List<Province> oldProvinces;
  List<Province> newProvinces;
  final List<Player> updatedPlayers = [];
}

/// Session context for applyBuildAndWorkOrders: game mutation, order maps, map topology.
class _BuildWorkState {
  _BuildWorkState({
    required this.game,
    required this.buildOrders,
    required this.workOrders,
    this.topology,
    this.tileMapByRegion,
    this.onDialogue,
    required this.work,
  });

  Game game;
  final Map<String, List<BuildUnitOrder>> buildOrders;
  final Map<String, List<WorkOrder>> workOrders;
  final MapTopology? topology;
  final Map<String, TileMapResult>? tileMapByRegion;
  final void Function(DialogueEvent)? onDialogue;
  final _WorkOrderState work;
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

  final work = _WorkOrderState(
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
  final state = _BuildWorkState(
    game: game,
    buildOrders: buildOrders,
    workOrders: workOrders,
    topology: topology,
    tileMapByRegion: tileMapByRegion,
    onDialogue: onDialogue,
    work: work,
  );

  _runBuildPhase(state);

  void applyExploreCompletion(_BuildWorkState s, Unit u, String regionId) {
    final cw = u.currentWork!;
    final parts = cw.tileKey.split('|');
    final regionIdFromWork = parts.isNotEmpty ? parts[0] : regionId;
    final provinceId = parts.length > 1
        ? parts[1]
        : ProvinceId.localIdFrom(u.locationProvinceId);
    final fullProvinceId = parts.length > 1
        ? ProvinceId.full(regionIdFromWork, provinceId)
        : u.locationProvinceId;
    final tileKeys =
        s
            .game
            .worldState
            .tileKeysByRegionAndProvince[regionIdFromWork]?[fullProvinceId] ??
        [];
    final playerId = u.ownerId;
    final vis = Map<String, String>.from(
      s.work.visibilityByTile[playerId] ?? {},
    );
    for (final tk in tileKeys) {
      vis[tk] = VisibilityLevel.fullyVisible.name;
    }
    s.work.visibilityByTile = Map<String, Map<String, String>>.from(
      s.work.visibilityByTile,
    )..[playerId] = vis;
  }

  void applyCompletedWorkTarget(
    _BuildWorkState s,
    Unit u,
    CurrentWork cw,
    List<Province> Function() getProvinces,
    void Function(List<Province>) setProvinces,
  ) {
    _dispatchCompletedWorkTarget(
      s,
      u,
      cw,
      getProvinces,
      setProvinces,
      applyExploreCompletion,
    );
  }

  void processWorkUnits(
    _BuildWorkState s,
    Map<String, Unit> unitsById,
    List<Province> Function() getProvinces,
    void Function(List<Province>) setProvinces,
  ) {
    final rand = s.game.globalGameSeed != null
        ? Random(
            s.game.globalGameSeed! +
                (s.game.worldState.turnState.turnNumber * 1000),
          )
        : Random();
    // Iterate over a snapshot to allow updating unitsById during the loop.
    for (final entry in unitsById.entries.toList()) {
      final u = entry.value;
      if (u.currentWork == null) continue;
      final cw = u.currentWork!;
      // Cancel work if tile no longer owned by this player (SPEC: unit dead / tile no longer owned).
      final purchasedByTile = s.game.worldState.purchasedTilesByTileKey;
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
        _log.d(
          'work cancelled unit=${u.id} reason=tile no longer owned tileKey=${cw.tileKey}',
        );
        continue;
      }
      // Cancel work if tile no longer under player control (conquest or purchase reverted). SPEC #376.
      // Use same rule as validation: owned province or purchased tile; skip for counter_spy/steal_tech.
      if (cw.workTarget != kWorkTargetCounterSpy &&
          cw.workTarget != kWorkTargetStealTech) {
        if (!isTileControlledByPlayer(s.game, u.ownerId, cw.tileKey)) {
          final restoredTile = u.originTileKey ?? u.tileKey;
          unitsById[entry.key] = u.copyWith(
            status: UnitStatus.idle,
            tileKey: restoredTile,
            clearCurrentWork: true,
            clearOriginTileKey: true,
            clearAssignedTileKey: true,
          );
          _log.d(
            'work cancelled unit=${u.id} reason=tile no longer under control tileKey=${cw.tileKey}',
          );
          continue;
        }
      }
      if (cw.workTarget == kWorkTargetCounterSpy) {
        // Per-turn: N% per friendly spy (cap M%) to kill one enemy spy in province
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
        if (enemySpies.isNotEmpty && rand.nextDouble() < killChance) {
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
            _log.d('work cancelled unit=$toRemove reason=unit dead');
          }
          unitsById.remove(toRemove);
        }
        continue;
      }
      final nextRemaining = cw.remainingTurns - 1;
      if (nextRemaining <= 0) {
        if (cw.workTarget == kWorkTargetStealTech) {
          final targetProvinceId = Unit.provinceIdFromTileKey(cw.tileKey);
          final otherPlayer = s.game.players
              .where(
                (p) =>
                    p.id != u.ownerId &&
                    p.capitalProvinceId == targetProvinceId,
              )
              .firstOrNull;
          if (otherPlayer != null) {
            final ourTech = s.game.playerById(u.ownerId)?.techUnlocked ?? {};
            final theirTech = otherPlayer.techUnlocked ?? {};
            final missing = theirTech.entries
                .where((e) => e.value == true && ourTech[e.key] != true)
                .map((e) => e.key)
                .toList();
            if (missing.isNotEmpty && rand.nextDouble() < spyTechStealChance) {
              final granted = missing[rand.nextInt(missing.length)];
              final player = s.game.players
                  .where((p) => p.id == u.ownerId)
                  .firstOrNull;
              if (player != null) {
                final updated = Map<String, bool>.from(
                  player.techUnlocked ?? {},
                )..[granted] = true;
                s.game = s.game.copyWith(
                  players: s.game.players
                      .map(
                        (p) => p.id == u.ownerId
                            ? p.copyWith(techUnlocked: updated)
                            : p,
                      )
                      .toList(),
                );
              }
            }
          }
        } else {
          applyCompletedWorkTarget(s, u, cw, getProvinces, setProvinces);
        }
        unitsById[entry.key] = u.copyWith(
          status: UnitStatus.idle,
          clearOriginTileKey: true,
          clearAssignedTileKey: true,
          clearCurrentWork: true,
        );
      } else {
        unitsById[entry.key] = u.copyWith(
          currentWork: cw.copyWith(remainingTurns: nextRemaining),
        );
      }
    }
  }

  _runWorkPhase(state, applyExploreCompletion, applyCompletedWorkTarget);

  processWorkUnits(
    state,
    state.work.oldUnitsById,
    () => state.work.oldProvinces,
    (p) => state.work.oldProvinces = p,
  );
  processWorkUnits(
    state,
    state.work.newUnitsById,
    () => state.work.newProvinces,
    (p) => state.work.newProvinces = p,
  );

  state.game = state.game.copyWith(
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

  return state.game.copyWith(
    players: state.work.updatedPlayers,
    worldState: state.game.worldState.copyWith(
      purchasedTilesByTileKey: state.work.purchasedTilesByTileKey,
      oldWorld: RegionData(
        provinces: state.game.worldState.oldWorld.provinces,
        units: state.work.oldUnitsById.values.toList(),
      ),
      newWorld: RegionData(
        provinces: state.game.worldState.newWorld.provinces,
        units: state.work.newUnitsById.values.toList(),
      ),
    ),
  );
}
