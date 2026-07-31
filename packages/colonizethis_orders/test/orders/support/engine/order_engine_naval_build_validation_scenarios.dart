// Table-driven OrderEngine naval/build validation scenarios (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../scenario_runner.dart';
import 'order_engine_naval_build_validation_expectation_shorthand.dart';

/// Canonical scenarios for OrderEngine naval/build validation family tests.
/// Labels must match wave-3 [DESCRIPTION_BASELINE.txt] entries and former
/// `order_engine_naval_build_validation_test.dart` descriptions.
List<RunnableScenario> orderEngineNavalBuildValidationScenarios() => [
  rs('move order accepted for own province across regions', () => nvExpectCrossRegionMove(unitType: kUnitTypeBuilder, nwOwnerId: 'p1', expectedStatus: OrderValidationStatus.accepted)),
  rs('move order rejected when destination is foreign province across regions',() => nvExpectCrossRegionMove(unitType: 'musketeers',nwOwnerId: 'p2',expectedStatus: OrderValidationStatus.rejected),),
  rs('work order rejected for invalid target for unit type', nvExpectInvalidWorkTargetRejected),
  rs('initial orders copy: getter returns equal but distinct lists', nvExpectInitialOrdersCopyDistinct),
  rs('naval move order rejected when fleet not found', nvExpectNavalMoveFleetNotFoundRejected),
  rs('blockade order rejected when not at war with province owner',() => nvExpectBlockadeMission(relationState: RelationState.atPeace,expectedStatus: OrderValidationStatus.rejected,reasonContains: 'not legal'),),
  rs('blockade order accepted when at war with province owner', () => nvExpectBlockadeMission(relationState: RelationState.atWar, expectedStatus: OrderValidationStatus.accepted)),
];
