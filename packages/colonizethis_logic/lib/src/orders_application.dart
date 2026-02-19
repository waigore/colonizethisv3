import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'naval.dart';

/// Order application helpers for build and work phases.
/// SPEC/program/orders.md

/// Applies BuildUnitOrder and WorkOrder for all players in [game].
///
/// When [topology] is provided, ship builds (BuildUnitOrder with ship unit type) spawn in home fleet.
/// - BuildUnitOrder: when isMilitary, consumes one peasant if available;
///   when ship type, deducts cost and adds ship to home fleet at capital port.
/// - WorkOrder: sets the unit status to working; no terrain change yet.
Game applyBuildAndWorkOrders(Game game, Orders orders, {MapTopology? topology}) {
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
      vis[tk] = 'fullyVisible';
    }
    visibilityByTile = Map<String, Map<String, String>>.from(visibilityByTile)
      ..[playerId] = vis;
  }

  for (final entry in oldUnitsById.entries) {
    final u = entry.value;
    if (u.currentWork == null) continue;
    final cw = u.currentWork!;
    final nextRemaining = cw.remainingTurns - 1;
    if (nextRemaining <= 0) {
      if (cw.workTarget == 'build_improvement') {
        final level = tileState.improvementLevel(cw.tileKey);
        tileState = tileState.setImprovement(cw.tileKey, (level + 1).clamp(0, 4));
      } else if (cw.workTarget == 'explore') {
        applyExploreCompletion(u, ProvinceId.regionIdFrom(u.locationProvinceId));
      } else if (cw.workTarget == 'build_road') {
        final level = tileState.roadLevel(cw.tileKey);
        tileState = tileState.setRoadLevel(cw.tileKey, (level + 1).clamp(0, 2));
      } else if (cw.workTarget == 'build_port' && topology != null) {
        final parts = cw.tileKey.split('|');
        final regionIdFromTile = parts.isNotEmpty ? parts[0] : ProvinceId.regionIdFrom(u.locationProvinceId);
        final localId = parts.length > 1 ? parts[1] : ProvinceId.localIdFrom(u.locationProvinceId);
        final fullProvinceId = ProvinceId.full(regionIdFromTile, localId);
        final seaZoneId = seaZoneIdForProvince(topology, localId);
        if (seaZoneId != null) {
          portsByProvinceSeaboard['$fullProvinceId|$seaZoneId'] = cw.tileKey;
          tileState = tileState.setRoadLevel(cw.tileKey, 4);
        }
      } else if (cw.workTarget == 'build_fort') {
        final idx = oldProvinces.indexWhere((p) => p.id == u.locationProvinceId);
        if (idx >= 0) {
          final p = oldProvinces[idx];
          oldProvinces = List<Province>.from(oldProvinces)
            ..[idx] = p.copyWith(fortLevel: (p.fortLevel + 1).clamp(0, 3));
        }
      } else if (cw.workTarget == 'build_rail') {
        tileState = tileState.setRoadLevel(cw.tileKey, 4);
      } else if (cw.workTarget == 'upgrade_town') {
        final level = tileState.improvementLevel(cw.tileKey);
        tileState = tileState.setImprovement(cw.tileKey, (level + 1).clamp(0, 4));
      }
      oldUnitsById[entry.key] = u.copyWith(status: UnitStatus.idle, currentWork: null);
    } else {
      oldUnitsById[entry.key] = u.copyWith(
        currentWork: cw.copyWith(remainingTurns: nextRemaining),
      );
    }
  }
  for (final entry in newUnitsById.entries) {
    final u = entry.value;
    if (u.currentWork == null) continue;
    final cw = u.currentWork!;
    final nextRemaining = cw.remainingTurns - 1;
    if (nextRemaining <= 0) {
      if (cw.workTarget == 'build_improvement') {
        final level = tileState.improvementLevel(cw.tileKey);
        tileState = tileState.setImprovement(cw.tileKey, (level + 1).clamp(0, 4));
      } else if (cw.workTarget == 'explore') {
        applyExploreCompletion(u, ProvinceId.regionIdFrom(u.locationProvinceId));
      } else if (cw.workTarget == 'build_road') {
        final level = tileState.roadLevel(cw.tileKey);
        tileState = tileState.setRoadLevel(cw.tileKey, (level + 1).clamp(0, 2));
      } else if (cw.workTarget == 'build_port' && topology != null) {
        final parts = cw.tileKey.split('|');
        final regionIdFromTile = parts.isNotEmpty ? parts[0] : ProvinceId.regionIdFrom(u.locationProvinceId);
        final localId = parts.length > 1 ? parts[1] : ProvinceId.localIdFrom(u.locationProvinceId);
        final fullProvinceId = ProvinceId.full(regionIdFromTile, localId);
        final seaZoneId = seaZoneIdForProvince(topology, localId);
        if (seaZoneId != null) {
          portsByProvinceSeaboard['$fullProvinceId|$seaZoneId'] = cw.tileKey;
          tileState = tileState.setRoadLevel(cw.tileKey, 4);
        }
      } else if (cw.workTarget == 'build_fort') {
        final idx = newProvinces.indexWhere((p) => p.id == u.locationProvinceId);
        if (idx >= 0) {
          final p = newProvinces[idx];
          newProvinces = List<Province>.from(newProvinces)
            ..[idx] = p.copyWith(fortLevel: (p.fortLevel + 1).clamp(0, 3));
        }
      } else if (cw.workTarget == 'build_rail') {
        tileState = tileState.setRoadLevel(cw.tileKey, 4);
      } else if (cw.workTarget == 'upgrade_town') {
        final level = tileState.improvementLevel(cw.tileKey);
        tileState = tileState.setImprovement(cw.tileKey, (level + 1).clamp(0, 4));
      }
      newUnitsById[entry.key] = u.copyWith(status: UnitStatus.idle, currentWork: null);
    } else {
      newUnitsById[entry.key] = u.copyWith(
        currentWork: cw.copyWith(remainingTurns: nextRemaining),
      );
    }
  }
  game = game.copyWith(
    worldState: game.worldState.copyWith(
      tileState: tileState,
      playerVisibilityByTile: visibilityByTile,
      portsByProvinceSeaboard: portsByProvinceSeaboard,
      oldWorld: RegionData(provinces: oldProvinces, units: oldUnitsById.values.toList()),
      newWorld: RegionData(provinces: newProvinces, units: newUnitsById.values.toList()),
    ),
  );

  final updatedPlayers = <Player>[];

  for (final player in game.players) {
    var stockpile = player.stockpile;
    var workers = player.workerPool;
    var treasury = player.treasury;

    // Build units for this player.
    for (final order in buildOrders[player.id] ?? const []) {
      if (order.isMilitary) {
        final econ = RegimentEconomyCatalog.byId[order.unitType];
        if (econ == null) {
          // Unknown regiment id; skip.
          continue;
        }

        // Tech gate: regiment buildable only if unlocking tech is in techUnlocked.
        // Catalog: colonizethis_data.unlockingTechByRegimentId. SPEC/game/tech-tree-military.md.
        final techUnlocked = player.techUnlocked ?? const {};
        final unlockingTechId = unlockingTechByRegimentId[order.unitType];
        if (unlockingTechId != null && techUnlocked[unlockingTechId] != true) {
          continue;
        }

        // Require at least one peasant to recruit a regiment.
        if (workers.peasants <= 0) {
          continue;
        }

        // Require sufficient treasury to pay the training cost.
        if (treasury < econ.buildTreasuryCost) {
          continue;
        }

        // Require sufficient stockpile for all material inputs.
        var hasAllInputs = true;
        for (final entry in econ.buildInputs.entries) {
          final available = stockpile.quantityOf(entry.key);
          if (available < entry.value) {
            hasAllInputs = false;
            break;
          }
        }
        if (!hasAllInputs) {
          continue;
        }

        // Apply costs: treasury, materials, and one worker.
        treasury -= econ.buildTreasuryCost;
        for (final entry in econ.buildInputs.entries) {
          stockpile = stockpile.applyDelta(entry.key, -entry.value);
        }
        workers = workers.copyWith(peasants: workers.peasants - 1);
      }

      // Ship build: spawn in home fleet at capital port. SPEC/program/naval-movement-resolution.md.
      if (!order.isMilitary && isShipUnitType(order.unitType) && topology != null) {
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
        final seaZoneId = seaZoneIdForProvince(topology, ProvinceId.localIdFrom(capProvinceId));
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
      }

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
        tileKey: order.isMilitary ? null : firstTileInSpawn,
      );

      if (regionId == 'newWorld') {
        newUnitsById[newUnit.id] = newUnit;
      } else {
        oldUnitsById[newUnit.id] = newUnit;
      }
    }

    // Work orders: assign new work or set status; resolve prospect.
    for (final order in workOrders[player.id] ?? const []) {
      Unit? u;
      if (oldUnitsById.containsKey(order.unitId)) {
        u = oldUnitsById[order.unitId]!;
      } else if (newUnitsById.containsKey(order.unitId)) {
        u = newUnitsById[order.unitId]!;
      }
      if (u != null) {
        final targetTileKey = order.targetTileKey;
        final hasValidTarget = targetTileKey.isNotEmpty;

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
            u.currentWork == null &&
            hasValidTarget) {
          final updated = u.copyWith(
            status: UnitStatus.working,
            tileKey: targetTileKey,
            currentWork: CurrentWork(
              workTarget: 'build_improvement',
              tileKey: targetTileKey,
              totalTurns: 1,
              remainingTurns: 1,
            ),
          );
          if (oldUnitsById.containsKey(order.unitId)) {
            oldUnitsById[order.unitId] = updated;
          } else {
            newUnitsById[order.unitId] = updated;
          }
          continue;
        }
        // Explore: multi-turn province reveal. SPEC/program/fog-and-exploration-resolution.md.
        if (order.target == 'explore' &&
            isExplorerUnit(u.type) &&
            u.currentWork == null &&
            hasValidTarget) {
          final regionId = oldUnitsById.containsKey(order.unitId) ? 'oldWorld' : 'newWorld';
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
            final updated = u.copyWith(
              status: UnitStatus.working,
              tileKey: targetTileKey,
              currentWork: CurrentWork(
                workTarget: 'explore',
                tileKey: targetTileKey,
                totalTurns: totalTurns,
                remainingTurns: totalTurns,
              ),
            );
            if (oldUnitsById.containsKey(order.unitId)) {
              oldUnitsById[order.unitId] = updated;
            } else {
              newUnitsById[order.unitId] = updated;
            }
            continue;
          }
        }
        // Terrain development: build_road, build_port, build_fort, build_rail, upgrade_town. SPEC/program/development-resolution.md.
        const engineerTargets = {'build_road', 'build_port', 'build_fort'};
        const railBuilderTargets = {'build_rail'};
        const builderTargets = {'upgrade_town'};
        final workTarget = order.target;
        if ((engineerTargets.contains(workTarget) && u.type == 'Engineer') ||
            (railBuilderTargets.contains(workTarget) && u.type == 'Rail Builder') ||
            (builderTargets.contains(workTarget) && u.type == 'Builder')) {
          if (u.currentWork == null && hasValidTarget) {
            const totalTurns = 1; // MVP; config/costs per spec later.
            final updated = u.copyWith(
              status: UnitStatus.working,
              tileKey: targetTileKey,
              currentWork: CurrentWork(
                workTarget: workTarget,
                tileKey: targetTileKey,
                totalTurns: totalTurns,
                remainingTurns: totalTurns,
              ),
            );
            if (oldUnitsById.containsKey(order.unitId)) {
              oldUnitsById[order.unitId] = updated;
            } else {
              newUnitsById[order.unitId] = updated;
            }
            continue;
          }
        }
        final updated = u.copyWith(
          status: UnitStatus.working,
          movementPoints: u.movementPoints,
        );
        if (oldUnitsById.containsKey(order.unitId)) {
          oldUnitsById[order.unitId] = updated;
        } else {
          newUnitsById[order.unitId] = updated;
        }
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
      oldWorld: updatedOldWorld,
      newWorld: updatedNewWorld,
    ),
  );
}

String _buildUnitId(String playerId, BuildUnitOrder order) {
  return '${playerId}_${order.unitType}_${order.spawnProvinceId}';
}

