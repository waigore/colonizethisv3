// Naval combine fleet helpers, autoclose tables, and combine typedefs (Refs #4352 Slice D).
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
}) => Fleet(
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
}) => Fleet(
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
}) => buildNavalPanelCapitalMergePortFleetsGame(
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
}) => Fleet(
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

NavalPanelCombineDisabledCase navalPanelCombineDisabledCase({
  required String name,
  required String humanId,
  required List<Province> provinces,
  required List<Fleet> fleets,
  required List<String> labels,
  Map<String, List<String>> tileKeysByProvince = const {},
  Map<String, String> portsByProvinceSeaboard = const {},
  int nextShipInstanceSeq = 3,
}) => (
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

Game navalPanelSameSeaCombineGame() {
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
