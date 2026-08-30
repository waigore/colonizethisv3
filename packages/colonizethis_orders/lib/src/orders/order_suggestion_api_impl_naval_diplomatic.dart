import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'order_resolution_context.dart';
import 'order_suggestion.dart' as suggestion;
import 'order_suggestion_api.dart';
import 'order_suggestion_api_impl_helpers.dart';

/// Naval and diplomatic [OrderSuggestionAPI] methods for [DefaultOrderSuggestionAPI].
mixin OrderSuggestionAPINavalDiplomatic {
  @override
  List<NavalMoveOrder> suggestNavalMoveOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders, {
    OrderResolutionContext? resolution,
  }) {
    final ctx = standardSuggestContext(
      view: view,
      game: game,
      topology: topology,
      currentOrders: currentOrders,
    );
    return ctx.loggedSuggest(
      'suggestNavalMoveOrders',
      () => suggestion.suggestNavalMoveOrders(
        ctx.view,
        ctx.game,
        ctx.topology,
        ctx.currentOrders,
        resolution: resolution,
      ),
    );
  }

  @override
  List<NavalMissionOrder> suggestNavalMissionOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders, {
    OrderResolutionContext? resolution,
  }) {
    final ctx = standardSuggestContext(
      view: view,
      game: game,
      topology: topology,
      currentOrders: currentOrders,
    );
    return ctx.loggedSuggest(
      'suggestNavalMissionOrders',
      () => suggestion.suggestNavalMissionOrders(
        ctx.view,
        ctx.game,
        ctx.topology,
        ctx.currentOrders,
        resolution: resolution,
      ),
    );
  }

  @override
  List<DiplomaticOrder> suggestDiplomaticOrders(
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
      'suggestDiplomaticOrders',
      () => suggestion.suggestDiplomaticOrders(
        ctx.view,
        ctx.game,
        ctx.topology,
        ctx.currentOrders,
        tileMapByRegion: tileMapByRegion,
      ),
    );
  }

  @override
  List<DiplomaticOrder> suggestDeclareWarOrders(
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
      'suggestDeclareWarOrders',
      () => suggestion.suggestDeclareWarOrders(
        ctx.view,
        ctx.game,
        ctx.topology,
        ctx.currentOrders,
        tileMapByRegion: tileMapByRegion,
      ),
    );
  }
}
