part of 'game_service.dart';

TurnResolutionResult _gameServiceResolveTurnWithTrace(
  GameService service, {
  required Game game,
  List<TurnTraceAiSection>? aiTraceSections,
  required TurnResolverConfig config,
}) {
  if (!service._turnTraceEnabled) {
    return resolveTurnForGameWithConfig(game: game, config: config);
  }
  final session = service._turnTraceSessionsByGameId.putIfAbsent(
    game.id,
    () => _TurnTraceSession(startedAtUtc: DateTime.now().toUtc()),
  );
  if (aiTraceSections != null) {
    session.aiTraceSections = List<TurnTraceAiSection>.unmodifiable(
      aiTraceSections,
    );
  }
  final tracedConfig = TurnResolverConfig(
    topology: config.topology,
    orders: config.orders,
    tileMapByRegion: config.tileMapByRegion,
    topologyByRegion: config.topologyByRegion,
    extractedByPlayerId: config.extractedByPlayerId,
    defaultAssignments: config.defaultAssignments,
    defaultAssignmentsByPlayerId: config.defaultAssignmentsByPlayerId,
    eventBus: config.eventBus,
    onDialogue: config.onDialogue,
    onGameEvent: config.onGameEvent,
    onProductionComplete: config.onProductionComplete,
    startFromPhase: config.startFromPhase,
    overtureDecisions: config.overtureDecisions,
    interventionDecisions: config.interventionDecisions,
    callToArmsDecisions: config.callToArmsDecisions,
    phaseHandlerOverrides: config.phaseHandlerOverrides,
    onPhaseProgress: config.onPhaseProgress,
    onTurnTracePhase: session.phases.add,
    turnTraceRuntime: session.turnTraceRuntime,
  );
  final result = resolveTurnForGameWithConfig(
    game: game,
    config: tracedConfig,
  );
  if (result is TurnResolutionComplete) {
    final exportedAiTraceSections =
        session.aiTraceSections ??
        _gameServiceBuildAiTraceSections(
          gameAtResolutionStart: game,
          orders: config.orders,
        );
    _gameServiceExportTurnTrace(
      service,
      gameAtResolutionStart: game,
      turnEndState: result.game,
      phases: session.phases,
      turnStartAt: session.startedAtUtc,
      ai: exportedAiTraceSections,
    );
    service._turnTraceSessionsByGameId.remove(game.id);
  }
  return result;
}

void _gameServiceExportTurnTrace(
  GameService service, {
  required Game gameAtResolutionStart,
  required Game turnEndState,
  required List<TurnTracePhaseTrace> phases,
  required DateTime turnStartAt,
  required List<TurnTraceAiSection> ai,
}) {
  final now = DateTime.now().toUtc();
  final document = TurnTraceMergedDocument(
    schemaVersion: kTurnTraceSchemaVersionV1,
    meta: TurnTraceMeta(
      gameId: gameAtResolutionStart.id,
      turnNumber: gameAtResolutionStart.worldState.turnState.turnNumber,
      traceEnabled: true,
      source: 'app',
      exportedAt: now.toIso8601String(),
      turnStartAt: turnStartAt.toIso8601String(),
      turnEndAt: now.toIso8601String(),
    ),
    ai: ai,
    turnResolution: TurnTraceResolutionSection(
      phases: List<TurnTracePhaseTrace>.unmodifiable(phases),
    ),
  );
  TurnTraceFileExporter(rootDirectory: service.turnTraceRootDirectory)
      .export(document)
      .then((file) {
        packageLogger('logic').d(
          'logic: turn_trace_exported gameId=${gameAtResolutionStart.id} '
          'turn=${gameAtResolutionStart.worldState.turnState.turnNumber} '
          'nextTurn=${turnEndState.worldState.turnState.turnNumber} '
          'path=${file.path}',
        );
      })
      .catchError((Object error, StackTrace stackTrace) {
        packageLogger('logic').e(
          'logic: turn_trace_export_failed gameId=${gameAtResolutionStart.id}',
          error: error,
          stackTrace: stackTrace,
        );
      });
}

List<TurnTraceAiSection> _gameServiceBuildAiTraceSections({
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
    final ordersByDomain = _gameServiceOrderCountsByDomain(player.id, orders);
    final finalOrders = _gameServiceFinalAggregatedOrders(player.id, orders);
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
            'turnNumber':
                gameAtResolutionStart.worldState.turnState.turnNumber,
          },
        },
        thresholds: const <String, Object?>{
          'constants': <String, Object?>{},
          'derived': <String, Object?>{},
          'effective': <String, Object?>{},
          'gates': <Object?>[],
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

Map<String, Object?> _gameServiceOrderCountsByDomain(
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

List<Map<String, Object?>> _gameServiceFinalAggregatedOrders(
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
      in orders.buildUnitOrdersByPlayerId[playerId] ?? const <BuildUnitOrder>[]) {
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
      in orders.navalMoveOrdersByPlayerId[playerId] ?? const <NavalMoveOrder>[]) {
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

class _TurnTraceSession {
  _TurnTraceSession({required this.startedAtUtc});

  final DateTime startedAtUtc;
  final List<TurnTracePhaseTrace> phases = <TurnTracePhaseTrace>[];
  final TurnTraceRuntime turnTraceRuntime = TurnTraceRuntime();
  List<TurnTraceAiSection>? aiTraceSections;
}
