// Naval units-panel scenario Game factories and fleet topology helpers (Refs #4048, #4117).
// Lives outside `app/test/support/` so scenario tables do not count toward the
// support LOC ratchet. Host/pump/wire helpers stay in naval_units_panel_test_support.dart.
// SPEC: SPEC/ui/naval-units-panel.md; SPEC/program/repo-lint.md.

import 'package:colonizethis_data/colonizethis_data.dart'
    show MapTopology, TopologyEdge, TopologyNode, TopologyNodeType;
import 'package:colonizethis_logic/colonizethis_logic.dart' show homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'panel_test_fixtures.dart';
import 'units_panel_test_shared.dart' show unitsPanelOwProvince;

/// Home-fleet-only game for part1 default assertions (single Split tooltip).
/// Refs #3656: lightweight fixture replaces procedural map generation.
Game buildNavalPanelHomeFleetOnlyGame() {
  final base = buildNavalPanelTestGame();
  final homeFleet = base.worldState.fleets.firstWhere(
    (f) => f.inPortAtProvinceId != null,
  );
  return base.copyWith(
    worldState: base.worldState.copyWith(fleets: [homeFleet]),
  );
}

/// Minimal sea-fleet game whose zone label comes from [seaZoneDisplayNameById].
Game buildNavalPanelNamedSeaZoneGame({
  String humanId = 'gp_named_sea',
  String zoneId = 'zone_alpha',
  String displayName = 'Caribbean Sea',
}) {
  const capProvince = 'oldWorld|cap1';
  return buildNavalPanelOwFleetsGame(
    gameId: 'named-sea',
    humanId: humanId,
    displayName: 'Named Sea Tester',
    capitalProvinceId: capProvince,
    oldWorldProvinces: [
      Province(
        id: 'cap1',
        regionId: 'oldWorld',
        ownerId: humanId,
        displayName: 'Capital',
      ),
    ],
    fleets: [
      Fleet(
        id: 'sea_named',
        ownerId: humanId,
        regionId: 'oldWorld',
        seaZoneId: zoneId,
        ships: const [ShipInstance(id: 's1', typeId: 'carrack')],
      ),
    ],
    seaZoneDisplayNameById: {'oldWorld|$zoneId': displayName},
    portsByProvinceSeaboard: const {
      'oldWorld|cap1|zone_alpha': 'oldWorld|cap1|0|0',
    },
    tileKeysByProvince: const {
      capProvince: ['oldWorld|cap1|0|0'],
    },
  );
}

/// Single home-fleet game used for ship-type display-name composition asserts.
Game buildNavalPanelShipLabelGame({String humanId = 'gp_ship_display'}) {
  return buildNavalPanelCapitalHomeAndPeersGame(
    humanId: humanId,
    gameId: 'g_ship_labels',
    displayName: 'Ship Label Tester',
    peerFleets: const [],
    homeShips: const [ShipInstance(id: 'h1', typeId: 'carrack')],
  );
}

/// OW capital + optional extra provinces / fleets for naval panel scenarios
/// (Refs #4013 densify of `naval_units_panel_part{3,4}_test.dart`).
Game buildNavalPanelOwFleetsGame({
  required String gameId,
  required String humanId,
  required String displayName,
  required List<Province> oldWorldProvinces,
  required List<Fleet> fleets,
  String? capitalProvinceId,
  Map<String, List<String>> tileKeysByProvince = const {},
  Map<String, String> portsByProvinceSeaboard = const {},
  Map<String, String> seaZoneDisplayNameById = const {},
  int? nextShipInstanceSeq,
  int treasury = 0,
}) {
  final player = capitalProvinceId == null
      ? Player(
          id: humanId,
          displayName: displayName,
          isHuman: true,
          treasury: treasury,
        )
      : Player(
          id: humanId,
          displayName: displayName,
          isHuman: true,
          capitalProvinceId: capitalProvinceId,
          capitalTile: CapitalTile(
            regionId: 'oldWorld',
            provinceId: capitalProvinceId,
            x: 0,
            y: 0,
          ),
          treasury: treasury,
        );
  return buildPanelTestGame(
    id: gameId,
    players: [player],
    oldWorldProvinces: oldWorldProvinces,
    fleets: fleets,
    portsByProvinceSeaboard: portsByProvinceSeaboard,
    seaZoneDisplayNameById: seaZoneDisplayNameById,
    tileKeysByRegionAndProvince: {'oldWorld': tileKeysByProvince},
    nextShipInstanceSeq: nextShipInstanceSeq ?? 1,
  );
}

/// Capital province owned by [humanId] with a home fleet plus peer fleets.
Game buildNavalPanelCapitalHomeAndPeersGame({
  required String humanId,
  required String gameId,
  required String displayName,
  required List<Fleet> peerFleets,
  List<ShipInstance> homeShips = const [
    ShipInstance(id: 'home_1', typeId: 'carrack'),
  ],
  FleetMission homeMission = FleetMission.none,
  String capitalLocalId = 'cap1',
  int? nextShipInstanceSeq,
}) {
  final capProvince = 'oldWorld|$capitalLocalId';
  final homeId = homeFleetIdFor(humanId);
  return buildNavalPanelOwFleetsGame(
    gameId: gameId,
    humanId: humanId,
    displayName: displayName,
    capitalProvinceId: capProvince,
    oldWorldProvinces: [
      Province(
        id: capitalLocalId,
        regionId: 'oldWorld',
        ownerId: humanId,
        displayName: 'Capital',
      ),
    ],
    fleets: [
      Fleet(
        id: homeId,
        ownerId: humanId,
        regionId: 'oldWorld',
        inPortAtProvinceId: capProvince,
        ships: homeShips,
        mission: homeMission,
      ),
      ...peerFleets,
    ],
    tileKeysByProvince: {
      capProvince: ['$capProvince|0|0'],
    },
    nextShipInstanceSeq: nextShipInstanceSeq,
  );
}

/// Capital + merge-port provinces with fleets typically berthed at the merge port.
///
/// When [includeMergePortTileKeys] is false, only the capital province has a
/// locate tile key so merge-port fleet rows are not wrapped in a locate
/// [InkWell] (widget tests need taps to reach [ExpansionTile] / checkboxes).
Game buildNavalPanelCapitalMergePortFleetsGame({
  required String humanId,
  required String gameId,
  required String displayName,
  required List<Fleet> fleets,
  String capitalLocalId = 'cap1',
  String mergePortLocalId = 'mergeport',
  String mergePortDisplayName = 'Merge Port',
  int? nextShipInstanceSeq,
  bool playerHasCapital = true,
  bool includeMergePortTileKeys = true,
}) {
  final capProvince = 'oldWorld|$capitalLocalId';
  final mergePort = 'oldWorld|$mergePortLocalId';
  final provinces = <Province>[
    if (playerHasCapital)
      Province(
        id: capitalLocalId,
        regionId: 'oldWorld',
        ownerId: humanId,
        displayName: 'Capital',
      ),
    Province(
      id: mergePortLocalId,
      regionId: 'oldWorld',
      ownerId: humanId,
      displayName: mergePortDisplayName,
    ),
  ];
  return buildNavalPanelOwFleetsGame(
    gameId: gameId,
    humanId: humanId,
    displayName: displayName,
    capitalProvinceId: playerHasCapital ? capProvince : null,
    oldWorldProvinces: provinces,
    fleets: fleets,
    tileKeysByProvince: {
      if (playerHasCapital) capProvince: ['$capProvince|0|0'],
      if (includeMergePortTileKeys) mergePort: ['$mergePort|0|0'],
    },
    nextShipInstanceSeq: nextShipInstanceSeq,
  );
}

/// Single sea-fleet game (no capital) for location-scope / auto-close pins.
Game buildNavalPanelSingleSeaFleetGame({
  required String humanId,
  required String gameId,
  required String displayName,
  String fleetId = 'f1',
  String seaZoneId = 's1',
  String shipId = 'ship_1',
  String shipTypeId = 'frigate',
}) {
  return buildNavalPanelOwFleetsGame(
    gameId: gameId,
    humanId: humanId,
    displayName: displayName,
    oldWorldProvinces: const [],
    fleets: [
      Fleet(
        id: fleetId,
        ownerId: humanId,
        regionId: 'oldWorld',
        seaZoneId: seaZoneId,
        ships: [ShipInstance(id: shipId, typeId: shipTypeId)],
      ),
    ],
  );
}

/// Empty-world human with no fleets (empty-state message pins).
Game buildNavalPanelEmptyHumanGame({
  String humanId = 'p_empty',
  String gameId = 'empty_naval',
  String displayName = 'Solo',
}) {
  return buildNavalPanelOwFleetsGame(
    gameId: gameId,
    humanId: humanId,
    displayName: displayName,
    oldWorldProvinces: const [],
    fleets: const [],
  );
}

/// Beachhead-mission sea fleet for status-line pins.
Game buildNavalPanelBeachheadMissionGame({
  String humanId = 'p_beach',
  String gameId = 'beach_test',
  String fleetId = 'bf1',
  String seaZoneId = 'atlantic',
}) {
  return buildNavalPanelOwFleetsGame(
    gameId: gameId,
    humanId: humanId,
    displayName: 'P',
    oldWorldProvinces: const [],
    fleets: [
      Fleet(
        id: fleetId,
        ownerId: humanId,
        regionId: 'oldWorld',
        seaZoneId: seaZoneId,
        shipTypeIds: const ['carrack'],
        mission: FleetMission.beachhead,
      ),
    ],
    portsByProvinceSeaboard: {
      'oldWorld|lisbon|$seaZoneId': 'oldWorld|lisbon|0|0',
    },
    tileKeysByProvince: const {
      'oldWorld|lisbon': ['oldWorld|lisbon|0|0'],
    },
  );
}

/// Two OW sea zones linked for Move / scoped auto-close cases.
MapTopology buildNavalTwoSeaZonesTopology({
  String fromZoneId = 'oldWorld|s1',
  String toZoneId = 'oldWorld|s2',
}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: fromZoneId,
        regionId: fromZoneId.split('|').first,
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: toZoneId,
        regionId: toZoneId.split('|').first,
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: [TopologyEdge(id1: fromZoneId, id2: toZoneId)],
  );
}

/// Home + at-sea fleet with a draft-move target display name (part5 subtitle).
Game buildNavalPanelDraftMoveSubtitleGame({
  String humanId = 'gp_draft_line',
  String gameId = 'g_draft_line',
  String capitalLocalId = 'capital',
  String seaFleetId = 'f_at_sea',
  String seaZoneId = 'sz0',
  String destinationZoneId = 'sz1',
  String destinationDisplayName = 'Target Sea',
}) {
  final capProvince = 'oldWorld|$capitalLocalId';
  return buildNavalPanelOwFleetsGame(
    gameId: gameId,
    humanId: humanId,
    displayName: 'P',
    capitalProvinceId: capProvince,
    oldWorldProvinces: [
      Province(
        id: capitalLocalId,
        regionId: 'oldWorld',
        ownerId: humanId,
        displayName: 'Capital',
      ),
    ],
    fleets: [
      Fleet(
        id: homeFleetIdFor(humanId),
        ownerId: humanId,
        regionId: 'oldWorld',
        inPortAtProvinceId: capProvince,
        ships: const [],
      ),
      Fleet(
        id: seaFleetId,
        ownerId: humanId,
        regionId: 'oldWorld',
        seaZoneId: seaZoneId,
        ships: const [ShipInstance(id: 's1', typeId: 'carrack')],
      ),
    ],
    seaZoneDisplayNameById: {
      'oldWorld|$destinationZoneId': destinationDisplayName,
    },
  );
}

/// Merge-port province id for combine-at-port scenarios (Refs #4183 Slice E).
const kNavalPanelMergePort = 'oldWorld|mergeport';

/// Capital province id for OW naval panel scenarios.
const kNavalPanelCapProvince = 'oldWorld|cap1';

typedef NavalPanelPortShipSpec = ({String id, String shipId, String typeId});

Fleet navalPanelPortShipFleet({
  required String id,
  required String humanId,
  required String port,
  required String shipId,
  String typeId = 'carrack',
}) {
  return Fleet(
    id: id,
    ownerId: humanId,
    regionId: 'oldWorld',
    inPortAtProvinceId: port,
    ships: [ShipInstance(id: shipId, typeId: typeId)],
  );
}

Fleet navalPanelSeaShipFleet({
  required String id,
  required String humanId,
  required String seaZoneId,
  required String shipId,
  String typeId = 'carrack',
}) {
  return Fleet(
    id: id,
    ownerId: humanId,
    regionId: 'oldWorld',
    seaZoneId: seaZoneId,
    inPortAtProvinceId: null,
    ships: [ShipInstance(id: shipId, typeId: typeId)],
  );
}

/// Fleets berthed at [kNavalPanelMergePort] from compact ship specs.
Game buildNavalPanelMergePortFleetsFromSpecs({
  required String humanId,
  required String gameId,
  required String displayName,
  required List<NavalPanelPortShipSpec> fleets,
  int? nextShipInstanceSeq,
}) {
  return buildNavalPanelCapitalMergePortFleetsGame(
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
}

/// Single merge-port fleet row (mission optional).
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

/// Capital + merge-port game with explicit fleet list.
Game buildNavalPanelMergePortFleetsGame({
  required String humanId,
  required String gameId,
  required String displayName,
  required List<Fleet> fleets,
  bool playerHasCapital = true,
  int nextShipInstanceSeq = 3,
}) => buildNavalPanelCapitalMergePortFleetsGame(
  humanId: humanId,
  gameId: gameId,
  displayName: displayName,
  playerHasCapital: playerHasCapital,
  nextShipInstanceSeq: nextShipInstanceSeq,
  fleets: fleets,
);

/// Two at-sea fleets in the same zone for combine pins.
Game buildNavalPanelSameSeaCombineGame({required String humanId}) {
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
        inPortAtProvinceId: null,
        ships: const [ShipInstance(id: 'ss1', typeId: 'carrack')],
        mission: FleetMission.patrol,
      ),
      Fleet(
        id: 'sea_2',
        ownerId: humanId,
        regionId: 'oldWorld',
        seaZoneId: 'zone_alpha',
        inPortAtProvinceId: null,
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

typedef NavalPanelCombineDisabledCase = ({
  String name,
  String humanId,
  Game Function() build,
  List<String> labels,
});

/// Combine-disabled matrix for part2 scenario-table pins (Refs #4183 Slice E).
List<NavalPanelCombineDisabledCase> navalPanelCombineDisabledCases() {
  return [
    (
      name:
          'AC: Fleets at different locations keep Combine disabled when both checked',
      humanId: 'gp_diff_loc',
      build: () {
        const humanId = 'gp_diff_loc';
        return buildNavalPanelOwFleetsGame(
          gameId: 'g_diff_loc',
          humanId: humanId,
          displayName: 'Diff-loc tester',
          capitalProvinceId: kNavalPanelCapProvince,
          oldWorldProvinces: [
            unitsPanelOwProvince('cap1', humanId, displayName: 'Capital'),
            unitsPanelOwProvince('port_a', humanId, displayName: 'Port A'),
            unitsPanelOwProvince('port_b', humanId, displayName: 'Port B'),
          ],
          fleets: [
            navalPanelPortShipFleet(
              id: 'fa',
              humanId: humanId,
              port: 'oldWorld|port_a',
              shipId: 'ship_1',
            ),
            navalPanelPortShipFleet(
              id: 'fb',
              humanId: humanId,
              port: 'oldWorld|port_b',
              shipId: 'ship_2',
              typeId: 'fluyte',
            ),
          ],
          tileKeysByProvince: {
            kNavalPanelCapProvince: ['oldWorld|cap1|0|0'],
          },
          nextShipInstanceSeq: 3,
        );
      },
      labels: const ['Fleet fa', 'Fleet fb'],
    ),
    (
      name:
          'AC: Fleets in different sea zones keep Combine disabled when both checked',
      humanId: 'gp_two_seas',
      build: () {
        const humanId = 'gp_two_seas';
        return buildNavalPanelOwFleetsGame(
          gameId: 'g_two_seas',
          humanId: humanId,
          displayName: 'Two seas tester',
          capitalProvinceId: kNavalPanelCapProvince,
          oldWorldProvinces: [
            unitsPanelOwProvince('coast', humanId, displayName: 'Coast'),
            unitsPanelOwProvince('cap1', humanId, displayName: 'Capital'),
          ],
          fleets: [
            navalPanelSeaShipFleet(
              id: 'sea_a',
              humanId: humanId,
              seaZoneId: 'zone_alpha',
              shipId: 'a1',
            ),
            navalPanelSeaShipFleet(
              id: 'sea_b',
              humanId: humanId,
              seaZoneId: 'zone_beta',
              shipId: 'b1',
              typeId: 'fluyte',
            ),
          ],
          portsByProvinceSeaboard: {
            'oldWorld|coast|zone_alpha': 'oldWorld|coast|0|0',
            'oldWorld|coast|zone_beta': 'oldWorld|coast|1|0',
          },
          tileKeysByProvince: {
            kNavalPanelCapProvince: ['oldWorld|cap1|0|0'],
            'oldWorld|coast': ['oldWorld|coast|0|0'],
          },
          nextShipInstanceSeq: 2,
        );
      },
      labels: const ['Fleet sea_a', 'Fleet sea_b'],
    ),
    (
      name:
          'AC: Fleet at sea and fleet in port keep Combine disabled when both checked',
      humanId: 'gp_sea_port',
      build: () {
        const humanId = 'gp_sea_port';
        return buildNavalPanelOwFleetsGame(
          gameId: 'g_sea_port',
          humanId: humanId,
          displayName: 'Sea-port tester',
          capitalProvinceId: kNavalPanelCapProvince,
          oldWorldProvinces: [
            unitsPanelOwProvince('cap1', humanId, displayName: 'Capital'),
            unitsPanelOwProvince('mergeport', humanId, displayName: 'Merge Port'),
            unitsPanelOwProvince('coast', humanId, displayName: 'Coast'),
          ],
          fleets: [
            navalPanelSeaShipFleet(
              id: 'at_sea',
              humanId: humanId,
              seaZoneId: 'zone_alpha',
              shipId: 's_sea',
            ),
            navalPanelPortShipFleet(
              id: 'in_port',
              humanId: humanId,
              port: kNavalPanelMergePort,
              shipId: 's_port',
              typeId: 'fluyte',
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
      },
      labels: const ['Fleet at_sea', 'Fleet in_port'],
    ),
  ];
}
