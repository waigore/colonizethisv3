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
  );
  return merged;
}

bool _isEmpty(Orders o) =>
    o.moveOrdersByPlayerId.isEmpty &&
    o.buildUnitOrdersByPlayerId.isEmpty &&
    o.workOrdersByPlayerId.isEmpty &&
    o.diplomaticOrdersByPlayerId.isEmpty &&
    o.researchOrdersByPlayerId.isEmpty &&
    o.navalMoveOrdersByPlayerId.isEmpty &&
    o.navalMissionOrdersByPlayerId.isEmpty;

Map<String, List<MoveOrder>> _mergeMoveOrders(
  Map<String, List<MoveOrder>> human,
  Map<String, List<MoveOrder>> ai,
) {
  final allPlayerIds = {...human.keys, ...ai.keys}.toList()..sort();
  final result = <String, List<MoveOrder>>{};
  final humanUnitsWithMove = <String>{};
  for (final playerId in allPlayerIds) {
    final humanList = human[playerId] ?? [];
    final aiList = ai[playerId] ?? [];
    humanUnitsWithMove.clear();
    for (final o in humanList) {
      humanUnitsWithMove.add(o.unitId);
    }
    final merged = [...humanList];
    for (final o in aiList) {
      if (!humanUnitsWithMove.contains(o.unitId)) {
        merged.add(o);
        humanUnitsWithMove.add(o.unitId);
      }
    }
    if (merged.isNotEmpty) result[playerId] = merged;
  }
  return result;
}

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
) {
  final allPlayerIds = {...human.keys, ...ai.keys}.toList()..sort();
  final result = <String, List<WorkOrder>>{};
  final humanUnitsWithWork = <String>{};
  for (final playerId in allPlayerIds) {
    final humanList = human[playerId] ?? [];
    final aiList = ai[playerId] ?? [];
    humanUnitsWithWork.clear();
    for (final o in humanList) {
      humanUnitsWithWork.add(o.unitId);
    }
    final merged = [...humanList];
    for (final o in aiList) {
      if (!humanUnitsWithWork.contains(o.unitId)) {
        merged.add(o);
        humanUnitsWithWork.add(o.unitId);
      }
    }
    if (merged.isNotEmpty) result[playerId] = merged;
  }
  return result;
}

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
) {
  final allPlayerIds = {...human.keys, ...ai.keys}.toList()..sort();
  final result = <String, List<NavalMoveOrder>>{};
  final humanFleetIds = <String>{};
  for (final playerId in allPlayerIds) {
    final humanList = human[playerId] ?? [];
    final aiList = ai[playerId] ?? [];
    humanFleetIds.clear();
    for (final o in humanList) {
      humanFleetIds.add(o.fleetId);
    }
    final merged = [...humanList];
    for (final o in aiList) {
      if (!humanFleetIds.contains(o.fleetId)) {
        merged.add(o);
        humanFleetIds.add(o.fleetId);
      }
    }
    if (merged.isNotEmpty) result[playerId] = merged;
  }
  return result;
}

Map<String, List<NavalMissionOrder>> _mergeNavalMissionOrders(
  Map<String, List<NavalMissionOrder>> human,
  Map<String, List<NavalMissionOrder>> ai,
) {
  final allPlayerIds = {...human.keys, ...ai.keys}.toList()..sort();
  final result = <String, List<NavalMissionOrder>>{};
  final humanFleetIds = <String>{};
  for (final playerId in allPlayerIds) {
    final humanList = human[playerId] ?? [];
    final aiList = ai[playerId] ?? [];
    humanFleetIds.clear();
    for (final o in humanList) {
      humanFleetIds.add(o.fleetId);
    }
    final merged = [...humanList];
    for (final o in aiList) {
      if (!humanFleetIds.contains(o.fleetId)) {
        merged.add(o);
        humanFleetIds.add(o.fleetId);
      }
    }
    if (merged.isNotEmpty) result[playerId] = merged;
  }
  return result;
}
