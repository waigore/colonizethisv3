import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../world/player_view.dart';

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
    Map<String, Unit>? unitsById,
  });
  List<NavalMissionOrder> suggestNavalMissionOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders, {
    Map<String, Unit>? unitsById,
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
}
