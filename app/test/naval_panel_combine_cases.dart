// Naval combine outcome/disabled scenario tables (Refs #4352 Slice D).
// SPEC: SPEC/ui/naval-units-panel.md; SPEC/program/repo-lint.md.

import 'package:colonizethis_models/colonizethis_models.dart';

import 'naval_panel_combine_support.dart';
import 'naval_units_panel_test_scenarios.dart';
import 'units_panel_test_shared.dart' show unitsPanelOwProvince;

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

List<NavalPanelCombineDisabledCase> navalPanelCombineDisabledCases() {
  const capTiles = {
    kNavalPanelCapProvince: ['oldWorld|cap1|0|0'],
  };
  return [
    navalPanelCombineDisabledCase(
      name:
          'AC: Fleets at different locations keep Combine disabled when both checked',
      humanId: 'gp_diff_loc',
      provinces: [
        unitsPanelOwProvince('cap1', 'gp_diff_loc', displayName: 'Capital'),
        unitsPanelOwProvince('port_a', 'gp_diff_loc', displayName: 'Port A'),
        unitsPanelOwProvince('port_b', 'gp_diff_loc', displayName: 'Port B'),
      ],
      fleets: [
        navalPanelPortShipFleet(
          id: 'fa',
          humanId: 'gp_diff_loc',
          port: 'oldWorld|port_a',
          shipId: 'ship_1',
        ),
        navalPanelPortShipFleet(
          id: 'fb',
          humanId: 'gp_diff_loc',
          port: 'oldWorld|port_b',
          shipId: 'ship_2',
          typeId: 'fluyte',
        ),
      ],
      labels: const ['Fleet fa', 'Fleet fb'],
      tileKeysByProvince: capTiles,
    ),
    navalPanelCombineDisabledCase(
      name:
          'AC: Fleets in different sea zones keep Combine disabled when both checked',
      humanId: 'gp_two_seas',
      provinces: [
        unitsPanelOwProvince('coast', 'gp_two_seas', displayName: 'Coast'),
        unitsPanelOwProvince('cap1', 'gp_two_seas', displayName: 'Capital'),
      ],
      fleets: [
        navalPanelSeaShipFleet(
          id: 'sea_a',
          humanId: 'gp_two_seas',
          seaZoneId: 'zone_alpha',
          shipId: 'a1',
        ),
        navalPanelSeaShipFleet(
          id: 'sea_b',
          humanId: 'gp_two_seas',
          seaZoneId: 'zone_beta',
          shipId: 'b1',
          typeId: 'fluyte',
        ),
      ],
      labels: const ['Fleet sea_a', 'Fleet sea_b'],
      portsByProvinceSeaboard: {
        'oldWorld|coast|zone_alpha': 'oldWorld|coast|0|0',
        'oldWorld|coast|zone_beta': 'oldWorld|coast|1|0',
      },
      tileKeysByProvince: {
        ...capTiles,
        'oldWorld|coast': ['oldWorld|coast|0|0'],
      },
      nextShipInstanceSeq: 2,
    ),
    navalPanelCombineDisabledCase(
      name:
          'AC: Fleet at sea and fleet in port keep Combine disabled when both checked',
      humanId: 'gp_sea_port',
      provinces: [
        unitsPanelOwProvince('cap1', 'gp_sea_port', displayName: 'Capital'),
        unitsPanelOwProvince(
          'mergeport',
          'gp_sea_port',
          displayName: 'Merge Port',
        ),
        unitsPanelOwProvince('coast', 'gp_sea_port', displayName: 'Coast'),
      ],
      fleets: [
        navalPanelSeaShipFleet(
          id: 'at_sea',
          humanId: 'gp_sea_port',
          seaZoneId: 'zone_alpha',
          shipId: 's_sea',
        ),
        navalPanelPortShipFleet(
          id: 'in_port',
          humanId: 'gp_sea_port',
          port: kNavalPanelMergePort,
          shipId: 's_port',
          typeId: 'fluyte',
        ),
      ],
      labels: const ['Fleet at_sea', 'Fleet in_port'],
      portsByProvinceSeaboard: {
        'oldWorld|coast|zone_alpha': 'oldWorld|coast|0|0',
      },
      tileKeysByProvince: {
        ...capTiles,
        'oldWorld|coast': ['oldWorld|coast|0|0'],
      },
    ),
  ];
}
