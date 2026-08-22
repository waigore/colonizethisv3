import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import '../../../../config/ux_settings_keys.dart';
import '../../../../providers/app_event_bus_provider.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../../../providers/blessed_ai_profiles_provider.dart';
import '../../../../providers/settings_provider.dart';
import '../../../../providers/turn_resolution_blocking_provider.dart';
import '../../../../providers/turn_resolution_runner_provider.dart';
import '../../../../core/services/turn_resolution/turn_resolution_blocking_service.dart';

import '../../widgets/shell/shell_player_context.dart';
import 'game_map_area_state_logic.dart';
import '../../turn_resolution/next_turn_confirmation_flow.dart';
import '../overlays/turn_resolution_processing_dialog.dart';
import '../overlays/turn_resolution_progress_labels.dart';
import '../../../../core/services/turn_resolution/turn_resolution_result_applier.dart';
import 'game_map_area.dart';
import 'game_map_area_log.dart';
import 'game_map_area_state_base.dart';
import 'game_map_area_turn_resolution_session.dart';

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
    if (!GameMapAreaStateLogicShell.allowsFullTurnResolution(game)) {
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
    final mapDataForConfirm = ref.read(gameServiceProvider).getMapData(game.id);
    final ok = await confirmNextTurnWithIdleCivilianWarning(
      context: context,
      game: game,
      currentTurn: currentTurn,
      humanPlayerId: humanPlayerId,
      orders: orders,
      warnIdleCiviliansEnabled: warnIdleCiviliansEnabled,
      bus: bus,
      topology: mapDataForConfirm?.combinedTopology,
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
        aiCatalog: ref.read(blessedAiProfileCatalogProvider).value ?? const {},
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
