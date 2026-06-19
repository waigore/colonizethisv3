import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/providers/blessed_ai_profiles_provider.dart';
import 'package:colonizethis_app/features/shell/new_game_leader_selection_dialog.dart';
import 'package:colonizethis_app/features/shell/new_game_setup_flow.dart';

final _logShell = packageLogger('shell');

/// Smaller than [GameSetupConfig.defaultConfig]: integration tests compile with
/// `CT_E2E=true` and must stay inside CI wall clocks (not the locked full-init
/// 60/30 profile). Production `main` / widget tests use [GameSetupConfig.defaultConfig].
GameSetupConfig _ctE2eNewGameLeaderTemplateConfig() {
  final d = GameSetupConfig.defaultConfig;
  return GameSetupConfig(
    selectedGreatPowerIds: d.selectedGreatPowerIds,
    leaderVariantByGpId: d.leaderVariantByGpId,
    continentCount: 2,
    minorNationCount: 2,
    tribeCount: 4,
    numProvincesOldWorld: 24,
    numProvincesNewWorld: 12,
    minProvincesPerMinor: 2,
    seed: d.seed,
    infiniteMode: d.infiniteMode,
    startingResources: d.startingResources,
    preferredInitialMapZoomMultiplier: d.preferredInitialMapZoomMultiplier,
    initTownRoadWiringRegionIds: d.initTownRoadWiringRegionIds,
  );
}

/// Feature-layer [OpenDialogEvent] builder for [NewGameLeaderSelectionDialog].
///
/// Refs #3546 (core→shell layering): this builder lives in the shell feature and
/// is injected into the core event-handler scope at the composition root via
/// `AppEventHandlerScope.extraDialogBuilders`, so `core/services/` no longer
/// imports `features/shell/`. SPEC/program/app-ui-wiring.md.
Widget buildNewGameLeaderSelectionDialog(
  BuildContext ctx,
  Map<String, Object?>? params,
) {
  final baseConfig = kCtE2EEnabled
      ? _ctE2eNewGameLeaderTemplateConfig()
      : GameSetupConfig.defaultConfig;
  final naming = defaultNamingConfig;
  final initialSelections = <String, String>{};
  for (final gpId in baseConfig.selectedGreatPowerIds) {
    final gp = naming.gpById(gpId);
    if (gp != null && gp.leaderVariants.isNotEmpty) {
      initialSelections[gpId] = gp.defaultLeaderVariantId;
    }
  }
  final container = ProviderScope.containerOf(ctx);
  final blessedNames =
      container.read(blessedAiProfileNamesProvider).value ?? const <String>[];
  return NewGameLeaderSelectionDialog(
    baseConfig: baseConfig,
    naming: naming,
    initialLeaderByGpId: initialSelections,
    blessedProfileNames: blessedNames,
    onCancel: () => Navigator.of(ctx).pop(),
    onConfirmed:
        (
          orderedGreatPowerIds,
          leaderVariantByGpId,
          seed,
          infiniteMode,
          terrainVariation,
          aiProfileByGpId,
        ) {
          final navCtx = appNavigatorKey.currentContext;
          if (navCtx == null) {
            _logShell.w(
              'appNavigatorKey has no context; skipping new game setup',
            );
            return;
          }
          final rootContainer = ProviderScope.containerOf(navCtx);
          final templateConfig = GameSetupConfig(
            selectedGreatPowerIds: orderedGreatPowerIds,
            leaderVariantByGpId: leaderVariantByGpId,
            continentCount: baseConfig.continentCount,
            minorNationCount: baseConfig.minorNationCount,
            tribeCount: baseConfig.tribeCount,
            numProvincesOldWorld: baseConfig.numProvincesOldWorld,
            numProvincesNewWorld: baseConfig.numProvincesNewWorld,
            minProvincesPerMinor: baseConfig.minProvincesPerMinor,
            seed: seed,
            infiniteMode: infiniteMode,
            terrainVariation: terrainVariation,
            startingResources: baseConfig.startingResources,
            initTownRoadWiringRegionIds: baseConfig.initTownRoadWiringRegionIds,
            aiProfileByGpId: aiProfileByGpId,
          );
          unawaited(
            runNewGameSetupAfterLeaderPick(
              navigatorKey: appNavigatorKey,
              container: rootContainer,
              templateConfig: templateConfig,
            ),
          );
        },
  );
}
