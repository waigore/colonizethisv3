part of 'game_screen.dart';

mixin _FallbackNextTurnRunner on ConsumerState<_FallbackNextTurnButton> {
  Future<void> runFlameCanvasFallbackNextTurn() async {
    final context = this.context;
    final game = widget.game;
    if (!GameMapAreaStateLogic.allowsFullTurnResolution(game)) {
      return;
    }
    final currentTurn = game.worldState.turnState.turnNumber;
    final ok = await showNextTurnConfirmationDialog(
      context,
      currentTurn: currentTurn,
    );
    if (ok != true || !context.mounted) {
      return;
    }

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
    ref.read(turnResolutionBlockingProvider.notifier).set(true);
    _gameScreenLog.i(
      'logic: next_turn_ui started gameId=${game.id} turn=$currentTurn '
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
    _gameScreenLog.i(
      'logic: next_turn_ui processing_dialog_painted gameId=${game.id} '
      'elapsedMs=${uiStopwatch.elapsedMilliseconds}',
    );

    StreamSubscription<TurnResolutionProgressEvent>? progressSub;
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
      _gameScreenLog.i(
        'logic: next_turn_ui session_started gameId=${game.id} '
        'sessionId=$activeSessionId elapsedMs=${uiStopwatch.elapsedMilliseconds}',
      );
      progressSub = session.progress.listen((event) {
        if (!context.mounted ||
            event.sessionId != activeSessionId ||
            event.marker != 'start') {
          return;
        }
        phaseNotifier.value = turnResolutionProgressPhaseLabel(event.phase);
        _gameScreenLog.d(
          'logic: next_turn_ui phase gameId=${game.id} sessionId=$activeSessionId '
          'phase=${event.phase} elapsedMs=${uiStopwatch.elapsedMilliseconds}',
        );
      });
      final terminal = await session.done;
      _gameScreenLog.i(
        'logic: next_turn_ui session_done gameId=${game.id} sessionId=$activeSessionId '
        'terminalType=${terminal.runtimeType} elapsedMs=${uiStopwatch.elapsedMilliseconds}',
      );
      if (!context.mounted) {
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
          _gameScreenLog.i(
            'logic: next_turn_ui external_result_handled gameId=${game.id} '
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
            _gameScreenLog.i(
              'logic: next_turn_ui worker_trace_export_path gameId=${game.id} '
              'sessionId=$activeSessionId path=${c.turnTraceExportPath}',
            );
          }
          final applyStopwatch = Stopwatch()..start();
          ref.read(turnResolutionResultApplierProvider).apply(c.result);
          _gameScreenLog.i(
            'logic: next_turn_ui result_applied gameId=${game.id} '
            'sessionId=$activeSessionId applyMs=${applyStopwatch.elapsedMilliseconds} '
            'elapsedMs=${uiStopwatch.elapsedMilliseconds}',
          );
        case TurnResolutionTerminalError e:
          messenger.showSnackBar(SnackBar(content: Text(failureMessage)));
          _gameScreenLog.e(
            'logic: next_turn_ui terminal_error gameId=${game.id} '
            'sessionId=$activeSessionId elapsedMs=${uiStopwatch.elapsedMilliseconds}',
            error: e.errorMessage,
            stackTrace: e.stackTrace.isEmpty
                ? null
                : StackTrace.fromString(e.stackTrace),
          );
          throw StateError(e.errorMessage);
      }
    } catch (_) {
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text(failureMessage)));
      }
      rethrow;
    } finally {
      clearTurnResolutionBlockingFlag();
      await progressSub?.cancel();
      _gameScreenLog.i(
        'logic: next_turn_ui cleanup_complete gameId=${game.id} '
        'elapsedMs=${uiStopwatch.elapsedMilliseconds}',
      );
      if (context.mounted && processingDialogOpen) {
        rootNavigator.pop();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        phaseNotifier.dispose();
      });
    }
  }
}
