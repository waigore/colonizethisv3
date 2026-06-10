import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_economy/src/economy/world_market/trade_order_suggester.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'order_resolution_context.dart';

/// Abstract order suggestion API for AI. SPEC/program/order-engine.md, ai-systems-impl.md.
/// colonizethis_ai calls this to get candidate orders; logic provides the implementation.
abstract class OrderSuggestionAPI {
  List<MoveOrder> suggestMoveOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  );
  List<ArmyMoveOrder> suggestArmyMoveOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  );
  List<WorkOrder> suggestWorkOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders, {
    Map<String, TileMapResult>? tileMapByRegion,
  });
  List<BuildUnitOrder> suggestBuildOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  );
  List<RecruitWorkerOrder> suggestRecruitWorkerOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  );
  List<ResearchOrder> suggestResearchOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  );
  List<NavalMoveOrder> suggestNavalMoveOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders, {
    OrderResolutionContext? resolution,
  });
  List<NavalMissionOrder> suggestNavalMissionOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders, {
    OrderResolutionContext? resolution,
  });
  List<DiplomaticOrder> suggestDiplomaticOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders, {
    Map<String, TileMapResult>? tileMapByRegion,
  });
  List<DiplomaticOrder> suggestDeclareWarOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders, {
    Map<String, TileMapResult>? tileMapByRegion,
  });

  /// Returns validator-clean offer and bid suggestions for [view]'s player.
  ///
  /// SPEC/program/world-market-resolution.md § Trade order suggestion API.
  /// The default implementation derives a [TradeSuggestionContext] from
  /// `game` (current stockpile, home-fleet cargo holds, world-market bid
  /// type cap) and delegates to `TradeOrderSuggester.suggest`. Callers may
  /// pass an explicit [contextOverride] to inject a richer projection
  /// (industry allocation, forecast needs) without touching the API surface.
  TradeSuggestionResult suggestTradeOrders(
    PlayerView view,
    Game game, {
    TradeSuggestionContext? contextOverride,
  });
}
