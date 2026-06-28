part of 'game_map_area.dart';

/// Next-turn resolution flow for [GameMapArea]: confirmation, the processing
/// dialog lifecycle, worker session orchestration, result application, and the
/// structured `next_turn_ui_map` timing logs (Refs #3699 Theme 3).
mixin _GameMapAreaTurnResolution
    on ConsumerState<GameMapArea>, _GameMapAreaStateBase {
  Future<void> _onNextTurn() async {
    if (_isTurnResolving) {
      return;
    }
    final game = ref.read(currentGameProvider);
    if (game == null) return;
    if (!GameMapAreaStateLogic.allowsFullTurnResolution(game)) {
      return;
    }

    final currentTurn = game.worldState.turnState.turnNumber;
    final ok = await showNextTurnConfirmationDialog(
      context,
      currentTurn: currentTurn,
    );
    if (ok != true) return;
    if (!mounted) return;

    final service = ref.read(gameServiceProvider);
    final runner = ref.read(turnResolutionRunnerProvider);
    final failureMessage = appL10n(context).game_turnResolutionFailedMessage;
    final messenger = ScaffoldMessenger.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final orders = ref.read(currentOrdersProvider);
    final mapData = service.getMapData(game.id);
    if (mapData == null) {
      throw StateError('Missing required map data for gameId=${game.id}');
    }

    final phaseNotifier = ValueNotifier<String>('Resolving turn...');
    var processingDialogOpen = true;
    final uiStopwatch = Stopwatch()..start();
    setState(() {
      _isTurnResolving = true;
    });
    ref.read(turnResolutionBlockingProvider.notifier).set(true);
    _gameMapNextTurnUiLog.i(
      'logic: next_turn_ui_map started gameId=${game.id} turn=$currentTurn '
      'turnTraceEnabled=${service.isTurnTraceEnabled}',
    );
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (_) => ValueListenableBuilder<String>(
          valueListenable: phaseNotifier,
          builder: (_, text, _) =>
              TurnResolutionProcessingDialog(phaseText: text),
        ),
      ).whenComplete(() {
        processingDialogOpen = false;
      }),
    );
    await awaitTurnResolutionProcessingDialogFirstPaint();
    _gameMapNextTurnUiLog.i(
      'logic: next_turn_ui_map processing_dialog_painted gameId=${game.id} '
      'elapsedMs=${uiStopwatch.elapsedMilliseconds}',
    );
    try {
      final aiCatalog =
          ref.read(blessedAiProfileCatalogProvider).value ?? const {};
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
      await _turnResolutionProgressSub?.cancel();
      _turnResolutionProgressSub = session.progress.listen((event) {
        if (!mounted ||
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
      if (!mounted) {
        return;
      }
      if (processingDialogOpen) {
        rootNavigator.pop();
        processingDialogOpen = false;
      }
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
            stackTrace: e.stackTrace.isEmpty
                ? null
                : StackTrace.fromString(e.stackTrace),
          );
          throw StateError(e.errorMessage);
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(failureMessage)));
      }
      rethrow;
    } finally {
      clearTurnResolutionBlockingFlag();
      await _turnResolutionProgressSub?.cancel();
      _turnResolutionProgressSub = null;
      _gameMapNextTurnUiLog.i(
        'logic: next_turn_ui_map cleanup_complete gameId=${game.id} '
        'elapsedMs=${uiStopwatch.elapsedMilliseconds}',
      );
      if (mounted && processingDialogOpen) {
        rootNavigator.pop();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        phaseNotifier.dispose();
      });
      if (mounted) {
        setState(() {
          _isTurnResolving = false;
        });
      }
    }
  }
}
