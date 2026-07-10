// Compact DefaultOrderSuggestionAPI suggestion assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';

import 'order_suggestion_api_impl_fixtures.dart';

/// Pins for [orderSuggestionApiImplScenarios] rows.
enum OrderSuggestionApiImplTarget {
  suggestMoveOrdersReturnsList,
  suggestWorkOrdersReturnsList,
  suggestBuildOrdersReturnsList,
  suggestBuildOrdersIncludesShipWhenAffordable,
  suggestResearchOrdersReturnsList,
  suggestNavalMoveOrdersReturnsList,
  suggestNavalMissionOrdersReturnsList,
  navalOrdersMatchWhenCallerSuppliesUnitsById,
  suggestDiplomaticOrdersReturnsList,
  suggestRecruitWorkerOrdersReturnsList,
  suggestRecruitWorkerOrdersIncludesPeasantWhenFabricAffordable,
}

const _api = DefaultOrderSuggestionAPI();

void runOrderSuggestionApiImplExpectation(OrderSuggestionApiImplTarget target) {
  switch (target) {
    case OrderSuggestionApiImplTarget.suggestMoveOrdersReturnsList:
      final game = apiImplDefaultGame();
      final view = apiImplViewFor(game, apiImplBaseTopology);
      final list =
          _api.suggestMoveOrders(view, game, apiImplBaseTopology, apiImplEmptyOrders);
      expect(list, isA<List<MoveOrder>>());

    case OrderSuggestionApiImplTarget.suggestWorkOrdersReturnsList:
      final game = apiImplDefaultGame();
      final view = apiImplViewFor(game, apiImplBaseTopology);
      final list =
          _api.suggestWorkOrders(view, game, apiImplBaseTopology, apiImplEmptyOrders);
      expect(list, isA<List<WorkOrder>>());

    case OrderSuggestionApiImplTarget.suggestBuildOrdersReturnsList:
      final game = apiImplDefaultGame();
      final view = apiImplViewFor(game, apiImplBaseTopology);
      final list =
          _api.suggestBuildOrders(view, game, apiImplBaseTopology, apiImplEmptyOrders);
      expect(list, isA<List<BuildUnitOrder>>());

    case OrderSuggestionApiImplTarget.suggestBuildOrdersIncludesShipWhenAffordable:
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

    case OrderSuggestionApiImplTarget.suggestResearchOrdersReturnsList:
      final game = apiImplDefaultGame();
      final view = apiImplViewFor(game, apiImplBaseTopology);
      final list = _api.suggestResearchOrders(
        view,
        game,
        apiImplBaseTopology,
        apiImplEmptyOrders,
      );
      expect(list, isA<List<ResearchOrder>>());

    case OrderSuggestionApiImplTarget.suggestNavalMoveOrdersReturnsList:
      final game = apiImplDefaultGame();
      final view = apiImplViewFor(game, apiImplBaseTopology);
      final list = _api.suggestNavalMoveOrders(
        view,
        game,
        apiImplBaseTopology,
        apiImplEmptyOrders,
      );
      expect(list, isA<List<NavalMoveOrder>>());

    case OrderSuggestionApiImplTarget.suggestNavalMissionOrdersReturnsList:
      final game = apiImplDefaultGame();
      final view = apiImplViewFor(game, apiImplBaseTopology);
      final list = _api.suggestNavalMissionOrders(
        view,
        game,
        apiImplBaseTopology,
        apiImplEmptyOrders,
      );
      expect(list, isA<List<NavalMissionOrder>>());

    case OrderSuggestionApiImplTarget.navalOrdersMatchWhenCallerSuppliesUnitsById:
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
        resolution:
            orderResolutionContextFromView(view, game, unitsById: unitsById),
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
        resolution:
            orderResolutionContextFromView(view, game, unitsById: unitsById),
      );
      expect(missionShared, missionDefault);

    case OrderSuggestionApiImplTarget.suggestDiplomaticOrdersReturnsList:
      final game = apiImplDefaultGame();
      final view = apiImplViewFor(game, apiImplBaseTopology);
      final list = _api.suggestDiplomaticOrders(
        view,
        game,
        apiImplBaseTopology,
        apiImplEmptyOrders,
      );
      expect(list, isA<List<DiplomaticOrder>>());

    case OrderSuggestionApiImplTarget.suggestRecruitWorkerOrdersReturnsList:
      final game = apiImplDefaultGame();
      final view = apiImplViewFor(game, apiImplBaseTopology);
      final list = _api.suggestRecruitWorkerOrders(
        view,
        game,
        apiImplBaseTopology,
        apiImplEmptyOrders,
      );
      expect(list, isA<List<RecruitWorkerOrder>>());

    case OrderSuggestionApiImplTarget
        .suggestRecruitWorkerOrdersIncludesPeasantWhenFabricAffordable:
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
}
