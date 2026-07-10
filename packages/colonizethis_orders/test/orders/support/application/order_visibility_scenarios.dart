// Table-driven order-visibility scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_visibility_run_rows.dart';

/// One row in order-visibility scenario tables.
class OrderVisibilityScenario implements RefsScenario {
  const OrderVisibilityScenario({
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

void runOrderVisibilityScenario(OrderVisibilityScenario scenario) {
  scenario.run();
}

/// Scenarios for provinceHasAtLeastVisibility.
List<OrderVisibilityScenario> provinceHasAtLeastVisibilityScenarios() => const [
      OrderVisibilityScenario(
        label: 'false when no tile has 4-part key for region/province',
        run: ovRunProvinceHasAtLeastVisibilityNoTileKey,
      ),
      OrderVisibilityScenario(
        label: 'true when a tile in province has at least min visibility',
        run: ovRunProvinceHasAtLeastVisibilityTileMeetsMin,
      ),
      OrderVisibilityScenario(
        label: 'ignores tile keys with wrong number of parts',
        run: ovRunProvinceHasAtLeastVisibilityIgnoresBadKeyParts,
      ),
      OrderVisibilityScenario(
        label: 'provinceHasAtLeastVisibility returns false when parts.length != 4',
        run: ovRunProvinceHasAtLeastVisibilityWrongPartCount,
      ),
    ];

/// Scenarios for tileHasAtLeastVisibility.
List<OrderVisibilityScenario> tileHasAtLeastVisibilityScenarios() => const [
      OrderVisibilityScenario(
        label: 'true when tile has at least min level',
        run: ovRunTileHasAtLeastVisibilityTrue,
      ),
      OrderVisibilityScenario(
        label: 'false when tile unknown',
        run: ovRunTileHasAtLeastVisibilityUnknown,
      ),
    ];

/// Scenarios for moveSourceVisibilityOk.
List<OrderVisibilityScenario> moveSourceVisibilityOkScenarios() => const [
      OrderVisibilityScenario(
        label: 'true when province has at least fogged',
        run: ovRunMoveSourceVisibilityOkFogged,
      ),
    ];

/// Scenarios for moveDestVisibilityOk.
List<OrderVisibilityScenario> moveDestVisibilityOkScenarios() => const [
      OrderVisibilityScenario(
        label: 'true when province has at least fogged',
        run: ovRunMoveDestVisibilityOkFogged,
      ),
    ];

/// Scenarios for workOrderVisibilityOk.
List<OrderVisibilityScenario> workOrderVisibilityOkScenarios() => const [
      OrderVisibilityScenario(
        label: 'explore requires partial reveal (known + unknown land tiles)',
        run: ovRunWorkExplorePartialReveal,
      ),
      OrderVisibilityScenario(
        label: 'explore rejects province with no unknown land tile',
        run: ovRunWorkExploreRejectsNoUnknownLand,
      ),
      OrderVisibilityScenario(
        label: 'explore rejects when worldState omitted',
        run: ovRunWorkExploreRejectsWithoutWorldState,
      ),
      OrderVisibilityScenario(
        label: 'prospect requires at least fogged',
        run: ovRunWorkProspectRequiresFogged,
      ),
      OrderVisibilityScenario(
        label: 'build_improvement allows owned province',
        run: ovRunWorkBuildImprovementOwnedProvince,
      ),
      OrderVisibilityScenario(
        label: 'unknown workTarget returns false',
        run: ovRunWorkUnknownTargetReturnsFalse,
      ),
      OrderVisibilityScenario(
        label: 'counter_spy allows owned province without fogged',
        run: ovRunWorkCounterSpyOwnedWithoutFogged,
      ),
      OrderVisibilityScenario(
        label: 'build_fort with fogged visibility on owned province',
        run: ovRunWorkBuildFortFoggedOwned,
      ),
      OrderVisibilityScenario(
        label: 'build_road with targetTileKey uses tile key for region and province',
        run: ovRunWorkBuildRoadTargetTileKey,
      ),
    ];
