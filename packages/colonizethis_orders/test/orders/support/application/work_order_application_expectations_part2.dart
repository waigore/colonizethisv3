part of 'work_order_application_expectations.dart';

void _unknownWorkTargetSkippedUnitStaysIdle() {
  final next = waaApply(
    workAppOwnedGame(units: [workAppUnit(type: kUnitTypeBuilder)]),
    workAppSingleWorkOrder(target: 'unknown_target'),
  );
  waaExpectUnitIdle(next);
}

void _buildRoadWithInsufficientMaterialsDoesNotSetCurrentWorkDeductStockpile() {
  waaExpectBuildRoadInsufficientMaterials();
}

void _buildRoadWithSufficientMaterialsDeductsMaterialsSetsCurrentWork() {
  waaExpectBuildRoadWithMaterialsDeductsStockpile();
}

void _counterSpyWorkOrderSetsCurrentWorkForSpyUnitOnOwnedCapitalProvince() {
  waaExpectCounterSpyOnCapital();
}

void _exploreWorkOrderSetsCurrentWorkWhenProvinceHasTiles() {
  waaExpectExploreWorkStarted();
}

void
_exploreWorkOrderTotalTurnsUsesRegionScopedFormulaCeil3TilesInPMaxTilesInRegion() {
  waaExpectExploreFormulaTiming();
}

void _engineerBuildRoadWorkOrderSetsCurrentWork() {
  waaExpectEngineerBuildRoadApplied();
}

void _buildPortWorkOrderSetsCurrentWorkWhenMaterialsSufficient() {
  waaExpectBuildPortApplied();
}
