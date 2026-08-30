// Naval units-panel sea/mission scenario factories (Refs #4352 Slice D).
// SPEC: SPEC/ui/naval-units-panel.md; SPEC/program/repo-lint.md.

import 'package:colonizethis_data/colonizethis_data.dart'
    show MapTopology, TopologyEdge, TopologyNode, TopologyNodeType;
import 'package:colonizethis_logic/colonizethis_logic.dart' show homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'naval_units_panel_ow_fleet_scenarios.dart';

/// Beachhead-mission sea fleet for status-line pins.
Game buildNavalPanelBeachheadMissionGame({
  String humanId = 'p_beach',
  String gameId = 'beach_test',
  String fleetId = 'bf1',
  String seaZoneId = 'atlantic',
}) => buildNavalPanelOwFleetsGame(
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

/// Sea-source fleet adjacent to capital for Home Fleet transfer pins.
Fleet navalPanelAdjacentSeaSourceFleet({
  required String humanId,
  String id = 'sea_source',
}) {
  return Fleet(
    id: id,
    ownerId: humanId,
    regionId: 'oldWorld',
    seaZoneId: 'zone_alpha',
    ships: const [
      ShipInstance(id: 'src_1', typeId: 'fluyte'),
      ShipInstance(id: 'src_2', typeId: 'carrack'),
    ],
  );
}

/// Home + adjacent sea-source fleet (part3 transfer-dialog matrix).
Game buildNavalPanelHomeAdjacentSeaSourceGame({
  String humanId = 'gp_home_adjacent',
  String gameId = 'g_home_adjacent_transfer',
}) {
  return buildNavalPanelCapitalHomeAndPeersGame(
    humanId: humanId,
    gameId: gameId,
    displayName: 'Home adjacent tester',
    peerFleets: [navalPanelAdjacentSeaSourceFleet(humanId: humanId)],
  );
}

/// Home + non-adjacent sea fleet keeps Combine disabled (part3).
Game buildNavalPanelHomeNonAdjacentSeaGame({
  String humanId = 'gp_home_non_adjacent',
  String gameId = 'g_home_non_adjacent_transfer',
}) {
  return buildNavalPanelCapitalHomeAndPeersGame(
    humanId: humanId,
    gameId: gameId,
    displayName: 'Home non-adjacent tester',
    peerFleets: [
      Fleet(
        id: 'sea_far',
        ownerId: humanId,
        regionId: 'oldWorld',
        seaZoneId: 'zone_far',
        ships: const [ShipInstance(id: 'src_1', typeId: 'fluyte')],
      ),
    ],
  );
}

/// Capital port marker-scope game for part1 location-scope pins.
Game buildNavalPanelMarkerScopeCapitalGame({
  String humanId = 'gp_marker_scope',
  String gameId = 'g_marker_scope',
}) {
  const capital = 'oldWorld|p1';
  return buildNavalPanelOwFleetsGame(
    gameId: gameId,
    humanId: humanId,
    displayName: 'Scope Test',
    capitalProvinceId: capital,
    oldWorldProvinces: [
      Province(
        id: 'p1',
        regionId: 'oldWorld',
        ownerId: humanId,
        displayName: 'Capital Port',
      ),
    ],
    fleets: [
      Fleet(
        id: homeFleetIdFor(humanId),
        ownerId: humanId,
        regionId: 'oldWorld',
        inPortAtProvinceId: capital,
        ships: const [ShipInstance(id: 'home_ship_1', typeId: 'carrack')],
      ),
    ],
    tileKeysByProvince: const {
      capital: ['oldWorld|p1|0|0'],
    },
  );
}

const kNavalMockupFidelityHumanId = 'gp_naval_fidelity';

/// Deterministic mockup-fidelity scenario (Refs #2866 S8, #4021).
Game buildNavalPanelMockupFidelityGame() {
  const humanId = kNavalMockupFidelityHumanId;
  const capitalProvinceId = 'oldWorld|cap1';
  const portProvinceId = 'oldWorld|port1';
  const zonePrefixedId = 'oldWorld|zone_alpha';
  final homeId = homeFleetIdFor(humanId);
  return buildNavalPanelOwFleetsGame(
    gameId: 'naval-fidelity',
    humanId: humanId,
    displayName: 'Fidelity Tester',
    capitalProvinceId: capitalProvinceId,
    oldWorldProvinces: const [
      Province(
        id: 'cap1',
        regionId: 'oldWorld',
        ownerId: humanId,
        displayName: 'London',
      ),
      Province(
        id: 'port1',
        regionId: 'oldWorld',
        ownerId: humanId,
        displayName: 'Portsmouth',
      ),
    ],
    fleets: [
      Fleet(
        id: homeId,
        ownerId: humanId,
        regionId: 'oldWorld',
        inPortAtProvinceId: capitalProvinceId,
        ships: const [
          ShipInstance(id: 'h1', typeId: 'carrack'),
          ShipInstance(id: 'h2', typeId: 'frigate'),
        ],
      ),
      Fleet(
        id: 'channel_fleet',
        ownerId: humanId,
        regionId: 'oldWorld',
        inPortAtProvinceId: portProvinceId,
        ships: const [
          ShipInstance(id: 'p1', typeId: 'frigate'),
          ShipInstance(id: 'p2', typeId: 'frigate'),
        ],
      ),
      Fleet(
        id: 'atlantic_fleet',
        ownerId: humanId,
        regionId: 'oldWorld',
        seaZoneId: 'zone_alpha',
        ships: const [ShipInstance(id: 's1', typeId: 'galleon')],
      ),
    ],
    seaZoneDisplayNameById: const {zonePrefixedId: 'Bay of Biscay'},
    tileKeysByProvince: const {
      capitalProvinceId: ['oldWorld|cap1|0|0'],
      portProvinceId: ['oldWorld|port1|0|0'],
    },
  );
}
