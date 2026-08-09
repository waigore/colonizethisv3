// Scenario tables for civilian_build_scoring_test.dart (Refs #4121 slice D).
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// AC8: default min-cap counts per civilian type.
const civilianBuildMinCountCases = <(String, int)>[
  (kUnitTypeBuilder, 2),
  (kUnitTypeExplorer, 1),
  (kUnitTypeEngineer, 1),
  (kUnitTypeSpy, 0),
];

/// AC8: default target counts per civilian type.
const civilianBuildTargetCountCases = <(String, int)>[
  (kUnitTypeBuilder, 2),
  (kUnitTypeExplorer, 2),
  (kUnitTypeEngineer, 1),
];

/// AC8: default max-cap counts per civilian type (`null` = no ceiling).
const civilianBuildMaxCountCases = <(String, int?)>[
  (kUnitTypeBuilder, 6),
  (kUnitTypeSpy, null),
];

/// AC3: counts strictly below Builder minCount (2).
const civilianBuildBelowMinCounts = <int>[0, 1];

/// AC4: phase → favored civilian type multipliers.
const civilianBuildPhaseFavorCases = <(String, String, double)>[
  (kUnitTypeBuilder, kCivilianBuildPhaseExpand, 2.0),
  (kUnitTypeBuilder, kCivilianBuildPhaseColonialLite, 2.0),
  (kUnitTypeExplorer, kCivilianBuildPhaseExpand, 1.0),
  (kUnitTypeExplorer, kCivilianBuildPhaseColonial, 2.0),
  (kUnitTypeMerchant, kCivilianBuildPhaseColonial, 2.0),
  (kUnitTypeBuilder, kCivilianBuildPhaseColonial, 1.0),
  (kUnitTypeEngineer, kCivilianBuildPhaseDevelop, 2.0),
  (kUnitTypeRailBuilder, kCivilianBuildPhaseDevelop, 2.0),
  (kUnitTypeExplorer, kCivilianBuildPhaseDevelop, 1.0),
];

/// ACPool: representative (type, count) pairs at default pool weight.
const civilianBuildPoolParityCases = <(String, int)>[
  (kUnitTypeBuilder, 0), // below min cap (hard floor)
  (kUnitTypeExplorer, 1), // replacement urgency band
  (kUnitTypeEngineer, 1), // at target
  (kUnitTypeSpy, 0), // phase-flat
  (kUnitTypeMerchant, 0),
  (kUnitTypeRailBuilder, 0),
];

/// ACHyst: canonical EXPAND→COLONIAL→DEVELOP phase order.
const civilianBuildNextPhaseCases = <(String, String)>[
  (kCivilianBuildPhaseExpand, kCivilianBuildPhaseColonial),
  (kCivilianBuildPhaseColonialLite, kCivilianBuildPhaseColonial),
  (kCivilianBuildPhaseColonial, kCivilianBuildPhaseDevelop),
  // DEVELOP is terminal — ramps toward itself (no-op).
  (kCivilianBuildPhaseDevelop, kCivilianBuildPhaseDevelop),
  // Unknown phase is treated as terminal (returns itself).
  ('mystery', 'mystery'),
];

/// ACHyst: Builder/Explorer smooth ramp across expand→colonial.
const civilianBuildSmoothRampCases = <(String, double, double)>[
  (kUnitTypeBuilder, 0.0, 2.0),
  (kUnitTypeBuilder, 0.5, 1.5),
  (kUnitTypeBuilder, 1.0, 1.0),
  (kUnitTypeExplorer, 0.0, 1.0),
  (kUnitTypeExplorer, 0.5, 1.5),
  (kUnitTypeExplorer, 1.0, 2.0),
];

/// ACHystNull: civilian types exercised in discrete-parity sweep.
const civilianBuildDiscreteParityTypes = <String>[
  kUnitTypeBuilder,
  kUnitTypeExplorer,
  kUnitTypeEngineer,
  kUnitTypeMerchant,
  kUnitTypeRailBuilder,
  kUnitTypeSpy,
];

/// ACHystNull: phase names exercised in discrete-parity sweep.
const civilianBuildDiscreteParityPhases = <String?>[
  kCivilianBuildPhaseExpand,
  kCivilianBuildPhaseColonialLite,
  kCivilianBuildPhaseColonial,
  kCivilianBuildPhaseDevelop,
  null,
];
