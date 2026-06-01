import 'package:colonizethis_models/colonizethis_models.dart';

/// Order merge at turn resolution. SPEC/program/order-engine.md, ai-planner.md.
/// Merges per-player lists (human + AI) with precedence: human over AI for conflicting orders.
/// Merge runs at turn resolution; consumes order-engine output (per-player lists).

/// Merges human and AI orders with precedence (human over AI).
/// For conflicting orders (e.g. same unit, same slot): human wins.
/// Stable ordering: by player id, then order type.
Orders mergeOrderLists({
  required Orders humanOrders,
  Orders? aiOrders,
}) {
  if (aiOrders == null || _isEmpty(aiOrders)) return humanOrders;

  final merged = Orders(
    moveOrdersByPlayerId: _mergeMoveOrders(
      humanOrders.moveOrdersByPlayerId,
      aiOrders.moveOrdersByPlayerId,
    ),
    armyMoveOrdersByPlayerId: _mergeArmyMoveOrders(
      humanOrders.armyMoveOrdersByPlayerId,
      aiOrders.armyMoveOrdersByPlayerId,
    ),
    buildUnitOrdersByPlayerId: _mergeBuildOrders(
      humanOrders.buildUnitOrdersByPlayerId,
      aiOrders.buildUnitOrdersByPlayerId,
    ),
    workOrdersByPlayerId: _mergeWorkOrders(
      humanOrders.workOrdersByPlayerId,
      aiOrders.workOrdersByPlayerId,
    ),
    diplomaticOrdersByPlayerId: _mergeDiplomaticOrders(
      humanOrders.diplomaticOrdersByPlayerId,
      aiOrders.diplomaticOrdersByPlayerId,
    ),
    researchOrdersByPlayerId: _mergeResearchOrders(
      humanOrders.researchOrdersByPlayerId,
      aiOrders.researchOrdersByPlayerId,
    ),
    navalMoveOrdersByPlayerId: _mergeNavalMoveOrders(
      humanOrders.navalMoveOrdersByPlayerId,
      aiOrders.navalMoveOrdersByPlayerId,
    ),
    navalMissionOrdersByPlayerId: _mergeNavalMissionOrders(
      humanOrders.navalMissionOrdersByPlayerId,
      aiOrders.navalMissionOrdersByPlayerId,
    ),
    tradeOrdersByPlayerId: _mergeTradeOrders(
      humanOrders.tradeOrdersByPlayerId,
      aiOrders.tradeOrdersByPlayerId,
    ),
  );
  return merged;
}

bool _isEmpty(Orders o) =>
    o.moveOrdersByPlayerId.isEmpty &&
    o.armyMoveOrdersByPlayerId.isEmpty &&
    o.buildUnitOrdersByPlayerId.isEmpty &&
    o.workOrdersByPlayerId.isEmpty &&
    o.diplomaticOrdersByPlayerId.isEmpty &&
    o.researchOrdersByPlayerId.isEmpty &&
    o.navalMoveOrdersByPlayerId.isEmpty &&
    o.navalMissionOrdersByPlayerId.isEmpty &&
    o.tradeOrdersByPlayerId.isEmpty;

Map<String, List<MoveOrder>> _mergeMoveOrders(
  Map<String, List<MoveOrder>> human,
  Map<String, List<MoveOrder>> ai,
) =>
    _mergeByConflictKey(human, ai, (o) => o.unitId);

Map<String, List<ArmyMoveOrder>> _mergeArmyMoveOrders(
  Map<String, List<ArmyMoveOrder>> human,
  Map<String, List<ArmyMoveOrder>> ai,
) =>
    _mergeByConflictKey(human, ai, (o) => o.armyId);

Map<String, List<BuildUnitOrder>> _mergeBuildOrders(
  Map<String, List<BuildUnitOrder>> human,
  Map<String, List<BuildUnitOrder>> ai,
) {
  final allPlayerIds = {...human.keys, ...ai.keys}.toList()..sort();
  final result = <String, List<BuildUnitOrder>>{};
  for (final playerId in allPlayerIds) {
    final humanList = human[playerId] ?? [];
    final aiList = ai[playerId] ?? [];
    final humanCount = humanList.length;
    final aiCount = aiList.length;
    final merged = [...humanList];
    for (var i = 0; i < aiCount && merged.length < humanCount + aiCount; i++) {
      merged.add(aiList[i]);
    }
    if (merged.isNotEmpty) result[playerId] = merged;
  }
  return result;
}

Map<String, List<WorkOrder>> _mergeWorkOrders(
  Map<String, List<WorkOrder>> human,
  Map<String, List<WorkOrder>> ai,
) =>
    _mergeByConflictKey(human, ai, (o) => o.unitId);

Map<String, List<DiplomaticOrder>> _mergeDiplomaticOrders(
  Map<String, List<DiplomaticOrder>> human,
  Map<String, List<DiplomaticOrder>> ai,
) {
  final allPlayerIds = {...human.keys, ...ai.keys}.toList()..sort();
  final result = <String, List<DiplomaticOrder>>{};
  final humanTargetsWithType = <String>{};
  for (final playerId in allPlayerIds) {
    final humanList = human[playerId] ?? [];
    final aiList = ai[playerId] ?? [];
    humanTargetsWithType.clear();
    for (final o in humanList) {
      humanTargetsWithType.add('${o.type.name}|${o.targetFactionId}');
    }
    final merged = [...humanList];
    for (final o in aiList) {
      final key = '${o.type.name}|${o.targetFactionId}';
      if (!humanTargetsWithType.contains(key)) {
        merged.add(o);
        humanTargetsWithType.add(key);
      }
    }
    if (merged.isNotEmpty) result[playerId] = merged;
  }
  return result;
}

Map<String, List<ResearchOrder>> _mergeResearchOrders(
  Map<String, List<ResearchOrder>> human,
  Map<String, List<ResearchOrder>> ai,
) {
  final allPlayerIds = {...human.keys, ...ai.keys}.toList()..sort();
  final result = <String, List<ResearchOrder>>{};
  for (final playerId in allPlayerIds) {
    final humanList = human[playerId] ?? [];
    final aiList = ai[playerId] ?? [];
    if (humanList.isNotEmpty) {
      result[playerId] = humanList;
    } else if (aiList.isNotEmpty) {
      result[playerId] = aiList;
    }
  }
  return result;
}

Map<String, List<NavalMoveOrder>> _mergeNavalMoveOrders(
  Map<String, List<NavalMoveOrder>> human,
  Map<String, List<NavalMoveOrder>> ai,
) =>
    _mergeByConflictKey(human, ai, (o) => o.fleetId);

Map<String, List<NavalMissionOrder>> _mergeNavalMissionOrders(
  Map<String, List<NavalMissionOrder>> human,
  Map<String, List<NavalMissionOrder>> ai,
) =>
    _mergeByConflictKey(human, ai, (o) => o.fleetId);

/// Human trade orders for a player replace AI trade for that player (Refs
/// #2994 F7, #2924 world-market path).
Map<String, List<TradeOrder>> _mergeTradeOrders(
  Map<String, List<TradeOrder>> human,
  Map<String, List<TradeOrder>> ai,
) {
  final allPlayerIds = {...human.keys, ...ai.keys}.toList()..sort();
  final result = <String, List<TradeOrder>>{};
  for (final playerId in allPlayerIds) {
    final humanList = human[playerId] ?? [];
    final aiList = ai[playerId] ?? [];
    if (humanList.isNotEmpty) {
      result[playerId] = humanList;
    } else if (aiList.isNotEmpty) {
      result[playerId] = aiList;
    }
  }
  return result;
}

Map<String, List<T>> _mergeByConflictKey<T>(
  Map<String, List<T>> human,
  Map<String, List<T>> ai,
  String Function(T) conflictKey,
) {
  final allPlayerIds = {...human.keys, ...ai.keys}.toList()..sort();
  final result = <String, List<T>>{};
  final humanKeys = <String>{};
  for (final playerId in allPlayerIds) {
    final humanList = human[playerId] ?? [];
    final aiList = ai[playerId] ?? [];
    humanKeys.clear();
    for (final o in humanList) {
      humanKeys.add(conflictKey(o));
    }
    final merged = List<T>.from(humanList);
    for (final o in aiList) {
      if (!humanKeys.contains(conflictKey(o))) {
        merged.add(o);
        humanKeys.add(conflictKey(o));
      }
    }
    if (merged.isNotEmpty) result[playerId] = merged;
  }
  return result;
}
