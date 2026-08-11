import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'order_suggestion.dart' as suggestion;
import 'order_suggestion_api.dart';
import 'order_suggestion_api_impl_helpers.dart';
import 'order_suggestion_api_impl_naval_diplomatic.dart';
import 'order_suggestion_api_impl_trade.dart';

/// Default implementation of [OrderSuggestionAPI] using the top-level suggest* functions.
class DefaultOrderSuggestionAPI
    with OrderSuggestionAPINavalDiplomatic, OrderSuggestionAPITrade
    implements OrderSuggestionAPI {
  const DefaultOrderSuggestionAPI();

  @override
  List<MoveOrder> suggestMoveOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) {
    final ctx = standardSuggestContext(
      view: view,
      game: game,
      topology: topology,
      currentOrders: currentOrders,
    );
    return ctx.loggedSuggest(
      'suggestMoveOrders turn=${game.worldState.turnState.turnNumber}',
      () => suggestion.suggestMoveOrders(
        ctx.view,
        ctx.game,
        ctx.topology,
        ctx.currentOrders,
      ),
    );
  }

  @override
  List<ArmyMoveOrder> suggestArmyMoveOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) {
    final ctx = standardSuggestContext(
      view: view,
      game: game,
      topology: topology,
      currentOrders: currentOrders,
    );
    return ctx.loggedSuggest(
      'suggestArmyMoveOrders',
      () => suggestion.suggestArmyMoveOrders(
        ctx.view,
        ctx.game,
        ctx.topology,
        ctx.currentOrders,
      ),
    );
  }

  @override
  List<WorkOrder> suggestWorkOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders, {
    Map<String, TileMapResult>? tileMapByRegion,
  }) {
    final ctx = standardSuggestContext(
      view: view,
      game: game,
      topology: topology,
      currentOrders: currentOrders,
    );
    return ctx.loggedSuggest(
      'suggestWorkOrders',
      () => suggestion.suggestWorkOrders(
        ctx.view,
        ctx.game,
        ctx.topology,
        ctx.currentOrders,
        tileMapByRegion: tileMapByRegion,
      ),
    );
  }

  @override
  List<BuildUnitOrder> suggestBuildOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders, {
    bool includeCivilianBuilds = false,
  }) {
    final ctx = standardSuggestContext(
      view: view,
      game: game,
      topology: topology,
      currentOrders: currentOrders,
    );
    return ctx.loggedSuggest(
      'suggestBuildOrders',
      () => suggestion.suggestBuildOrders(
        ctx.view,
        ctx.game,
        ctx.topology,
        ctx.currentOrders,
        includeCivilianBuilds: includeCivilianBuilds,
      ),
    );
  }

  @override
  List<RecruitWorkerOrder> suggestRecruitWorkerOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) {
    final ctx = standardSuggestContext(
      view: view,
      game: game,
      topology: topology,
      currentOrders: currentOrders,
    );
    return ctx.loggedSuggest(
      'suggestRecruitWorkerOrders',
      () => suggestion.suggestRecruitWorkerOrders(
        ctx.view,
        ctx.game,
        ctx.topology,
        ctx.currentOrders,
      ),
    );
  }

  @override
  List<ResearchOrder> suggestResearchOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders, {
    int researchNavalWeight = 0,
    int researchMilitaryWeight = 0,
    int researchEconomicWeight = 0,
    int researchExplorationWeight = 0,
    int researchSeed = 0,
    int categoryDiversifyWeight = 0,
  }) {
    final ctx = standardSuggestContext(
      view: view,
      game: game,
      topology: topology,
      currentOrders: currentOrders,
    );
    return ctx.loggedSuggest(
      'suggestResearchOrders',
      () => suggestion.suggestResearchOrders(
        ctx.view,
        ctx.game,
        ctx.topology,
        ctx.currentOrders,
        researchNavalWeight: researchNavalWeight,
        researchMilitaryWeight: researchMilitaryWeight,
        researchEconomicWeight: researchEconomicWeight,
        researchExplorationWeight: researchExplorationWeight,
        researchSeed: researchSeed,
        categoryDiversifyWeight: categoryDiversifyWeight,
      ),
    );
  }
}
