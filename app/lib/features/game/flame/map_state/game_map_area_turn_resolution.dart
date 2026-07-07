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
      final sessionResult = await _awaitGameMapAreaTurnResolutionSession(
        host: this,
        ref: ref,
        runner: runner,
        game: game,
        orders: orders,
        mapData: mapData,
        phaseNotifier: phaseNotifier,
        uiStopwatch: uiStopwatch,
      );
      if (!mounted) {
        return;
      }
      if (processingDialogOpen) {
        rootNavigator.pop();
        processingDialogOpen = false;
      }
      _applyGameMapAreaTurnResolutionTerminal(
        ref: ref,
        terminal: sessionResult.terminal,
        service: service,
        game: game,
        activeSessionId: sessionResult.sessionId,
        uiStopwatch: uiStopwatch,
        failureMessage: failureMessage,
        messenger: messenger,
      );
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
