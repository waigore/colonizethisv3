// SPEC/ui/game-initializing.md — progress dialog, async setup, error + retry.
// Retry: fixed user seed K uses K+N per attempt; user seed 0 keeps 0 each attempt (fresh
// time-based effective seed when init runs).

import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/core/services/game_session_clear.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/features/shell/new_game_setup_seed_for_attempt.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_loading_indicator.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';

part 'new_game_setup_flow_dialogs_error.dart';
part 'new_game_setup_flow_dialogs_progress.dart';

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
    clearActiveGameSession(container);
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
      terrainVariation: templateConfig.terrainVariation,
      startingResources: templateConfig.startingResources,
      initTownRoadWiringRegionIds: templateConfig.initTownRoadWiringRegionIds,
      aiProfileByGpId: templateConfig.aiProfileByGpId,
      advancedStart: templateConfig.advancedStart,
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
        applyNewGameSession(container, game);
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
