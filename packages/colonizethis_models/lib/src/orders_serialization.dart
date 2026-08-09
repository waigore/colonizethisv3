/// Orders JSON encode/decode helpers extracted so [Orders] stays under the
/// models 400 physical-line cap (Refs #4136). Public API remains
/// [Orders.toJson] / [Orders.fromJson] on the aggregate.
library;

import 'diplomacy.dart';
import 'orders.dart';
import 'world_market.dart';

Map<String, dynamic> encodeOrdersToJson(Orders orders) {
  return {
    'moveOrdersByPlayerId': orders.moveOrdersByPlayerId.map(
      (playerId, orderList) =>
          MapEntry(playerId, orderList.map((o) => o.toJson()).toList()),
    ),
    if (orders.armyMoveOrdersByPlayerId.isNotEmpty)
      'armyMoveOrdersByPlayerId': orders.armyMoveOrdersByPlayerId.map(
        (playerId, orderList) =>
            MapEntry(playerId, orderList.map((o) => o.toJson()).toList()),
      ),
    'buildUnitOrdersByPlayerId': orders.buildUnitOrdersByPlayerId.map(
      (playerId, orderList) =>
          MapEntry(playerId, orderList.map((o) => o.toJson()).toList()),
    ),
    'workOrdersByPlayerId': orders.workOrdersByPlayerId.map(
      (playerId, orderList) =>
          MapEntry(playerId, orderList.map((o) => o.toJson()).toList()),
    ),
    if (orders.diplomaticOrdersByPlayerId.isNotEmpty)
      'diplomaticOrdersByPlayerId': orders.diplomaticOrdersByPlayerId.map(
        (playerId, orderList) =>
            MapEntry(playerId, orderList.map((o) => o.toJson()).toList()),
      ),
    if (orders.researchOrdersByPlayerId.isNotEmpty)
      'researchOrdersByPlayerId': orders.researchOrdersByPlayerId.map(
        (playerId, orderList) =>
            MapEntry(playerId, orderList.map((o) => o.toJson()).toList()),
      ),
    if (orders.navalMoveOrdersByPlayerId.isNotEmpty)
      'navalMoveOrdersByPlayerId': orders.navalMoveOrdersByPlayerId.map(
        (playerId, orderList) =>
            MapEntry(playerId, orderList.map((o) => o.toJson()).toList()),
      ),
    if (orders.navalMissionOrdersByPlayerId.isNotEmpty)
      'navalMissionOrdersByPlayerId': orders.navalMissionOrdersByPlayerId.map(
        (playerId, orderList) =>
            MapEntry(playerId, orderList.map((o) => o.toJson()).toList()),
      ),
    if (orders.recruitWorkerOrdersByPlayerId.isNotEmpty)
      'recruitWorkerOrdersByPlayerId': orders.recruitWorkerOrdersByPlayerId.map(
        (playerId, orderList) =>
            MapEntry(playerId, orderList.map((o) => o.toJson()).toList()),
      ),
    if (orders.tradeOrdersByPlayerId.isNotEmpty)
      'tradeOrdersByPlayerId': orders.tradeOrdersByPlayerId.map(
        (playerId, orderList) =>
            MapEntry(playerId, orderList.map((o) => o.toJson()).toList()),
      ),
  };
}

Map<String, List<T>> _decodeOrderMap<T>(
  Map<String, dynamic> json,
  String key,
  T Function(Map<String, dynamic>) decode,
) {
  final raw = json[key] as Map<dynamic, dynamic>? ?? {};
  final byPlayerId = <String, List<T>>{};
  raw.forEach((mapKey, value) {
    final playerId = mapKey.toString();
    final list = (value as List<dynamic>? ?? [])
        .map(
          (e) => decode(
            Map<String, dynamic>.from(e as Map<Object?, Object?>),
          ),
        )
        .toList();
    byPlayerId[playerId] = list;
  });
  return byPlayerId;
}

Orders decodeOrdersFromJson(Map<String, dynamic> json) {
  return Orders(
    moveOrdersByPlayerId: _decodeOrderMap(json, 'moveOrdersByPlayerId', MoveOrder.fromJson),
    armyMoveOrdersByPlayerId:
        _decodeOrderMap(json, 'armyMoveOrdersByPlayerId', ArmyMoveOrder.fromJson),
    buildUnitOrdersByPlayerId:
        _decodeOrderMap(json, 'buildUnitOrdersByPlayerId', BuildUnitOrder.fromJson),
    workOrdersByPlayerId: _decodeOrderMap(json, 'workOrdersByPlayerId', WorkOrder.fromJson),
    recruitWorkerOrdersByPlayerId: _decodeOrderMap(
      json,
      'recruitWorkerOrdersByPlayerId',
      RecruitWorkerOrder.fromJson,
    ),
    diplomaticOrdersByPlayerId:
        _decodeOrderMap(json, 'diplomaticOrdersByPlayerId', DiplomaticOrder.fromJson),
    researchOrdersByPlayerId:
        _decodeOrderMap(json, 'researchOrdersByPlayerId', ResearchOrder.fromJson),
    navalMoveOrdersByPlayerId:
        _decodeOrderMap(json, 'navalMoveOrdersByPlayerId', NavalMoveOrder.fromJson),
    navalMissionOrdersByPlayerId:
        _decodeOrderMap(json, 'navalMissionOrdersByPlayerId', NavalMissionOrder.fromJson),
    tradeOrdersByPlayerId: _decodeOrderMap(json, 'tradeOrdersByPlayerId', TradeOrder.fromJson),
  );
}
