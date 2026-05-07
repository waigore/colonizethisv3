// SPEC/ui/game-initializing.md — progress dialog, async setup, error + retry.
// Retry: fixed user seed K uses K+N per attempt; user seed 0 keeps 0 each attempt (fresh
// time-based effective seed when init runs).

import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_app/app.dart';
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
Future<void> runNewGameSetupAfterLeaderPick({
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
      startingResources: templateConfig.startingResources,
      initTownRoadWiringRegionIds: templateConfig.initTownRoadWiringRegionIds,
    );

    final outcome = await _showNewGameProgressDialog(
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
        final retry = await _showNewGameErrorDialog(error);
        if (retry) {
          attemptIndex++;
          continue;
        }
        return;
    }
  }
}

Future<_NewGameOutcome?> _showNewGameProgressDialog({
  required GameSetupConfig config,
  required GameService service,
}) async {
  final ctx = appNavigatorKey.currentContext;
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

Future<bool> _showNewGameErrorDialog(Object error) async {
  final ctx = appNavigatorKey.currentContext;
  if (ctx == null) {
    return false;
  }
  final l10n = appL10n(ctx);
  final retry = await showDialog<bool>(
    context: ctx,
    useRootNavigator: true,
    builder: (ctx) => CtDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.shell_newGameError_title,
            style: Theme.of(ctx).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SelectableText(error.toString()),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CtNinePatchButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n.common_close),
              ),
              const SizedBox(width: 8),
              CtNinePatchButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n.shell_newGameError_retry),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return retry ?? false;
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
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: CtDialogShell(
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
              size: 40,
              strokeWidth: 2,
              color: theme.colorScheme.primary,
              center: false,
            ),
            const SizedBox(height: 16),
            Text(_stepLabel(context, _stepIndex), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
