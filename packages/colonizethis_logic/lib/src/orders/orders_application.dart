import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../dossier/event_dialogue.dart';
import '../economy/build_cost.dart';
import 'orders_application_helpers.dart';
import '../world/naval.dart';
import '../world/player_view.dart';
import '../world/province_lookup.dart';
import '../world/tile_control.dart';
import '../world/unit_lookup.dart';

final _log = logicLogger();

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
  final cleared = unit.copyWith(
    clearCurrentWork: true,
    status: UnitStatus.idle,
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

/// Mutable state shared by build phase, work phase, and processWorkUnits.
class _BuildWorkState {
  _BuildWorkState({
    required this.game,
    required this.buildOrders,
    required this.workOrders,
    this.topology,
    this.tileMapByRegion,
    this.onDialogue,
    required this.oldUnitsById,
    required this.newUnitsById,
    required this.tileState,
    required this.visibilityByTile,
    required this.portsByProvinceSeaboard,
    required this.purchasedTilesByTileKey,
    required this.oldProvinces,
    required this.newProvinces,
  });

  Game game;
  final Map<String, List<BuildUnitOrder>> buildOrders;
  final Map<String, List<WorkOrder>> workOrders;
  final MapTopology? topology;
  final Map<String, TileMapResult>? tileMapByRegion;
  final void Function(DialogueEvent)? onDialogue;
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

/// Applies build orders for all players. Mutates [state.game], [state.oldUnitsById], [state.newUnitsById].
void _runBuildPhase(_BuildWorkState state) {
  for (final player in state.game.players) {
    var workers = player.workerPool;
    var stockpile = player.stockpile;
    var treasury = player.treasury;

    for (final order in state.buildOrders[player.id] ?? const []) {
      final category = buildUnitCategoryForUnitType(order.unitType);
      if (category == BuildUnitCategory.unknown) continue;

      final check = canAffordBuild(player, order, workers, stockpile, treasury);
      if (!check.canAfford) continue;

      final after = applyBuildCostDeduction(
        player,
        order,
        workers,
        stockpile,
        treasury,
      );
      workers = after.workers;
      stockpile = after.stockpile;
      treasury = after.treasury;

      if (category == BuildUnitCategory.naval) {
        final capProvinceId = player.capitalProvinceId;
        if (capProvinceId == null) continue;
        final regionId = ProvinceId.regionIdFrom(capProvinceId);
        // Only add ship when capital is sea-bound (has a port). SPEC/game/ships-and-naval.md.
        if (state.topology == null) continue;
        final seaZoneAtCap = seaZoneIdForProvince(
          state.topology!,
          ProvinceId.localIdFrom(capProvinceId),
          regionId: regionId,
        );
        if (seaZoneAtCap == null) continue;

        var fleets = List<Fleet>.from(state.game.worldState.fleets);
        final homeFleetId = homeFleetIdFor(player.id);
        final existing = fleets.indexWhere(
          (f) => f.id == homeFleetId && f.ownerId == player.id,
        );
        if (existing >= 0) {
          final f = fleets[existing];
          fleets = List<Fleet>.from(fleets)
            ..[existing] = f.copyWith(
              shipTypeIds: [...f.shipTypeIds, order.unitType],
            );
        } else {
          fleets = [
            ...fleets,
            Fleet(
              id: homeFleetId,
              ownerId: player.id,
              seaZoneId: null,
              inPortAtProvinceId: capProvinceId,
              regionId: regionId,
              shipTypeIds: [order.unitType],
            ),
          ];
        }
        state.game = state.game.copyWith(
          worldState: state.game.worldState.copyWith(fleets: fleets),
        );
        continue;
      }

      final spawnProvinceId = order.spawnProvinceId;
      final regionId = ProvinceId.regionIdFrom(spawnProvinceId);
      final tileKeysByRegion =
          state.game.worldState.tileKeysByRegionAndProvince;
      final firstTileInSpawn =
          tileKeysByRegion[regionId]?[spawnProvinceId]?.isNotEmpty == true
          ? tileKeysByRegion[regionId]![spawnProvinceId]!.first
          : null;

      final newUnit = Unit(
        id: _buildUnitId(player.id, order),
        type: order.unitType,
        ownerId: player.id,
        locationProvinceId: spawnProvinceId,
        tileKey: category == BuildUnitCategory.civilian
            ? firstTileInSpawn
            : null,
      );

      if (regionId == kRegionNewWorld) {
        state.newUnitsById[newUnit.id] = newUnit;
      } else {
        state.oldUnitsById[newUnit.id] = newUnit;
      }
    }

    // Apply build-phase deductions to this player so _runWorkPhase sees updated state.
    state.game = state.game.copyWith(
      players: state.game.players
          .map(
            (p) => p.id == player.id
                ? p.copyWith(
                    stockpile: stockpile,
                    workerPool: workers,
                    treasury: treasury,
                  )
                : p,
          )
          .toList(),
    );
  }
}

/// Applies BuildUnitOrder and WorkOrder for all players in [game].
///
/// When [topology] is provided, ship builds spawn in home fleet.
/// When [onDialogue] is provided, reactive dialogue (e.g. forts_on_border) may be emitted for AI leaders.
/// BuildUnitOrder is applied by unit type category (civilian / military / naval) per buildUnitCategoryForUnitType.
/// - Civilian: deduct treasury + paper, add unit with tileKey.
/// - Military: deduct cost + worker, add unit.
/// - Naval: deduct cost, add ship to home fleet at capital port.
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

  final state = _BuildWorkState(
    game: game,
    buildOrders: buildOrders,
    workOrders: workOrders,
    topology: topology,
    tileMapByRegion: tileMapByRegion,
    onDialogue: onDialogue,
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
    final vis = Map<String, String>.from(s.visibilityByTile[playerId] ?? {});
    for (final tk in tileKeys) {
      vis[tk] = VisibilityLevel.fullyVisible.name;
    }
    s.visibilityByTile = Map<String, Map<String, String>>.from(
      s.visibilityByTile,
    )..[playerId] = vis;
  }

  void applyCompletedWorkTarget(
    _BuildWorkState s,
    Unit u,
    CurrentWork cw,
    List<Province> Function() getProvinces,
    void Function(List<Province>) setProvinces,
  ) {
    _log.d(
      'logic: work completed unit=${u.id} workTarget=${cw.workTarget} tileKey=${cw.tileKey}',
    );
    switch (cw.workTarget) {
      case 'build_improvement':
        final level = s.tileState.improvementLevel(cw.tileKey);
        s.tileState = s.tileState.setImprovement(
          cw.tileKey,
          (level + 1).clamp(0, 4),
        );
        break;
      case 'upgrade_town':
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
        break;
      case 'explore':
        applyExploreCompletion(
          s,
          u,
          ProvinceId.regionIdFrom(u.locationProvinceId),
        );
        break;
      case 'build_road':
        {
          final roadLevel = s.tileState.roadLevel(cw.tileKey);
          final player = s.game.players
              .where((p) => p.id == u.ownerId)
              .firstOrNull;
          final hasRoadConstruction =
              player?.techUnlocked?['road_construction'] == true;
          final nextLevel = (roadLevel + 1).clamp(
            0,
            hasRoadConstruction ? 2 : 1,
          );
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
          break;
        }
      case 'build_port':
        if (s.topology != null) {
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
            s.portsByProvinceSeaboard['$fullProvinceId|$seaZoneId'] =
                cw.tileKey;
            s.tileState = s.tileState.setRoadLevel(cw.tileKey, 4);
          }
        }
        break;
      case 'build_fort':
        {
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
            for (final e in events) s.onDialogue!(e);
          }
          break;
        }
      case 'build_rail':
        s.tileState = s.tileState.setRoadLevel(cw.tileKey, 4);
        break;
      case 'steal_tech':
      case 'counter_spy':
        break;
      default:
        break;
    }
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
        unitsById[entry.key] = u.copyWith(
          status: UnitStatus.idle,
          clearCurrentWork: true,
        );
        _log.d(
          'logic: work cancelled unit=${u.id} reason=tile no longer owned tileKey=${cw.tileKey}',
        );
        continue;
      }
      // Cancel work if tile no longer under player control (conquest or purchase reverted). SPEC #376.
      // Use same rule as validation: owned province or purchased tile; skip for counter_spy/steal_tech.
      if (cw.workTarget != 'counter_spy' && cw.workTarget != 'steal_tech') {
        if (!isTileControlledByPlayer(s.game, u.ownerId, cw.tileKey)) {
          unitsById[entry.key] = u.copyWith(
            status: UnitStatus.idle,
            clearCurrentWork: true,
          );
          _log.d(
            'logic: work cancelled unit=${u.id} reason=tile no longer under control tileKey=${cw.tileKey}',
          );
          continue;
        }
      }
      if (cw.workTarget == 'counter_spy') {
        // Per-turn: N% per friendly spy (cap M%) to kill one enemy spy in province
        final provinceId = u.locationProvinceId;
        final friendlySpies = unitsById.values
            .where(
              (x) =>
                  x.ownerId == u.ownerId &&
                  isSpyUnit(x.type) &&
                  x.currentWork?.workTarget == 'counter_spy' &&
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
          if (removed?.currentWork != null) {
            _log.d('logic: work cancelled unit=$toRemove reason=unit dead');
          }
          unitsById.remove(toRemove);
        }
        continue;
      }
      final nextRemaining = cw.remainingTurns - 1;
      if (nextRemaining <= 0) {
        if (cw.workTarget == 'steal_tech') {
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
    state.oldUnitsById,
    () => state.oldProvinces,
    (p) => state.oldProvinces = p,
  );
  processWorkUnits(
    state,
    state.newUnitsById,
    () => state.newProvinces,
    (p) => state.newProvinces = p,
  );

  state.game = state.game.copyWith(
    worldState: state.game.worldState.copyWith(
      tileState: state.tileState,
      playerVisibilityByTile: state.visibilityByTile,
      portsByProvinceSeaboard: state.portsByProvinceSeaboard,
      purchasedTilesByTileKey: state.purchasedTilesByTileKey,
      oldWorld: RegionData(
        provinces: state.oldProvinces,
        units: state.oldUnitsById.values.toList(),
      ),
      newWorld: RegionData(
        provinces: state.newProvinces,
        units: state.newUnitsById.values.toList(),
      ),
    ),
  );

  return state.game.copyWith(
    players: state.updatedPlayers,
    worldState: state.game.worldState.copyWith(
      purchasedTilesByTileKey: state.purchasedTilesByTileKey,
      oldWorld: RegionData(
        provinces: state.game.worldState.oldWorld.provinces,
        units: state.oldUnitsById.values.toList(),
      ),
      newWorld: RegionData(
        provinces: state.game.worldState.newWorld.provinces,
        units: state.newUnitsById.values.toList(),
      ),
    ),
  );
}

void _runWorkPhase(
  _BuildWorkState state,
  void Function(_BuildWorkState, Unit, String) applyExploreCompletion,
  void Function(
    _BuildWorkState,
    Unit,
    CurrentWork,
    List<Province> Function(),
    void Function(List<Province>),
  )
  applyCompletedWorkTarget,
) {
  final workOrders = state.workOrders;
  final tileState = state.tileState;
  final oldUnitsById = state.oldUnitsById;
  final newUnitsById = state.newUnitsById;
  final purchasedTilesByTileKey = state.purchasedTilesByTileKey;

  for (final player in state.game.players) {
    var stockpile = player.stockpile;
    var workers = player.workerPool;
    var treasury = player.treasury;

    Unit? lookupUnit(String unitId) =>
        oldUnitsById[unitId] ?? newUnitsById[unitId];

    void updateUnit(String unitId, Unit updated) {
      if (oldUnitsById.containsKey(unitId)) {
        oldUnitsById[unitId] = updated;
      } else {
        newUnitsById[unitId] = updated;
      }
    }

    String regionForUnit(String unitId) =>
        oldUnitsById.containsKey(unitId) ? kRegionOldWorld : kRegionNewWorld;

    Province? provinceById(String id) =>
        tryGetProvince(state.game.worldState, id);

    bool canAffordMaterialCost(WorkOrderCost cost) {
      for (final e in cost.entries) {
        if (stockpile.quantityOf(e.key) < e.value) return false;
      }
      return true;
    }

    void deductMaterialCost(WorkOrderCost cost) {
      for (final e in cost.entries) {
        stockpile = stockpile.applyDelta(e.key, -e.value);
      }
    }

    for (final order in workOrders[player.id] ?? const []) {
      final u = lookupUnit(order.unitId);
      if (u == null) continue;
      final targetTileKey = order.targetTileKey;
      final hasValidTarget = targetTileKey.isNotEmpty;

      // Configuration for standard work order targets that use material cost.
      // Reduces duplication in WorkOrder application by centralizing validation,
      // cost computation, and unit update logic.
      // Special targets (purchase_land, prospect, explore, steal_tech, counter_spy)
      // are handled separately due to their unique logic.
      ({
        String target,
        bool Function(String) allowedForUnitType,
        WorkOrderCost? Function() costFn,
        int Function() totalTurnsFn,
      })
      workTargetConfig(String target) {
        switch (target) {
          case 'build_improvement':
            return (
              target: target,
              allowedForUnitType: (t) =>
                  isWorkOrderTargetAllowedForUnitType(t, target),
              costFn: () => workOrderMaterialCost(
                target,
                improvementLevel: tileState.improvementLevel(targetTileKey),
              ),
              totalTurnsFn: () => totalTurnsForWork(
                target,
                improvementLevel: tileState.improvementLevel(targetTileKey),
              ),
            );
          case 'build_road':
            return (
              target: target,
              allowedForUnitType: (t) =>
                  isWorkOrderTargetAllowedForUnitType(t, target),
              costFn: () => workOrderMaterialCost(target),
              totalTurnsFn: () => totalTurnsForWork(target),
            );
          case 'build_port':
            return (
              target: target,
              allowedForUnitType: (t) =>
                  isWorkOrderTargetAllowedForUnitType(t, target),
              costFn: () => workOrderMaterialCost(target),
              totalTurnsFn: () => totalTurnsForWork(target),
            );
          case 'build_fort':
            return (
              target: target,
              allowedForUnitType: (t) =>
                  isWorkOrderTargetAllowedForUnitType(t, target),
              costFn: () {
                final prov = provinceById(u.locationProvinceId);
                final fortLevel = prov?.fortLevel ?? 0;
                return workOrderMaterialCost(target, fortLevel: fortLevel);
              },
              totalTurnsFn: () {
                final prov = provinceById(u.locationProvinceId);
                final fortLevel = prov?.fortLevel ?? 0;
                return totalTurnsForWork(target, fortLevel: fortLevel);
              },
            );
          case 'build_rail':
            return (
              target: target,
              allowedForUnitType: (t) =>
                  isWorkOrderTargetAllowedForUnitType(t, target),
              costFn: () => workOrderMaterialCost(target),
              totalTurnsFn: () => totalTurnsForWork(target),
            );
          case 'upgrade_town':
            return (
              target: target,
              allowedForUnitType: (t) =>
                  isWorkOrderTargetAllowedForUnitType(t, target),
              costFn: () => workOrderMaterialCost(target),
              totalTurnsFn: () => totalTurnsForWork(target),
            );
          default:
            // Fall through to individual handling for non-standard targets
            return (
              target: target,
              allowedForUnitType: (_) => false,
              costFn: () => null,
              totalTurnsFn: () => 1,
            );
        }
      }

      // Applies a standard work order using the config dispatch.
      // Returns true if the order was applied, false otherwise.
      bool applyStandardWorkOrder(String orderTarget) {
        if (u.currentWork != null) return false;
        if (!hasValidTarget) return false;

        final config = workTargetConfig(orderTarget);
        if (!config.allowedForUnitType(u.type)) return false;

        final cost = config.costFn();
        if (cost == null) return false;
        if (!canAffordMaterialCost(cost)) return false;

        deductMaterialCost(cost);
        final totalTurns = config.totalTurnsFn();

        _log.d(
          'logic: work order accepted and assigned unit=${order.unitId} target=$orderTarget targetTileKey=$targetTileKey totalTurns=$totalTurns',
        );
        updateUnit(
          order.unitId,
          u.copyWith(
            status: UnitStatus.working,
            tileKey: targetTileKey,
            currentWork: CurrentWork(
              workTarget: orderTarget,
              tileKey: targetTileKey,
              totalTurns: totalTurns,
              remainingTurns: totalTurns,
            ),
          ),
        );
        return true;
      }

      if (order.target == 'purchase_land' &&
          isWorkOrderTargetAllowedForUnitType(u.type, 'purchase_land') &&
          hasValidTarget) {
        // SPEC/game/diplomacy.md (GP–Minor/Tribe Rules): purchase_land requires an Embassy
        // with the Minor/Tribe and the buyer must not be at war with that faction.
        final resourceId =
            state.game.worldState.resourceByTileKey[targetTileKey];
        if (resourceId != null) {
          final provinceId =
              Unit.provinceIdFromTileKey(targetTileKey) ?? u.locationProvinceId;
          final province = provinceById(provinceId);
          final ownerId = province?.ownerId;
          if (ownerId == null) {
            continue;
          }

          final hasEmbassy = state.game.overtureStates.any(
            (o) => o.gpId == player.id && o.targetId == ownerId && o.hasEmbassy,
          );
          if (!hasEmbassy) {
            continue;
          }

          final atWar = state.game.diplomacyRelations.any((rel) {
            final ids = {rel.factionId1, rel.factionId2};
            return ids.contains(player.id) &&
                ids.contains(ownerId) &&
                rel.atWar;
          });
          if (atWar) {
            continue;
          }

          final cost = purchaseLandCost(resourceId);
          if (treasury >= cost) {
            // First purchaser wins; tile can only be owned by one GP. SPEC/civilian-units.md.
            if (!purchasedTilesByTileKey.containsKey(targetTileKey)) {
              treasury -= cost;
              purchasedTilesByTileKey[targetTileKey] = player.id;
            }
          }
        }
        continue;
      }

      if (order.target == 'steal_tech' &&
          isWorkOrderTargetAllowedForUnitType(u.type, 'steal_tech') &&
          u.currentWork == null &&
          hasValidTarget) {
        const totalTurns = 5;
        _log.d(
          'logic: work order accepted and assigned unit=${order.unitId} target=steal_tech targetTileKey=$targetTileKey totalTurns=$totalTurns',
        );
        updateUnit(
          order.unitId,
          u.copyWith(
            status: UnitStatus.working,
            tileKey: targetTileKey,
            currentWork: CurrentWork(
              workTarget: 'steal_tech',
              tileKey: targetTileKey,
              totalTurns: totalTurns,
              remainingTurns: totalTurns,
            ),
          ),
        );
        continue;
      }

      if (order.target == 'counter_spy' &&
          isWorkOrderTargetAllowedForUnitType(u.type, 'counter_spy') &&
          u.currentWork == null &&
          hasValidTarget) {
        const totalTurns = 0;
        _log.d(
          'logic: work order accepted and assigned unit=${order.unitId} target=counter_spy targetTileKey=$targetTileKey totalTurns=$totalTurns',
        );
        updateUnit(
          order.unitId,
          u.copyWith(
            status: UnitStatus.working,
            tileKey: targetTileKey,
            currentWork: CurrentWork(
              workTarget: 'counter_spy',
              tileKey: targetTileKey,
              totalTurns: totalTurns,
              remainingTurns: 1,
            ),
          ),
        );
        continue;
      }

      if (order.target == 'prospect' &&
          hasValidTarget &&
          isExplorerUnit(u.type) &&
          isMineralEligibleTile(
            state.game,
            state.tileMapByRegion,
            targetTileKey,
          )) {
        final existing =
            state.game.worldState.playerProspectedTiles[player.id] ?? const {};
        final newProspected = Set<String>.from(existing)..add(targetTileKey);
        state.game = state.game.copyWith(
          worldState: state.game.worldState.copyWith(
            playerProspectedTiles: {
              ...state.game.worldState.playerProspectedTiles,
              player.id: newProspected,
            },
          ),
        );
      }
      if (order.target == 'build_improvement') {
        if (applyStandardWorkOrder('build_improvement')) continue;
      }
      if (order.target == 'explore' &&
          isExplorerUnit(u.type) &&
          u.currentWork == null &&
          hasValidTarget) {
        final regionId = regionForUnit(order.unitId);
        final provinceId =
            Unit.provinceIdFromTileKey(targetTileKey) ?? u.locationProvinceId;
        final byProvince =
            state.game.worldState.tileKeysByRegionAndProvince[regionId];
        final tilesInP = byProvince?[provinceId]?.length ?? 0;
        if (tilesInP > 0 && byProvince != null && byProvince.isNotEmpty) {
          var maxTiles = 0;
          for (final list in byProvince.values) {
            if (list.length > maxTiles) maxTiles = list.length;
          }
          if (maxTiles < 1) maxTiles = 1;
          final totalTurns = (3 * tilesInP / maxTiles).ceil().clamp(1, 999);
          _log.d(
            'logic: work order accepted and assigned unit=${order.unitId} target=explore targetTileKey=$targetTileKey totalTurns=$totalTurns',
          );
          updateUnit(
            order.unitId,
            u.copyWith(
              status: UnitStatus.working,
              tileKey: targetTileKey,
              currentWork: CurrentWork(
                workTarget: 'explore',
                tileKey: targetTileKey,
                totalTurns: totalTurns,
                remainingTurns: totalTurns,
              ),
            ),
          );
          continue;
        }
      }
      final workTarget = order.target;
      if (workTarget == 'build_road') {
        if (applyStandardWorkOrder('build_road')) continue;
      }
      if (workTarget == 'build_port') {
        if (applyStandardWorkOrder('build_port')) continue;
      }
      if (workTarget == 'build_fort') {
        final prov = provinceById(u.locationProvinceId);
        final fortLevel = prov?.fortLevel ?? 0;
        if (fortLevel == 1 &&
            player.techUnlocked?['mine_engineering'] != true) {
          _log.d(
            'logic: build_fort skipped - Mine Engineering required for fort level 2',
          );
          continue;
        }
        if (fortLevel == 2 && player.techUnlocked?['modern_forts'] != true) {
          _log.d(
            'logic: build_fort skipped - Modern Forts required for fort level 3',
          );
          continue;
        }
        if (applyStandardWorkOrder('build_fort')) continue;
      }
      if (workTarget == 'build_rail') {
        if (applyStandardWorkOrder('build_rail')) continue;
      }
      if (workTarget == 'upgrade_town') {
        if (applyStandardWorkOrder('upgrade_town')) continue;
      }
    }

    state.updatedPlayers.add(
      player.copyWith(
        stockpile: stockpile,
        workerPool: workers,
        treasury: treasury,
      ),
    );
  }
}

String _buildUnitId(String playerId, BuildUnitOrder order) {
  return '${playerId}_${order.unitType}_${order.spawnProvinceId}';
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
        'logic: build_road propagating level $nextLevel to adjacent ${isCapital ? "capital" : "port"} tile $adjacentTileKey',
      );
      final currentLevel = tileState.roadLevel(adjacentTileKey);
      // Only upgrade, never downgrade.
      if (nextLevel > currentLevel) {
        setTileState(tileState.setRoadLevel(adjacentTileKey, nextLevel));
      }
    }
  }
}
