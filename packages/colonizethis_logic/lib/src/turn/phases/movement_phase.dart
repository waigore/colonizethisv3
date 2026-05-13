import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../constants.dart';
import '../../orders/bundled_civilian_work_order.dart';
import '../../orders/draft_orders_mutations.dart';
import '../../world/army_movement.dart';
import '../../world/movement.dart';
import '../trace/turn_trace_runtime.dart';
import '../../world/naval_resolution.dart';
import '../../world/player_view.dart';
import '../../world/province_lookup.dart';
import '../../world/unit_lookup.dart';

Game runMovementPhase(
  Game game,
  MapTopology topology,
  Orders orders, {
  CivilianMoveOrderTraceCallback? onCivilianMoveOrderTrace,
  BundledWorkMoveTraceCallback? onBundledWorkMoveTrace,
  ArmyMoveOrderTraceCallback? onArmyMoveOrderTrace,
}) {
  var state = game;

  final moveOrders = orders.moveOrdersByPlayerId;
  if (moveOrders.isNotEmpty) {
    final ownerByProvinceId = <String, String?>{
      for (final p in allProvinces(state.worldState)) p.id: p.ownerId,
    };

    final originalOldWorld = state.worldState.oldWorld;
    final originalNewWorld = state.worldState.newWorld;

    final tiled = applyCivilianTileMoveOrdersToWorldRegions(
      state,
      moveOrders,
      onCivilianMoveOrderTrace: onCivilianMoveOrderTrace,
    );
    final oldWorld = tiled.oldWorld;
    final newWorld = tiled.newWorld;
    // Defer the deep copy of spyRevealTurnsByPlayer until a spy actually
    // leaves an enemy province; most turns have zero such events, so the
    // eager copy was wasted O(players * provinces) work per move phase.
    // Refs #2394 Category D.
    final originalSpyTimers = state.worldState.spyRevealTurnsByPlayer;
    Map<String, Map<String, int>>? mutableSpyTimers;
    Map<String, int> spyTimersForOwner(String ownerId) {
      mutableSpyTimers ??= {
        for (final entry in originalSpyTimers.entries)
          entry.key: Map<String, int>.from(entry.value),
      };
      return mutableSpyTimers!.putIfAbsent(ownerId, () => <String, int>{});
    }

    void recordSpyLeft(String ownerId, String provinceId) {
      final provinceOwner = ownerByProvinceId[provinceId];
      if (provinceOwner == null || provinceOwner == ownerId) {
        return;
      }
      spyTimersForOwner(ownerId)[provinceId] = 5;
    }

    void recordSpyProvinceChanges(RegionData before, RegionData after) {
      final afterById = <String, Unit>{};
      for (final x in after.units) {
        afterById.putIfAbsent(x.id, () => x);
      }
      for (final u in before.units) {
        if (!isSpyUnit(u.type)) continue;
        final afterUnit = afterById[u.id];
        if (afterUnit == null) continue;
        if (afterUnit.locationProvinceId != u.locationProvinceId) {
          recordSpyLeft(u.ownerId, u.locationProvinceId);
        }
      }
    }

    recordSpyProvinceChanges(originalOldWorld, oldWorld);
    recordSpyProvinceChanges(originalNewWorld, newWorld);
    state = state.copyWith(
      worldState: state.worldState.copyWith(
        oldWorld: oldWorld,
        newWorld: newWorld,
        spyRevealTurnsByPlayer: mutableSpyTimers ?? originalSpyTimers,
      ),
    );
  }
  state = applyImplicitBundledCivilianWorkOrderMoves(
    state,
    topology,
    orders,
    onBundledWorkMoveTrace: onBundledWorkMoveTrace,
  );

  final armyMoveOrders = orders.armyMoveOrdersByPlayerId;
  if (armyMoveOrders.isNotEmpty) {
    bool isDestinationOwnedByPlayer(
      String playerId,
      String destFullProvinceId,
    ) =>
        tryGetProvince(state.worldState, destFullProvinceId)?.ownerId ==
        playerId;

    final filtered = onArmyMoveOrderTrace == null
        ? armyMoveOrders
        : _preTraceArmyMoveGlobalRejections(
            armyMoveOrders,
            state.worldState,
            onArmyMoveOrderTrace: onArmyMoveOrderTrace,
          );

    final cross = applyCrossRegionArmyMovesWithinOwnedProvinces(
      game: state,
      worldState: state.worldState,
      armyMoveOrdersByPlayerId: filtered,
      onArmyMoveOrderTrace: onArmyMoveOrderTrace,
    );
    var ws = cross.worldState;
    final remaining = cross.remainingArmyMoveOrdersByPlayerId;
    ws = applyArmyMoveOrdersToRegion(
      ws,
      topology,
      remaining,
      regionId: kRegionOldWorld,
      isDestinationOwnedByPlayer: isDestinationOwnedByPlayer,
      onArmyMoveOrderTrace: onArmyMoveOrderTrace,
    );
    ws = applyArmyMoveOrdersToRegion(
      ws,
      topology,
      remaining,
      regionId: kRegionNewWorld,
      isDestinationOwnedByPlayer: isDestinationOwnedByPlayer,
      onArmyMoveOrderTrace: onArmyMoveOrderTrace,
    );
    state = state.copyWith(worldState: ws);
  }

  final navalOrders = orders.navalMoveOrdersByPlayerId;
  if (navalOrders.isNotEmpty) {
    state = applyNavalMovesAndShipReveal(state, topology, navalOrders);
  }

  final missionOrders = navalMissionOrdersRespectingNavalMoves(
    orders.navalMissionOrdersByPlayerId,
    orders.navalMoveOrdersByPlayerId,
  );
  state = applyNavalMissionOrders(state, missionOrders);

  return state;
}

Game applyImplicitBundledCivilianWorkOrderMoves(
  Game game,
  MapTopology topology,
  Orders orders, {
  BundledWorkMoveTraceCallback? onBundledWorkMoveTrace,
}) {
  var state = game;
  final workByPlayerId = orders.workOrdersByPlayerId;
  if (workByPlayerId.isEmpty) {
    return state;
  }

  final unitById = unitsByIdFromWorld(state.worldState);
  final viewByPlayerId = <String, PlayerView>{};
  for (final entry in workByPlayerId.entries) {
    final playerId = entry.key;
    final diplomatic =
        orders.diplomaticOrdersByPlayerId[playerId] ??
        const <DiplomaticOrder>[];
    var view = viewByPlayerId.putIfAbsent(
      playerId,
      () => buildPlayerView(state, topology, playerId),
    );
    for (final workOrder in entry.value) {
      final unit = unitById[workOrder.unitId];
      if (unit == null || unit.ownerId != playerId) {
        onBundledWorkMoveTrace?.call(
          playerId: playerId,
          order: workOrder,
          applied: false,
          ignoreReason: 'missing_or_foreign_unit',
        );
        continue;
      }
      if (!civilianBundledWorkNeedsProvinceMoveLeg(state, unit, workOrder)) {
        onBundledWorkMoveTrace?.call(
          playerId: playerId,
          order: workOrder,
          applied: false,
          ignoreReason: 'move_leg_not_required',
        );
        continue;
      }
      final destination = executionProvinceFullIdFromWorkOrder(
        state,
        workOrder,
      );
      if (destination == null) {
        onBundledWorkMoveTrace?.call(
          playerId: playerId,
          order: workOrder,
          applied: false,
          ignoreReason: 'destination_unresolved',
        );
        continue;
      }
      final destinationTile = firstLegalBundledEntryTileKeyInProvince(
        game: state,
        topology: topology,
        playerId: playerId,
        unit: unit,
        destProvinceFullId: destination,
        preferredTargetTileKey: workOrder.targetTileKey,
        view: view,
        unitsById: unitById,
        diplomaticOrders: diplomatic,
      );
      if (destinationTile == null) {
        onBundledWorkMoveTrace?.call(
          playerId: playerId,
          order: workOrder,
          applied: false,
          destinationProvinceId: destination,
          ignoreReason: 'destination_tile_unavailable',
        );
        continue;
      }

      final destinationRegion = ProvinceId.regionIdFrom(destination);
      final sourceRegion = ProvinceId.regionIdFrom(unit.locationProvinceId);
      final movedUnit = unit.copyWith(
        locationProvinceId: destination,
        tileKey: destinationTile,
      );
      var ws = state.worldState;
      if (sourceRegion == destinationRegion) {
        ws = ws.updateRegionById(sourceRegion, (region) {
          final next = <Unit>[
            for (final u in region.units)
              if (u.id != unit.id) u,
          ]..add(movedUnit);
          return RegionData(provinces: region.provinces, units: next);
        });
      } else {
        ws = ws.updateRegionById(sourceRegion, (region) {
          final next = <Unit>[
            for (final u in region.units)
              if (u.id != unit.id) u,
          ];
          return RegionData(provinces: region.provinces, units: next);
        });
        ws = ws.updateRegionById(destinationRegion, (region) {
          return RegionData(
            provinces: region.provinces,
            units: [...region.units, movedUnit],
          );
        });
      }
      state = state.copyWith(worldState: ws);
      unitById[unit.id] = movedUnit;
      view = _playerViewWithMovedUnit(view, movedUnit);
      viewByPlayerId[playerId] = view;
      onBundledWorkMoveTrace?.call(
        playerId: playerId,
        order: workOrder,
        applied: true,
        destinationProvinceId: destination,
        destinationTileKey: destinationTile,
      );
    }
  }
  return state;
}

PlayerView _playerViewWithMovedUnit(PlayerView view, Unit movedUnit) {
  return PlayerView(
    playerId: view.playerId,
    player: view.player,
    ownUnitsById: <String, Unit>{...view.ownUnitsById, movedUnit.id: movedUnit},
    provincesById: view.provincesById,
    visibilityByTile: view.visibilityByTile,
    prospectedTiles: view.prospectedTiles,
    diplomacyByOtherId: view.diplomacyByOtherId,
  );
}

/// Emits trace events for army move orders rejected by global checks
/// (army not found, owner mismatch, home army locked) and returns the orders
/// that should still flow into the cross-region and same-region helpers.
///
/// Pre-tracing here avoids double-emit from the two same-region passes which
/// otherwise both observe global-decision rejections.
Map<String, List<ArmyMoveOrder>> _preTraceArmyMoveGlobalRejections(
  Map<String, List<ArmyMoveOrder>> armyMoveOrdersByPlayerId,
  WorldState worldState, {
  required ArmyMoveOrderTraceCallback onArmyMoveOrderTrace,
}) {
  final armyById = {for (final a in worldState.armies) a.id: a};
  final filtered = <String, List<ArmyMoveOrder>>{};
  for (final entry in armyMoveOrdersByPlayerId.entries) {
    final playerId = entry.key;
    final keep = <ArmyMoveOrder>[];
    for (final order in entry.value) {
      final army = armyById[order.armyId];
      if (army == null) {
        onArmyMoveOrderTrace(
          playerId: playerId,
          order: order,
          applied: false,
          ignoreReason: 'army_not_found',
        );
        continue;
      }
      if (army.ownerId != playerId) {
        onArmyMoveOrderTrace(
          playerId: playerId,
          order: order,
          applied: false,
          ignoreReason: 'owner_mismatch',
        );
        continue;
      }
      if (army.isHomeArmy) {
        onArmyMoveOrderTrace(
          playerId: playerId,
          order: order,
          applied: false,
          ignoreReason: 'home_army_locked',
        );
        continue;
      }
      keep.add(order);
    }
    if (keep.isNotEmpty) {
      filtered[playerId] = keep;
    }
  }
  return filtered;
}
