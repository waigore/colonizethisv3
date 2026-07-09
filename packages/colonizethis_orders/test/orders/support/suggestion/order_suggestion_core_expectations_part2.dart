part of 'order_suggestion_core_expectations.dart';

void _suggestBuildOrdersReturnsList() {
  oscExpectCapitalBuildSuggestList(
    oscPlayer(
      capitalProvinceId: OscIds.prov('p1'),
      workerPool: const WorkerPool(peasants: 2),
      treasury: 500,
    ),
  );
}

void _suggestBuildOrdersReturnsShipWhenAffordable() {
  oscExpectAffordableShipBuildSuggestions();
}

void _suggestBuildOrdersCanReturnBothRegimentAndShipWhenBothAffordable() {
  oscExpectAffordableRegimentAndShipBuildSuggestions();
}

void _suggestResearchOrdersReturnsList() {
  oscExpectResearchSuggestList();
}

void _suggestNavalMoveOrdersReturnsList() {
  oscExpectNavalMoveSuggestList();
}

void _counterSpyWorkSuggestedForSpyInOwnedProvinceWithTiles() {
  oscExpectWorkTargetNotEmpty(
    oscSuggestWork(oscSpyInOwnedProvinceGame(), oscProvinceTopology(['p1'])),
    kWorkTargetCounterSpy,
  );
}

void _purchaseLandWorkSuggestedForMerchantWhenMinorProvinceHasResourceTile() {
  oscExpectMerchantPurchaseLandWorkSuggested();
}
