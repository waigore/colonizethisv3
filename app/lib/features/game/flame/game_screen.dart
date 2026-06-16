export 'game_screen_shared.dart';

import 'dart:async';

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:flame/game.dart' hide Game;
import 'package:flutter/material.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/ui_screen_ids.dart';
import '../../../../providers/app_event_bus_provider.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../../../providers/map_view_provider.dart';
import '../../../../providers/turn_resolution_blocking_provider.dart';
import '../../../../providers/blessed_ai_profiles_provider.dart';
import '../../../../providers/turn_resolution_runner_provider.dart';
import '../../../core/services/ai_profile_resolution.dart';
import '../../../core/services/turn_resolution_blocking_service.dart';
import '../../../core/services/turn_resolution_runner.dart';
import '../../../widgets/ct_icon_action.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/ct_screen_shell.dart';
import '../../../widgets/game_to_ui_bus_listener.dart';

import '../dialogue/call_to_arms_dialogue_overlay.dart';
import '../dialogue/game_start_intro_overlay.dart';
import '../dialogue/intervention_dialogue_overlay.dart';
import '../dialogue/overture_dialogue_overlay.dart';
import '../dialogue/tribe_first_contact_overlay.dart';
import '../dialogue/tribe_first_contact_sync.dart';
import 'exit_confirm_dialog.dart';
import 'game_canvas.dart';
import 'game_map_area.dart';
import 'game_map_area_state_logic.dart';
import 'game_screen_shared.dart'
    show kGameMapNextTurnButtonKey, kNextTurnDisabledOpacity;
import 'next_turn_confirmation_dialog.dart';
import 'turn_resolution_processing_dialog.dart';
import 'turn_resolution_progress_labels.dart';
import 'turn_resolution_result_applier.dart';
import 'victory_overlay.dart';

final _gameScreenLog = packageLogger('logic');

/// Shows the in-game pause menu (Debug log, Resume). SPEC/program/debug-log-viewer.md.
/// Emits [OpenPauseMenuPanelEvent]; shell event handler shows the bottom sheet.
void _showPauseMenu(AppEventBus bus) {
  bus.emit(const OpenPauseMenuPanelEvent());
}

/// Flame-canvas fallback Next-turn button (used when `mapViewDataProvider == null`).
class _FallbackNextTurnButton extends ConsumerWidget {
  const _FallbackNextTurnButton({
    required this.game,
    required this.turnResolutionBlocking,
  });

  final Game game;
  final bool turnResolutionBlocking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool nextTurnEnabled = !turnResolutionBlocking &&
        GameMapAreaStateLogic.allowsFullTurnResolution(game);

    Future<void> runFlameCanvasNextTurn() async {
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

    return CtNinePatchButton(
      key: kGameMapNextTurnButtonKey,
      enabled: nextTurnEnabled,
      onPressed: nextTurnEnabled ? runFlameCanvasNextTurn : null,
      disabledOpacityOverride: kNextTurnDisabledOpacity,
      child: Text(
        appL10n(context).game_nextTurnButton(
          game.worldState.turnState.turnNumber,
          turnToYear(
            game.worldState.turnState.turnNumber,
            game.turnTimeMapping,
          ),
        ),
      ),
    );
  }
}

/// Hosts the Flame game canvas or map. When map data exists, shows map + province/sea zone overlay.
class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  /// SPEC/ui/game-screen.md — [UiScreenIds.gameScreen].
  static const screenId = UiScreenIds.gameScreen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(currentGameProvider);
    final mapViewData = ref.watch(mapViewDataProvider);
    final victory = game?.victory;
    final showOverlayButtons =
        game != null && victory == null && mapViewData == null;
    // The in-game map shell renders its own 36 dp `GameTopBar`; the mockup
    // shows no secondary `CtScreenShell` title band above it, so suppress it
    // when the map shell is active (issue #2861 M2 / R2). The Flame-canvas
    // fallback path keeps the titled shell.
    final bool mapShellActive = game != null && mapViewData != null;
    final introShownIds = ref.watch(gameIdsWithIntroShownProvider);
    final showIntro = game != null && !introShownIds.contains(game.id);
    final heraldQueue = ref.watch(tribeFirstContactHeraldQueueProvider);
    final pendingHerald =
        heraldQueue.isNotEmpty ? heraldQueue.first : null;
    final pendingDiplomacy = ref.watch(pendingDiplomacyProvider);
    final turnResolutionBlocking = ref.watch(turnResolutionBlockingProvider);
    Widget content = Stack(
      children: [
        if (mapViewData != null && game != null)
          GameMapArea(game: game, mapViewData: mapViewData)
        else
          GameWidget(game: ColonizeThisGame()),
        if (showOverlayButtons) ...[
          Positioned(
            left: 16,
            top: 16,
            child: CtIconAction(
              icon: Icons.menu,
              iconSize: 24,
              onPressed: () => _showPauseMenu(ref.read(appEventBusProvider)),
              tooltip: appL10n(context).game_pauseMenu_tooltip,
            ),
          ),
          Positioned(
            right: 16,
            top: 16,
            child: _FallbackNextTurnButton(
              game: game,
              turnResolutionBlocking: turnResolutionBlocking,
            ),
          ),
        ],
        if (game != null && victory != null)
          VictoryOverlay(
            game: game,
            victory: victory,
            bus: ref.read(appEventBusProvider),
          ),
      ],
    );

    if (game != null) {
      content = TribeFirstContactSyncListener(
        child: GameToUIBusListener(gameId: game.id, child: content),
      );
    }

    if (showIntro) {
      content = GameStartIntroOverlay(
        onDismissed: () {
          ref.read(gameIdsWithIntroShownProvider.notifier).markShown(game.id);
        },
        child: content,
      );
    }

    if (!showIntro && game != null && pendingHerald != null) {
      content = TribeFirstContactOverlay(
        tribeName: pendingHerald.tribeName,
        capitalName: pendingHerald.capitalName,
        onDismissed: () {
          ref
              .read(tribeFirstContactHeraldsShownProvider.notifier)
              .markShown(game.id, pendingHerald.tribeId);
          ref.read(tribeFirstContactHeraldQueueProvider.notifier).dequeueHead();
        },
        child: content,
      );
    }

    if (game != null && pendingDiplomacy != null) {
      switch (pendingDiplomacy) {
        case PendingDiplomacyOvertures(:final offers) when offers.isNotEmpty:
          content = OvertureDialogueOverlay(
            game: game,
            pendingOvertures: offers,
            onDecisions: (decisions) {
              final service = ref.read(gameServiceProvider);
              final orders = ref.read(currentOrdersProvider);
              final result = service.resumeOvertureDecisions(
                game,
                offers,
                decisions,
                orders,
              );
              ref.read(turnResolutionResultApplierProvider).apply(result);
            },
            child: content,
          );
        case PendingDiplomacyIntervention(:final prompts)
            when prompts.isNotEmpty:
          content = InterventionDialogueOverlay(
            game: game,
            prompts: prompts,
            onDecisions: (decisions) {
              final service = ref.read(gameServiceProvider);
              final orders = ref.read(currentOrdersProvider);
              final result = service.resumeInterventionDecisions(
                game,
                decisions,
                orders,
              );
              ref.read(turnResolutionResultApplierProvider).apply(result);
            },
            child: content,
          );
        case PendingDiplomacyCallToArms(:final pending) when pending.isNotEmpty:
          content = CallToArmsDialogueOverlay(
            game: game,
            pending: pending,
            onDecisions: (decisions) {
              final service = ref.read(gameServiceProvider);
              final orders = ref.read(currentOrdersProvider);
              final result = service.resumeCallToArmsDecisions(
                game,
                decisions,
                orders,
              );
              ref.read(turnResolutionResultApplierProvider).apply(result);
            },
            child: content,
          );
        case _:
          break;
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || !context.mounted) return;
        final shouldExit = await showExitToMainMenuConfirmDialog(context);
        if (!shouldExit || !context.mounted) return;
        ref.read(appEventBusProvider).emit(const NavigateToShellEvent());
      },
      child: CtScreenShell(
        title: appL10n(context).game_screenTitle,
        showTitleBar: !mapShellActive,
        child: content,
      ),
    );
  }
}
