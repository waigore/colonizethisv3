import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'economy_production.dart';
import 'movement.dart';
import 'turn_resolver.dart';

/// Order engine: current-turn orders per player, validation, projected effects.
/// SPEC/program/order-engine.md. Does not mutate world state.

/// Validation result for one order. First invalid + all subsequent rejected.
enum OrderValidationStatus { accepted, rejected }

class OrderValidationResult {
  const OrderValidationResult({
    required this.status,
    this.reason,
  });

  final OrderValidationStatus status;
  final String? reason;

  bool get isAccepted => status == OrderValidationStatus.accepted;
}

/// Projected effects after dry-run of orders. For UI feedback.
class ProjectedEffects {
  const ProjectedEffects({
    this.workerCount,
    this.unitLocations,
    this.stockpileDeltas,
    this.treasuryDelta,
  });

  final int? workerCount;
  final Map<String, String>? unitLocations;
  final Map<String, int>? stockpileDeltas;
  final int? treasuryDelta;
}

/// Order engine: holds per-player orders, validates in submission order,
/// exposes projected effects. No world state mutation.
class OrderEngine {
  OrderEngine({
    Orders initialOrders = const Orders(),
  }) : _orders = Orders(
          moveOrdersByPlayerId: Map.from(initialOrders.moveOrdersByPlayerId)
            ..updateAll((_, v) => List.from(v)),
          buildUnitOrdersByPlayerId:
              Map.from(initialOrders.buildUnitOrdersByPlayerId)
                ..updateAll((_, v) => List.from(v)),
          workOrdersByPlayerId: Map.from(initialOrders.workOrdersByPlayerId)
            ..updateAll((_, v) => List.from(v)),
        researchOrdersByPlayerId:
            Map.from(initialOrders.researchOrdersByPlayerId)
              ..updateAll((_, v) => List.from(v)),
        );

  Orders _orders;

  Orders get orders => _copyOrders(_orders);

  Orders _copyOrders(Orders o) => Orders(
        moveOrdersByPlayerId: o.moveOrdersByPlayerId.map(
          (k, v) => MapEntry(k, List<MoveOrder>.from(v)),
        ),
        buildUnitOrdersByPlayerId: o.buildUnitOrdersByPlayerId.map(
          (k, v) => MapEntry(k, List<BuildUnitOrder>.from(v)),
        ),
        workOrdersByPlayerId: o.workOrdersByPlayerId.map(
          (k, v) => MapEntry(k, List<WorkOrder>.from(v)),
        ),
        researchOrdersByPlayerId: o.researchOrdersByPlayerId.map(
          (k, v) => MapEntry(k, List<ResearchOrder>.from(v)),
        ),
      );

  /// Adds order for [playerId]. Re-validates full list; returns validation result.
  OrderValidationResult addMoveOrder(String playerId, MoveOrder order) {
    final list = _orders.moveOrdersByPlayerId[playerId] ?? [];
    _orders = Orders(
      moveOrdersByPlayerId: {..._orders.moveOrdersByPlayerId, playerId: [...list, order]},
      buildUnitOrdersByPlayerId: _orders.buildUnitOrdersByPlayerId,
      workOrdersByPlayerId: _orders.workOrdersByPlayerId,
      researchOrdersByPlayerId: _orders.researchOrdersByPlayerId,
    );
    final results = validatePlayerOrders(playerId);
    final lastIdx = results.length - 1;
    if (lastIdx < 0) {
      return const OrderValidationResult(status: OrderValidationStatus.accepted);
    }
    return results.last;
  }

  /// Adds a move order using full game/topology context for validation.
  OrderValidationResult addMoveOrderWithContext(
    Game game,
    MapTopology topology,
    String playerId,
    MoveOrder order,
  ) {
    final list = _orders.moveOrdersByPlayerId[playerId] ?? [];
    _orders = Orders(
      moveOrdersByPlayerId: {..._orders.moveOrdersByPlayerId, playerId: [...list, order]},
      buildUnitOrdersByPlayerId: _orders.buildUnitOrdersByPlayerId,
      workOrdersByPlayerId: _orders.workOrdersByPlayerId,
      researchOrdersByPlayerId: _orders.researchOrdersByPlayerId,
    );
    final results = validatePlayerOrdersWithContext(game, topology, playerId);
    if (results.isEmpty) {
      return const OrderValidationResult(status: OrderValidationStatus.accepted);
    }
    return results.last;
  }

  OrderValidationResult addBuildOrder(String playerId, BuildUnitOrder order) {
    final list = _orders.buildUnitOrdersByPlayerId[playerId] ?? [];
    _orders = Orders(
      moveOrdersByPlayerId: _orders.moveOrdersByPlayerId,
      buildUnitOrdersByPlayerId: {..._orders.buildUnitOrdersByPlayerId, playerId: [...list, order]},
      workOrdersByPlayerId: _orders.workOrdersByPlayerId,
      researchOrdersByPlayerId: _orders.researchOrdersByPlayerId,
    );
    final results = validatePlayerOrders(playerId);
    return results.isEmpty
        ? const OrderValidationResult(status: OrderValidationStatus.accepted)
        : results.last;
  }

  /// Adds a build order using full game/topology context for validation.
  OrderValidationResult addBuildOrderWithContext(
    Game game,
    MapTopology topology,
    String playerId,
    BuildUnitOrder order,
  ) {
    final list = _orders.buildUnitOrdersByPlayerId[playerId] ?? [];
    _orders = Orders(
      moveOrdersByPlayerId: _orders.moveOrdersByPlayerId,
      buildUnitOrdersByPlayerId: {..._orders.buildUnitOrdersByPlayerId, playerId: [...list, order]},
      workOrdersByPlayerId: _orders.workOrdersByPlayerId,
      researchOrdersByPlayerId: _orders.researchOrdersByPlayerId,
    );
    final results = validatePlayerOrdersWithContext(game, topology, playerId);
    if (results.isEmpty) {
      return const OrderValidationResult(status: OrderValidationStatus.accepted);
    }
    return results.last;
  }

  OrderValidationResult addWorkOrder(String playerId, WorkOrder order) {
    final list = _orders.workOrdersByPlayerId[playerId] ?? [];
    _orders = Orders(
      moveOrdersByPlayerId: _orders.moveOrdersByPlayerId,
      buildUnitOrdersByPlayerId: _orders.buildUnitOrdersByPlayerId,
      workOrdersByPlayerId: {..._orders.workOrdersByPlayerId, playerId: [...list, order]},
      researchOrdersByPlayerId: _orders.researchOrdersByPlayerId,
    );
    final results = validatePlayerOrders(playerId);
    return results.isEmpty
        ? const OrderValidationResult(status: OrderValidationStatus.accepted)
        : results.last;
  }

  /// Adds a work order using full game/topology context for validation.
  OrderValidationResult addWorkOrderWithContext(
    Game game,
    MapTopology topology,
    String playerId,
    WorkOrder order,
  ) {
    final list = _orders.workOrdersByPlayerId[playerId] ?? [];
    _orders = Orders(
      moveOrdersByPlayerId: _orders.moveOrdersByPlayerId,
      buildUnitOrdersByPlayerId: _orders.buildUnitOrdersByPlayerId,
      workOrdersByPlayerId: {..._orders.workOrdersByPlayerId, playerId: [...list, order]},
      researchOrdersByPlayerId: _orders.researchOrdersByPlayerId,
    );
    final results = validatePlayerOrdersWithContext(game, topology, playerId);
    if (results.isEmpty) {
      return const OrderValidationResult(status: OrderValidationStatus.accepted);
    }
    return results.last;
  }

  void removeMoveOrder(String playerId, int index) {
    final list = List<MoveOrder>.from(_orders.moveOrdersByPlayerId[playerId] ?? []);
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      _orders = Orders(
        moveOrdersByPlayerId: {..._orders.moveOrdersByPlayerId, playerId: list},
        buildUnitOrdersByPlayerId: _orders.buildUnitOrdersByPlayerId,
        workOrdersByPlayerId: _orders.workOrdersByPlayerId,
        researchOrdersByPlayerId: _orders.researchOrdersByPlayerId,
      );
    }
  }

  void removeBuildOrder(String playerId, int index) {
    final list = List<BuildUnitOrder>.from(_orders.buildUnitOrdersByPlayerId[playerId] ?? []);
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      _orders = Orders(
        moveOrdersByPlayerId: _orders.moveOrdersByPlayerId,
        buildUnitOrdersByPlayerId: {..._orders.buildUnitOrdersByPlayerId, playerId: list},
        workOrdersByPlayerId: _orders.workOrdersByPlayerId,
        researchOrdersByPlayerId: _orders.researchOrdersByPlayerId,
      );
    }
  }

  void removeWorkOrder(String playerId, int index) {
    final list = List<WorkOrder>.from(_orders.workOrdersByPlayerId[playerId] ?? []);
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      _orders = Orders(
        moveOrdersByPlayerId: _orders.moveOrdersByPlayerId,
        buildUnitOrdersByPlayerId: _orders.buildUnitOrdersByPlayerId,
        workOrdersByPlayerId: {..._orders.workOrdersByPlayerId, playerId: list},
        researchOrdersByPlayerId: _orders.researchOrdersByPlayerId,
      );
    }
  }

  /// Validates full list in submission order. First invalid + all subsequent rejected.
  List<OrderValidationResult> validatePlayerOrders(String playerId) {
    final results = <OrderValidationResult>[];
    final moves = _orders.moveOrdersByPlayerId[playerId] ?? [];
    final builds = _orders.buildUnitOrdersByPlayerId[playerId] ?? [];
    final works = _orders.workOrdersByPlayerId[playerId] ?? [];
    var rejected = false;

    for (final o in moves) {
      if (rejected) {
        results.add(OrderValidationResult(
          status: OrderValidationStatus.rejected,
          reason: 'Previous order invalid',
        ));
        continue;
      }
      final r = _validateMoveOrder(o, playerId);
      results.add(r);
      if (!r.isAccepted) rejected = true;
    }
    for (final o in builds) {
      if (rejected) {
        results.add(OrderValidationResult(
          status: OrderValidationStatus.rejected,
          reason: 'Previous order invalid',
        ));
        continue;
      }
      final r = _validateBuildOrder(o, playerId);
      results.add(r);
      if (!r.isAccepted) rejected = true;
    }
    for (final o in works) {
      if (rejected) {
        results.add(OrderValidationResult(
          status: OrderValidationStatus.rejected,
          reason: 'Previous order invalid',
        ));
        continue;
      }
      final r = _validateWorkOrder(o, playerId);
      results.add(r);
      if (!r.isAccepted) rejected = true;
    }
    return results;
  }

  OrderValidationResult _validateMoveOrder(MoveOrder o, String playerId) {
    // Topology check requires Game + MapTopology; we don't have them in engine.
    // Engine stores orders; validation needs world state. So we need to pass Game.
    // Refactor: validatePlayerOrders(game, topology, playerId).
    return const OrderValidationResult(status: OrderValidationStatus.accepted);
  }

  OrderValidationResult _validateBuildOrder(BuildUnitOrder o, String playerId) {
    return const OrderValidationResult(status: OrderValidationStatus.accepted);
  }

  OrderValidationResult _validateWorkOrder(WorkOrder o, String playerId) {
    return const OrderValidationResult(status: OrderValidationStatus.accepted);
  }

  /// Validates with full context. Call this when Game and topology available.
  List<OrderValidationResult> validatePlayerOrdersWithContext(
    Game game,
    MapTopology topology,
    String playerId,
  ) {
    final results = <OrderValidationResult>[];
    final player = game.players.cast<Player?>().firstWhere(
          (p) => p?.id == playerId,
          orElse: () => null,
        );
    if (player == null) return results;

    final moves = _orders.moveOrdersByPlayerId[playerId] ?? [];
    final builds = _orders.buildUnitOrdersByPlayerId[playerId] ?? [];
    final works = _orders.workOrdersByPlayerId[playerId] ?? [];
    var rejected = false;

    final region = game.worldState.oldWorld;
    final unitsById = {for (final u in region.units) u.id: u}
      ..addAll({for (final u in game.worldState.newWorld.units) u.id: u});

    final provincesById = <String, Province>{};
    for (final p in game.worldState.oldWorld.provinces) {
      provincesById[p.id] = p;
    }
    for (final p in game.worldState.newWorld.provinces) {
      provincesById[p.id] = p;
    }

    bool _ownerIsGreatPower(String? ownerId) {
      if (ownerId == null) return false;
      return game.players.any((p) => p.id == ownerId);
    }

    bool _ownerIsMinorOrTribe(String? ownerId) {
      if (ownerId == null) return false;
      return game.minorNations.any((m) => m.id == ownerId) ||
          game.tribes.any((t) => t.id == ownerId);
    }

    for (final o in moves) {
      if (rejected) {
        results.add(OrderValidationResult(status: OrderValidationStatus.rejected, reason: 'Previous invalid'));
        continue;
      }
      final unit = unitsById[o.unitId];
      var valid = unit != null &&
          unit.ownerId == playerId &&
          isValidLandMove(topology, unit.provinceId, o.destinationProvinceId);
      String? reason;

      if (!valid) {
        reason = 'Invalid move';
      } else {
        final destProvince = provincesById[o.destinationProvinceId];
        final destOwnerId = destProvince?.ownerId;
        final isMilitary = isMilitaryUnit(unit.type);
        final isExplorer = isExplorerUnit(unit.type);
        final isMerchant = isMerchantUnit(unit.type);

        if (!isMilitary && destOwnerId != null && destOwnerId != playerId) {
          if (_ownerIsGreatPower(destOwnerId)) {
            // Civilians may not enter other Great Power territory at all.
            valid = false;
            reason = 'Civilian cannot enter other Great Power territory';
          } else if (_ownerIsMinorOrTribe(destOwnerId)) {
            // Explorers (and Merchants, when in scope) may enter Minors/Tribes.
            if (!(isExplorer || isMerchant)) {
              valid = false;
              reason = 'Civilian cannot enter Minor/Tribe territory';
            }
          }
        }
      }

      results.add(OrderValidationResult(
        status: valid ? OrderValidationStatus.accepted : OrderValidationStatus.rejected,
        reason: valid ? null : reason ?? 'Invalid move',
      ));
      if (!valid) rejected = true;
    }

    var workers = player.workerPool;
    var stockpile = player.stockpile;
    var treasury = player.treasury;
    for (final o in builds) {
      if (rejected) {
        results.add(OrderValidationResult(status: OrderValidationStatus.rejected, reason: 'Previous invalid'));
        continue;
      }
      var valid = true;
      String? reason;

      // All units spawn in the player's capital; require that a capital exists.
      if (player.capitalProvinceId == null) {
        valid = false;
        reason = 'No capital to spawn unit';
      }

      if (o.isMilitary) {
        final econ = RegimentEconomyCatalog.byId[o.unitType];
        if (econ == null) valid = false;
        if (valid && workers.peasants <= 0) valid = false;
        if (valid && treasury < econ!.buildTreasuryCost) valid = false;
        if (valid) {
          for (final e in econ!.buildInputs.entries) {
            if (stockpile.quantityOf(e.key) < e.value) {
              valid = false;
              break;
            }
          }
        }
        if (valid) {
          treasury -= econ!.buildTreasuryCost;
          for (final e in econ.buildInputs.entries) {
            stockpile = stockpile.applyDelta(e.key, -e.value);
          }
          workers = workers.copyWith(peasants: workers.peasants - 1);
        }
      }
      results.add(OrderValidationResult(
        status: valid ? OrderValidationStatus.accepted : OrderValidationStatus.rejected,
        reason: valid
            ? null
            : reason ?? 'Insufficient resources',
      ));
      if (!valid) rejected = true;
    }

    for (final o in works) {
      if (rejected) {
        results.add(OrderValidationResult(status: OrderValidationStatus.rejected, reason: 'Previous invalid'));
        continue;
      }
      final unit = unitsById[o.unitId];
      var valid = unit != null && unit.ownerId == playerId;
      String? reason;

      if (!valid) {
        reason = 'Unit not found';
      } else {
        // Validate target against unit type and ownership of current province.
        final type = unit.type;
        final isExplorer = isExplorerUnit(type);
        final isWorker = isCivilianWorkerUnit(type);

        const explorerTargets = {'explore', 'prospect'};
        const builderTargets = {'build_improvement', 'upgrade_town'};
        const engineerTargets = {'build_road', 'build_port', 'build_fort', 'build_rail'};

        bool targetOk = false;
        if (isExplorer) {
          targetOk = explorerTargets.contains(o.target);
        } else if (isWorker) {
          // Distinguish Builder vs Engineer by supported targets.
          if (builderTargets.contains(o.target)) {
            targetOk = true;
          } else if (engineerTargets.contains(o.target)) {
            targetOk = true;
          }
        }

        if (!targetOk) {
          valid = false;
          reason = 'Invalid work target for unit type';
        } else if (!isExplorer) {
          // Non-explorer civilians must work only in owned or rights-granted provinces.
          final province = provincesById[unit.provinceId];
          final ownerId = province?.ownerId;
          if (ownerId != null && ownerId != playerId) {
            valid = false;
            reason = 'Cannot work in foreign province';
          }
        }
      }

      results.add(OrderValidationResult(
        status: valid ? OrderValidationStatus.accepted : OrderValidationStatus.rejected,
        reason: valid ? null : reason ?? 'Unit not found',
      ));
      if (!valid) rejected = true;
    }
    return results;
  }

  /// Dry-run: apply orders to copy of game, return projected effects.
  ProjectedEffects projectedEffects(
    Game game,
    MapTopology topology,
    String playerId, {
    List<AssignedRecipe> defaultAssignments = const [],
  }) {
    final orders = _copyOrders(_orders);
    final tileMapByRegion = <String, TileMapResult>{};
    final next = resolveTurnForGame(
      game: game,
      topology: topology,
      orders: orders,
      tileMapByRegion: tileMapByRegion.isEmpty ? null : tileMapByRegion,
      defaultAssignments: defaultAssignments,
    );
    final player = next.players.cast<Player?>().firstWhere(
          (p) => p?.id == playerId,
          orElse: () => null,
        );
    if (player == null) return const ProjectedEffects();

    final origPlayer = game.players.cast<Player?>().firstWhere(
          (p) => p?.id == playerId,
          orElse: () => null,
        );

    return ProjectedEffects(
      workerCount: player.workerPool.totalWorkers,
      treasuryDelta: origPlayer != null ? player.treasury - origPlayer.treasury : null,
    );
  }
}
