import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'game_service.dart';
import 'game_service_map_cache.dart';
import 'game_service_turn_trace.dart';

TurnResolutionResult gameServiceRunTurnResolution(
  GameService service,
  Game current, {
  Orders? orders,
  Orders? aiOrders,
  List<TurnTraceAiSection>? aiTraceSections,
  MapTopology? topology,
  Map<String, TileMapResult>? tileMapByRegion,
  void Function(GameEvent)? onGameEvent,
}) {
  final mapData = gameServiceRequiredMapDataView(service, current.id);
  final topo = topology ?? mapData.combinedTopology;
  final tileMaps = tileMapByRegion ?? mapData.tileMapByRegion;
  final humanOrders = orders ?? const Orders();
  final resolvedOrders = aiOrders != null
      ? mergeOrderLists(humanOrders: humanOrders, aiOrders: aiOrders)
      : humanOrders;
  final result = gameServiceResolveTurnWithTrace(
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
  gameServiceEmitTurnResolutionEvents(service, result);
  return result;
}

TurnResolutionResult gameServiceResumeTurnFromDiplomacy(
  GameService service,
  Game game,
  Orders orders, {
  void Function(GameEvent)? onGameEvent,
  List<CallToArmsDecision>? callToArmsDecisions,
  List<OvertureDecision>? overtureDecisions,
  List<FtpDecision>? ftpDecisions,
  List<InterventionDecision>? interventionDecisions,
}) {
  final mapData = gameServiceRequiredMapDataView(service, game.id);
  final result = gameServiceResolveTurnWithTrace(
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
  gameServiceEmitTurnResolutionEvents(service, result);
  return result;
}

void gameServiceEmitTurnResolutionEvents(
  GameService service,
  TurnResolutionResult result,
) {
  if (result is TurnResolutionComplete) {
    final complete = result;
    service.saveGame(complete.game);
    gameServiceMirrorAutoSave(service, complete.game);
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
