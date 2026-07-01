import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import '../turn_phase_handler_helpers.dart';
import '../turn_pipeline_state.dart';
import '../turn_resolver_config.dart';
import '../naval_resolution.dart';
import 'movement_phase_bundled_work.dart';

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
    final tiled = applyCivilianTileMoveOrdersToWorldRegions(
      state,
      moveOrders,
      onCivilianMoveOrderTrace: onCivilianMoveOrderTrace,
    );
    final oldWorld = tiled.oldWorld;
    final newWorld = tiled.newWorld;
    state = state.updateWorldState(
      (ws) => ws.copyWith(
        oldWorld: oldWorld,
        newWorld: newWorld,
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
        state.worldState.tryGetProvince(destFullProvinceId)?.ownerId ==
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
    state = state.withWorldState(ws);
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

TurnPhaseStepOutcome movementTurnPhaseHandler(
  TurnPipelineState acc,
  TurnResolverConfig config,
  int turn,
) => simpleGamePhase(
  (game, config) => runMovementPhase(
    game,
    config.topology,
    config.orders,
    onCivilianMoveOrderTrace:
        config.turnTraceRuntime?.handleCivilianMoveOrderTrace,
    onBundledWorkMoveTrace: config.turnTraceRuntime?.handleBundledWorkMoveTrace,
    onArmyMoveOrderTrace: config.turnTraceRuntime?.handleArmyMoveOrderTrace,
  ),
)(acc, config, turn);
