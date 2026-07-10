// Table-driven OrderEngine naval/build validation scenarios (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../scenario_runner.dart';
import 'order_engine_naval_build_validation_expectation_shorthand.dart';

/// Canonical scenarios for OrderEngine naval/build validation family tests.
/// Labels must match wave-3 [DESCRIPTION_BASELINE.txt] entries and former
/// `order_engine_naval_build_validation_test.dart` descriptions.
List<RunnableScenario> orderEngineNavalBuildValidationScenarios() => [
  RunnableScenario(
    label: 'move order accepted for own province across regions',
    run: () => nvExpectCrossRegionMove(
      unitType: kUnitTypeBuilder,
      nwOwnerId: 'p1',
      expectedStatus: OrderValidationStatus.accepted,
    ),
  ),
  RunnableScenario(
    label:
        'move order rejected when destination is foreign province across regions',
    run: () => nvExpectCrossRegionMove(
      unitType: 'musketeers',
      nwOwnerId: 'p2',
      expectedStatus: OrderValidationStatus.rejected,
    ),
  ),
  RunnableScenario(
    label: 'work order rejected for invalid target for unit type',
    run: nvExpectInvalidWorkTargetRejected,
  ),
  RunnableScenario(
    label: 'initial orders copy: getter returns equal but distinct lists',
    run: nvExpectInitialOrdersCopyDistinct,
  ),
  RunnableScenario(
    label: 'naval move order rejected when fleet not found',
    run: nvExpectNavalMoveFleetNotFoundRejected,
  ),
  RunnableScenario(
    label: 'blockade order rejected when not at war with province owner',
    run: () => nvExpectBlockadeMission(
      relationState: RelationState.atPeace,
      expectedStatus: OrderValidationStatus.rejected,
      reasonContains: 'at war',
    ),
  ),
  RunnableScenario(
    label: 'blockade order accepted when at war with province owner',
    run: () => nvExpectBlockadeMission(
      relationState: RelationState.atWar,
      expectedStatus: OrderValidationStatus.accepted,
    ),
  ),
];
