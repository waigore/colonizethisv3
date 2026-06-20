import 'package:colonizethis_models/colonizethis_models.dart';

/// Order merge at turn resolution. SPEC/program/order-engine.md, ai-planner.md.
/// Merges per-player lists (human + AI) with precedence: human over AI for conflicting orders.
/// Merge runs at turn resolution; consumes order-engine output (per-player lists).

/// Merges human and AI orders with precedence (human over AI).
/// For conflicting orders (e.g. same unit, same slot): human wins.
/// Stable ordering: by player id, then order type.
///
/// Each [Orders] field uses an explicit [_mergeOrders] call because the record
/// carries ten distinct order-list types with different merge strategies and
/// conflict keys — a descriptor loop would need heterogeneous generics or
/// dynamic casts with no net clarity gain (Refs #3500 Phase 5).
Orders mergeOrderLists({
  required Orders humanOrders,
  Orders? aiOrders,
}) {
  if (aiOrders == null || _isEmpty(aiOrders)) return humanOrders;

  final merged = Orders(
    moveOrdersByPlayerId: _mergeOrders(
      humanOrders.moveOrdersByPlayerId,
      aiOrders.moveOrdersByPlayerId,
      MergeStrategy.conflictKey,
      keyOf: (o) => o.unitId,
    ),
    armyMoveOrdersByPlayerId: _mergeOrders(
      humanOrders.armyMoveOrdersByPlayerId,
      aiOrders.armyMoveOrdersByPlayerId,
      MergeStrategy.conflictKey,
      keyOf: (o) => o.armyId,
    ),
    buildUnitOrdersByPlayerId: _mergeOrders(
      humanOrders.buildUnitOrdersByPlayerId,
      aiOrders.buildUnitOrdersByPlayerId,
      MergeStrategy.countCap,
    ),
    workOrdersByPlayerId: _mergeOrders(
      humanOrders.workOrdersByPlayerId,
      aiOrders.workOrdersByPlayerId,
      MergeStrategy.conflictKey,
      keyOf: (o) => o.unitId,
    ),
    diplomaticOrdersByPlayerId: _mergeOrders(
      humanOrders.diplomaticOrdersByPlayerId,
      aiOrders.diplomaticOrdersByPlayerId,
      MergeStrategy.compositeKey,
      keyOf: (o) => '${o.type.name}|${o.targetFactionId}',
    ),
    researchOrdersByPlayerId: _mergeOrders(
      humanOrders.researchOrdersByPlayerId,
      aiOrders.researchOrdersByPlayerId,
      MergeStrategy.replacePerPlayer,
    ),
    navalMoveOrdersByPlayerId: _mergeOrders(
      humanOrders.navalMoveOrdersByPlayerId,
      aiOrders.navalMoveOrdersByPlayerId,
      MergeStrategy.conflictKey,
      keyOf: (o) => o.fleetId,
    ),
    navalMissionOrdersByPlayerId: _mergeOrders(
      humanOrders.navalMissionOrdersByPlayerId,
      aiOrders.navalMissionOrdersByPlayerId,
      MergeStrategy.conflictKey,
      keyOf: (o) => o.fleetId,
    ),
    tradeOrdersByPlayerId: _mergeOrders(
      humanOrders.tradeOrdersByPlayerId,
      aiOrders.tradeOrdersByPlayerId,
      MergeStrategy.replacePerPlayer,
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

/// Per-player merge strategy for one order-type list.
///
/// All strategies merge per `playerId` with human precedence; they differ only
/// in how an AI order is admitted alongside the human list for that player.
enum MergeStrategy {
  /// AI order admitted only when its [keyOf] value does not collide with any
  /// human order for the same player (single-field conflict key; human wins).
  /// Used by move, army-move, work, and naval move/mission orders.
  conflictKey,

  /// Same dedup semantics as [conflictKey] but the [keyOf] value is a composite
  /// of several fields (e.g. `type.name|targetFactionId`). Used by diplomatic
  /// orders, where a player may hold one order per (type, target) pair.
  compositeKey,

  /// AI orders appended after the human list for the same player, capped at
  /// `humanCount + aiCount` total. Used by build orders (no conflict key:
  /// human and AI builds coexist up to the combined count).
  countCap,

  /// The human list replaces the AI list wholesale per player: human list wins
  /// when non-empty, otherwise the AI list is used. Used by research and trade
  /// orders (Refs #2994 F7, #2924 world-market path).
  replacePerPlayer,
}

/// Unified per-order-type merge. Combines human + AI per-player lists with
/// human precedence according to [strategy].
///
/// [keyOf] is required for [MergeStrategy.conflictKey] and
/// [MergeStrategy.compositeKey] and ignored otherwise.
Map<String, List<T>> _mergeOrders<T>(
  Map<String, List<T>> human,
  Map<String, List<T>> ai,
  MergeStrategy strategy, {
  String Function(T)? keyOf,
}) {
  final allPlayerIds = {...human.keys, ...ai.keys}.toList()..sort();
  final result = <String, List<T>>{};
  final seenKeys = <String>{};
  for (final playerId in allPlayerIds) {
    final humanList = human[playerId] ?? const [];
    final aiList = ai[playerId] ?? const [];
    final merged = _mergeForPlayer(
      humanList,
      aiList,
      strategy,
      keyOf,
      seenKeys,
    );
    if (merged.isNotEmpty) result[playerId] = merged;
  }
  return result;
}

List<T> _mergeForPlayer<T>(
  List<T> humanList,
  List<T> aiList,
  MergeStrategy strategy,
  String Function(T)? keyOf,
  Set<String> seenKeys,
) {
  switch (strategy) {
    case MergeStrategy.replacePerPlayer:
      if (humanList.isNotEmpty) return humanList;
      if (aiList.isNotEmpty) return aiList;
      return const [];
    case MergeStrategy.countCap:
      final cap = humanList.length + aiList.length;
      final merged = [...humanList];
      for (var i = 0; i < aiList.length && merged.length < cap; i++) {
        merged.add(aiList[i]);
      }
      return merged;
    case MergeStrategy.conflictKey:
    case MergeStrategy.compositeKey:
      final key = keyOf!;
      seenKeys.clear();
      for (final o in humanList) {
        seenKeys.add(key(o));
      }
      final merged = List<T>.from(humanList);
      for (final o in aiList) {
        final k = key(o);
        if (!seenKeys.contains(k)) {
          merged.add(o);
          seenKeys.add(k);
        }
      }
      return merged;
  }
}
