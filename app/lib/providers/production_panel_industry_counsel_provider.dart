import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_logic/industry_counsel_api.dart'
    show rankIndustryCounselRecommendations;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/game/widgets/shell/shell_player_context.dart';
import 'game_service_provider.dart';
import 'games_provider.dart';
import 'production_allocation_provider.dart';
import 'production_panel_session_cache.dart';

/// Industry counsel stars — deferred from first paint; session-cached on reopen.
final productionPanelIndustryCounselProvider = Provider.autoDispose<
    Map<String, IndustryCounselRecommendation>?>((ref) {
  final game = ref.watch(currentGameProvider);
  if (game == null) return null;
  final orders = ref.watch(currentOrdersProvider);
  final desiredOutputByRecipe = ref.watch(productionDesiredOutputProvider);
  final mapData = ref.watch(gameServiceProvider).getMapData(game.id);
  if (mapData == null) return null;

  final playerId = resolveShellPanelPlayerId(
    ref.watch(shellPlayerContextProvider),
    game,
  );
  final revision = productionPanelSessionRevision(
    game: game,
    orders: orders,
    desiredOutputByRecipe: desiredOutputByRecipe,
  );
  final session = ref.read(productionPanelSessionCacheProvider).state;
  if (session.counselRevision == revision &&
      session.starredProduceRecommendationsByRecipeId != null) {
    return session.starredProduceRecommendationsByRecipeId;
  }

  final recommendations = ctAppPerfSync(
    'production.industryCounsel',
    () => rankIndustryCounselRecommendations(
      game: game,
      playerId: playerId,
      currentOrders: orders,
      topology: mapData.combinedTopology,
      tileMapByRegion: mapData.tileMapByRegion,
    ),
  );
  final starred = starredProduceRecommendationsFromRanked(recommendations);
  ref.read(productionPanelSessionCacheProvider).storeIndustryCounsel(
        revision: revision,
        starredProduceRecommendationsByRecipeId: starred,
      );
  return starred;
});
