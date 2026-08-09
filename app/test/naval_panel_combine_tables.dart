// Naval combine/autoclose scenario tables (Refs #4224 Slice D).
// Lives outside `naval_units_panel_*` family LOC so part shards stay lean.

import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'naval_units_panel_test_scenarios.dart';
import 'units_panel_test_shared.dart' show unitsPanelOwProvince;

// --- Combine / merge-port scenario tables (Refs #4224 Slice D) ---

typedef NavalPanelPortShipSpec = ({String id, String shipId, String typeId});

Fleet navalPanelPortShipFleet({
  required String id,
  required String humanId,
  required String port,
  required String shipId,
  String typeId = 'carrack',
}) =>
    Fleet(
      id: id,
      ownerId: humanId,
      regionId: 'oldWorld',
      inPortAtProvinceId: port,
      ships: [ShipInstance(id: shipId, typeId: typeId)],
    );

Fleet navalPanelSeaShipFleet({
  required String id,
  required String humanId,
  required String seaZoneId,
  required String shipId,
  String typeId = 'carrack',
}) =>
    Fleet(
      id: id,
      ownerId: humanId,
      regionId: 'oldWorld',
      seaZoneId: seaZoneId,
      ships: [ShipInstance(id: shipId, typeId: typeId)],
    );

Game buildNavalPanelMergePortFleetsFromSpecs({
  required String humanId,
  required String gameId,
  required String displayName,
  required List<NavalPanelPortShipSpec> fleets,
  int? nextShipInstanceSeq,
}) =>
    buildNavalPanelCapitalMergePortFleetsGame(
      humanId: humanId,
      gameId: gameId,
      displayName: displayName,
      includeMergePortTileKeys: false,
      nextShipInstanceSeq: nextShipInstanceSeq ?? fleets.length + 1,
      fleets: [
        for (final f in fleets)
          navalPanelPortShipFleet(
            id: f.id,
            humanId: humanId,
            port: kNavalPanelMergePort,
            shipId: f.shipId,
            typeId: f.typeId,
          ),
      ],
    );

Fleet navalPanelPortFleetAtMergePort(
  String id,
  String humanId,
  String shipId,
  String typeId, {
  FleetMission mission = FleetMission.none,
}) =>
    Fleet(
      id: id,
      ownerId: humanId,
      regionId: 'oldWorld',
      inPortAtProvinceId: kNavalPanelMergePort,
      ships: [ShipInstance(id: shipId, typeId: typeId)],
      mission: mission,
    );

typedef NavalPanelAutocloseCase = ({
  String humanId,
  String gameId,
  String displayName,
  String? locationScopeKey,
  MapTopology? topology,
  bool removeFleetOnNextFrame,
  bool emitMove,
  bool expectFleetRow,
  int closeCount,
});

List<NavalPanelAutocloseCase> navalPanelAutocloseCases() => [
  (
    humanId: 'gp_scope_autoclose_yes',
    gameId: 'g_scope_autoclose_yes',
    displayName: 'Scoped AutoClose',
    locationScopeKey: 'sea:oldWorld|s1',
    topology: null,
    removeFleetOnNextFrame: false,
    emitMove: true,
    expectFleetRow: true,
    closeCount: 1,
  ),
  (
    humanId: 'gp_scope_autoclose_no_full',
    gameId: 'g_scope_autoclose_no_full',
    displayName: 'Full List',
    locationScopeKey: null,
    topology: null,
    removeFleetOnNextFrame: false,
    emitMove: true,
    expectFleetRow: false,
    closeCount: 0,
  ),
  (
    humanId: 'gp_scope_autoclose_no_external',
    gameId: 'g_scope_autoclose_no_external',
    displayName: 'Scoped External',
    locationScopeKey: 'sea:oldWorld|s1',
    topology: const MapTopology(),
    removeFleetOnNextFrame: true,
    emitMove: false,
    expectFleetRow: false,
    closeCount: 0,
  ),
];

typedef NavalPanelCombineDisabledCase = ({
  String name,
  String humanId,
  Game Function() build,
  List<String> labels,
});

typedef NavalPanelCombineOutcomeCase = ({
  String name,
  Game Function() build,
  String humanId,
  List<String> labels,
  bool scroll,
  bool? expectCombineEnabled,
  bool pinCollapsedSplitToolbar,
  String expectedSurvivorId,
  List<String> expectedShipIds,
  int? expectedFleetCount,
  FleetMission expectedSurvivorMission,
});

NavalPanelCombineOutcomeCase navalPanelMergePortOutcome({
  required String name,
  required String humanId,
  required String gameId,
  required List<NavalPanelPortShipSpec> fleets,
  List<String>? labels,
  bool scroll = false,
  bool? expectCombineEnabled,
  bool pinCollapsedSplitToolbar = false,
  int? expectedFleetCount,
}) {
  final survivorId = fleets.first.id;
  return (
    name: name,
    build: () => buildNavalPanelMergePortFleetsFromSpecs(
      humanId: humanId,
      gameId: gameId,
      displayName: '$humanId tester',
      fleets: fleets,
    ),
    humanId: humanId,
    labels: labels ?? [for (final f in fleets) 'Fleet ${f.id}'],
    scroll: scroll,
    expectCombineEnabled: expectCombineEnabled,
    pinCollapsedSplitToolbar: pinCollapsedSplitToolbar,
    expectedSurvivorId: survivorId,
    expectedShipIds: [for (final f in fleets) f.shipId],
    expectedFleetCount: expectedFleetCount,
    expectedSurvivorMission: FleetMission.none,
  );
}

NavalPanelCombineDisabledCase _combineDisabledCase({
  required String name,
  required String humanId,
  required List<Province> provinces,
  required List<Fleet> fleets,
  required List<String> labels,
  Map<String, List<String>> tileKeysByProvince = const {},
  Map<String, String> portsByProvinceSeaboard = const {},
  int nextShipInstanceSeq = 3,
}) =>
    (
      name: name,
      humanId: humanId,
      build: () => buildNavalPanelOwFleetsGame(
        gameId: 'g_$humanId',
        humanId: humanId,
        displayName: '$humanId tester',
        capitalProvinceId: kNavalPanelCapProvince,
        oldWorldProvinces: provinces,
        fleets: fleets,
        tileKeysByProvince: tileKeysByProvince,
        portsByProvinceSeaboard: portsByProvinceSeaboard,
        nextShipInstanceSeq: nextShipInstanceSeq,
      ),
      labels: labels,
    );

Game _navalPanelSameSeaCombineGame() {
  const humanId = 'gp_same_sea_combine';
  return buildNavalPanelOwFleetsGame(
    gameId: 'g_same_sea_combine',
    humanId: humanId,
    displayName: 'Same-sea combine',
    capitalProvinceId: kNavalPanelCapProvince,
    oldWorldProvinces: [
      unitsPanelOwProvince('coast', humanId, displayName: 'Coast'),
      unitsPanelOwProvince('cap1', humanId, displayName: 'Capital'),
    ],
    fleets: [
      Fleet(
        id: 'sea_1',
        ownerId: humanId,
        regionId: 'oldWorld',
        seaZoneId: 'zone_alpha',
        ships: const [ShipInstance(id: 'ss1', typeId: 'carrack')],
        mission: FleetMission.patrol,
      ),
      Fleet(
        id: 'sea_2',
        ownerId: humanId,
        regionId: 'oldWorld',
        seaZoneId: 'zone_alpha',
        ships: const [ShipInstance(id: 'ss2', typeId: 'fluyte')],
      ),
    ],
    portsByProvinceSeaboard: {
      'oldWorld|coast|zone_alpha': 'oldWorld|coast|0|0',
    },
    tileKeysByProvince: {
      kNavalPanelCapProvince: ['oldWorld|cap1|0|0'],
      'oldWorld|coast': ['oldWorld|coast|0|0'],
    },
    nextShipInstanceSeq: 3,
  );
}

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
    build: _navalPanelSameSeaCombineGame,
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
        navalPanelPortFleetAtMergePort('r1', 'gp_reverse_check', 'rs1', 'carrack'),
        navalPanelPortFleetAtMergePort('r2', 'gp_reverse_check', 'rs2', 'fluyte'),
        navalPanelPortFleetAtMergePort('r3', 'gp_reverse_check', 'rs3', 'carrack'),
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
  const capTiles = {kNavalPanelCapProvince: ['oldWorld|cap1|0|0']};
  return [
    _combineDisabledCase(
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
    _combineDisabledCase(
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
    _combineDisabledCase(
      name:
          'AC: Fleet at sea and fleet in port keep Combine disabled when both checked',
      humanId: 'gp_sea_port',
      provinces: [
        unitsPanelOwProvince('cap1', 'gp_sea_port', displayName: 'Capital'),
        unitsPanelOwProvince('mergeport', 'gp_sea_port', displayName: 'Merge Port'),
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
