// Clears player-app game-session in-memory state.
// SPEC/program/save-load-session-clear.md.

import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_province_panel_provider.dart';
import 'package:colonizethis_app/providers/province_overlay_read_model_cache_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_app/providers/observe_session_provider.dart';
import 'package:colonizethis_app/providers/offline_queue_provider.dart';
import 'package:colonizethis_app/providers/counsel_panel_session_cache_provider.dart';
import 'package:colonizethis_app/providers/diplomacy_panel_session_cache_provider.dart';
import 'package:colonizethis_app/providers/production_allocation_provider.dart';
import 'package:colonizethis_app/providers/production_panel_projection_provider.dart';
import 'package:colonizethis_app/providers/units_panel_session_cache_provider.dart';
import 'package:colonizethis_app/providers/victory_panel_session_cache_provider.dart';
import 'package:colonizethis_app/providers/technology_panel_session_cache_provider.dart';
import 'package:colonizethis_app/providers/region_minimap_provider.dart';
import 'package:colonizethis_app/providers/turn_resolution_blocking_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _log = packageLogger('logic');

/// Drops all game-session providers, GameService caches, and bus deferred work.
/// Does not touch [settingsProvider], Hive, or Flutter/Flame asset caches.
void clearActiveGameSession(ProviderContainer container) {
  _log.i('logic: clearActiveGameSession');
  container.read(currentGameProvider.notifier).clear();
  container.read(currentOrdersProvider.notifier).clear();
  container.read(productionDesiredOutputProvider.notifier).replaceAll(const {});
  container.read(observeSessionProvider.notifier).reset();
  container.read(pendingDiplomacyProvider.notifier).clear();
  container.read(tribeFirstContactHeraldQueueProvider.notifier).clear();
  container.read(tribeFirstContactHeraldsShownProvider.notifier).clear();
  container.read(gameIdsWithIntroShownProvider.notifier).clear();
  container.read(mapProvincePanelProvider.notifier).reset();
  container.read(provinceOverlayReadModelCacheProvider).reset();
  container.read(productionPanelSessionCacheProvider).reset();
  container.read(unitsPanelSessionCacheProvider).reset();
  container.read(counselPanelSessionCacheProvider).reset();
  container.read(diplomacyPanelSessionCacheProvider).reset();
  container.read(victoryPanelSessionCacheProvider).reset();
  container.read(technologyPanelSessionCacheProvider).reset();
  container.read(regionMinimapVisibleProvider.notifier).reset();
  container.read(mapProvinceOverlayVisibleProvider.notifier).reset();
  container.read(mapProvinceOwnershipTintVisibleProvider.notifier).reset();
  container.read(mapProvinceNamesVisibleProvider.notifier).reset();
  container.read(turnResolutionBlockingProvider.notifier).set(false);
  container.read(offlineQueueProvider.notifier).clear();
  container.read(gameServiceProvider).clearSessionCaches();
  container.read(appEventBusProvider).dropUnconsumedEvents();
}

/// Applies a loaded [GameSaveSession] to session providers (after clear+disk load).
void applyGameSaveSession(ProviderContainer container, GameSaveSession session) {
  container.read(currentGameProvider.notifier).setGame(session.game);
  container.read(currentOrdersProvider.notifier).replaceAll(session.draftOrders);
  container
      .read(productionDesiredOutputProvider.notifier)
      .replaceAll(session.productionDesiredOutputByRecipe);
}

/// Clear → load → apply. Returns null when load fails after clear (empty session).
GameSaveSession? clearLoadAndApplyGameSession({
  required ProviderContainer container,
  required GameSaveSession? Function() load,
}) {
  clearActiveGameSession(container);
  final session = load();
  if (session == null) {
    _log.w('logic: clearLoadAndApplyGameSession load returned null');
    return null;
  }
  applyGameSaveSession(container, session);
  return session;
}

/// Installs a newly created [Game] after an earlier [clearActiveGameSession]
/// (clear must run **before** create so the new map cache is not wiped).
void applyNewGameSession(ProviderContainer container, Game game) {
  container.read(currentGameProvider.notifier).setGame(game);
  container.read(currentOrdersProvider.notifier).clear();
  container.read(productionDesiredOutputProvider.notifier).replaceAll(const {});
}
