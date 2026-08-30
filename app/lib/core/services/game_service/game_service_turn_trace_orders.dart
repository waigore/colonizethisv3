import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

List<TurnTraceAiSection> gameServiceBuildAiTraceSections({
  required Game gameAtResolutionStart,
  required Orders orders,
}) {
  final aiPlayers = gameAtResolutionStart.players
      .where(
        (player) => gameAtResolutionStart.aiControlByGpId[player.id] ?? false,
      )
      .toList(growable: false);
  if (aiPlayers.isEmpty) {
    return const <TurnTraceAiSection>[];
  }
  final sections = <TurnTraceAiSection>[];
  for (final player in aiPlayers) {
    final ordersByDomain = gameServiceOrderCountsByDomain(player.id, orders);
    final finalOrders = gameServiceFinalAggregatedOrders(player.id, orders);
    sections.add(
      TurnTraceAiSection(
        factionId: player.id,
        state: <String, Object?>{
          'winningCandidate': <String, Object?>{
            'selection': 'submitted_orders',
            'orderCount': finalOrders.length,
          },
          'topAlternates': const <Object?>[],
          'aggregates': <String, Object?>{
            'totalOrders': finalOrders.length,
            'ordersByDomain': ordersByDomain,
          },
          'decisionContext': <String, Object?>{
            'turnNumber': gameAtResolutionStart.worldState.turnState.turnNumber,
          },
        },
        thresholds: const <String, Object?>{
          'constants': <String, Object?>{},
          'derived': <String, Object?>{},
          'effective': <String, Object?>{},
          'gates': const <Object?>[],
        },
        outcome: <String, Object?>{
          'domainOutputs': ordersByDomain,
          'finalAggregatedOrders': finalOrders,
          'emittedOrderCount': finalOrders.length,
        },
      ),
    );
  }
  return List<TurnTraceAiSection>.unmodifiable(sections);
}

Map<String, Object?> gameServiceOrderCountsByDomain(
  String playerId,
  Orders orders,
) {
  return <String, Object?>{
    'move':
        (orders.moveOrdersByPlayerId[playerId] ?? const <MoveOrder>[]).length,
    'armyMove':
        (orders.armyMoveOrdersByPlayerId[playerId] ?? const <ArmyMoveOrder>[])
            .length,
    'build':
        (orders.buildUnitOrdersByPlayerId[playerId] ?? const <BuildUnitOrder>[])
            .length,
    'work':
        (orders.workOrdersByPlayerId[playerId] ?? const <WorkOrder>[]).length,
    'diplomatic':
        (orders.diplomaticOrdersByPlayerId[playerId] ??
                const <DiplomaticOrder>[])
            .length,
    'research':
        (orders.researchOrdersByPlayerId[playerId] ?? const <ResearchOrder>[])
            .length,
    'navalMove':
        (orders.navalMoveOrdersByPlayerId[playerId] ?? const <NavalMoveOrder>[])
            .length,
    'navalMission':
        (orders.navalMissionOrdersByPlayerId[playerId] ??
                const <NavalMissionOrder>[])
            .length,
  };
}

List<Map<String, Object?>> gameServiceFinalAggregatedOrders(
  String playerId,
  Orders orders,
) {
  final aggregated = <Map<String, Object?>>[];
  for (final order
      in orders.moveOrdersByPlayerId[playerId] ?? const <MoveOrder>[]) {
    aggregated.add(<String, Object?>{
      'domain': 'move',
      'unitId': order.unitId,
      'destinationTileKey': order.destinationTileKey,
    });
  }
  for (final order
      in orders.armyMoveOrdersByPlayerId[playerId] ?? const <ArmyMoveOrder>[]) {
    aggregated.add(<String, Object?>{
      'domain': 'armyMove',
      'armyId': order.armyId,
      'destinationProvinceId': order.destinationProvinceId,
    });
  }
  for (final order
      in orders.buildUnitOrdersByPlayerId[playerId] ??
          const <BuildUnitOrder>[]) {
    aggregated.add(<String, Object?>{
      'domain': 'build',
      'unitType': order.unitType,
      'spawnProvinceId': order.spawnProvinceId,
    });
  }
  for (final order
      in orders.workOrdersByPlayerId[playerId] ?? const <WorkOrder>[]) {
    aggregated.add(<String, Object?>{
      'domain': 'work',
      'unitId': order.unitId,
      'targetTileKey': order.targetTileKey,
      'target': order.target,
    });
  }
  for (final order
      in orders.diplomaticOrdersByPlayerId[playerId] ??
          const <DiplomaticOrder>[]) {
    aggregated.add(<String, Object?>{
      'domain': 'diplomatic',
      'type': order.type.name,
      'targetFactionId': order.targetFactionId,
      if (order.amount != null) 'amount': order.amount,
    });
  }
  for (final order
      in orders.researchOrdersByPlayerId[playerId] ?? const <ResearchOrder>[]) {
    aggregated.add(<String, Object?>{
      'domain': 'research',
      'slotIndex': order.slotIndex,
      'techId': order.techId,
      'funding': order.funding.name,
    });
  }
  for (final order
      in orders.navalMoveOrdersByPlayerId[playerId] ??
          const <NavalMoveOrder>[]) {
    aggregated.add(<String, Object?>{
      'domain': 'navalMove',
      'fleetId': order.fleetId,
      'isDock': order.isDock,
      'destinationSeaZoneId': order.destinationSeaZoneId,
      'destinationPortProvinceId': order.destinationPortProvinceId,
    });
  }
  for (final order
      in orders.navalMissionOrdersByPlayerId[playerId] ??
          const <NavalMissionOrder>[]) {
    aggregated.add(<String, Object?>{
      'domain': 'navalMission',
      'fleetId': order.fleetId,
      'mission': order.mission,
      'targetProvinceId': order.targetProvinceId,
      'targetPortId': order.targetPortId,
    });
  }
  return List<Map<String, Object?>>.unmodifiable(aggregated);
}
