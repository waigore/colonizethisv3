// dart format off
// Table-driven build-cost scenarios (Refs #3856, #3979).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Pins for unknown-unit afford/reject rows.
typedef BuildCostUnknownUnitPins = ({bool viaApplyDeduction, int peasants, int treasury, int expectedPeasants, int expectedTreasury});

BuildCostScenario buildCostUnknownUnitScenario({required String label, required BuildCostUnknownUnitPins pins}) =>
    (label: label, unknownUnit: pins, affordApply: null, affordReject: null, refs: null);

/// Pins for afford-then-apply catalog rows.
typedef BuildCostAffordApplyPins = ({String unitType, bool isMilitary, int peasants, int treasuryPadding});

BuildCostScenario buildCostAffordApplyScenario({required String label, required BuildCostAffordApplyPins pins}) =>
    (label: label, unknownUnit: null, affordApply: pins, affordReject: null, refs: null);

/// Pins for afford-reject rows.
typedef BuildCostAffordRejectPins = ({
  String unitType,
  bool isMilitary,
  int peasants,
  Map<String, bool>? techUnlocked,
  int treasuryPadding,
  String expectedReason,
});

BuildCostScenario buildCostAffordRejectScenario({required String label, required BuildCostAffordRejectPins pins}) =>
    (label: label, unknownUnit: null, affordApply: null, affordReject: pins, refs: null);

/// One row for build-cost tables (Refs #3979). Exactly one pin family is set.
typedef BuildCostScenario = ({
  String label,
  BuildCostUnknownUnitPins? unknownUnit,
  BuildCostAffordApplyPins? affordApply,
  BuildCostAffordRejectPins? affordReject,
  String? refs,
});

/// Canonical scenarios for [canAffordBuild] and [applyBuildCostDeduction].
List<BuildCostScenario> buildCostScenarios() => [
  buildCostUnknownUnitScenario(label: 'canAffordBuild returns false for unknown unit type', pins: (viaApplyDeduction: false, peasants: 10, treasury: 10000, expectedPeasants: 10, expectedTreasury: 10000)),
  buildCostUnknownUnitScenario(label: 'applyBuildCostDeduction returns unchanged state for unknown unit type', pins: (viaApplyDeduction: true, peasants: 5, treasury: 1000, expectedPeasants: 5, expectedTreasury: 1000)),
  buildCostAffordApplyScenario(label: 'civilian Builder: apply matches catalog after canAfford true', pins: (unitType: kUnitTypeBuilder, isMilitary: false, peasants: 10, treasuryPadding: 5000)),
  buildCostAffordApplyScenario(label: 'military peasant_levies: apply matches catalog after canAfford true', pins: (unitType: 'peasant_levies', isMilitary: true, peasants: 3, treasuryPadding: 500)),
  buildCostAffordApplyScenario(label: 'naval carrack: apply matches catalog after canAfford true', pins: (unitType: 'carrack', isMilitary: false, peasants: 10, treasuryPadding: 500)),
  buildCostAffordRejectScenario(label: 'naval carrack: canAfford false when peasants are zero', pins: (unitType: 'carrack', isMilitary: false, peasants: 0, techUnlocked: null, treasuryPadding: 10, expectedReason: 'Insufficient workers')),
  buildCostAffordRejectScenario(label: 'naval fluyte: canAfford false when unlocking tech missing', pins: (unitType: 'fluyte', isMilitary: false, peasants: 10, techUnlocked: {}, treasuryPadding: 500, expectedReason: 'Required technology not unlocked')),
  buildCostAffordRejectScenario(label: 'military lancers: canAfford false when unlocking tech missing', pins: (unitType: 'lancers', isMilitary: true, peasants: 5, techUnlocked: {}, treasuryPadding: 500, expectedReason: 'Required technology not unlocked')),
  buildCostAffordRejectScenario(label: 'military peasant_levies: canAfford false when peasants are zero', pins: (unitType: 'peasant_levies', isMilitary: true, peasants: 0, techUnlocked: null, treasuryPadding: 500, expectedReason: 'Insufficient workers')),
];
// dart format on
