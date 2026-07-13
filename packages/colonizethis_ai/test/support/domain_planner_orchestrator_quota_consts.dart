/// Quota / fixture-id constants for domain-planner orchestrator pins
/// (Refs #3941 / #3972).
library;

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'planner_test_helpers.dart';

/// Default nation id used by domain-planner orchestrator integration pins.
const String kOrchestratorGp1NationId = 'gp1';

/// Sub-quota OW province set for gp1: 7 IDs
/// (`< kObserverConquestMinOwProvincesPerGp` = 10) so
/// `isBelowObserverConquestQuota` is true and EXPAND is reachable.
///
/// Shared by `domain_planner_orchestrator_*_test.dart` fixtures (Refs #3941).
const List<String> kGp1OwProvincesBelowQuota = <String>[
  'oldWorld|gp1_0',
  'oldWorld|gp1_1',
  'oldWorld|gp1_2',
  'oldWorld|gp1_3',
  'oldWorld|gp1_4',
  'oldWorld|gp1_5',
  'oldWorld|gp1_6',
];

/// At-quota OW province set for gp1: 11 IDs
/// (`>= kObserverConquestMinOwProvincesPerGp` = 10) so EXPAND is cleared and
/// COLONIAL / DEVELOP selection is driven by colonial-acquisition visibility.
///
/// Shared by `domain_planner_orchestrator_*_test.dart` fixtures (Refs #3941).
const List<String> kGp1OwProvincesAtQuota = <String>[
  'oldWorld|gp1_0',
  'oldWorld|gp1_1',
  'oldWorld|gp1_2',
  'oldWorld|gp1_3',
  'oldWorld|gp1_4',
  'oldWorld|gp1_5',
  'oldWorld|gp1_6',
  'oldWorld|gp1_7',
  'oldWorld|gp1_8',
  'oldWorld|gp1_9',
  'oldWorld|gp1_10',
];

/// Past-quota OW province set for gp1: 12 IDs so DEVELOP negative controls
/// in orchestrator declare-war pins stay off COLONIAL visibility.
const List<String> kGp1OwProvincesDevelop = <String>[
  'oldWorld|gp1_0',
  'oldWorld|gp1_1',
  'oldWorld|gp1_2',
  'oldWorld|gp1_3',
  'oldWorld|gp1_4',
  'oldWorld|gp1_5',
  'oldWorld|gp1_6',
  'oldWorld|gp1_7',
  'oldWorld|gp1_8',
  'oldWorld|gp1_9',
  'oldWorld|gp1_10',
  'oldWorld|gp1_11',
];

/// Eight OW provinces for the EXPAND two-GP peace orchestrator pin
/// (`domain_planner_orchestrator_expand_two_gp_peace_test.dart`).
///
/// Strictly below `kObserverConquestMinOwProvincesPerGp` (10) while one
/// province larger than [kGp1OwProvincesBelowQuota] so the EXPAND frontier
/// geometry matches the historical 8-province pin (Refs #3941).
const List<String> kGp1OwProvincesExpandTwoGp = <String>[
  'oldWorld|gp1_0',
  'oldWorld|gp1_1',
  'oldWorld|gp1_2',
  'oldWorld|gp1_3',
  'oldWorld|gp1_4',
  'oldWorld|gp1_5',
  'oldWorld|gp1_6',
  'oldWorld|gp1_7',
];

/// Shared minor-war fixture ids for the minimal EXPAND orchestrator pins
/// (`domain_planner_orchestrator_{domain_gates,phase_plan_injection,
/// trade_orders_wiring}_test.dart`; Refs #2832 / #2509 S5 / #2994 F7).
const String kOrchestratorMinorId = 'minor1';
const String kOrchestratorFieldArmyId = 'field_a';
const String kOrchestratorOwMinorProvince = 'oldWorld|minor1';
const String kOrchestratorOwHomeProvince = 'oldWorld|gp1_0';

/// Shared NW tribe fixture ids for colonial / lock-recovery orchestrator pins.
const String kOrchestratorTribeId = 'tribe1';
const String kOrchestratorTribeNwProvince = 'newWorld|tribe1_nw0';

/// GP-owned NW province used by DEVELOP declare-war suppression pins so
/// `hasColonialAcquisitionTargets` stays false while NW ownership is non-zero.
const String kOrchestratorGpOwnedNwProvince = 'newWorld|gp1_nw0';

/// Shared adjacent-minor fixture for EXPAND minor declare-war orchestrator pins.
const String kOrchestratorAdjacentMinorId = 'minor1';
const String kOrchestratorAdjacentMinorOwProvince = 'oldWorld|minor1_0';

/// GP-only invadable frontier blocker fixture for EXPAND orchestrator pins.
const String kOrchestratorBlockerGpId = 'gp2';
const List<String> kOrchestratorBlockerOwProvinces = <String>[
  'oldWorld|gp2_inv_0',
  'oldWorld|gp2_inv_1',
  'oldWorld|gp2_inv_2',
  'oldWorld|gp2_inv_3',
];

/// COLONIAL-lite near-quota OW set (`kObserverColonialLiteNearQuotaOw` = 9).
const List<String> kGp1OwProvincesColonialLiteNearQuota = <String>[
  'oldWorld|gp1_0',
  'oldWorld|gp1_1',
  'oldWorld|gp1_2',
  'oldWorld|gp1_3',
  'oldWorld|gp1_4',
  'oldWorld|gp1_5',
  'oldWorld|gp1_6',
  'oldWorld|gp1_7',
  'oldWorld|gp1_8',
];

/// Exact OW conquest quota (`kObserverConquestMinOwProvincesPerGp` = 10).
///
/// Distinct from [kGp1OwProvincesAtQuota] (11 provinces) used for COLONIAL /
/// DEVELOP visibility pins.
const List<String> kGp1OwProvincesExactQuota = <String>[
  'oldWorld|gp1_0',
  'oldWorld|gp1_1',
  'oldWorld|gp1_2',
  'oldWorld|gp1_3',
  'oldWorld|gp1_4',
  'oldWorld|gp1_5',
  'oldWorld|gp1_6',
  'oldWorld|gp1_7',
  'oldWorld|gp1_8',
  'oldWorld|gp1_9',
];

/// COLONIAL-lite work-phasing fixture ids (NW builder / merchant tiles).
const String kOrchestratorColonialLiteNwGpProvince = 'newWorld|gp1_nw0';
const String kOrchestratorColonialLiteNwTribeProvince = 'newWorld|tribe1_nw0';
const String kOrchestratorColonialLiteNwGpTile =
    'newWorld|gp1_nw0|0|0';
const String kOrchestratorColonialLiteNwTribeTile =
    'newWorld|tribe1_nw0|0|0';

/// COLONIAL-lite invasion army-move mixed-candidate fixture ids.
const String kOrchestratorColonialLiteInvasionOwMinorProvince =
    'oldWorld|minor1_p0';
const String kOrchestratorColonialLiteInvasionFieldArmyId = 'field_a';

/// Spy civilian-work orchestrator pin fixture ids.
const String kOrchestratorSpyUnitId = 's1';
const String kOrchestratorSpyOwnProvince = 'oldWorld|p1';
const String kOrchestratorSpyCounterSpyTile = 'oldWorld|p1|0|0';

/// Builds `oldWorld|gp1_0` … `oldWorld|gp1_{count-1}` for parameterized quota pins.
List<String> gp1OwProvincesForCount(int count) => <String>[
      for (var i = 0; i < count; i++) 'oldWorld|gp1_$i',
    ];

/// Empty cargo EconomyPlan shared by many orchestrator pins.
const EconomyPlan kOrchestratorEmptyEconomyPlan = kTestEconomyPlan;

