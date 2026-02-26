import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';

import '../constants.dart';
import '../dossier/event_dialogue.dart';
import '../world/naval.dart';
import '../world/player_view.dart';

final Logger _log = Logger();

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

  bool isMineralEligibleTile(String tileKey) {
    const mineralTerrains = {
      TerrainType.swamp,
      TerrainType.hills,
      TerrainType.mountain,
      TerrainType.desert,
    };

    if (tileMapByRegion != null && tileMapByRegion.isNotEmpty) {
      final parts = tileKey.split('|');
      if (parts.length == 4) {
        final regionId = parts[0];
        final x = int.tryParse(parts[2]);
        final y = int.tryParse(parts[3]);
        final tileMap = tileMapByRegion[regionId];
        if (tileMap != null && x != null && y != null) {
          final terrain = tileMap.terrainAt(x, y);
          if (terrain != null) {
            return mineralTerrains.contains(terrain);
          }
        }
      }
    }

    final resourceId = game.worldState.resourceByTileKey[tileKey];
    if (resourceId == null || resourceId.isEmpty) {
      return false;
    }
    const mineralIds = {
      'iron',
      'copper',
      'tin',
      'coal',
      'silver',
      'gold',
      'gems',
      'diamonds',
    };
    return mineralIds.contains(resourceId);
  }

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
          // SPEC/program/development-resolution.md and SPEC/game/capital-and-connectivity.md
          final tileMap = tileMapByRegion;
          if (tileMap != null) {
            _propagateRoadToAdjacentCapitalOrPort(
              tileKey: cw.tileKey,
              nextLevel: nextLevel,
              player: player,
              worldState: gameForPlayer.worldState,
              tileMapByRegion: tileMap,
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
    for (final entry in unitsById.entries) {
      final u = entry.value;
      if (u.currentWork == null) continue;
      final cw = u.currentWork!;
      // Cancel work if tile no longer owned by this player (SPEC: unit dead / tile no longer owned).
      final purchasedByTile = gameForPlayer.worldState.purchasedTilesByTileKey;
      if (purchasedByTile.containsKey(cw.tileKey) &&
          purchasedByTile[cw.tileKey] != u.ownerId) {
        unitsById[entry.key] =
            u.copyWith(status: UnitStatus.idle, currentWork: null);
        _log.d(
            'logic: work cancelled unit=${u.id} reason=tile no longer owned tileKey=${cw.tileKey}');
        continue;
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
            u.copyWith(status: UnitStatus.idle, currentWork: null);
      } else {
        unitsById[entry.key] = u.copyWith(
          currentWork: cw.copyWith(remainingTurns: nextRemaining),
        );
      }
    }
    return currentGame;
  }

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
      } else if (category == BuildUnitCategory.civilian) {
        final econ = CivilianEconomyCatalog.byId[order.unitType];
        if (econ == null) continue;

        final unlockingTechId = unlockingTechByCivilianId[order.unitType];
        if (unlockingTechId != null &&
            (player.techUnlocked?[unlockingTechId] != true)) {
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
        game.worldState.oldWorld.provinces
            .where((p) => p.id == id)
            .firstOrNull ??
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

          final cost = 15 * landPurchaseBasePrice(resourceId);
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
          isMineralEligibleTile(targetTileKey)) {
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
      if (order.target == 'build_improvement' &&
          isWorkOrderTargetAllowedForUnitType(u.type, 'build_improvement') &&
          u.currentWork == null &&
          hasValidTarget) {
        final improvementLevel = tileState.improvementLevel(targetTileKey);
        final cost = workOrderMaterialCost('build_improvement',
            improvementLevel: improvementLevel);
        if (cost != null && canAffordMaterialCost(cost)) {
          deductMaterialCost(cost);
          final totalTurns = totalTurnsForWork('build_improvement',
              improvementLevel: improvementLevel);
          _log.d(
              'logic: work order accepted and assigned unit=${order.unitId} target=build_improvement targetTileKey=$targetTileKey totalTurns=$totalTurns');
          updateUnit(
              order.unitId,
              u.copyWith(
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
      if (workTarget == 'build_road' &&
          isWorkOrderTargetAllowedForUnitType(u.type, 'build_road') &&
          u.currentWork == null &&
          hasValidTarget) {
        final cost = workOrderMaterialCost('build_road');
        if (cost != null && canAffordMaterialCost(cost)) {
          deductMaterialCost(cost);
          final totalTurns = totalTurnsForWork('build_road');
          _log.d(
              'logic: work order accepted and assigned unit=${order.unitId} target=build_road targetTileKey=$targetTileKey totalTurns=$totalTurns');
          updateUnit(
              order.unitId,
              u.copyWith(
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
      if (workTarget == 'build_port' &&
          isWorkOrderTargetAllowedForUnitType(u.type, 'build_port') &&
          u.currentWork == null &&
          hasValidTarget) {
        final cost = workOrderMaterialCost('build_port');
        if (cost != null && canAffordMaterialCost(cost)) {
          deductMaterialCost(cost);
          final totalTurns = totalTurnsForWork('build_port');
          _log.d(
              'logic: work order accepted and assigned unit=${order.unitId} target=build_port targetTileKey=$targetTileKey totalTurns=$totalTurns');
          updateUnit(
              order.unitId,
              u.copyWith(
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
      if (workTarget == 'build_fort' &&
          isWorkOrderTargetAllowedForUnitType(u.type, 'build_fort') &&
          u.currentWork == null &&
          hasValidTarget) {
        final prov = provinceById(u.locationProvinceId);
        final fortLevel = prov?.fortLevel ?? 0;
        final cost = workOrderMaterialCost('build_fort', fortLevel: fortLevel);
        if (cost != null && canAffordMaterialCost(cost)) {
          deductMaterialCost(cost);
          final totalTurns =
              totalTurnsForWork('build_fort', fortLevel: fortLevel);
          _log.d(
              'logic: work order accepted and assigned unit=${order.unitId} target=build_fort targetTileKey=$targetTileKey totalTurns=$totalTurns');
          updateUnit(
              order.unitId,
              u.copyWith(
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
      if (workTarget == 'build_rail' &&
          isWorkOrderTargetAllowedForUnitType(u.type, 'build_rail') &&
          u.currentWork == null &&
          hasValidTarget) {
        final cost = workOrderMaterialCost('build_rail');
        if (cost != null && canAffordMaterialCost(cost)) {
          deductMaterialCost(cost);
          final totalTurns = totalTurnsForWork('build_rail');
          _log.d(
              'logic: work order accepted and assigned unit=${order.unitId} target=build_rail targetTileKey=$targetTileKey totalTurns=$totalTurns');
          updateUnit(
              order.unitId,
              u.copyWith(
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
      if (workTarget == 'upgrade_town' &&
          isWorkOrderTargetAllowedForUnitType(u.type, 'upgrade_town') &&
          u.currentWork == null &&
          hasValidTarget) {
        final cost = workOrderMaterialCost('upgrade_town');
        if (cost != null && canAffordMaterialCost(cost)) {
          deductMaterialCost(cost);
          final totalTurns = totalTurnsForWork('upgrade_town');
          _log.d(
              'logic: work order accepted and assigned unit=${order.unitId} target=upgrade_town targetTileKey=$targetTileKey totalTurns=$totalTurns');
          updateUnit(
              order.unitId,
              u.copyWith(
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
      final currentLevel = worldState.tileState.roadLevel(adjacentTileKey);
      // Only upgrade, never downgrade
      if (nextLevel > currentLevel) {
        setTileState(worldState.tileState.setRoadLevel(adjacentTileKey, nextLevel));
      }
    }
  }
}
