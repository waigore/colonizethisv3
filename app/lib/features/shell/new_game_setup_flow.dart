// SPEC/ui/game-initializing.md — progress dialog, async setup, error + retry.
// Retry: fixed user seed K uses K+N per attempt; user seed 0 keeps 0 each attempt (fresh
// time-based effective seed when init runs).

import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';
import 'package:colonizethis_app/core/services/game_session_clear.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/features/shell/new_game_setup_seed_for_attempt.dart';
import 'new_game_setup_flow_dialogs_error.dart';
import 'new_game_setup_flow_dialogs_progress.dart';
import 'new_game_setup_flow_outcome.dart';

export 'new_game_setup_flow_dialogs_error.dart' show NewGameErrorCard;
export 'new_game_setup_flow_dialogs_progress.dart' show NewGameSetupProgressView;

final _log = packageLogger('shell');

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

    final outcome = await showNewGameSetupProgressDialog(
      navigatorKey: navigatorKey,
      config: config,
      service: service,
    );
    if (outcome == null) {
      _log.w('new game setup: could not show progress dialog');
      return;
    }

    switch (outcome) {
      case NewGameSetupOutcomeSuccess(:final game):
        applyNewGameSession(container, game);
        ctAppPerfInstant('navigate.game');
        bus.emit(const NavigateToRouteEvent(Routes.game));
        return;
      case NewGameSetupOutcomeFailure(:final error):
        final retry = await showNewGameSetupErrorDialog(
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
