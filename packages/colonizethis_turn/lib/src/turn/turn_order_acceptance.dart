import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';

/// Filters [orders] by validation [results] (consuming via [idxBox]).
void filterOrderList<T>(
  String playerId,
  List<T> orders,
  List<OrderValidationResult> results,
  List<int> idxBox,
  void Function(String playerId, T order) addAccepted,
  String Function(T order) orderSummary,
  GameEventBus? eventBus,
  void Function(GameEvent)? onGameEvent,
) {
  for (final order in orders) {
    final r = idxBox[0] >= results.length
        ? OrderValidationResult.accepted()
        : results[idxBox[0]++];
    if (r.isAccepted) {
      addAccepted(playerId, order);
    } else if (r.reason != null) {
      final event = OrderRejectedEvent(
        playerId: playerId,
        orderSummary: orderSummary(order),
        reasonCode: r.reason!,
      );
      deliverGameEvent(event, eventBus: eventBus, onGameEvent: onGameEvent);
    }
  }
}

Orders filterAcceptedOrdersForAllPlayers({
  required OrderEngine engine,
  required Game game,
  required MapTopology topology,
  GameEventBus? eventBus,
  void Function(GameEvent)? onGameEvent,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final original = engine.orders;
  final moveByPlayer = <String, List<MoveOrder>>{};
  final armyMoveByPlayer = <String, List<ArmyMoveOrder>>{};
  final buildByPlayer = <String, List<BuildUnitOrder>>{};
  final workByPlayer = <String, List<WorkOrder>>{};
  final diploByPlayer = <String, List<DiplomaticOrder>>{};

  final playerIds = <String>{
    ...original.moveOrdersByPlayerId.keys,
    ...original.armyMoveOrdersByPlayerId.keys,
    ...original.buildUnitOrdersByPlayerId.keys,
    ...original.workOrdersByPlayerId.keys,
    ...original.diplomaticOrdersByPlayerId.keys,
  };

  for (final playerId in playerIds) {
    final moves = original.moveOrdersByPlayerId[playerId] ?? const [];
    final armyMoves = original.armyMoveOrdersByPlayerId[playerId] ?? const [];
    final builds = original.buildUnitOrdersByPlayerId[playerId] ?? const [];
    final works = original.workOrdersByPlayerId[playerId] ?? const [];
    final diplo =
        original.diplomaticOrdersByPlayerId[playerId] ??
        const <DiplomaticOrder>[];

    if (moves.isEmpty &&
        armyMoves.isEmpty &&
        builds.isEmpty &&
        works.isEmpty &&
        diplo.isEmpty) {
      continue;
    }

    final results = engine.validatePlayerOrdersWithContext(
      game,
      topology,
      playerId,
      tileMapByRegion: tileMapByRegion,
    );
    final idxBox = [0];

    filterOrderList<MoveOrder>(
      playerId,
      moves,
      results,
      idxBox,
      (pid, m) => moveByPlayer.putIfAbsent(pid, () => <MoveOrder>[]).add(m),
      (m) => 'Move order: ${m.unitId} -> ${m.destinationTileKey}',
      eventBus,
      onGameEvent,
    );
    filterOrderList<ArmyMoveOrder>(
      playerId,
      armyMoves,
      results,
      idxBox,
      (pid, m) =>
          armyMoveByPlayer.putIfAbsent(pid, () => <ArmyMoveOrder>[]).add(m),
      (m) => 'Army move: ${m.armyId} -> ${m.destinationProvinceId}',
      eventBus,
      onGameEvent,
    );
    filterOrderList<BuildUnitOrder>(
      playerId,
      builds,
      results,
      idxBox,
      (pid, b) =>
          buildByPlayer.putIfAbsent(pid, () => <BuildUnitOrder>[]).add(b),
      (b) => 'Build unit: ${b.unitType}',
      eventBus,
      onGameEvent,
    );
    filterOrderList<WorkOrder>(
      playerId,
      works,
      results,
      idxBox,
      (pid, w) => workByPlayer.putIfAbsent(pid, () => <WorkOrder>[]).add(w),
      (w) => 'Work order: ${w.target}',
      eventBus,
      onGameEvent,
    );

    if (diplo.isNotEmpty) {
      diploByPlayer[playerId] = List<DiplomaticOrder>.from(diplo);
    }
  }

  // Research, naval, and mission orders are not filtered here; shallow-copying
  // the outer map would not isolate inner lists anyway. Pass through references.
  final researchByPlayer = original.researchOrdersByPlayerId;
  final navalByPlayer = original.navalMoveOrdersByPlayerId;
  final missionByPlayer = original.navalMissionOrdersByPlayerId;

  return Orders(
    moveOrdersByPlayerId: moveByPlayer,
    armyMoveOrdersByPlayerId: armyMoveByPlayer,
    buildUnitOrdersByPlayerId: buildByPlayer,
    workOrdersByPlayerId: workByPlayer,
    diplomaticOrdersByPlayerId: diploByPlayer,
    researchOrdersByPlayerId: researchByPlayer,
    navalMoveOrdersByPlayerId: navalByPlayer,
    navalMissionOrdersByPlayerId: missionByPlayer,
  );
}
