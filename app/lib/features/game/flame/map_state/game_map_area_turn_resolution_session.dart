import 'dart:async';

import 'package:flutter/material.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show AiProfile;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show TurnResolutionComplete, TurnTraceAiSection;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import '../../../../core/services/ai/ai_profile_resolution.dart';
import '../../../../core/services/game_service/game_service.dart' show GameMapData, GameService;
import '../../../../core/services/turn_resolution/turn_resolution_result_applier.dart';
import '../../../../core/services/turn_resolution/turn_resolution_runner.dart'
    show
        TurnResolutionProgressEvent,
        TurnResolutionRunner,
        TurnResolutionTerminalComplete,
        TurnResolutionTerminalError,
        TurnResolutionTerminalEvent;
import '../overlays/turn_resolution_progress_labels.dart';
import 'game_map_area_logging.dart';
import 'game_map_area_state_base.dart';

Future<({TurnResolutionTerminalEvent terminal, String sessionId})>
    awaitGameMapAreaTurnResolutionSession({
  required GameMapAreaStateBase host,
  required GameService service,
  required Map<String, AiProfile> aiCatalog,
  required TurnResolutionRunner runner,
  required ct_models.Game game,
  required ct_models.Orders orders,
  required GameMapData mapData,
  required ValueNotifier<String> phaseNotifier,
  required Stopwatch uiStopwatch,
}) async {
  final aiProfiles = resolveAiProfilesForGame(game, aiCatalog);
  final session = runner.startResolution(
    game: game,
    orders: orders,
    topology: mapData.combinedTopology,
    tileMapByRegion: mapData.tileMapByRegion,
    turnTraceEnabled: service.isTurnTraceEnabled,
    turnTraceRootDirectory: service.turnTraceRootDirectory,
    aiProfiles: aiProfiles,
  );
  final activeSessionId = session.sessionId;
  gameMapNextTurnUiLog.i(
    'logic: next_turn_ui_map session_started gameId=${game.id} '
    'sessionId=$activeSessionId elapsedMs=${uiStopwatch.elapsedMilliseconds}',
  );
  await host.turnResolutionProgressSub?.cancel();
  host.turnResolutionProgressSub = session.progress.listen((event) {
    if (!host.mounted ||
        event.sessionId != activeSessionId ||
        event.marker != 'start') {
      return;
    }
    phaseNotifier.value = turnResolutionProgressPhaseLabel(event.phase);
    gameMapNextTurnUiLog.d(
      'logic: next_turn_ui_map phase gameId=${game.id} sessionId=$activeSessionId '
      'phase=${event.phase} elapsedMs=${uiStopwatch.elapsedMilliseconds}',
    );
  });
  final terminal = await session.done;
  gameMapNextTurnUiLog.i(
    'logic: next_turn_ui_map session_done gameId=${game.id} sessionId=$activeSessionId '
    'terminalType=${terminal.runtimeType} elapsedMs=${uiStopwatch.elapsedMilliseconds}',
  );
  return (terminal: terminal, sessionId: activeSessionId);
}

void applyGameMapAreaTurnResolutionTerminal({
  required TurnResolutionResultApplier resultApplier,
  required TurnResolutionTerminalEvent terminal,
  required GameService service,
  required ct_models.Game game,
  required String activeSessionId,
  required Stopwatch uiStopwatch,
  required String failureMessage,
  required ScaffoldMessengerState messenger,
}) {
  switch (terminal) {
    case TurnResolutionTerminalComplete c:
      final handleStopwatch = Stopwatch()..start();
      service.handleExternallyResolvedTurnResult(c.result);
      gameMapNextTurnUiLog.i(
        'logic: next_turn_ui_map external_result_handled gameId=${game.id} '
        'sessionId=$activeSessionId handleMs=${handleStopwatch.elapsedMilliseconds} '
        'resultType=${c.result.runtimeType}',
      );
      if (service.isTurnTraceEnabled &&
          c.result is TurnResolutionComplete &&
          c.turnTracePhases != null &&
          c.turnTraceStartedAtUtc != null) {
        final complete = c.result as TurnResolutionComplete;
        service.exportTurnTraceForExternallyResolvedTurn(
          gameAtResolutionStart: game,
          turnEndState: complete.game,
          phases: c.turnTracePhases!,
          ai: c.aiTraceSections ?? const <TurnTraceAiSection>[],
          turnStartAtUtc: c.turnTraceStartedAtUtc!,
        );
      }
      if (c.turnTraceExportPath != null) {
        gameMapNextTurnUiLog.i(
          'logic: next_turn_ui_map worker_trace_export_path gameId=${game.id} '
          'sessionId=$activeSessionId path=${c.turnTraceExportPath}',
        );
      }
      final applyStopwatch = Stopwatch()..start();
      resultApplier.apply(c.result);
      gameMapNextTurnUiLog.i(
        'logic: next_turn_ui_map result_applied gameId=${game.id} '
        'sessionId=$activeSessionId applyMs=${applyStopwatch.elapsedMilliseconds} '
        'elapsedMs=${uiStopwatch.elapsedMilliseconds}',
      );
    case TurnResolutionTerminalError e:
      messenger.showSnackBar(SnackBar(content: Text(failureMessage)));
      gameMapNextTurnUiLog.e(
        'logic: next_turn_ui_map terminal_error gameId=${game.id} '
        'sessionId=$activeSessionId elapsedMs=${uiStopwatch.elapsedMilliseconds}',
        error: e.errorMessage,
        stackTrace:
            e.stackTrace.isEmpty ? null : StackTrace.fromString(e.stackTrace),
      );
      throw StateError(e.errorMessage);
  }
}
