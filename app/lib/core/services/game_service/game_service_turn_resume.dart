part of 'game_service.dart';

TurnResolutionResult _gameServiceRunTurnResolution(
  GameService service,
  Game current, {
  Orders? orders,
  Orders? aiOrders,
  List<TurnTraceAiSection>? aiTraceSections,
  MapTopology? topology,
  Map<String, TileMapResult>? tileMapByRegion,
  void Function(GameEvent)? onGameEvent,
}) {
  final mapData = service._requiredMapDataView(current.id);
  final topo = topology ?? mapData.combinedTopology;
  final tileMaps = tileMapByRegion ?? mapData.tileMapByRegion;
  final humanOrders = orders ?? const Orders();
  final resolvedOrders = aiOrders != null
      ? mergeOrderLists(humanOrders: humanOrders, aiOrders: aiOrders)
      : humanOrders;
  final result = _gameServiceResolveTurnWithTrace(
    service,
    game: current,
    aiTraceSections: aiTraceSections,
    config: TurnResolverConfig(
      topology: topo,
      orders: resolvedOrders,
      tileMapByRegion: tileMaps,
      eventSink: TurnEventSink(
        eventBus: service.logicEventBus,
        onGameEvent: onGameEvent,
      ),
    ),
  );
  _gameServiceEmitTurnResolutionEvents(service, result);
  return result;
}

TurnResolutionResult _gameServiceResumeTurnFromDiplomacy(
  GameService service,
  Game game,
  Orders orders, {
  void Function(GameEvent)? onGameEvent,
  List<CallToArmsDecision>? callToArmsDecisions,
  List<OvertureDecision>? overtureDecisions,
  List<FtpDecision>? ftpDecisions,
  List<InterventionDecision>? interventionDecisions,
}) {
  final mapData = service._requiredMapDataView(game.id);
  final result = _gameServiceResolveTurnWithTrace(
    service,
    game: game,
    config: TurnResolverConfig(
      topology: mapData.combinedTopology,
      orders: orders,
      tileMapByRegion: mapData.tileMapByRegion,
      eventSink: TurnEventSink(
        eventBus: service.logicEventBus,
        onGameEvent: onGameEvent,
      ),
      startFromPhase: TurnPhase.diplomacy,
      callToArmsDecisions: callToArmsDecisions,
      overtureDecisions: overtureDecisions,
      ftpDecisions: ftpDecisions,
      interventionDecisions: interventionDecisions,
    ),
  );
  _gameServiceEmitTurnResolutionEvents(service, result);
  return result;
}

void _gameServiceEmitTurnResolutionEvents(
  GameService service,
  TurnResolutionResult result,
) {
  if (result is TurnResolutionComplete) {
    final complete = result;
    service.saveGame(complete.game);
    service._mirrorAutoSave(complete.game);
    service.eventBus?.emit(
      TurnResolutionCompleteEvent(
        gameId: complete.game.id,
        turnNumber: complete.game.worldState.turnState.turnNumber,
        turnNewsDigest: complete.turnNewsDigest,
      ),
    );
    return;
  }
  if (result is TurnResolutionPendingOvertures) {
    service.eventBus?.emit(OvertureRequiredEvent(overtures: result.pendingOvertures));
    return;
  }
  if (result is TurnResolutionPendingFtp) {
    // FTP accept/reject UI is follow-up work; pending state is set via
    // [applyTurnResolutionResult] / [pendingDiplomacyProvider].
    return;
  }
  if (result is TurnResolutionPendingIntervention) {
    service.eventBus?.emit(
      InterventionRequiredEvent(prompts: result.pendingInterventions),
    );
    return;
  }
  if (result is TurnResolutionPendingCallToArms) {
    service.eventBus?.emit(
      CallToArmsRequiredEvent(pending: result.pendingCallToArms),
    );
  }
}
