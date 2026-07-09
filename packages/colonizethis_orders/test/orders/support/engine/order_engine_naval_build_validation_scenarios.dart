// Table-driven OrderEngine naval/build validation scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_engine_naval_build_validation_expectations.dart';

/// One row in [orderEngineNavalBuildValidationScenarios].
class OrderEngineNavalBuildValidationScenario implements RefsScenario {
  const OrderEngineNavalBuildValidationScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderEngineNavalBuildValidationTarget target;
  @override
  final String? refs;
}

void runOrderEngineNavalBuildValidationScenario(
  OrderEngineNavalBuildValidationScenario scenario,
) {
  runOrderEngineNavalBuildValidationExpectation(scenario.target);
}

/// Canonical scenarios for OrderEngine naval/build validation family tests.
/// Labels must match wave-3 [DESCRIPTION_BASELINE.txt] entries and former
/// `order_engine_naval_build_validation_test.dart` descriptions.
List<OrderEngineNavalBuildValidationScenario>
    orderEngineNavalBuildValidationScenarios() => const [
          OrderEngineNavalBuildValidationScenario(
            label: 'move order accepted for own province across regions',
            target: OrderEngineNavalBuildValidationTarget
                .moveAcceptedOwnProvinceAcrossRegions,
          ),
          OrderEngineNavalBuildValidationScenario(
            label: 'move order rejected when destination is foreign province across regions',
            target: OrderEngineNavalBuildValidationTarget
                .moveRejectedForeignProvinceAcrossRegions,
          ),
          OrderEngineNavalBuildValidationScenario(
            label: 'work order rejected for invalid target for unit type',
            target: OrderEngineNavalBuildValidationTarget
                .workRejectedInvalidTargetForUnitType,
          ),
          OrderEngineNavalBuildValidationScenario(
            label: 'initial orders copy: getter returns equal but distinct lists',
            target:
                OrderEngineNavalBuildValidationTarget.initialOrdersCopyDistinctLists,
          ),
          OrderEngineNavalBuildValidationScenario(
            label: 'naval move order rejected when fleet not found',
            target:
                OrderEngineNavalBuildValidationTarget.navalMoveRejectedFleetNotFound,
          ),
          OrderEngineNavalBuildValidationScenario(
            label: 'blockade order rejected when not at war with province owner',
            target: OrderEngineNavalBuildValidationTarget.blockadeRejectedNotAtWar,
          ),
          OrderEngineNavalBuildValidationScenario(
            label: 'blockade order accepted when at war with province owner',
            target: OrderEngineNavalBuildValidationTarget.blockadeAcceptedAtWar,
          ),
        ];
