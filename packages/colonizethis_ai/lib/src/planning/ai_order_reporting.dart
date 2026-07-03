import 'package:colonizethis_models/colonizethis_models.dart';

class _OrderFamilyDescriptor {
  const _OrderFamilyDescriptor({
    required this.domain,
    required this.countFor,
    required this.aggregateFor,
  });

  final String domain;
  final int Function(Orders orders, String playerId) countFor;
  final Iterable<Map<String, Object?>> Function(
    Orders orders,
    String playerId,
  )
  aggregateFor;
}

final _orderFamilyDescriptors = <_OrderFamilyDescriptor>[
  _OrderFamilyDescriptor(
    domain: 'move',
    countFor: (orders, playerId) =>
        (orders.moveOrdersByPlayerId[playerId] ?? const <MoveOrder>[]).length,
    aggregateFor: (orders, playerId) sync* {
      for (final order
          in orders.moveOrdersByPlayerId[playerId] ?? const <MoveOrder>[]) {
        yield <String, Object?>{
          'domain': 'move',
          'unitId': order.unitId,
          'destinationTileKey': order.destinationTileKey,
        };
      }
    },
  ),
  _OrderFamilyDescriptor(
    domain: 'armyMove',
    countFor: (orders, playerId) =>
        (orders.armyMoveOrdersByPlayerId[playerId] ?? const <ArmyMoveOrder>[])
            .length,
    aggregateFor: (orders, playerId) sync* {
      for (final order
          in orders.armyMoveOrdersByPlayerId[playerId] ??
              const <ArmyMoveOrder>[]) {
        yield <String, Object?>{
          'domain': 'armyMove',
          'armyId': order.armyId,
          'destinationProvinceId': order.destinationProvinceId,
        };
      }
    },
  ),
  _OrderFamilyDescriptor(
    domain: 'build',
    countFor: (orders, playerId) =>
        (orders.buildUnitOrdersByPlayerId[playerId] ?? const <BuildUnitOrder>[])
            .length,
    aggregateFor: (orders, playerId) sync* {
      for (final order
          in orders.buildUnitOrdersByPlayerId[playerId] ??
              const <BuildUnitOrder>[]) {
        yield <String, Object?>{
          'domain': 'build',
          'unitType': order.unitType,
          'spawnProvinceId': order.spawnProvinceId,
        };
      }
    },
  ),
  _OrderFamilyDescriptor(
    domain: 'work',
    countFor: (orders, playerId) =>
        (orders.workOrdersByPlayerId[playerId] ?? const <WorkOrder>[]).length,
    aggregateFor: (orders, playerId) sync* {
      for (final order
          in orders.workOrdersByPlayerId[playerId] ?? const <WorkOrder>[]) {
        yield <String, Object?>{
          'domain': 'work',
          'unitId': order.unitId,
          'targetTileKey': order.targetTileKey,
          'target': order.target,
        };
      }
    },
  ),
  _OrderFamilyDescriptor(
    domain: 'diplomatic',
    countFor: (orders, playerId) =>
        (orders.diplomaticOrdersByPlayerId[playerId] ??
                const <DiplomaticOrder>[])
            .length,
    aggregateFor: (orders, playerId) sync* {
      for (final order
          in orders.diplomaticOrdersByPlayerId[playerId] ??
              const <DiplomaticOrder>[]) {
        yield <String, Object?>{
          'domain': 'diplomatic',
          'type': order.type.name,
          'targetFactionId': order.targetFactionId,
          if (order.amount != null) 'amount': order.amount,
        };
      }
    },
  ),
  _OrderFamilyDescriptor(
    domain: 'research',
    countFor: (orders, playerId) =>
        (orders.researchOrdersByPlayerId[playerId] ?? const <ResearchOrder>[])
            .length,
    aggregateFor: (orders, playerId) sync* {
      for (final order
          in orders.researchOrdersByPlayerId[playerId] ??
              const <ResearchOrder>[]) {
        yield <String, Object?>{
          'domain': 'research',
          'slotIndex': order.slotIndex,
          'techId': order.techId,
          'funding': order.funding.name,
        };
      }
    },
  ),
  _OrderFamilyDescriptor(
    domain: 'navalMove',
    countFor: (orders, playerId) =>
        (orders.navalMoveOrdersByPlayerId[playerId] ?? const <NavalMoveOrder>[])
            .length,
    aggregateFor: (orders, playerId) sync* {
      for (final order
          in orders.navalMoveOrdersByPlayerId[playerId] ??
              const <NavalMoveOrder>[]) {
        yield <String, Object?>{
          'domain': 'navalMove',
          'fleetId': order.fleetId,
          'isDock': order.isDock,
          'destinationSeaZoneId': order.destinationSeaZoneId,
          'destinationPortProvinceId': order.destinationPortProvinceId,
        };
      }
    },
  ),
  _OrderFamilyDescriptor(
    domain: 'navalMission',
    countFor: (orders, playerId) =>
        (orders.navalMissionOrdersByPlayerId[playerId] ??
                const <NavalMissionOrder>[])
            .length,
    aggregateFor: (orders, playerId) sync* {
      for (final order
          in orders.navalMissionOrdersByPlayerId[playerId] ??
              const <NavalMissionOrder>[]) {
        yield <String, Object?>{
          'domain': 'navalMission',
          'fleetId': order.fleetId,
          'mission': order.mission,
          'targetProvinceId': order.targetProvinceId,
          'targetPortId': order.targetPortId,
        };
      }
    },
  ),
  _OrderFamilyDescriptor(
    domain: 'trade',
    countFor: (orders, playerId) =>
        (orders.tradeOrdersByPlayerId[playerId] ?? const <TradeOrder>[]).length,
    aggregateFor: (orders, playerId) sync* {
      for (final order
          in orders.tradeOrdersByPlayerId[playerId] ?? const <TradeOrder>[]) {
        yield <String, Object?>{
          'domain': 'trade',
          'commodityId': order.commodityId,
          'type': order.type.name,
          'quantity': order.quantity,
          'priority': order.priority,
        };
      }
    },
  ),
];

Map<String, Object?> orderCountsByDomain(String playerId, Orders orders) {
  return <String, Object?>{
    for (final descriptor in _orderFamilyDescriptors)
      descriptor.domain: descriptor.countFor(orders, playerId),
  };
}

List<Map<String, Object?>> finalAggregatedOrders(
  String playerId,
  Orders orders,
) {
  final aggregated = <Map<String, Object?>>[];
  for (final descriptor in _orderFamilyDescriptors) {
    aggregated.addAll(descriptor.aggregateFor(orders, playerId));
  }
  return List<Map<String, Object?>>.unmodifiable(aggregated);
}
