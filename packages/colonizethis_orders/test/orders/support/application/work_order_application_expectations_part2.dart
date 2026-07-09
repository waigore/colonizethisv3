part of 'work_order_application_expectations.dart';

void _unknownWorkTargetSkippedUnitStaysIdle() {
  waaExpectUnknownTargetIdle();
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
