// SPEC/ui/game-initializing.md — progress dialog, async setup, error + retry.
// Retry: fixed user seed K uses K+N per attempt; user seed 0 keeps 0 each attempt (fresh
// time-based effective seed when init runs).

import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/perf/app_perf_trace.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/features/shell/new_game_setup_seed_for_attempt.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_loading_indicator.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';

final _log = packageLogger('shell');

sealed class _NewGameOutcome {}

class _NewGameOutcomeSuccess extends _NewGameOutcome {
  _NewGameOutcomeSuccess(this.game);
  final Game game;
}

class _NewGameOutcomeFailure extends _NewGameOutcome {
  _NewGameOutcomeFailure(this.error);
  final Object error;
}

/// Runs phased new-game creation after leader selection: progress dialog, navigate on success,
/// error dialog with retry. SPEC/ui/game-initializing.md.
///
/// [navigatorKey] is the long-lived root navigator handle used to show the
/// progress and error dialogs after the leader-selection dialog has popped
/// itself. Inject explicitly (do not read a global) so the dependency is
/// visible at the call site and testable: SPEC/program/app-ui-wiring.md.
Future<void> runNewGameSetupAfterLeaderPick({
  required GlobalKey<NavigatorState> navigatorKey,
  required ProviderContainer container,
  required GameSetupConfig templateConfig,
}) async {
  // Leader dialog pops synchronously before this async function continues; yield so
  // the route can close and the next frame can run before we push progress UI.
  await Future<void>.delayed(Duration.zero);

  final baseSeed = templateConfig.seed;
  var attemptIndex = 0;
  final service = container.read(gameServiceProvider);
  final bus = container.read(appEventBusProvider);

  while (true) {
    final perAttemptSeed = newGameSetupConfigSeedForAttempt(
      dialogChosenSeed: baseSeed,
      attemptIndex: attemptIndex,
    );
    final config = GameSetupConfig(
      selectedGreatPowerIds: templateConfig.selectedGreatPowerIds,
      leaderVariantByGpId: templateConfig.leaderVariantByGpId,
      continentCount: templateConfig.continentCount,
      minorNationCount: templateConfig.minorNationCount,
      tribeCount: templateConfig.tribeCount,
      numProvincesOldWorld: templateConfig.numProvincesOldWorld,
      numProvincesNewWorld: templateConfig.numProvincesNewWorld,
      minProvincesPerMinor: templateConfig.minProvincesPerMinor,
      seed: perAttemptSeed,
      infiniteMode: templateConfig.infiniteMode,
      startingResources: templateConfig.startingResources,
      initTownRoadWiringRegionIds: templateConfig.initTownRoadWiringRegionIds,
    );

    final outcome = await _showNewGameProgressDialog(
      navigatorKey: navigatorKey,
      config: config,
      service: service,
    );
    if (outcome == null) {
      _log.w('new game setup: could not show progress dialog');
      return;
    }

    switch (outcome) {
      case _NewGameOutcomeSuccess(:final game):
        container.read(currentGameProvider.notifier).setGame(game);
        ctAppPerfInstant('navigate.game');
        bus.emit(const NavigateToRouteEvent(Routes.game));
        return;
      case _NewGameOutcomeFailure(:final error):
        final retry = await _showNewGameErrorDialog(
          navigatorKey: navigatorKey,
          error: error,
        );
        if (retry) {
          attemptIndex++;
          continue;
        }
        return;
    }
  }
}

Future<_NewGameOutcome?> _showNewGameProgressDialog({
  required GlobalKey<NavigatorState> navigatorKey,
  required GameSetupConfig config,
  required GameService service,
}) async {
  final ctx = navigatorKey.currentContext;
  if (ctx == null) {
    return null;
  }
  return showDialog<_NewGameOutcome>(
    context: ctx,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (dialogCtx) =>
        _NewGameSetupProgressDialog(config: config, service: service),
  );
}

Future<bool> _showNewGameErrorDialog({
  required GlobalKey<NavigatorState> navigatorKey,
  required Object error,
}) async {
  final ctx = navigatorKey.currentContext;
  if (ctx == null) {
    return false;
  }
  final l10n = appL10n(ctx);
  final retry = await showDialog<bool>(
    context: ctx,
    useRootNavigator: true,
    builder: (ctx) => CtDialogShell(
      child: NewGameErrorCard(
        title: l10n.shell_newGameError_title,
        message: error.toString(),
        closeLabel: l10n.common_close,
        retryLabel: l10n.shell_newGameError_retry,
        onClose: () => Navigator.of(ctx).pop(false),
        onRetry: () => Navigator.of(ctx).pop(true),
      ),
    ),
  );
  return retry ?? false;
}

/// `--danger`-bordered error card painted inside the [CtDialogShell] when
/// new-game setup fails.
///
/// SPEC: `SPEC/ui/game-initializing.md` § Failure and retry; dark-theme
/// visual contract from issue #2867 R34 (1 px `--danger` border on all four
/// sides, `Retry` primary + `Close` secondary `CtNinePatchButton` actions).
///
/// The card is decoupled from any `Navigator` so Widgetbook and widget tests
/// can compose it directly without driving a `showDialog` flow. The shell
/// flow wires [onClose] / [onRetry] to `Navigator.pop(false / true)` so the
/// existing `Future<bool>` retry contract in [_showNewGameErrorDialog]
/// remains unchanged.
class NewGameErrorCard extends StatelessWidget {
  const NewGameErrorCard({
    super.key,
    required this.title,
    required this.message,
    required this.closeLabel,
    required this.retryLabel,
    this.onClose,
    this.onRetry,
  });

  /// Short error-card title (e.g. "Could not create game").
  final String title;

  /// Exception body (typically `error.toString()`).
  final String message;

  /// Label for the secondary (`Close`) `CtNinePatchButton`.
  final String closeLabel;

  /// Label for the primary (`Retry`) `CtNinePatchButton`.
  final String retryLabel;

  /// Invoked when the user taps the `Close` button. Optional so the card can
  /// be previewed in Widgetbook without wiring a callback.
  final VoidCallback? onClose;

  /// Invoked when the user taps the `Retry` button. Optional so the card can
  /// be previewed in Widgetbook without wiring a callback.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: EditorialMonoclePalette.danger, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(CtSpacing.ml),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SelectableText(message),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CtNinePatchButton(
                  onPressed: onClose,
                  child: Text(closeLabel),
                ),
                const SizedBox(width: 8),
                CtNinePatchButton(
                  onPressed: onRetry,
                  child: Text(retryLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _stepLabel(BuildContext context, int stepIndex) {
  final l10n = appL10n(context);
  switch (stepIndex) {
    case 0:
      return l10n.shell_newGameProgress_stepOldWorld;
    case 1:
      return l10n.shell_newGameProgress_stepNewWorld;
    case 2:
      return l10n.shell_newGameProgress_stepWarp;
    case 3:
      return l10n.shell_newGameProgress_stepBuildWorld;
    case 4:
      return l10n.shell_newGameProgress_stepSave;
    default:
      return l10n.shell_newGameProgress_title;
  }
}

/// Inert visual for the new-game progress dialog body (SHEL30001).
///
/// Renders the `CtDialogShell` chrome, the localised progress title, the
/// 48 px `--accent` spinner ring, and the current phase label for
/// [stepIndex] ∈ `0..4` per `SPEC/ui/game-initializing.md` § Dark-theme
/// visual contract (issue #2867 R32–R33).
///
/// This widget is intentionally synchronous and side-effect free so it can
/// be composed by Widgetbook stories and widget tests without driving the
/// `GameService` setup pipeline. The shell dialog
/// ([_NewGameSetupProgressDialog]) wraps this view in `PopScope(canPop:
/// false)` and drives [stepIndex] from the live `onProgress` callback.
class NewGameSetupProgressView extends StatelessWidget {
  const NewGameSetupProgressView({super.key, required this.stepIndex});

  /// Index of the current coarse setup phase (`0..4`); values outside that
  /// range fall back to the generic progress title per [_stepLabel].
  final int stepIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    return CtDialogShell(
      maxWidth: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            l10n.shell_newGameProgress_title,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          CtLoadingIndicator(
            size: 48,
            strokeWidth: 2,
            color: EditorialMonoclePalette.accent,
            center: false,
          ),
          const SizedBox(height: 16),
          Text(_stepLabel(context, stepIndex), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _NewGameSetupProgressDialog extends StatefulWidget {
  const _NewGameSetupProgressDialog({
    required this.config,
    required this.service,
  });

  final GameSetupConfig config;
  final GameService service;

  @override
  State<_NewGameSetupProgressDialog> createState() =>
      _NewGameSetupProgressDialogState();
}

class _NewGameSetupProgressDialogState
    extends State<_NewGameSetupProgressDialog> {
  var _stepIndex = 0;

  @override
  void initState() {
    super.initState();
    // Defer work by one extra frame so the modal route and nine-patch can paint
    // before map generation runs on the UI isolate (SPEC/ui/game-initializing.md).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_run());
      });
    });
  }

  Future<void> _run() async {
    try {
      final game = await widget.service.createNewGameAsync(
        config: widget.config,
        onProgress: (stepIndex, _) {
          if (mounted) {
            setState(() => _stepIndex = stepIndex);
          }
        },
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(_NewGameOutcomeSuccess(game));
    } catch (e, st) {
      _log.e('new game setup failed', error: e, stackTrace: st);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(_NewGameOutcomeFailure(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: NewGameSetupProgressView(stepIndex: _stepIndex),
    );
  }
}
