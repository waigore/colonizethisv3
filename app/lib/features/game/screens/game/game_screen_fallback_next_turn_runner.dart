import 'dart:async';

import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/ai/ai_profile_resolution.dart';
import '../../../../core/services/turn_resolution/turn_resolution_result_applier.dart';
import '../../../../core/services/turn_resolution/turn_resolution_runner.dart';
import '../../../../config/ux_settings_keys.dart';
import '../../../../providers/app_event_bus_provider.dart';
import '../../../../providers/blessed_ai_profiles_provider.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../../../providers/settings_provider.dart';
import '../../../../providers/turn_resolution_blocking_provider.dart';
import '../../../../providers/turn_resolution_runner_provider.dart';
import '../../../../core/services/turn_resolution/turn_resolution_blocking_service.dart';
import '../../widgets/shell/shell_player_context.dart';
import '../../flame/map_state/map_state.dart';
import '../../turn_resolution/next_turn_confirmation_flow.dart';
import '../../flame/overlays/turn_resolution_processing_dialog.dart';
import '../../flame/overlays/turn_resolution_progress_labels.dart';
import 'game_screen_fallback_next_turn.dart';

final _gameScreenFallbackNextTurnLog = packageLogger('logic');

mixin GameScreenFallbackNextTurnRunner
    on ConsumerState<GameScreenFallbackNextTurnButton> {
  Future<void> runFlameCanvasFallbackNextTurn() async {
    final context = this.context;
    final game = widget.game;
    if (!GameMapAreaStateLogic.allowsFullTurnResolution(game)) {
      return;
    }
    final currentTurn = game.worldState.turnState.turnNumber;
    final shell = ref.read(shellPlayerContextProvider);
    final humanPlayerId = shell.mapPlayerIdFor(game);
    final orders = ref.read(currentOrdersProvider);
    final settings = ref.read(settingsProvider);
    final warnIdleCiviliansEnabled =
        settings[UxSettingsKeys.warnIdleCiviliansOnEndTurn] as bool? ?? true;
    final bus = ref.read(appEventBusProvider);
    final ok = await confirmNextTurnWithIdleCivilianWarning(
      context: context,
      game: game,
      currentTurn: currentTurn,
      humanPlayerId: humanPlayerId,
      orders: orders,
      warnIdleCiviliansEnabled: warnIdleCiviliansEnabled,
      bus: bus,
      onDisableIdleCivilianWarning: () => ref
          .read(settingsProvider.notifier)
          .setValue(UxSettingsKeys.warnIdleCiviliansOnEndTurn, false),
    );
    if (!ok || !context.mounted) {
      return;
    }

    final service = ref.read(gameServiceProvider);
    final runner = ref.read(turnResolutionRunnerProvider);
    final failureMessage = appL10n(context).game_turnResolutionFailedMessage;
    final messenger = ScaffoldMessenger.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final mapData = service.getMapData(game.id);
    if (mapData == null) {
      throw StateError('Missing required map data for gameId=${game.id}');
    }

    final phaseNotifier = ValueNotifier<String>('Resolving turn...');
    var processingDialogOpen = true;
    final uiStopwatch = Stopwatch()..start();
    ref.read(turnResolutionBlockingProvider.notifier).set(true);
    _gameScreenFallbackNextTurnLog.i(
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
    _gameScreenFallbackNextTurnLog.i(
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
      _gameScreenFallbackNextTurnLog.i(
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
        _gameScreenFallbackNextTurnLog.d(
          'logic: next_turn_ui phase gameId=${game.id} sessionId=$activeSessionId '
          'phase=${event.phase} elapsedMs=${uiStopwatch.elapsedMilliseconds}',
        );
      });
      final terminal = await session.done;
      _gameScreenFallbackNextTurnLog.i(
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
          _gameScreenFallbackNextTurnLog.i(
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
            _gameScreenFallbackNextTurnLog.i(
              'logic: next_turn_ui worker_trace_export_path gameId=${game.id} '
              'sessionId=$activeSessionId path=${c.turnTraceExportPath}',
            );
          }
          final applyStopwatch = Stopwatch()..start();
          ref.read(turnResolutionResultApplierProvider).apply(c.result);
          _gameScreenFallbackNextTurnLog.i(
            'logic: next_turn_ui result_applied gameId=${game.id} '
            'sessionId=$activeSessionId applyMs=${applyStopwatch.elapsedMilliseconds} '
            'elapsedMs=${uiStopwatch.elapsedMilliseconds}',
          );
        case TurnResolutionTerminalError e:
          messenger.showSnackBar(SnackBar(content: Text(failureMessage)));
          _gameScreenFallbackNextTurnLog.e(
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
      _gameScreenFallbackNextTurnLog.i(
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
