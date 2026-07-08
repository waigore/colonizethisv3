// Table-driven build-cost scenarios (Refs #3856).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'build_cost_expectations.dart';

/// One row in a build-cost scenario table.
class BuildCostScenario {
  const BuildCostScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  final String label;
  final void Function() run;
  final String? refs;
}

/// Runs [scenario] (setup + assertions live in [BuildCostScenario.run]).
void runBuildCostScenario(BuildCostScenario scenario) {
  scenario.run();
}

/// Canonical scenarios for [canAffordBuild] and [applyBuildCostDeduction].
List<BuildCostScenario> buildCostScenarios() => [
      ..._buildCostUnknownUnitScenarios(),
      ..._buildCostAffordApplyScenarios(),
      ..._buildCostAffordRejectScenarios(),
    ];

List<BuildCostScenario> _buildCostUnknownUnitScenarios() => [
      buildCostUnknownUnitScenario(
        label: 'canAffordBuild returns false for unknown unit type',
        pins: (
          viaApplyDeduction: false,
          peasants: 10,
          treasury: 10000,
          expectedPeasants: 10,
          expectedTreasury: 10000,
        ),
      ),
      buildCostUnknownUnitScenario(
        label:
            'applyBuildCostDeduction returns unchanged state for unknown unit type',
        pins: (
          viaApplyDeduction: true,
          peasants: 5,
          treasury: 1000,
          expectedPeasants: 5,
          expectedTreasury: 1000,
        ),
      ),
    ];

List<BuildCostScenario> _buildCostAffordApplyScenarios() => [
      buildCostAffordApplyScenario(
        label: 'civilian Builder: apply matches catalog after canAfford true',
        pins: (
          unitType: kUnitTypeBuilder,
          isMilitary: false,
          peasants: 10,
          treasuryPadding: 5000,
        ),
      ),
      buildCostAffordApplyScenario(
        label: 'military peasant_levies: apply matches catalog after canAfford true',
        pins: (
          unitType: 'peasant_levies',
          isMilitary: true,
          peasants: 3,
          treasuryPadding: 500,
        ),
      ),
      buildCostAffordApplyScenario(
        label: 'naval carrack: apply matches catalog after canAfford true',
        pins: (
          unitType: 'carrack',
          isMilitary: false,
          peasants: 10,
          treasuryPadding: 500,
        ),
      ),
    ];

List<BuildCostScenario> _buildCostAffordRejectScenarios() => [
      buildCostAffordRejectScenario(
        label: 'naval carrack: canAfford false when peasants are zero',
        pins: (
          unitType: 'carrack',
          isMilitary: false,
          peasants: 0,
          techUnlocked: null,
          treasuryPadding: 10,
          expectedReason: 'Insufficient workers',
        ),
      ),
      buildCostAffordRejectScenario(
        label: 'naval fluyte: canAfford false when unlocking tech missing',
        pins: (
          unitType: 'fluyte',
          isMilitary: false,
          peasants: 10,
          techUnlocked: {},
          treasuryPadding: 500,
          expectedReason: 'Required technology not unlocked',
        ),
      ),
      buildCostAffordRejectScenario(
        label: 'military lancers: canAfford false when unlocking tech missing',
        pins: (
          unitType: 'lancers',
          isMilitary: true,
          peasants: 5,
          techUnlocked: {},
          treasuryPadding: 500,
          expectedReason: 'Required technology not unlocked',
        ),
      ),
      buildCostAffordRejectScenario(
        label: 'military peasant_levies: canAfford false when peasants are zero',
        pins: (
          unitType: 'peasant_levies',
          isMilitary: true,
          peasants: 0,
          techUnlocked: null,
          treasuryPadding: 500,
          expectedReason: 'Insufficient workers',
        ),
      ),
    ];
