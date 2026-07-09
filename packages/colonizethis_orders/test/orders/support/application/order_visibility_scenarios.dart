// Table-driven order-visibility scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_visibility_expectations.dart';

/// One row in order-visibility scenario tables.
class OrderVisibilityScenario implements RefsScenario {
  const OrderVisibilityScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderVisibilityTarget target;
  @override
  final String? refs;
}

void runOrderVisibilityScenario(OrderVisibilityScenario scenario) {
  runOrderVisibilityExpectation(scenario.target);
}

/// Scenarios for provinceHasAtLeastVisibility.
List<OrderVisibilityScenario> provinceHasAtLeastVisibilityScenarios() => const [
      OrderVisibilityScenario(
        label: 'false when no tile has 4-part key for region/province',
        target: OrderVisibilityTarget.provinceHasAtLeastVisibilityNoTileKey,
      ),
      OrderVisibilityScenario(
        label: 'true when a tile in province has at least min visibility',
        target: OrderVisibilityTarget.provinceHasAtLeastVisibilityTileMeetsMin,
      ),
      OrderVisibilityScenario(
        label: 'ignores tile keys with wrong number of parts',
        target: OrderVisibilityTarget.provinceHasAtLeastVisibilityIgnoresBadKeyParts,
      ),
      OrderVisibilityScenario(
        label: 'provinceHasAtLeastVisibility returns false when parts.length != 4',
        target: OrderVisibilityTarget.provinceHasAtLeastVisibilityWrongPartCount,
      ),
    ];

/// Scenarios for tileHasAtLeastVisibility.
List<OrderVisibilityScenario> tileHasAtLeastVisibilityScenarios() => const [
      OrderVisibilityScenario(
        label: 'true when tile has at least min level',
        target: OrderVisibilityTarget.tileHasAtLeastVisibilityTrue,
      ),
      OrderVisibilityScenario(
        label: 'false when tile unknown',
        target: OrderVisibilityTarget.tileHasAtLeastVisibilityUnknown,
      ),
    ];

/// Scenarios for moveSourceVisibilityOk.
List<OrderVisibilityScenario> moveSourceVisibilityOkScenarios() => const [
      OrderVisibilityScenario(
        label: 'true when province has at least fogged',
        target: OrderVisibilityTarget.moveSourceVisibilityOkFogged,
      ),
    ];

/// Scenarios for moveDestVisibilityOk.
List<OrderVisibilityScenario> moveDestVisibilityOkScenarios() => const [
      OrderVisibilityScenario(
        label: 'true when province has at least fogged',
        target: OrderVisibilityTarget.moveDestVisibilityOkFogged,
      ),
    ];

/// Scenarios for workOrderVisibilityOk.
List<OrderVisibilityScenario> workOrderVisibilityOkScenarios() => const [
      OrderVisibilityScenario(
        label: 'explore requires partial reveal (known + unknown land tiles)',
        target: OrderVisibilityTarget.workExplorePartialReveal,
      ),
      OrderVisibilityScenario(
        label: 'explore rejects province with no unknown land tile',
        target: OrderVisibilityTarget.workExploreRejectsNoUnknownLand,
      ),
      OrderVisibilityScenario(
        label: 'explore rejects when worldState omitted',
        target: OrderVisibilityTarget.workExploreRejectsWithoutWorldState,
      ),
      OrderVisibilityScenario(
        label: 'prospect requires at least fogged',
        target: OrderVisibilityTarget.workProspectRequiresFogged,
      ),
      OrderVisibilityScenario(
        label: 'build_improvement allows owned province',
        target: OrderVisibilityTarget.workBuildImprovementOwnedProvince,
      ),
      OrderVisibilityScenario(
        label: 'unknown workTarget returns false',
        target: OrderVisibilityTarget.workUnknownTargetReturnsFalse,
      ),
      OrderVisibilityScenario(
        label: 'counter_spy allows owned province without fogged',
        target: OrderVisibilityTarget.workCounterSpyOwnedWithoutFogged,
      ),
      OrderVisibilityScenario(
        label: 'build_fort with fogged visibility on owned province',
        target: OrderVisibilityTarget.workBuildFortFoggedOwned,
      ),
      OrderVisibilityScenario(
        label: 'build_road with targetTileKey uses tile key for region and province',
        target: OrderVisibilityTarget.workBuildRoadTargetTileKey,
      ),
    ];
