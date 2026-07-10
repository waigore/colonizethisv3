// Compact OrderEngine naval/build validation assertions (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'order_engine_naval_build_validation_expectation_shorthand.dart';

/// Pins for [orderEngineNavalBuildValidationScenarios] rows.
enum OrderEngineNavalBuildValidationTarget {
  moveAcceptedOwnProvinceAcrossRegions,
  moveRejectedForeignProvinceAcrossRegions,
  workRejectedInvalidTargetForUnitType,
  initialOrdersCopyDistinctLists,
  navalMoveRejectedFleetNotFound,
  blockadeRejectedNotAtWar,
  blockadeAcceptedAtWar,
}

void runOrderEngineNavalBuildValidationExpectation(
  OrderEngineNavalBuildValidationTarget target,
) {
  switch (target) {
    case OrderEngineNavalBuildValidationTarget.moveAcceptedOwnProvinceAcrossRegions:
      nvExpectCrossRegionMove(
        unitType: kUnitTypeBuilder,
        nwOwnerId: 'p1',
        expectedStatus: OrderValidationStatus.accepted,
      );
    case OrderEngineNavalBuildValidationTarget
        .moveRejectedForeignProvinceAcrossRegions:
      nvExpectCrossRegionMove(
        unitType: 'musketeers',
        nwOwnerId: 'p2',
        expectedStatus: OrderValidationStatus.rejected,
      );
    case OrderEngineNavalBuildValidationTarget.workRejectedInvalidTargetForUnitType:
      nvExpectInvalidWorkTargetRejected();
    case OrderEngineNavalBuildValidationTarget.initialOrdersCopyDistinctLists:
      nvExpectInitialOrdersCopyDistinct();
    case OrderEngineNavalBuildValidationTarget.navalMoveRejectedFleetNotFound:
      nvExpectNavalMoveFleetNotFoundRejected();
    case OrderEngineNavalBuildValidationTarget.blockadeRejectedNotAtWar:
      nvExpectBlockadeMission(
        relationState: RelationState.atPeace,
        expectedStatus: OrderValidationStatus.rejected,
        reasonContains: 'at war',
      );
    case OrderEngineNavalBuildValidationTarget.blockadeAcceptedAtWar:
      nvExpectBlockadeMission(
        relationState: RelationState.atWar,
        expectedStatus: OrderValidationStatus.accepted,
      );
  }
}
