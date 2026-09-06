// Naval combine outcome scenario table (Refs #4352 Slice D).
// Disabled cases: naval_panel_combine_disabled_cases.dart.

import 'package:colonizethis_models/colonizethis_models.dart';

import 'naval_panel_combine_outcome_helpers.dart';
import 'naval_panel_combine_support.dart';
import 'naval_units_panel_test_scenarios.dart';

export 'naval_panel_combine_disabled_cases.dart';

List<NavalPanelCombineOutcomeCase> navalPanelCombineOutcomeCases() => [
  navalPanelMergePortOutcome(
    name: 'AC: Combining fleets creates correct ship counts',
    humanId: 'gp_combine_count',
    gameId: 'g_combine_count',
    fleets: const [
      (id: 'test_fleet_1', shipId: 'ship_1', typeId: 'carrack'),
      (id: 'test_fleet_2', shipId: 'ship_2', typeId: 'fluyte'),
    ],
  ),
  navalPanelMergePortOutcome(
    name:
        'AC: Combining three fleets at same port merges all ships into first in panel order',
    humanId: 'gp_three_combine',
    gameId: 'g_three_combine',
    fleets: const [
      (id: 'c1', shipId: 's1', typeId: 'carrack'),
      (id: 'c2', shipId: 's2', typeId: 'fluyte'),
      (id: 'c3', shipId: 's3', typeId: 'carrack'),
    ],
    scroll: true,
    expectedFleetCount: 1,
  ),
  (
    name: 'AC: combine same-sea survivors merge into first fleet id',
    build: navalPanelSameSeaCombineGame,
    humanId: 'gp_same_sea_combine',
    labels: const ['Fleet sea_1', 'Fleet sea_2'],
    scroll: false,
    expectCombineEnabled: true,
    pinCollapsedSplitToolbar: false,
    expectedSurvivorId: 'sea_1',
    expectedShipIds: ['ss1', 'ss2'],
    expectedFleetCount: 1,
    expectedSurvivorMission: FleetMission.none,
  ),
  (
    name: 'AC: combine clears patrol/blockade mission on survivor',
    build: () => buildNavalPanelCapitalMergePortFleetsGame(
      humanId: 'gp_mission_clear',
      gameId: 'g_mission_clear',
      displayName: 'Mission clear tester',
      fleets: [
        navalPanelPortFleetAtMergePort(
          'm1',
          'gp_mission_clear',
          'ms1',
          'carrack',
          mission: FleetMission.patrol,
        ),
        navalPanelPortFleetAtMergePort(
          'm2',
          'gp_mission_clear',
          'ms2',
          'fluyte',
          mission: FleetMission.blockade,
        ),
      ],
    ),
    humanId: 'gp_mission_clear',
    labels: const ['Fleet m1', 'Fleet m2'],
    scroll: false,
    expectCombineEnabled: null,
    pinCollapsedSplitToolbar: false,
    expectedSurvivorId: 'm1',
    expectedShipIds: ['ms1', 'ms2'],
    expectedFleetCount: 1,
    expectedSurvivorMission: FleetMission.none,
  ),
  (
    name:
        'AC: Three-fleet combine survivor is first in panel order regardless of check order',
    build: () => buildNavalPanelCapitalMergePortFleetsGame(
      humanId: 'gp_reverse_check',
      gameId: 'g_reverse_check',
      displayName: 'Reverse check tester',
      nextShipInstanceSeq: 4,
      fleets: [
        navalPanelPortFleetAtMergePort(
          'r1',
          'gp_reverse_check',
          'rs1',
          'carrack',
        ),
        navalPanelPortFleetAtMergePort(
          'r2',
          'gp_reverse_check',
          'rs2',
          'fluyte',
        ),
        navalPanelPortFleetAtMergePort(
          'r3',
          'gp_reverse_check',
          'rs3',
          'carrack',
        ),
      ],
    ),
    humanId: 'gp_reverse_check',
    labels: const ['Fleet r3', 'Fleet r2', 'Fleet r1'],
    scroll: true,
    expectCombineEnabled: null,
    pinCollapsedSplitToolbar: false,
    expectedSurvivorId: 'r1',
    expectedShipIds: ['rs1', 'rs2', 'rs3'],
    expectedFleetCount: 1,
    expectedSurvivorMission: FleetMission.none,
  ),
  navalPanelMergePortOutcome(
    name:
        'AC: Collapsed rows keep inline Split action while checkbox selection works',
    humanId: 'gp_collapsed_cb',
    gameId: 'g_collapsed_cb',
    fleets: const [
      (id: 'col_a', shipId: 'cs1', typeId: 'carrack'),
      (id: 'col_b', shipId: 'cs2', typeId: 'fluyte'),
    ],
    pinCollapsedSplitToolbar: true,
  ),
];

