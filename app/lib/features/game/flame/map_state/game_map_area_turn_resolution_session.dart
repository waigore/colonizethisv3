part of 'game_map_area.dart';

Future<({TurnResolutionTerminalEvent terminal, String sessionId})>
    _awaitGameMapAreaTurnResolutionSession({
  required _GameMapAreaStateBase host,
  required WidgetRef ref,
  required TurnResolutionRunner runner,
  required ct_models.Game game,
  required ct_models.Orders orders,
  required GameMapData mapData,
  required ValueNotifier<String> phaseNotifier,
  required Stopwatch uiStopwatch,
}) async {
  final service = ref.read(gameServiceProvider);
  final aiCatalog = ref.read(blessedAiProfileCatalogProvider).value ?? const {};
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
  _gameMapNextTurnUiLog.i(
    'logic: next_turn_ui_map session_started gameId=${game.id} '
    'sessionId=$activeSessionId elapsedMs=${uiStopwatch.elapsedMilliseconds}',
  );
  await host._turnResolutionProgressSub?.cancel();
  host._turnResolutionProgressSub = session.progress.listen((event) {
    if (!host.mounted ||
        event.sessionId != activeSessionId ||
        event.marker != 'start') {
      return;
    }
    phaseNotifier.value = turnResolutionProgressPhaseLabel(event.phase);
    _gameMapNextTurnUiLog.d(
      'logic: next_turn_ui_map phase gameId=${game.id} sessionId=$activeSessionId '
      'phase=${event.phase} elapsedMs=${uiStopwatch.elapsedMilliseconds}',
    );
  });
  final terminal = await session.done;
  _gameMapNextTurnUiLog.i(
    'logic: next_turn_ui_map session_done gameId=${game.id} sessionId=$activeSessionId '
    'terminalType=${terminal.runtimeType} elapsedMs=${uiStopwatch.elapsedMilliseconds}',
  );
  return (terminal: terminal, sessionId: activeSessionId);
}

void _applyGameMapAreaTurnResolutionTerminal({
  required WidgetRef ref,
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
      _gameMapNextTurnUiLog.i(
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
        _gameMapNextTurnUiLog.i(
          'logic: next_turn_ui_map worker_trace_export_path gameId=${game.id} '
          'sessionId=$activeSessionId path=${c.turnTraceExportPath}',
        );
      }
      final applyStopwatch = Stopwatch()..start();
      ref.read(turnResolutionResultApplierProvider).apply(c.result);
      _gameMapNextTurnUiLog.i(
        'logic: next_turn_ui_map result_applied gameId=${game.id} '
        'sessionId=$activeSessionId applyMs=${applyStopwatch.elapsedMilliseconds} '
        'elapsedMs=${uiStopwatch.elapsedMilliseconds}',
      );
    case TurnResolutionTerminalError e:
      messenger.showSnackBar(SnackBar(content: Text(failureMessage)));
      _gameMapNextTurnUiLog.e(
        'logic: next_turn_ui_map terminal_error gameId=${game.id} '
        'sessionId=$activeSessionId elapsedMs=${uiStopwatch.elapsedMilliseconds}',
        error: e.errorMessage,
        stackTrace:
            e.stackTrace.isEmpty ? null : StackTrace.fromString(e.stackTrace),
      );
      throw StateError(e.errorMessage);
  }
}
