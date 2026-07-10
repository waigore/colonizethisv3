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
    eventSink: config.eventSink,
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

class _TurnTraceSession {
  _TurnTraceSession({required this.startedAtUtc});

  final DateTime startedAtUtc;
  final List<TurnTracePhaseTrace> phases = <TurnTracePhaseTrace>[];
  final TurnTraceRuntime turnTraceRuntime = TurnTraceRuntime();
  List<TurnTraceAiSection>? aiTraceSections;
}
