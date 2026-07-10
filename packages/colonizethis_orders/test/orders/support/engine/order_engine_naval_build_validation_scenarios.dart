// Table-driven OrderEngine naval/build validation scenarios (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../scenario_runner.dart';
import 'order_engine_naval_build_validation_expectation_shorthand.dart';

/// One row in [orderEngineNavalBuildValidationScenarios].
class OrderEngineNavalBuildValidationScenario implements RefsScenario {
  const OrderEngineNavalBuildValidationScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

void runOrderEngineNavalBuildValidationScenario(
  OrderEngineNavalBuildValidationScenario scenario,
) {
  scenario.run();
}

/// Canonical scenarios for OrderEngine naval/build validation family tests.
/// Labels must match wave-3 [DESCRIPTION_BASELINE.txt] entries and former
/// `order_engine_naval_build_validation_test.dart` descriptions.
List<OrderEngineNavalBuildValidationScenario>
    orderEngineNavalBuildValidationScenarios() => [
          OrderEngineNavalBuildValidationScenario(
            label: 'move order accepted for own province across regions',
            run: () => nvExpectCrossRegionMove(
              unitType: kUnitTypeBuilder,
              nwOwnerId: 'p1',
              expectedStatus: OrderValidationStatus.accepted,
            ),
          ),
          OrderEngineNavalBuildValidationScenario(
            label: 'move order rejected when destination is foreign province across regions',
            run: () => nvExpectCrossRegionMove(
              unitType: 'musketeers',
              nwOwnerId: 'p2',
              expectedStatus: OrderValidationStatus.rejected,
            ),
          ),
          OrderEngineNavalBuildValidationScenario(
            label: 'work order rejected for invalid target for unit type',
            run: nvExpectInvalidWorkTargetRejected,
          ),
          OrderEngineNavalBuildValidationScenario(
            label: 'initial orders copy: getter returns equal but distinct lists',
            run: nvExpectInitialOrdersCopyDistinct,
          ),
          OrderEngineNavalBuildValidationScenario(
            label: 'naval move order rejected when fleet not found',
            run: nvExpectNavalMoveFleetNotFoundRejected,
          ),
          OrderEngineNavalBuildValidationScenario(
            label: 'blockade order rejected when not at war with province owner',
            run: () => nvExpectBlockadeMission(
              relationState: RelationState.atPeace,
              expectedStatus: OrderValidationStatus.rejected,
              reasonContains: 'at war',
            ),
          ),
          OrderEngineNavalBuildValidationScenario(
            label: 'blockade order accepted when at war with province owner',
            run: () => nvExpectBlockadeMission(
              relationState: RelationState.atWar,
              expectedStatus: OrderValidationStatus.accepted,
            ),
          ),
        ];
