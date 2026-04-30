import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

part 'domain_planners_test_body_part.g.dart';

// Fake suggestion API used to drive domain planners deterministically in tests.
class _FakeOrderSuggestionAPI implements OrderSuggestionAPI {
  const _FakeOrderSuggestionAPI({
    required this.work,
    required this.build,
    required this.move,
    required this.research,
    required this.navalMove,
    required this.navalMission,
    this.diplomatic = const [],
    this.armyMove = const [],
  });

  final List<WorkOrder> work;
  final List<BuildUnitOrder> build;
  final List<MoveOrder> move;
  final List<ResearchOrder> research;
  final List<NavalMoveOrder> navalMove;
  final List<NavalMissionOrder> navalMission;
  final List<DiplomaticOrder> diplomatic;
  final List<ArmyMoveOrder> armyMove;

  @override
  List<MoveOrder> suggestMoveOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) => move;

  @override
  List<ArmyMoveOrder> suggestArmyMoveOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) => armyMove;

  @override
  List<WorkOrder> suggestWorkOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders, {
    Map<String, TileMapResult>? tileMapByRegion,
  }) => work;

  @override
  List<BuildUnitOrder> suggestBuildOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) => build;

  @override
  List<ResearchOrder> suggestResearchOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) => research;

  @override
  List<NavalMoveOrder> suggestNavalMoveOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) => navalMove;

  @override
  List<NavalMissionOrder> suggestNavalMissionOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) => navalMission;

  @override
  List<DiplomaticOrder> suggestDiplomaticOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders, {
    Map<String, TileMapResult>? tileMapByRegion,
  }) => diplomatic;
}

void main() {
  _defineTests();
}
