import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

// Fake suggestion API used to drive domain planners deterministically in tests.
class FakeOrderSuggestionAPIForDomainPlannerTests
    implements OrderSuggestionAPI {
  const FakeOrderSuggestionAPIForDomainPlannerTests({
    required this.work,
    required this.build,
    required this.move,
    required this.research,
    required this.navalMove,
    required this.navalMission,
    this.diplomatic = const [],
    this.armyMove = const [],
    this.recruitWorker = const [],
  });

  final List<WorkOrder> work;
  final List<BuildUnitOrder> build;
  final List<MoveOrder> move;
  final List<ResearchOrder> research;
  final List<NavalMoveOrder> navalMove;
  final List<NavalMissionOrder> navalMission;
  final List<DiplomaticOrder> diplomatic;
  final List<ArmyMoveOrder> armyMove;
  final List<RecruitWorkerOrder> recruitWorker;

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
    Orders currentOrders, {
    bool includeCivilianBuilds = false,
  }) => build;

  @override
  List<RecruitWorkerOrder> suggestRecruitWorkerOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) => recruitWorker;

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
  }) => research;

  @override
  List<NavalMoveOrder> suggestNavalMoveOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders, {
    OrderResolutionContext? resolution,
  }) => navalMove;

  @override
  List<NavalMissionOrder> suggestNavalMissionOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders, {
    OrderResolutionContext? resolution,
  }) => navalMission;

  @override
  List<DiplomaticOrder> suggestDiplomaticOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders, {
    Map<String, TileMapResult>? tileMapByRegion,
  }) => diplomatic;

  @override
  List<DiplomaticOrder> suggestDeclareWarOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders, {
    Map<String, TileMapResult>? tileMapByRegion,
  }) => diplomatic
      .where((o) => o.type == DiplomaticOrderType.declareWar)
      .toList();

  @override
  TradeSuggestionResult suggestTradeOrders(
    PlayerView view,
    Game game, {
    TradeSuggestionContext? contextOverride,
  }) => TradeSuggestionResult.empty;
}
