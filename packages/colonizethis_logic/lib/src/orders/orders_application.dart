import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';

import '../constants.dart';
import '../dossier/event_dialogue.dart';
import '../economy/build_cost.dart';
import 'orders_application_helpers.dart';
import '../world/naval.dart';
import '../world/player_view.dart';
import '../world/province_lookup.dart';

final Logger _log = Logger();

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
  final cleared =
      unit.copyWith(clearCurrentWork: true, status: UnitStatus.idle);
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

  // Index units by id for oldWorld and newWorld.
  final oldUnitsById = {
    for (final u in game.worldState.oldWorld.units) u.id: u
  };
  final newUnitsById = {
    for (final u in game.worldState.newWorld.units) u.id: u
  };

  // Development progress: all units with currentWork (one pass). SPEC/development-resolution.md.
  var tileState = game.worldState.tileState;
  var visibilityByTile = game.worldState.playerVisibilityByTile;
  var portsByProvinceSeaboard =
      Map<String, String>.from(game.worldState.portsByProvinceSeaboard);
  var purchasedTilesByTileKey =
      Map<String, String>.from(game.worldState.purchasedTilesByTileKey);
  var oldProvinces = List<Province>.from(game.worldState.oldWorld.provinces);
  var newProvinces = List<Province>.from(game.worldState.newWorld.provinces);

  void applyExploreCompletion(Unit u, String regionId) {
    final cw = u.currentWork!;
    final parts = cw.tileKey.split('|');
    final regionIdFromWork = parts.isNotEmpty ? parts[0] : regionId;
    final provinceId = parts.length > 1
        ? parts[1]
        : ProvinceId.localIdFrom(u.locationProvinceId);
    final fullProvinceId = parts.length > 1
        ? ProvinceId.full(regionIdFromWork, provinceId)
        : u.locationProvinceId;
    final tileKeys = game.worldState
            .tileKeysByRegionAndProvince[regionIdFromWork]?[fullProvinceId] ??
        [];
    final playerId = u.ownerId;
    final vis = Map<String, String>.from(visibilityByTile[playerId] ?? {});
    for (final tk in tileKeys) {
      vis[tk] = VisibilityLevel.fullyVisible.name;
    }
    visibilityByTile = Map<String, Map<String, String>>.from(visibilityByTile)
      ..[playerId] = vis;
  }

  void applyCompletedWorkTarget(
      Unit u,
      CurrentWork cw,
      List<Province> Function() getProvinces,
      void Function(List<Province>) setProvinces,
      Game gameForPlayer) {
    _log.d(
        'logic: work completed unit=${u.id} workTarget=${cw.workTarget} tileKey=${cw.tileKey}');
    switch (cw.workTarget) {
      case 'build_improvement':
        final level = tileState.improvementLevel(cw.tileKey);
        tileState =
            tileState.setImprovement(cw.tileKey, (level + 1).clamp(0, 4));
        break;
      case 'upgrade_town':
        final provinces = getProvinces();
        final idx = provinces.indexWhere((p) => p.id == u.locationProvinceId);
        if (idx >= 0) {
          final p = provinces[idx];
          setProvinces(List<Province>.from(provinces)
            ..[idx] = p.copyWith(
                townDevelopmentLevel:
                    (p.townDevelopmentLevel + 1).clamp(0, 4)));
        }
        break;
      case 'explore':
        applyExploreCompletion(
            u, ProvinceId.regionIdFrom(u.locationProvinceId));
        break;
      case 'build_road':
        {
          final roadLevel = tileState.roadLevel(cw.tileKey);
          final player =
              gameForPlayer.players.where((p) => p.id == u.ownerId).firstOrNull;
          final hasRoadConstruction =
              player?.techUnlocked?['road_construction'] == true;
          final nextLevel =
              (roadLevel + 1).clamp(0, hasRoadConstruction ? 2 : 1);
          tileState = tileState.setRoadLevel(cw.tileKey, nextLevel);

          // Propagate transport level to adjacent capital/port tiles per
          // SPEC/program/development-resolution.md and SPEC/game/capital-and-connectivity.md.
          final tileMap = tileMapByRegion;
          if (tileMap != null) {
            _propagateRoadToAdjacentCapitalOrPort(
              tileKey: cw.tileKey,
              nextLevel: nextLevel,
              player: player,
              worldState: gameForPlayer.worldState,
              tileMapByRegion: tileMap,
              tileState: tileState,
              setTileState: (newTileState) => tileState = newTileState,
            );
          }
          break;
        }
      case 'build_port':
        if (topology != null) {
          final parts = cw.tileKey.split('|');
          final regionIdFromTile = parts.isNotEmpty
              ? parts[0]
              : ProvinceId.regionIdFrom(u.locationProvinceId);
          final localId = parts.length > 1
              ? parts[1]
              : ProvinceId.localIdFrom(u.locationProvinceId);
          final fullProvinceId = ProvinceId.full(regionIdFromTile, localId);
          final seaZoneId = seaZoneIdForProvince(topology, localId,
              regionId: regionIdFromTile);
          if (seaZoneId != null) {
            portsByProvinceSeaboard['$fullProvinceId|$seaZoneId'] = cw.tileKey;
            tileState = tileState.setRoadLevel(cw.tileKey, 4);
          }
        }
        break;
      case 'build_fort':
        {
          final provinces = getProvinces();
          final idx = provinces.indexWhere((p) => p.id == u.locationProvinceId);
          if (idx >= 0) {
            final p = provinces[idx];
            setProvinces(List<Province>.from(provinces)
              ..[idx] = p.copyWith(fortLevel: (p.fortLevel + 1).clamp(0, 3)));
          }
          if (topology != null && onDialogue != null) {
            final seed = ((gameForPlayer.globalGameSeed ?? 0) ^
                    (gameForPlayer.worldState.turnState.turnNumber *
                        0x9E3779B1))
                .toInt();
            final events = dialogueEventsForReactiveFortsOnBorder(
              gameForPlayer,
              topology,
              u.ownerId,
              u.locationProvinceId,
              seed,
            );
            for (final e in events) onDialogue(e);
          }
          break;
        }
      case 'build_rail':
        tileState = tileState.setRoadLevel(cw.tileKey, 4);
        break;
      case 'steal_tech':
        // Resolved in processWorkUnits with roll and tech grant
        break;
      case 'counter_spy':
        // Ongoing; per-turn kill resolved in processWorkUnits
        break;
      default:
        break;
    }
  }

  Game processWorkUnits(
    Game gameForPlayer,
    Map<String, Unit> unitsById,
    List<Province> Function() getProvinces,
    void Function(List<Province>) setProvinces,
  ) {
    var currentGame = gameForPlayer;
    final rand = gameForPlayer.globalGameSeed != null
        ? Random(gameForPlayer.globalGameSeed! +
            (gameForPlayer.worldState.turnState.turnNumber * 1000))
        : Random();
    // Iterate over a snapshot to allow updating unitsById during the loop.
    for (final entry in unitsById.entries.toList()) {
      final u = entry.value;
      if (u.currentWork == null) continue;
      final cw = u.currentWork!;
      // Cancel work if tile no longer owned by this player (SPEC: unit dead / tile no longer owned).
      final purchasedByTile = gameForPlayer.worldState.purchasedTilesByTileKey;
      if (purchasedByTile.containsKey(cw.tileKey) &&
          purchasedByTile[cw.tileKey] != u.ownerId) {
        unitsById[entry.key] =
            u.copyWith(status: UnitStatus.idle, clearCurrentWork: true);
        _log.d(
            'logic: work cancelled unit=${u.id} reason=tile no longer owned tileKey=${cw.tileKey}');
        continue;
      }
      // Cancel work if province containing target tile is no longer owned (conquest). SPEC #376.
      // Skip for counter_spy and steal_tech: those work targets are in enemy/other territory by design.
      if (cw.workTarget != 'counter_spy' && cw.workTarget != 'steal_tech') {
        final targetProvinceId = Unit.provinceIdFromTileKey(cw.tileKey);
        if (targetProvinceId != null) {
          final provinces = getProvinces();
          final targetProvince =
              provinces.where((p) => p.id == targetProvinceId).firstOrNull;
          if (targetProvince != null && targetProvince.ownerId != u.ownerId) {
            unitsById[entry.key] =
                u.copyWith(status: UnitStatus.idle, clearCurrentWork: true);
            _log.d(
                'logic: work cancelled unit=${u.id} reason=province conquered provinceId=$targetProvinceId tileKey=${cw.tileKey}');
            continue;
          }
        }
      }
      if (cw.workTarget == 'counter_spy') {
        // Per-turn: 5% per friendly spy (cap 30%) to kill one enemy spy in province
        final provinceId = u.locationProvinceId;
        final friendlySpies = unitsById.values
            .where((x) =>
                x.ownerId == u.ownerId &&
                isSpyUnit(x.type) &&
                x.currentWork?.workTarget == 'counter_spy' &&
                x.locationProvinceId == provinceId)
            .length;
        final killChance = (friendlySpies * 5).clamp(0, 30) / 100.0;
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
          final otherPlayer = currentGame.players
              .where((p) =>
                  p.id != u.ownerId && p.capitalProvinceId == targetProvinceId)
              .firstOrNull;
          if (otherPlayer != null) {
            final ourTech =
                currentGame.playerById(u.ownerId)?.techUnlocked ?? {};
            final theirTech = otherPlayer.techUnlocked ?? {};
            final missing = theirTech.entries
                .where((e) => e.value == true && ourTech[e.key] != true)
                .map((e) => e.key)
                .toList();
            if (missing.isNotEmpty && rand.nextDouble() < 0.08) {
              final granted = missing[rand.nextInt(missing.length)];
              final player = currentGame.players
                  .where((p) => p.id == u.ownerId)
                  .firstOrNull;
              if (player != null) {
                final updated =
                    Map<String, bool>.from(player.techUnlocked ?? {})
                      ..[granted] = true;
                currentGame = currentGame.copyWith(
                  players: currentGame.players
                      .map((p) => p.id == u.ownerId
                          ? p.copyWith(techUnlocked: updated)
                          : p)
                      .toList(),
                );
              }
            }
          }
        } else {
          applyCompletedWorkTarget(
              u, cw, getProvinces, setProvinces, currentGame);
        }
        unitsById[entry.key] =
            u.copyWith(status: UnitStatus.idle, clearCurrentWork: true);
      } else {
        unitsById[entry.key] = u.copyWith(
          currentWork: cw.copyWith(remainingTurns: nextRemaining),
        );
      }
    }
    return currentGame;
  }

  final updatedPlayers = <Player>[];

  for (final player in game.players) {
    var stockpile = player.stockpile;
    var workers = player.workerPool;
    var treasury = player.treasury;

    // Build units for this player. Shared cost rules: build_cost.canAffordBuild / applyBuildCostDeduction.
    for (final order in buildOrders[player.id] ?? const []) {
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
        final seaZoneId = topology != null
            ? seaZoneIdForProvince(
                topology, ProvinceId.localIdFrom(capProvinceId),
                regionId: regionId)
            : null;
        if (seaZoneId == null) continue;

        var fleets = List<Fleet>.from(game.worldState.fleets);
        final homeFleetId = 'fleet_${player.id}';
        final existing = fleets
            .indexWhere((f) => f.id == homeFleetId && f.ownerId == player.id);
        if (existing >= 0) {
          final f = fleets[existing];
          fleets = List<Fleet>.from(fleets)
            ..[existing] =
                f.copyWith(shipTypeIds: [...f.shipTypeIds, order.unitType]);
        } else {
          fleets = [
            ...fleets,
            Fleet(
              id: homeFleetId,
              ownerId: player.id,
              seaZoneId: seaZoneId,
              regionId: regionId,
              shipTypeIds: [order.unitType],
            )
          ];
        }
        game = game.copyWith(
          worldState: game.worldState.copyWith(fleets: fleets),
        );
        continue;
      }

      // Spawn unit for military and civilian (naval already continued above).
      final spawnProvinceId = order.spawnProvinceId;
      final regionId = ProvinceId.regionIdFrom(spawnProvinceId);
      final tileKeysByRegion = game.worldState.tileKeysByRegionAndProvince;
      final firstTileInSpawn =
          tileKeysByRegion[regionId]?[spawnProvinceId]?.isNotEmpty == true
              ? tileKeysByRegion[regionId]![spawnProvinceId]!.first
              : null;

      final newUnit = Unit(
        id: _buildUnitId(player.id, order),
        type: order.unitType,
        ownerId: player.id,
        provinceId: spawnProvinceId,
        tileKey:
            category == BuildUnitCategory.civilian ? firstTileInSpawn : null,
      );

      if (regionId == kRegionNewWorld) {
        newUnitsById[newUnit.id] = newUnit;
      } else {
        oldUnitsById[newUnit.id] = newUnit;
      }
    }

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
        tryGetProvince(game.worldState, id);

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
        int Function() totalTurnsFn
      }) workTargetConfig(String target) {
        switch (target) {
          case 'build_improvement':
            return (
              target: target,
              allowedForUnitType: (t) =>
                  isWorkOrderTargetAllowedForUnitType(t, target),
              costFn: () => workOrderMaterialCost(target,
                  improvementLevel: tileState.improvementLevel(targetTileKey)),
              totalTurnsFn: () => totalTurnsForWork(target,
                  improvementLevel: tileState.improvementLevel(targetTileKey)),
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
            'logic: work order accepted and assigned unit=${order.unitId} target=$orderTarget targetTileKey=$targetTileKey totalTurns=$totalTurns');
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
            ));
        return true;
      }

      if (order.target == 'purchase_land' &&
          isWorkOrderTargetAllowedForUnitType(u.type, 'purchase_land') &&
          hasValidTarget) {
        // SPEC/game/diplomacy.md (GP–Minor/Tribe Rules): purchase_land requires an Embassy
        // with the Minor/Tribe and the buyer must not be at war with that faction.
        final resourceId = game.worldState.resourceByTileKey[targetTileKey];
        if (resourceId != null) {
          final provinceId =
              Unit.provinceIdFromTileKey(targetTileKey) ?? u.locationProvinceId;
          final province = provinceById(provinceId);
          final ownerId = province?.ownerId;
          if (ownerId == null) {
            continue;
          }

          final hasEmbassy = game.overtureStates.any(
            (o) => o.gpId == player.id && o.targetId == ownerId && o.hasEmbassy,
          );
          if (!hasEmbassy) {
            continue;
          }

          final atWar = game.diplomacyRelations.any((rel) {
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
            treasury -= cost;
            purchasedTilesByTileKey[targetTileKey] = player.id;
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
            'logic: work order accepted and assigned unit=${order.unitId} target=steal_tech targetTileKey=$targetTileKey totalTurns=$totalTurns');
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
            ));
        continue;
      }

      if (order.target == 'counter_spy' &&
          isWorkOrderTargetAllowedForUnitType(u.type, 'counter_spy') &&
          u.currentWork == null &&
          hasValidTarget) {
        const totalTurns = 0;
        _log.d(
            'logic: work order accepted and assigned unit=${order.unitId} target=counter_spy targetTileKey=$targetTileKey totalTurns=$totalTurns');
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
            ));
        continue;
      }

      if (order.target == 'prospect' &&
          hasValidTarget &&
          isExplorerUnit(u.type) &&
          isMineralEligibleTile(game, tileMapByRegion, targetTileKey)) {
        final existing =
            game.worldState.playerProspectedTiles[player.id] ?? const {};
        final newProspected = Set<String>.from(existing)..add(targetTileKey);
        game = game.copyWith(
          worldState: game.worldState.copyWith(
            playerProspectedTiles: {
              ...game.worldState.playerProspectedTiles,
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
            game.worldState.tileKeysByRegionAndProvince[regionId];
        final tilesInP = byProvince?[provinceId]?.length ?? 0;
        if (tilesInP > 0 && byProvince != null && byProvince.isNotEmpty) {
          var maxTiles = 0;
          for (final list in byProvince.values) {
            if (list.length > maxTiles) maxTiles = list.length;
          }
          if (maxTiles < 1) maxTiles = 1;
          final totalTurns = (3 * tilesInP / maxTiles).ceil().clamp(1, 999);
          _log.d(
              'logic: work order accepted and assigned unit=${order.unitId} target=explore targetTileKey=$targetTileKey totalTurns=$totalTurns');
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
              ));
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
              'logic: build_fort skipped - Mine Engineering required for fort level 2');
          continue;
        }
        if (fortLevel == 2 &&
            player.techUnlocked?['modern_forts'] != true) {
          _log.d(
              'logic: build_fort skipped - Modern Forts required for fort level 3');
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

    updatedPlayers.add(
      player.copyWith(
        stockpile: stockpile,
        workerPool: workers,
        treasury: treasury,
      ),
    );
  }

  // Process work (decrement remainingTurns, apply effects when 0) after applying
  // new work orders from Orders so same-turn assignments can complete. SPEC/program/development-resolution.md.
  game = processWorkUnits(
      game, oldUnitsById, () => oldProvinces, (p) => oldProvinces = p);
  game = processWorkUnits(
      game, newUnitsById, () => newProvinces, (p) => newProvinces = p);
  game = game.copyWith(
    worldState: game.worldState.copyWith(
      tileState: tileState,
      playerVisibilityByTile: visibilityByTile,
      portsByProvinceSeaboard: portsByProvinceSeaboard,
      purchasedTilesByTileKey: purchasedTilesByTileKey,
      oldWorld: RegionData(
          provinces: oldProvinces, units: oldUnitsById.values.toList()),
      newWorld: RegionData(
          provinces: newProvinces, units: newUnitsById.values.toList()),
    ),
  );

  final updatedOldWorld = RegionData(
    provinces: game.worldState.oldWorld.provinces,
    units: oldUnitsById.values.toList(),
  );
  final updatedNewWorld = RegionData(
    provinces: game.worldState.newWorld.provinces,
    units: newUnitsById.values.toList(),
  );

  return game.copyWith(
    players: updatedPlayers,
    worldState: game.worldState.copyWith(
      purchasedTilesByTileKey: purchasedTilesByTileKey,
      oldWorld: updatedOldWorld,
      newWorld: updatedNewWorld,
    ),
  );
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
    final adjacentTileKey =
        CapitalTile.tileKey(targetRegionId, '$targetRegionId|$cellId', nx, ny);

    // Check if adjacent tile is the player's capital or a port
    final isCapital = adjacentTileKey == capitalTileKey;
    final isPort = portTileKeys.contains(adjacentTileKey);

    if (isCapital || isPort) {
      _log.d(
          'logic: build_road propagating level $nextLevel to adjacent ${isCapital ? "capital" : "port"} tile $adjacentTileKey');
      final currentLevel = tileState.roadLevel(adjacentTileKey);
      // Only upgrade, never downgrade.
      if (nextLevel > currentLevel) {
        setTileState(tileState.setRoadLevel(adjacentTileKey, nextLevel));
      }
    }
  }
}
