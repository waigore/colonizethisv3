import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_logic/industry_counsel_api.dart'
    show
        DevelopmentCounselRecommendation,
        MilitaryCounselRecommendation,
        TradeCounselBookResult,
        rankDevelopmentCounselRecommendations,
        rankIndustryCounselRecommendations,
        rankMilitaryCounselRecommendations,
        rankTradeCounselRecommendationsForHuman;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'panel_session_revision.dart'
    show panelOrdersRevision, panelWorldRevision;
import 'production_panel_projection_provider.dart'
    show productionDesiredOutputRevision;

typedef CounselPanelSessionRevision = ({
  String gameId,
  int turnNumber,
  int worldRevision,
  int ordersRevision,
  int desiredOutputRevision,
  int topologyRevision,
});

class CounselPanelSessionCacheState {
  const CounselPanelSessionCacheState({
    this.industryRevision,
    this.industry,
    this.tradeRevision,
    this.trade,
    this.militaryRevision,
    this.military,
    this.developmentRevision,
    this.development,
  });

  final CounselPanelSessionRevision? industryRevision;
  final List<IndustryCounselRecommendation>? industry;
  final CounselPanelSessionRevision? tradeRevision;
  final TradeCounselBookResult? trade;
  final CounselPanelSessionRevision? militaryRevision;
  final List<MilitaryCounselRecommendation>? military;
  final CounselPanelSessionRevision? developmentRevision;
  final List<DevelopmentCounselRecommendation>? development;
}

/// Cross-visit cache for `GAME90001` tab projections (Refs #4688 Slice 8).
class CounselPanelSessionCache {
  CounselPanelSessionCacheState state = const CounselPanelSessionCacheState();

  void reset() {
    state = const CounselPanelSessionCacheState();
  }
}

final counselPanelSessionCacheProvider = Provider<CounselPanelSessionCache>(
  (ref) => CounselPanelSessionCache(),
);

CounselPanelSessionRevision counselPanelSessionRevision({
  required Game game,
  required Orders orders,
  required Map<String, int> desiredOutputByRecipe,
  required MapTopology topology,
}) {
  return (
    gameId: game.id,
    turnNumber: game.worldState.turnState.turnNumber,
    worldRevision: panelWorldRevision(game),
    ordersRevision: panelOrdersRevision(orders),
    desiredOutputRevision: productionDesiredOutputRevision(desiredOutputByRecipe),
    topologyRevision: Object.hashAll(topology.nodes.map((node) => node.id)),
  );
}

List<IndustryCounselRecommendation> resolveCounselIndustryRecommendations({
  required CounselPanelSessionCache cache,
  required CounselPanelSessionRevision revision,
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
}) {
  if (cache.state.industryRevision == revision && cache.state.industry != null) {
    return cache.state.industry!;
  }
  final recommendations = ctAppPerfSync(
    'counsel.industryBuild',
    () => rankIndustryCounselRecommendations(
      game: game,
      playerId: playerId,
      currentOrders: currentOrders,
      topology: topology,
      tileMapByRegion: tileMapByRegion,
    ),
  );
  cache.state = CounselPanelSessionCacheState(
    industryRevision: revision,
    industry: recommendations,
    tradeRevision: cache.state.tradeRevision,
    trade: cache.state.trade,
    militaryRevision: cache.state.militaryRevision,
    military: cache.state.military,
    developmentRevision: cache.state.developmentRevision,
    development: cache.state.development,
  );
  return recommendations;
}

TradeCounselBookResult resolveCounselTradeBook({
  required CounselPanelSessionCache cache,
  required CounselPanelSessionRevision revision,
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
  required List<AssignedRecipe> productionAssignments,
}) {
  if (cache.state.tradeRevision == revision && cache.state.trade != null) {
    return cache.state.trade!;
  }
  final tradeCounsel = ctAppPerfSync(
    'counsel.tradeBuild',
    () => rankTradeCounselRecommendationsForHuman(
      game: game,
      playerId: playerId,
      productionAssignments: productionAssignments,
      currentOrders: currentOrders,
      topology: topology,
      tileMapByRegion: tileMapByRegion,
    ),
  );
  cache.state = CounselPanelSessionCacheState(
    industryRevision: cache.state.industryRevision,
    industry: cache.state.industry,
    tradeRevision: revision,
    trade: tradeCounsel,
    militaryRevision: cache.state.militaryRevision,
    military: cache.state.military,
    developmentRevision: cache.state.developmentRevision,
    development: cache.state.development,
  );
  return tradeCounsel;
}

List<MilitaryCounselRecommendation> resolveCounselMilitaryRecommendations({
  required CounselPanelSessionCache cache,
  required CounselPanelSessionRevision revision,
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required MapTopology topology,
}) {
  if (cache.state.militaryRevision == revision &&
      cache.state.military != null) {
    return cache.state.military!;
  }
  final recommendations = ctAppPerfSync(
    'counsel.militaryBuild',
    () => rankMilitaryCounselRecommendations(
      game: game,
      playerId: playerId,
      currentOrders: currentOrders,
      topology: topology,
    ),
  );
  cache.state = CounselPanelSessionCacheState(
    industryRevision: cache.state.industryRevision,
    industry: cache.state.industry,
    tradeRevision: cache.state.tradeRevision,
    trade: cache.state.trade,
    militaryRevision: revision,
    military: recommendations,
    developmentRevision: cache.state.developmentRevision,
    development: cache.state.development,
  );
  return recommendations;
}

List<DevelopmentCounselRecommendation> resolveCounselDevelopmentRecommendations({
  required CounselPanelSessionCache cache,
  required CounselPanelSessionRevision revision,
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
}) {
  if (cache.state.developmentRevision == revision &&
      cache.state.development != null) {
    return cache.state.development!;
  }
  final recommendations = ctAppPerfSync(
    'counsel.developmentBuild',
    () => rankDevelopmentCounselRecommendations(
      game: game,
      playerId: playerId,
      currentOrders: currentOrders,
      topology: topology,
      tileMapByRegion: tileMapByRegion,
    ),
  );
  cache.state = CounselPanelSessionCacheState(
    industryRevision: cache.state.industryRevision,
    industry: cache.state.industry,
    tradeRevision: cache.state.tradeRevision,
    trade: cache.state.trade,
    militaryRevision: cache.state.militaryRevision,
    military: cache.state.military,
    developmentRevision: revision,
    development: recommendations,
  );
  return recommendations;
}
