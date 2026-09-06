// Combine outcome typedefs and game builders (Refs #4352 Slice D, #4734 densify).

import 'package:colonizethis_models/colonizethis_models.dart';

import 'naval_panel_combine_support.dart';
import 'naval_units_panel_test_scenarios.dart';
import 'units_panel_test_shared.dart' show unitsPanelOwProvince;

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
