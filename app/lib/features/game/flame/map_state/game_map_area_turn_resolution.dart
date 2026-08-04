import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_data/colonizethis_data.dart';

import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import '../../../../core/services/game_service/game_service.dart'
    show GameMapData, GameService;
import '../../../../config/ux_settings_keys.dart';
import '../../../../providers/app_event_bus_provider.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../../../providers/blessed_ai_profiles_provider.dart';
import '../../../../providers/settings_provider.dart';
import '../../../../providers/turn_resolution_blocking_provider.dart';
import '../../../../providers/turn_resolution_runner_provider.dart';
import '../../../../core/services/ai/ai_profile_resolution.dart';
import '../../../../core/services/turn_resolution/turn_resolution_blocking_service.dart';
import '../../../../core/services/turn_resolution/turn_resolution_runner.dart';

import '../../widgets/shell/shell_player_context.dart';
import 'game_map_area_state_logic.dart';
import '../../turn_resolution/next_turn_confirmation_flow.dart';
import '../overlays/turn_resolution_processing_dialog.dart';
import '../overlays/turn_resolution_progress_labels.dart';
import '../../../../core/services/turn_resolution/turn_resolution_result_applier.dart';
import 'game_map_area.dart';
import 'game_map_area_log.dart';
import 'game_map_area_state_base.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_turn/colonizethis_turn.dart';
import 'package:colonizethis_logic/ai_api.dart';

/// Next-turn resolution flow for [GameMapArea]: confirmation, the processing
/// dialog lifecycle, worker session orchestration, result application, and the
/// structured `next_turn_ui_map` timing logs (Refs #3699 Theme 3).
mixin GameMapAreaTurnResolution
    on ConsumerState<GameMapArea>, GameMapAreaStateBase {
  Future<void> onNextTurn() async {
    if (isTurnResolving) {
      return;
    }
    final game = ref.read(currentGameProvider);
    if (game == null) return;
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
    if (!ok) return;
    if (!mounted) return;

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
    setState(() {
      isTurnResolving = true;
    });
    ref.read(turnResolutionBlockingProvider.notifier).set(true);
    gameMapNextTurnUiLog.i(
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
    gameMapNextTurnUiLog.i(
      'logic: next_turn_ui_map processing_dialog_painted gameId=${game.id} '
      'elapsedMs=${uiStopwatch.elapsedMilliseconds}',
    );
    try {
      final sessionResult = await awaitGameMapAreaTurnResolutionSession(
        host: this,
        service: service,
        aiCatalog:
            ref.read(blessedAiProfileCatalogProvider).value ?? const {},
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
      applyGameMapAreaTurnResolutionTerminal(
        resultApplier: ref.read(turnResolutionResultApplierProvider),
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
      await turnResolutionProgressSub?.cancel();
      turnResolutionProgressSub = null;
      gameMapNextTurnUiLog.i(
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
          isTurnResolving = false;
        });
      }
    }
  }
}

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
