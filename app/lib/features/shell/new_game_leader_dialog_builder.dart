import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colonizethis_app/providers/blessed_ai_profiles_provider.dart';
import 'package:colonizethis_app/features/shell/new_game_leader_selection_dialog.dart';
import 'package:colonizethis_app/features/shell/new_game_setup_flow.dart';
import 'package:colonizethis_app/features/shell/new_game_setup_template.dart';

final _logShell = packageLogger('shell');

/// Feature-layer [OpenDialogEvent] builder factory for
/// [NewGameLeaderSelectionDialog].
///
/// Refs #3546 (core→shell layering): this builder lives in the shell feature and
/// is injected into the core event-handler scope at the composition root via
/// `AppEventHandlerScope.extraDialogBuilders`, so `core/services/` no longer
/// imports `features/shell/`. The scope resolves this factory with the app
/// navigator key, so the shell threads the key explicitly instead of reading
/// the global `appNavigatorKey` (which `repo.app_event_bus_decoupling` confines
/// to `core/services/` + `app.dart`). SPEC/program/app-ui-wiring.md.
DialogBuilder buildNewGameLeaderSelectionDialog(
  GlobalKey<NavigatorState> navigatorKey,
) {
  return (ctx, params) {
    final baseConfig = newGameSetupTemplateConfig();
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
            advancedStart,
          ) {
            final navCtx = navigatorKey.currentContext;
            if (navCtx == null) {
              _logShell.w(
                'navigator key has no context; skipping new game setup',
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
              initTownRoadWiringRegionIds:
                  baseConfig.initTownRoadWiringRegionIds,
              aiProfileByGpId: aiProfileByGpId,
              advancedStart: advancedStart,
            );
            unawaited(
              runNewGameSetupAfterLeaderPick(
                navigatorKey: navigatorKey,
                container: rootContainer,
                templateConfig: templateConfig,
              ),
            );
          },
    );
  };
}
