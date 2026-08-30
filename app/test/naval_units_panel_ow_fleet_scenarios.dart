// Naval units-panel OW fleet scenario factories (Refs #4352 Slice D).
// SPEC: SPEC/ui/naval-units-panel.md; SPEC/program/repo-lint.md.

import 'package:colonizethis_logic/colonizethis_logic.dart' show homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'panel_test_fixtures.dart';

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

/// OW capital + optional extra provinces / fleets for naval panel scenarios
/// (Refs #4013 densify of naval panel concern suites).
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
}) => buildNavalPanelOwFleetsGame(
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

/// Empty-world human with no fleets (empty-state message pins).
Game buildNavalPanelEmptyHumanGame({
  String humanId = 'p_empty',
  String gameId = 'empty_naval',
  String displayName = 'Solo',
}) => buildNavalPanelOwFleetsGame(
  gameId: gameId,
  humanId: humanId,
  displayName: displayName,
  oldWorldProvinces: const [],
  fleets: const [],
);
