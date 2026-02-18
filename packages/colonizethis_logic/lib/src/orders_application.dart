import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Order application helpers for build and work phases.
/// SPEC/program/orders.md

/// Applies BuildUnitOrder and WorkOrder for all players in [game].
///
/// Costs and detailed validation are intentionally stubbed for Phase 2:
/// - BuildUnitOrder: when isMilitary, consumes one peasant if available;
///   always spawns the unit at the requested province.
/// - WorkOrder: sets the unit status to working; no terrain change yet.
Game applyBuildAndWorkOrders(Game game, Orders orders) {
  final buildOrders = orders.buildUnitOrdersByPlayerId;
  final workOrders = orders.workOrdersByPlayerId;
  if (buildOrders.isEmpty && workOrders.isEmpty) {
    return game;
  }

  // Index units by id for oldWorld and newWorld.
  final oldUnitsById = {for (final u in game.worldState.oldWorld.units) u.id: u};
  final newUnitsById = {for (final u in game.worldState.newWorld.units) u.id: u};

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

        // Tech gate: if an unlocking tech is configured for this regiment,
        // require it to be present in the player's techUnlocked set.
        final techUnlocked = player.techUnlocked ?? const {};
        // Placeholder mapping for MVP; full mapping comes from tech catalog.
        const Map<String, String> unlockingTechByRegimentId = {
          // 'rifle_infantry': 'some_military_tech',
        };
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

      final newUnit = Unit(
        id: _buildUnitId(player.id, order),
        type: order.unitType,
        ownerId: player.id,
        provinceId: order.spawnProvinceId,
      );

      // Decide region by spawnProvinceId prefix (oldWorld/newWorld) or default to oldWorld.
      if (newUnit.provinceId.startsWith('newWorld')) {
        newUnitsById[newUnit.id] = newUnit;
      } else {
        oldUnitsById[newUnit.id] = newUnit;
      }
    }

    // Work orders: set status to working for matching units.
    for (final order in workOrders[player.id] ?? const []) {
      if (oldUnitsById.containsKey(order.unitId)) {
        final u = oldUnitsById[order.unitId]!;
        oldUnitsById[order.unitId] = Unit(
          id: u.id,
          type: u.type,
          ownerId: u.ownerId,
          provinceId: u.provinceId,
          status: UnitStatus.working,
          movementPoints: u.movementPoints,
        );
      } else if (newUnitsById.containsKey(order.unitId)) {
        final u = newUnitsById[order.unitId]!;
        newUnitsById[order.unitId] = Unit(
          id: u.id,
          type: u.type,
          ownerId: u.ownerId,
          provinceId: u.provinceId,
          status: UnitStatus.working,
          movementPoints: u.movementPoints,
        );
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

