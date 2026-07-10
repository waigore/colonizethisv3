// Table-driven DefaultOrderSuggestionAPI suggestion scenarios (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';
import 'order_suggestion_api_impl_fixtures.dart';

const _api = DefaultOrderSuggestionAPI();

void osaiRunSuggestMoveOrdersReturnsList() {
  final game = apiImplDefaultGame();
  final view = apiImplViewFor(game, apiImplBaseTopology);
  final list = _api.suggestMoveOrders(
    view,
    game,
    apiImplBaseTopology,
    apiImplEmptyOrders,
  );
  expect(list, isA<List<MoveOrder>>());
}

void osaiRunSuggestWorkOrdersReturnsList() {
  final game = apiImplDefaultGame();
  final view = apiImplViewFor(game, apiImplBaseTopology);
  final list = _api.suggestWorkOrders(
    view,
    game,
    apiImplBaseTopology,
    apiImplEmptyOrders,
  );
  expect(list, isA<List<WorkOrder>>());
}

void osaiRunSuggestBuildOrdersReturnsList() {
  final game = apiImplDefaultGame();
  final view = apiImplViewFor(game, apiImplBaseTopology);
  final list = _api.suggestBuildOrders(
    view,
    game,
    apiImplBaseTopology,
    apiImplEmptyOrders,
  );
  expect(list, isA<List<BuildUnitOrder>>());
}

void osaiRunSuggestBuildOrdersIncludesShipWhenAffordable() {
  final game = apiImplAffordableShipGame();
  final view = apiImplViewFor(game, apiImplSingleProvinceTopology);
  final list = _api.suggestBuildOrders(
    view,
    game,
    apiImplSingleProvinceTopology,
    apiImplEmptyOrders,
  );
  final shipBuilds = list
      .where((o) => ShipEconomyCatalog.byId.containsKey(o.unitType))
      .toList();
  expect(
    shipBuilds,
    isNotEmpty,
    reason: 'API should suggest ship builds when affordable',
  );
}

void osaiRunSuggestResearchOrdersReturnsList() {
  final game = apiImplDefaultGame();
  final view = apiImplViewFor(game, apiImplBaseTopology);
  final list = _api.suggestResearchOrders(
    view,
    game,
    apiImplBaseTopology,
    apiImplEmptyOrders,
  );
  expect(list, isA<List<ResearchOrder>>());
}

void osaiRunSuggestNavalMoveOrdersReturnsList() {
  final game = apiImplDefaultGame();
  final view = apiImplViewFor(game, apiImplBaseTopology);
  final list = _api.suggestNavalMoveOrders(
    view,
    game,
    apiImplBaseTopology,
    apiImplEmptyOrders,
  );
  expect(list, isA<List<NavalMoveOrder>>());
}

void osaiRunSuggestNavalMissionOrdersReturnsList() {
  final game = apiImplDefaultGame();
  final view = apiImplViewFor(game, apiImplBaseTopology);
  final list = _api.suggestNavalMissionOrders(
    view,
    game,
    apiImplBaseTopology,
    apiImplEmptyOrders,
  );
  expect(list, isA<List<NavalMissionOrder>>());
}

void osaiRunNavalOrdersMatchWhenCallerSuppliesUnitsById() {
  final game = apiImplDefaultGame();
  final view = apiImplViewFor(game, apiImplBaseTopology);
  final unitsById = unitsByIdFromWorld(game.worldState);
  final moveDefault = _api.suggestNavalMoveOrders(
    view,
    game,
    apiImplBaseTopology,
    apiImplEmptyOrders,
  );
  final moveShared = _api.suggestNavalMoveOrders(
    view,
    game,
    apiImplBaseTopology,
    apiImplEmptyOrders,
    resolution: orderResolutionContextFromView(
      view,
      game,
      unitsById: unitsById,
    ),
  );
  expect(moveShared, moveDefault);
  final missionDefault = _api.suggestNavalMissionOrders(
    view,
    game,
    apiImplBaseTopology,
    apiImplEmptyOrders,
  );
  final missionShared = _api.suggestNavalMissionOrders(
    view,
    game,
    apiImplBaseTopology,
    apiImplEmptyOrders,
    resolution: orderResolutionContextFromView(
      view,
      game,
      unitsById: unitsById,
    ),
  );
  expect(missionShared, missionDefault);
}

void osaiRunSuggestDiplomaticOrdersReturnsList() {
  final game = apiImplDefaultGame();
  final view = apiImplViewFor(game, apiImplBaseTopology);
  final list = _api.suggestDiplomaticOrders(
    view,
    game,
    apiImplBaseTopology,
    apiImplEmptyOrders,
  );
  expect(list, isA<List<DiplomaticOrder>>());
}

void osaiRunSuggestRecruitWorkerOrdersReturnsList() {
  final game = apiImplDefaultGame();
  final view = apiImplViewFor(game, apiImplBaseTopology);
  final list = _api.suggestRecruitWorkerOrders(
    view,
    game,
    apiImplBaseTopology,
    apiImplEmptyOrders,
  );
  expect(list, isA<List<RecruitWorkerOrder>>());
}

void osaiRunSuggestRecruitWorkerOrdersIncludesPeasantWhenFabricAffordable() {
  final game = apiImplFabricRecruitGame();
  final view = apiImplViewFor(game, apiImplSingleProvinceTopology);
  final list = _api.suggestRecruitWorkerOrders(
    view,
    game,
    apiImplSingleProvinceTopology,
    apiImplEmptyOrders,
  );
  expect(
    list.any((o) => o.targetTier == WorkerTier.peasant),
    isTrue,
    reason:
        'API impl must surface peasant recruit when 2 fabric affords '
        'the cost row',
  );
}

List<RunnableScenario> orderSuggestionApiImplScenarios() => const [
  rs('suggestMoveOrders returns list', osaiRunSuggestMoveOrdersReturnsList),
  rs('suggestWorkOrders returns list', osaiRunSuggestWorkOrdersReturnsList),
  rs('suggestBuildOrders returns list', osaiRunSuggestBuildOrdersReturnsList),
  rs('suggestBuildOrders includes ship types when player can afford a ship', osaiRunSuggestBuildOrdersIncludesShipWhenAffordable),
  rs('suggestResearchOrders returns list', osaiRunSuggestResearchOrdersReturnsList),
  rs('suggestNavalMoveOrders returns list', osaiRunSuggestNavalMoveOrdersReturnsList),
  rs('suggestNavalMissionOrders returns list', osaiRunSuggestNavalMissionOrdersReturnsList),
  rs('suggestNavalMoveOrders and suggestNavalMissionOrders match when caller supplies unitsById (Refs #2394)', osaiRunNavalOrdersMatchWhenCallerSuppliesUnitsById, '#2394'),
  rs('suggestDiplomaticOrders returns list', osaiRunSuggestDiplomaticOrdersReturnsList),
  rs('suggestRecruitWorkerOrders returns list (#2692 S7)', osaiRunSuggestRecruitWorkerOrdersReturnsList, '#2692 S7'),
  rs('suggestRecruitWorkerOrders includes peasant when fabric is affordable (#2692 S7)', osaiRunSuggestRecruitWorkerOrdersIncludesPeasantWhenFabricAffordable, '#2692 S7'),
];
