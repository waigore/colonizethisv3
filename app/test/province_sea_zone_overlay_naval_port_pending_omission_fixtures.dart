// Fixtures for sea-zone naval port-pending omission pins.

import 'package:colonizethis_logic/colonizethis_logic.dart' show PlayerView, VisibilityLevel;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'province_overlay_test_harness.dart';

const seaZoneNavalOmissionRegionId = 'oldWorld';
const _localPortProvinceId = 'pPort';
const _localDestPortProvinceId = 'pDest';
const _localSeaZoneId = 's0';

String get seaZoneNavalOmissionPortId =>
    '$seaZoneNavalOmissionRegionId|$_localPortProvinceId';
String get seaZoneNavalOmissionDestPortId =>
    '$seaZoneNavalOmissionRegionId|$_localDestPortProvinceId';
String get seaZoneNavalOmissionSeaId =>
    '$seaZoneNavalOmissionRegionId|$_localSeaZoneId';

String seaZoneNavalOmissionPortTileKey() =>
    '$seaZoneNavalOmissionPortId|0|0';
String seaZoneNavalOmissionSeaTileKey() =>
    '$seaZoneNavalOmissionSeaId|1|0';

Future<void> pumpSeaZoneNavalOmissionOverlayLayout(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

Game seaZoneNavalOmissionGameWithInPortFleet() {
  return Game(
    id: 'sea_zone_naval_omission_test',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: seaZoneNavalOmissionPortId,
            regionId: seaZoneNavalOmissionRegionId,
            displayName: 'PortProv',
            ownerId: 'gp1',
          ),
          Province(
            id: seaZoneNavalOmissionDestPortId,
            regionId: seaZoneNavalOmissionRegionId,
            displayName: 'DestPort',
            ownerId: 'gp1',
          ),
        ],
      ),
      newWorld: const RegionData(),
      fleets: [
        Fleet(
          id: 'fleet_in_port',
          ownerId: 'gp1',
          regionId: seaZoneNavalOmissionRegionId,
          inPortAtProvinceId: seaZoneNavalOmissionPortId,
          shipTypeIds: const ['sloop'],
        ),
      ],
      tileKeysByRegionAndProvince: {
        seaZoneNavalOmissionRegionId: {
          seaZoneNavalOmissionPortId: [seaZoneNavalOmissionPortTileKey()],
        },
      },
      seaZoneDisplayNameById: {
        seaZoneNavalOmissionSeaId: 'North Atlantic',
      },
    ),
    players: const [
      Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
    ],
  );
}

RegionMapViewData seaZoneNavalOmissionRegionWithPortAndRevealedSea() {
  return RegionMapViewData(
    regionId: seaZoneNavalOmissionRegionId,
    width: 2,
    height: 1,
    cellSize: 32,
    cells: const [
      CellViewData(
        x: 0,
        y: 0,
        regionCellId: _localPortProvinceId,
        isSea: false,
        terrainTypeId: 'plains',
        visibility: TileVisibility.visible,
      ),
      CellViewData(
        x: 1,
        y: 0,
        regionCellId: _localSeaZoneId,
        isSea: true,
        terrainTypeId: 'ocean',
        visibility: TileVisibility.visible,
      ),
    ],
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: const {'gp1'},
    terrainColors: const {},
  );
}

PlayerView seaZoneNavalOmissionHumanPlayerView() {
  return PlayerView(
    playerId: 'gp1',
    player: const Player(
      id: 'gp1',
      displayName: 'Human',
      isHuman: true,
      treasury: 0,
    ),
    ownUnitsById: const {},
    provincesById: const {},
    visibilityByTile: {
      seaZoneNavalOmissionPortTileKey(): VisibilityLevel.fullyVisible,
      seaZoneNavalOmissionSeaTileKey(): VisibilityLevel.fullyVisible,
    },
    prospectedTiles: const {},
    diplomacyByOtherId: const {},
  );
}

Orders seaZoneNavalOmissionPendingDockAndMissionOrders() {
  return Orders(
    navalMoveOrdersByPlayerId: {
      'gp1': [
        NavalMoveOrder(
          fleetId: 'fleet_in_port',
          destinationPortProvinceId: seaZoneNavalOmissionDestPortId,
        ),
      ],
    },
    navalMissionOrdersByPlayerId: {
      'gp1': [
        const NavalMissionOrder(
          fleetId: 'fleet_in_port',
          mission: 'patrol',
        ),
      ],
    },
  );
}

Widget wrapSeaZoneNavalOmissionOverlay({
  required Game game,
  required RegionMapViewData region,
  required String displayId,
  required String? selectedTileKey,
  required PlayerView view,
  required Orders orders,
}) {
  return buildProvinceOverlayDarkThemeShell(
    game: game,
    region: region,
    displayId: displayId,
    selectedTileKey: selectedTileKey,
    playerView: view,
    draftOrders: orders,
  );
}
