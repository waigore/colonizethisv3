import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../dossier/event_dialogue.dart';
import '../world/naval.dart';
import '../world/player_view.dart';

/// Order application helpers for build and work phases.
/// SPEC/program/orders.md

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
  void Function(DialogueEvent)? onDialogue,
}) {
  final buildOrders = orders.buildUnitOrdersByPlayerId;
  final workOrders = orders.workOrdersByPlayerId;
  if (buildOrders.isEmpty && workOrders.isEmpty) {
    return game;
  }

  // Index units by id for oldWorld and newWorld.
  final oldUnitsById = {for (final u in game.worldState.oldWorld.units) u.id: u};
  final newUnitsById = {for (final u in game.worldState.newWorld.units) u.id: u};

  // Development progress: all units with currentWork (one pass). SPEC/development-resolution.md.
  var tileState = game.worldState.tileState;
  var visibilityByTile = game.worldState.playerVisibilityByTile;
  var portsByProvinceSeaboard = Map<String, String>.from(game.worldState.portsByProvinceSeaboard);
  var purchasedTilesByTileKey = Map<String, String>.from(game.worldState.purchasedTilesByTileKey);
  var oldProvinces = List<Province>.from(game.worldState.oldWorld.provinces);
  var newProvinces = List<Province>.from(game.worldState.newWorld.provinces);

  void applyExploreCompletion(Unit u, String regionId) {
    final cw = u.currentWork!;
    final parts = cw.tileKey.split('|');
    final regionIdFromWork = parts.isNotEmpty ? parts[0] : regionId;
    final provinceId = parts.length > 1 ? parts[1] : ProvinceId.localIdFrom(u.locationProvinceId);
    final fullProvinceId = parts.length > 1
        ? ProvinceId.full(regionIdFromWork, provinceId)
        : u.locationProvinceId;
    final tileKeys = game.worldState.tileKeysByRegionAndProvince[regionIdFromWork]?[fullProvinceId] ?? [];
    final playerId = u.ownerId;
    final vis = Map<String, String>.from(visibilityByTile[playerId] ?? {});
    for (final tk in tileKeys) {
      vis[tk] = VisibilityLevel.fullyVisible.name;
    }
    visibilityByTile = Map<String, Map<String, String>>.from(visibilityByTile)
      ..[playerId] = vis;
  }

  void applyCompletedWorkTarget(Unit u, CurrentWork cw, List<Province> Function() getProvinces, void Function(List<Province>) setProvinces, Game gameForPlayer) {
    switch (cw.workTarget) {
      case 'build_improvement':
        final level = tileState.improvementLevel(cw.tileKey);
        tileState = tileState.setImprovement(cw.tileKey, (level + 1).clamp(0, 4));
        break;
      case 'upgrade_town':
        final provinces = getProvinces();
        final idx = provinces.indexWhere((p) => p.id == u.locationProvinceId);
        if (idx >= 0) {
          final p = provinces[idx];
          setProvinces(List<Province>.from(provinces)
            ..[idx] = p.copyWith(townDevelopmentLevel: (p.townDevelopmentLevel + 1).clamp(0, 4)));
        }
        break;
      case 'explore':
        applyExploreCompletion(u, ProvinceId.regionIdFrom(u.locationProvinceId));
        break;
      case 'build_road': {
        final roadLevel = tileState.roadLevel(cw.tileKey);
        final player = gameForPlayer.players.where((p) => p.id == u.ownerId).firstOrNull;
        final hasRoadConstruction = player?.techUnlocked?['road_construction'] == true;
        final nextLevel = (roadLevel + 1).clamp(0, hasRoadConstruction ? 2 : 1);
        tileState = tileState.setRoadLevel(cw.tileKey, nextLevel);
        break;
      }
      case 'build_port':
        if (topology != null) {
          final parts = cw.tileKey.split('|');
          final regionIdFromTile = parts.isNotEmpty ? parts[0] : ProvinceId.regionIdFrom(u.locationProvinceId);
          final localId = parts.length > 1 ? parts[1] : ProvinceId.localIdFrom(u.locationProvinceId);
          final fullProvinceId = ProvinceId.full(regionIdFromTile, localId);
          final seaZoneId = seaZoneIdForProvince(topology, localId);
          if (seaZoneId != null) {
            portsByProvinceSeaboard['$fullProvinceId|$seaZoneId'] = cw.tileKey;
            tileState = tileState.setRoadLevel(cw.tileKey, 4);
          }
        }
        break;
      case 'build_fort': {
        final provinces = getProvinces();
        final idx = provinces.indexWhere((p) => p.id == u.locationProvinceId);
        if (idx >= 0) {
          final p = provinces[idx];
          setProvinces(List<Province>.from(provinces)
            ..[idx] = p.copyWith(fortLevel: (p.fortLevel + 1).clamp(0, 3)));
        }
        if (topology != null && onDialogue != null) {
          final seed = ((gameForPlayer.globalGameSeed ?? 0) ^
                  (gameForPlayer.worldState.turnState.turnNumber * 0x9E3779B1))
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
        ? Random(gameForPlayer.globalGameSeed! + (gameForPlayer.worldState.turnState.turnNumber * 1000))
        : Random();
    for (final entry in unitsById.entries) {
      final u = entry.value;
      if (u.currentWork == null) continue;
      final cw = u.currentWork!;
      if (cw.workTarget == 'counter_spy') {
        // Per-turn: 5% per friendly spy (cap 30%) to kill one enemy spy in province
        final provinceId = u.locationProvinceId;
        final friendlySpies = unitsById.values.where((x) =>
            x.ownerId == u.ownerId && isSpyUnit(x.type) &&
            x.currentWork?.workTarget == 'counter_spy' &&
            x.locationProvinceId == provinceId).length;
        final killChance = (friendlySpies * 5).clamp(0, 30) / 100.0;
        final enemySpies = unitsById.entries.where((e) {
          final x = e.value;
          return x.ownerId != u.ownerId && isSpyUnit(x.type) && x.locationProvinceId == provinceId;
        }).toList();
        if (enemySpies.isNotEmpty && rand.nextDouble() < killChance) {
          final toRemove = enemySpies.first.key;
          unitsById.remove(toRemove);
        }
        continue;
      }
      final nextRemaining = cw.remainingTurns - 1;
      if (nextRemaining <= 0) {
        if (cw.workTarget == 'steal_tech') {
          final targetProvinceId = Unit.provinceIdFromTileKey(cw.tileKey);
          final otherPlayer = currentGame.players.where((p) =>
              p.id != u.ownerId && p.capitalProvinceId == targetProvinceId).firstOrNull;
          if (otherPlayer != null) {
            final ourTech = currentGame.playerById(u.ownerId)?.techUnlocked ?? {};
            final theirTech = otherPlayer.techUnlocked ?? {};
            final missing = theirTech.entries.where((e) => e.value == true && ourTech[e.key] != true).map((e) => e.key).toList();
            if (missing.isNotEmpty && rand.nextDouble() < 0.08) {
              final granted = missing[rand.nextInt(missing.length)];
              final player = currentGame.players.where((p) => p.id == u.ownerId).firstOrNull;
              if (player != null) {
                final updated = Map<String, bool>.from(player.techUnlocked ?? {})..[granted] = true;
                currentGame = currentGame.copyWith(
                  players: currentGame.players.map((p) =>
                      p.id == u.ownerId ? p.copyWith(techUnlocked: updated) : p).toList(),
                );
              }
            }
          }
        } else {
          applyCompletedWorkTarget(u, cw, getProvinces, setProvinces, currentGame);
        }
        unitsById[entry.key] = u.copyWith(status: UnitStatus.idle, currentWork: null);
      } else {
        unitsById[entry.key] = u.copyWith(
          currentWork: cw.copyWith(remainingTurns: nextRemaining),
        );
      }
    }
    return currentGame;
  }

  game = processWorkUnits(game, oldUnitsById, () => oldProvinces, (p) => oldProvinces = p);
  game = processWorkUnits(game, newUnitsById, () => newProvinces, (p) => newProvinces = p);
  game = game.copyWith(
    worldState: game.worldState.copyWith(
      tileState: tileState,
      playerVisibilityByTile: visibilityByTile,
      portsByProvinceSeaboard: portsByProvinceSeaboard,
      purchasedTilesByTileKey: purchasedTilesByTileKey,
      oldWorld: RegionData(provinces: oldProvinces, units: oldUnitsById.values.toList()),
      newWorld: RegionData(provinces: newProvinces, units: newUnitsById.values.toList()),
    ),
  );

  final updatedPlayers = <Player>[];

  for (final player in game.players) {
    var stockpile = player.stockpile;
    var workers = player.workerPool;
    var treasury = player.treasury;

    // Build units for this player. Branch on unit type category (civilian / military / naval).
    for (final order in buildOrders[player.id] ?? const []) {
      final category = buildUnitCategoryForUnitType(order.unitType);
      if (category == BuildUnitCategory.unknown) continue;

      if (category == BuildUnitCategory.military) {
        final econ = RegimentEconomyCatalog.byId[order.unitType];
        if (econ == null) continue;

        final techUnlocked = player.techUnlocked ?? const {};
        final unlockingTechId = unlockingTechByRegimentId[order.unitType];
        if (unlockingTechId != null && techUnlocked[unlockingTechId] != true) {
          continue;
        }

        if (workers.peasants <= 0) continue;
        if (treasury < econ.buildTreasuryCost) continue;

        var hasAllInputs = true;
        for (final entry in econ.buildInputs.entries) {
          if (stockpile.quantityOf(entry.key) < entry.value) {
            hasAllInputs = false;
            break;
          }
        }
        if (!hasAllInputs) continue;

        treasury -= econ.buildTreasuryCost;
        for (final entry in econ.buildInputs.entries) {
          stockpile = stockpile.applyDelta(entry.key, -entry.value);
        }
        workers = workers.copyWith(peasants: workers.peasants - 1);
      } else if (category == BuildUnitCategory.naval) {
        final shipEcon = ShipEconomyCatalog.byId[order.unitType];
        if (shipEcon == null) continue;
        final capProvinceId = player.capitalProvinceId;
        if (capProvinceId == null) continue;
        if (treasury < shipEcon.buildTreasuryCost) continue;
        var hasAllInputs = true;
        for (final entry in shipEcon.buildInputs.entries) {
          if (stockpile.quantityOf(entry.key) < entry.value) {
            hasAllInputs = false;
            break;
          }
        }
        if (!hasAllInputs) continue;

        treasury -= shipEcon.buildTreasuryCost;
        for (final entry in shipEcon.buildInputs.entries) {
          stockpile = stockpile.applyDelta(entry.key, -entry.value);
        }

        final regionId = ProvinceId.regionIdFrom(capProvinceId);
        final seaZoneId = topology != null
            ? seaZoneIdForProvince(topology, ProvinceId.localIdFrom(capProvinceId))
            : null;
        if (seaZoneId == null) continue;

        var fleets = List<Fleet>.from(game.worldState.fleets);
        final homeFleetId = 'fleet_${player.id}';
        final existing = fleets.indexWhere((f) => f.id == homeFleetId && f.ownerId == player.id);
        if (existing >= 0) {
          final f = fleets[existing];
          fleets = List<Fleet>.from(fleets)
            ..[existing] = f.copyWith(shipTypeIds: [...f.shipTypeIds, order.unitType]);
        } else {
          fleets = [...fleets, Fleet(
            id: homeFleetId,
            ownerId: player.id,
            seaZoneId: seaZoneId,
            regionId: regionId,
            shipTypeIds: [order.unitType],
          )];
        }
        game = game.copyWith(
          worldState: game.worldState.copyWith(fleets: fleets),
        );
        continue;
      } else if (category == BuildUnitCategory.civilian) {
        final econ = CivilianEconomyCatalog.byId[order.unitType];
        if (econ == null) continue;

        final unlockingTechId = unlockingTechByCivilianId[order.unitType];
        if (unlockingTechId != null && (player.techUnlocked?[unlockingTechId] != true)) {
          continue;
        }
        if (treasury < econ.buildTreasuryCost) continue;
        var hasAllInputs = true;
        for (final entry in econ.buildInputs.entries) {
          if (stockpile.quantityOf(entry.key) < entry.value) {
            hasAllInputs = false;
            break;
          }
        }
        if (!hasAllInputs) continue;

        treasury -= econ.buildTreasuryCost;
        for (final entry in econ.buildInputs.entries) {
          stockpile = stockpile.applyDelta(entry.key, -entry.value);
        }
      }

      // Spawn unit for military and civilian (naval already continued above).
      final spawnProvinceId = order.spawnProvinceId;
      final regionId = ProvinceId.regionIdFrom(spawnProvinceId);
      final tileKeysByRegion = game.worldState.tileKeysByRegionAndProvince;
      final firstTileInSpawn = tileKeysByRegion[regionId]?[spawnProvinceId]?.isNotEmpty == true
          ? tileKeysByRegion[regionId]![spawnProvinceId]!.first
          : null;

      final newUnit = Unit(
        id: _buildUnitId(player.id, order),
        type: order.unitType,
        ownerId: player.id,
        provinceId: spawnProvinceId,
        tileKey: category == BuildUnitCategory.civilian ? firstTileInSpawn : null,
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
        game.worldState.oldWorld.provinces.where((p) => p.id == id).firstOrNull ??
        game.worldState.newWorld.provinces.where((p) => p.id == id).firstOrNull;

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

      if (order.target == 'purchase_land' && isWorkOrderTargetAllowedForUnitType(u.type, 'purchase_land') && hasValidTarget) {
        final resourceId = game.worldState.resourceByTileKey[targetTileKey];
        if (resourceId != null) {
          final cost = 15 * landPurchaseBasePrice(resourceId);
          if (treasury >= cost) {
            treasury -= cost;
            purchasedTilesByTileKey[targetTileKey] = player.id;
          }
        }
        continue;
      }

      if (order.target == 'steal_tech' && isWorkOrderTargetAllowedForUnitType(u.type, 'steal_tech') && u.currentWork == null && hasValidTarget) {
        updateUnit(order.unitId, u.copyWith(
          status: UnitStatus.working,
          tileKey: targetTileKey,
          currentWork: CurrentWork(
            workTarget: 'steal_tech',
            tileKey: targetTileKey,
            totalTurns: 5,
            remainingTurns: 5,
          ),
        ));
        continue;
      }

      if (order.target == 'counter_spy' && isWorkOrderTargetAllowedForUnitType(u.type, 'counter_spy') && u.currentWork == null && hasValidTarget) {
        updateUnit(order.unitId, u.copyWith(
          status: UnitStatus.working,
          tileKey: targetTileKey,
          currentWork: CurrentWork(
            workTarget: 'counter_spy',
            tileKey: targetTileKey,
            totalTurns: 0,
            remainingTurns: 1,
          ),
        ));
        continue;
      }

      if (order.target == 'prospect' && hasValidTarget) {
        final existing = game.worldState.playerProspectedTiles[player.id] ?? const {};
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
      if (order.target == 'build_improvement' &&
          isWorkOrderTargetAllowedForUnitType(u.type, 'build_improvement') &&
          u.currentWork == null &&
          hasValidTarget) {
        final improvementLevel = tileState.improvementLevel(targetTileKey);
        final cost = workOrderMaterialCost('build_improvement', improvementLevel: improvementLevel);
        if (cost != null && canAffordMaterialCost(cost)) {
          deductMaterialCost(cost);
          final totalTurns = totalTurnsForWork('build_improvement', improvementLevel: improvementLevel);
          updateUnit(order.unitId, u.copyWith(
            status: UnitStatus.working,
            tileKey: targetTileKey,
            currentWork: CurrentWork(
              workTarget: 'build_improvement',
              tileKey: targetTileKey,
              totalTurns: totalTurns,
              remainingTurns: totalTurns,
            ),
          ));
        }
        continue;
      }
      if (order.target == 'explore' &&
          isExplorerUnit(u.type) &&
          u.currentWork == null &&
          hasValidTarget) {
        final regionId = regionForUnit(order.unitId);
        final provinceId = Unit.provinceIdFromTileKey(targetTileKey) ?? u.locationProvinceId;
        final byProvince = game.worldState.tileKeysByRegionAndProvince[regionId];
        final tilesInP = byProvince?[provinceId]?.length ?? 0;
        if (tilesInP > 0 && byProvince != null && byProvince.isNotEmpty) {
          var maxTiles = 0;
          for (final list in byProvince.values) {
            if (list.length > maxTiles) maxTiles = list.length;
          }
          if (maxTiles < 1) maxTiles = 1;
          final totalTurns = (3 * tilesInP / maxTiles).ceil().clamp(1, 999);
          updateUnit(order.unitId, u.copyWith(
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
      if (workTarget == 'build_road' && isWorkOrderTargetAllowedForUnitType(u.type, 'build_road') && u.currentWork == null && hasValidTarget) {
        final cost = workOrderMaterialCost('build_road');
        if (cost != null && canAffordMaterialCost(cost)) {
          deductMaterialCost(cost);
          final totalTurns = totalTurnsForWork('build_road');
          updateUnit(order.unitId, u.copyWith(
            status: UnitStatus.working,
            tileKey: targetTileKey,
            currentWork: CurrentWork(
              workTarget: workTarget,
              tileKey: targetTileKey,
              totalTurns: totalTurns,
              remainingTurns: totalTurns,
            ),
          ));
        }
        continue;
      }
      if (workTarget == 'build_port' && isWorkOrderTargetAllowedForUnitType(u.type, 'build_port') && u.currentWork == null && hasValidTarget) {
        final cost = workOrderMaterialCost('build_port');
        if (cost != null && canAffordMaterialCost(cost)) {
          deductMaterialCost(cost);
          final totalTurns = totalTurnsForWork('build_port');
          updateUnit(order.unitId, u.copyWith(
            status: UnitStatus.working,
            tileKey: targetTileKey,
            currentWork: CurrentWork(
              workTarget: workTarget,
              tileKey: targetTileKey,
              totalTurns: totalTurns,
              remainingTurns: totalTurns,
            ),
          ));
        }
        continue;
      }
      if (workTarget == 'build_fort' && isWorkOrderTargetAllowedForUnitType(u.type, 'build_fort') && u.currentWork == null && hasValidTarget) {
        final prov = provinceById(u.locationProvinceId);
        final fortLevel = prov?.fortLevel ?? 0;
        final cost = workOrderMaterialCost('build_fort', fortLevel: fortLevel);
        if (cost != null && canAffordMaterialCost(cost)) {
          deductMaterialCost(cost);
          final totalTurns = totalTurnsForWork('build_fort', fortLevel: fortLevel);
          updateUnit(order.unitId, u.copyWith(
            status: UnitStatus.working,
            tileKey: targetTileKey,
            currentWork: CurrentWork(
              workTarget: workTarget,
              tileKey: targetTileKey,
              totalTurns: totalTurns,
              remainingTurns: totalTurns,
            ),
          ));
        }
        continue;
      }
      if (workTarget == 'build_rail' && isWorkOrderTargetAllowedForUnitType(u.type, 'build_rail') && u.currentWork == null && hasValidTarget) {
        final cost = workOrderMaterialCost('build_rail');
        if (cost != null && canAffordMaterialCost(cost)) {
          deductMaterialCost(cost);
          final totalTurns = totalTurnsForWork('build_rail');
          updateUnit(order.unitId, u.copyWith(
            status: UnitStatus.working,
            tileKey: targetTileKey,
            currentWork: CurrentWork(
              workTarget: workTarget,
              tileKey: targetTileKey,
              totalTurns: totalTurns,
              remainingTurns: totalTurns,
            ),
          ));
        }
        continue;
      }
      if (workTarget == 'upgrade_town' && isWorkOrderTargetAllowedForUnitType(u.type, 'upgrade_town') && u.currentWork == null && hasValidTarget) {
        final cost = workOrderMaterialCost('upgrade_town');
        if (cost != null && canAffordMaterialCost(cost)) {
          deductMaterialCost(cost);
          final totalTurns = totalTurnsForWork('upgrade_town');
          updateUnit(order.unitId, u.copyWith(
            status: UnitStatus.working,
            tileKey: targetTileKey,
            currentWork: CurrentWork(
              workTarget: workTarget,
              tileKey: targetTileKey,
              totalTurns: totalTurns,
              remainingTurns: totalTurns,
            ),
          ));
        }
        continue;
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

