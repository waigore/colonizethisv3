import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show pendingMoveOrderForUnit, projectedCivilianTileKey;
import 'package:colonizethis_world/colonizethis_world.dart'
    show WorldStateProvinceLookup, WorldStateUnitLookup;

/// Returns whether [prefixedProvinceId] (`regionId|localProvinceId`) is not
/// owned by [humanPlayerId].
bool isForeignProvinceForPlayer({
  required Game game,
  required String prefixedProvinceId,
  required String humanPlayerId,
}) {
  final province = game.worldState.tryGetProvince(prefixedProvinceId);
  if (province == null) return false;
  return province.ownerId != humanPlayerId;
}

/// Counts human-owned Spies whose projected tile (draft move/work aware) lies
/// in [prefixedProvinceId].
int countOwnSpiesProjectedInProvince({
  required Game game,
  required Orders orders,
  required String humanPlayerId,
  required String prefixedProvinceId,
}) {
  var count = 0;
  for (final unit in _humanSpies(game, humanPlayerId)) {
    final tileKey = projectedCivilianTileKey(
      unit: unit,
      playerId: humanPlayerId,
      orders: orders,
    );
    if (tileKey == null) continue;
    final provinceFullId = Unit.provinceIdFromTileKey(tileKey);
    if (provinceFullId == null) continue;
    if (provinceFullId == prefixedProvinceId) {
      count++;
    }
  }
  return count;
}

/// True when committing [newDestinationTileKey] for [spyUnitId] would leave
/// a foreign province with zero own Spies projected there after the move.
bool spyLeaveIntelWarningNeeded({
  required Game game,
  required Orders orders,
  required String humanPlayerId,
  required String spyUnitId,
  required String newDestinationTileKey,
}) {
  final spy = _findUnit(game, spyUnitId);
  if (spy == null || spy.type != kUnitTypeSpy) return false;

  final currentTile = projectedCivilianTileKey(
    unit: spy,
    playerId: humanPlayerId,
    orders: orders,
  );
  if (currentTile == null) return false;
  final provinceFullId = Unit.provinceIdFromTileKey(currentTile);
  if (provinceFullId == null) return false;
  if (!isForeignProvinceForPlayer(
    game: game,
    prefixedProvinceId: provinceFullId,
    humanPlayerId: humanPlayerId,
  )) {
    return false;
  }

  final ordersAfterMove = applySpyRelocateMoveToOrders(
    orders: orders,
    humanPlayerId: humanPlayerId,
    spyUnitId: spyUnitId,
    destinationTileKey: newDestinationTileKey,
  );
  return countOwnSpiesProjectedInProvince(
        game: game,
        orders: ordersAfterMove,
        humanPlayerId: humanPlayerId,
        prefixedProvinceId: provinceFullId,
      ) ==
      0;
}

/// Stages [destinationTileKey] as the draft move for [spyUnitId], replacing any
/// prior draft move/work for that unit (xor rule).
Orders applySpyRelocateMoveToOrders({
  required Orders orders,
  required String humanPlayerId,
  required String spyUnitId,
  required String destinationTileKey,
}) {
  final nextMoves = List<MoveOrder>.from(
    orders.moveOrdersByPlayerId[humanPlayerId] ?? const <MoveOrder>[],
  )..removeWhere((o) => o.unitId == spyUnitId);
  nextMoves.add(
    MoveOrder(unitId: spyUnitId, destinationTileKey: destinationTileKey),
  );
  final nextWorks = List<WorkOrder>.from(
    orders.workOrdersByPlayerId[humanPlayerId] ?? const <WorkOrder>[],
  )..removeWhere((o) => o.unitId == spyUnitId);
  return orders.copyWith(
    moveOrdersByPlayerId: {
      ...orders.moveOrdersByPlayerId,
      humanPlayerId: nextMoves,
    },
    workOrdersByPlayerId: {
      ...orders.workOrdersByPlayerId,
      humanPlayerId: nextWorks,
    },
  );
}

/// Removes a pending draft move for [unitId], if any.
Orders removePendingCivilianMoveForUnit({
  required Orders orders,
  required String humanPlayerId,
  required String unitId,
}) {
  final prior =
      orders.moveOrdersByPlayerId[humanPlayerId] ?? const <MoveOrder>[];
  final next = [
    for (final MoveOrder o in prior)
      if (o.unitId != unitId) o,
  ];
  if (next.length == prior.length) return orders;
  return orders.copyWith(
    moveOrdersByPlayerId: {
      ...orders.moveOrdersByPlayerId,
      humanPlayerId: next,
    },
  );
}

MoveOrder? pendingCivilianMoveForUnit({
  required Orders orders,
  required String humanPlayerId,
  required String unitId,
}) {
  return pendingMoveOrderForUnit(
    playerId: humanPlayerId,
    unitId: unitId,
    orders: orders,
  );
}

List<Unit> _humanSpies(Game game, String humanPlayerId) {
  return [
    for (final u in game.worldState.allUnitsById.values)
      if (u.ownerId == humanPlayerId && u.type == kUnitTypeSpy) u,
  ];
}

Unit? _findUnit(Game game, String unitId) =>
    game.worldState.tryGetUnitById(unitId);
