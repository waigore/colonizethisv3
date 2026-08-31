import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart'
    show TradeCounselRecommendation, assignedRecipesFromDesiredOutput;
import 'package:colonizethis_logic/industry_counsel_api.dart'
    show
        rankTradeCounselRecommendationsForHuman,
        tradeCounselHighlightsByCommodityId;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/game_service/try_get_game_map_data.dart';
import '../features/game/widgets/shell/shell_player_context.dart';
import 'development_panel_projection_provider.dart'
    show developmentPanelOrdersRevision, developmentPanelWorldRevision;
import 'game_service_provider.dart';
import 'games_provider.dart';
import 'production_allocation_provider.dart';
import 'production_panel_projection_provider.dart'
    show productionDesiredOutputRevision;

typedef TradePanelSessionRevision = ({
  String gameId,
  int turnNumber,
  int worldRevision,
  int ordersRevision,
  int desiredOutputRevision,
  int topologyRevision,
  String playerId,
});

class TradePanelSessionCacheState {
  const TradePanelSessionCacheState({
    this.revision,
    this.highlightsByCommodityId,
  });

  final TradePanelSessionRevision? revision;
  final Map<String, TradeCounselRecommendation>? highlightsByCommodityId;
}

/// Cross-visit cache for `GAME60001` trade counsel highlights (Refs #4688 Slice 3).
class TradePanelSessionCache {
  TradePanelSessionCacheState state = const TradePanelSessionCacheState();

  void reset() {
    state = const TradePanelSessionCacheState();
  }
}

final tradePanelSessionCacheProvider = Provider<TradePanelSessionCache>(
  (ref) => TradePanelSessionCache(),
);

TradePanelSessionRevision tradePanelSessionRevision({
  required Game game,
  required String playerId,
  required Orders orders,
  required Map<String, int> desiredOutputByRecipe,
  required MapTopology topology,
}) {
  return (
    gameId: game.id,
    turnNumber: game.worldState.turnState.turnNumber,
    worldRevision: developmentPanelWorldRevision(game),
    ordersRevision: developmentPanelOrdersRevision(orders),
    desiredOutputRevision: productionDesiredOutputRevision(desiredOutputByRecipe),
    topologyRevision: Object.hashAll(topology.nodes.map((node) => node.id)),
    playerId: playerId,
  );
}

/// Trade counsel row highlights — deferred from first paint; session-cached on reopen.
final tradePanelTradeCounselHighlightsProvider = Provider.autoDispose<
    Map<String, TradeCounselRecommendation>?>((ref) {
  final game = ref.watch(currentGameProvider);
  if (game == null) return null;
  final orders = ref.watch(currentOrdersProvider);
  final desiredOutputByRecipe = ref.watch(productionDesiredOutputProvider);
  final mapData = tryGetGameMapData(
    () => ref.watch(gameServiceProvider).getMapData(game.id),
  );

  final playerId = resolveShellPanelPlayerId(
    ref.watch(shellPlayerContextProvider),
    game,
  );
  final MapTopology topology;
  final Map<String, TileMapResult> tileMapByRegion;
  if (mapData != null) {
    topology = mapData.combinedTopology;
    tileMapByRegion = mapData.tileMapByRegion;
  } else {
    topology = MapTopology();
    tileMapByRegion = const {};
  }
  final revision = tradePanelSessionRevision(
    game: game,
    playerId: playerId,
    orders: orders,
    desiredOutputByRecipe: desiredOutputByRecipe,
    topology: topology,
  );
  final session = ref.read(tradePanelSessionCacheProvider).state;
  if (session.revision == revision && session.highlightsByCommodityId != null) {
    return session.highlightsByCommodityId;
  }

  final productionAssignments = assignedRecipesFromDesiredOutput(
    desiredOutputByRecipe,
  );
  final tradeCounsel = ctAppPerfSync(
    'trade.counselBuild',
    () => rankTradeCounselRecommendationsForHuman(
      game: game,
      playerId: playerId,
      productionAssignments: productionAssignments,
      currentOrders: orders,
      topology: topology,
      tileMapByRegion: tileMapByRegion,
    ),
  );
  final highlights = tradeCounselHighlightsByCommodityId(tradeCounsel);
  ref.read(tradePanelSessionCacheProvider).state = TradePanelSessionCacheState(
    revision: revision,
    highlightsByCommodityId: highlights,
  );
  return highlights;
});
