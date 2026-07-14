// Shared Game / RegionMapViewData scenario mutators for ProvinceSeaZoneDetailOverlay
// dark-token suites. Refs #4013.

import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show demoGameForOverlay, demoRegionForOverlay;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show PlayerView, VisibilityLevel;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Returns [demoRegionForOverlay] with each cell's visibility overridden by
/// [visibilityForCell]. Used by obfuscated / sea-zone Political dark-token
/// suites to force fully-unrevealed or partially-revealed branches without
/// depending on the debug-init visibility distribution.
RegionMapViewData regionMapWithCellVisibility({
  required TileVisibility Function(CellViewData cell) visibilityForCell,
}) {
  final base = demoRegionForOverlay;
  final cells = base.cells
      .map(
        (c) => CellViewData(
          x: c.x,
          y: c.y,
          regionCellId: c.regionCellId,
          isSea: c.isSea,
          terrainTypeId: c.terrainTypeId,
          terrainType: c.terrainType,
          resourceId: c.resourceId,
          ownerFactionId: c.ownerFactionId,
          provinceDisplayName: c.provinceDisplayName,
          improvementLevel: c.improvementLevel,
          roadLevel: c.roadLevel,
          visibility: visibilityForCell(c),
        ),
      )
      .toList();
  return RegionMapViewData(
    regionId: base.regionId,
    width: base.width,
    height: base.height,
    cellSize: base.cellSize,
    cells: cells,
    capitalMarkers: base.capitalMarkers,
    portMarkers: base.portMarkers,
    factionColors: base.factionColors,
    greatPowerFactionIds: base.greatPowerFactionIds,
    terrainColors: base.terrainColors,
    unitMarkers: base.unitMarkers,
  );
}

/// Demo game plus one `pikemen` regiment (Military dark-token pins), and
/// optionally a pending land [MoveOrder].
({Game game, Orders orders, String unitId}) gameWithMilitaryDarkTokenUnit({
  required String ownerId,
  required String provinceId,
  bool withPendingMove = false,
  String? destinationTileKey,
}) {
  final base = demoGameForOverlay;
  final ws = base.worldState;
  const unitId = 'test_pikemen_militaryDarkTokens';
  // `pikemen` is a canonical regiment id so `isMilitaryUnit` is true and
  // the unit lands in the Military section (not Civilian).
  final regiment = Unit(
    id: unitId,
    type: 'pikemen',
    ownerId: ownerId,
    locationProvinceId: provinceId,
  );
  final updatedOldWorld = RegionData(
    provinces: ws.oldWorld.provinces,
    units: [...ws.oldWorld.units, regiment],
  );
  final game = base.copyWith(
    worldState: ws.copyWith(oldWorld: updatedOldWorld),
  );

  Orders orders = const Orders();
  if (withPendingMove) {
    if (destinationTileKey == null) {
      fail(
        'Test setup: withPendingMove requires destinationTileKey to be set.',
      );
    }
    orders = Orders(
      moveOrdersByPlayerId: {
        ownerId: [
          MoveOrder(unitId: unitId, destinationTileKey: destinationTileKey),
        ],
      },
    );
  }
  return (game: game, orders: orders, unitId: unitId);
}

/// Demo game plus one in-port fleet and a pending [NavalMoveOrder] (Naval
/// dark-token pins).
({Game game, Orders orders, String fleetId}) gameWithFleetAndPendingNavalMove({
  required String ownerId,
  required String provinceId,
  required String destinationSeaZoneId,
}) {
  final base = demoGameForOverlay;
  final ws = base.worldState;
  const fleetId = 'test_fleet_navalDarkTokens';
  final fleet = Fleet(
    id: fleetId,
    ownerId: ownerId,
    inPortAtProvinceId: provinceId,
    regionId: 'oldWorld',
    shipTypeIds: const ['frigate'],
  );
  final game = base.copyWith(
    worldState: ws.copyWith(fleets: [...ws.fleets, fleet]),
  );
  final orders = Orders(
    navalMoveOrdersByPlayerId: {
      ownerId: [
        NavalMoveOrder(
          fleetId: fleetId,
          destinationSeaZoneId: destinationSeaZoneId,
        ),
      ],
    },
  );
  return (game: game, orders: orders, fleetId: fleetId);
}

/// Picks a non-empty sea-zone id for a pending naval move destination.
String seaZoneIdForPendingNavalMove(Game game) {
  final namedZones = game.worldState.seaZoneDisplayNameById.keys;
  if (namedZones.isNotEmpty) {
    return namedZones.first;
  }
  return 'oldWorld|s1';
}

/// Clears units, fleets, and `resourceByTileKey` so Economic / Military /
/// Civilian / Naval empty-state `—` placeholders fire on a human-owned
/// province.
Game sparseOverlayGame(Game base) {
  final ws = base.worldState;
  return base.copyWith(
    worldState: ws.copyWith(
      oldWorld: RegionData(provinces: ws.oldWorld.provinces, units: const []),
      newWorld: RegionData(provinces: ws.newWorld.provinces, units: const []),
      fleets: const [],
      resourceByTileKey: const <String, String>{},
    ),
  );
}

/// Clears fleets so the sea-zone Naval empty branch is deterministic.
Game gameWithNoFleets(Game base) {
  return base.copyWith(worldState: base.worldState.copyWith(fleets: const []));
}

/// Builds `{regionId}|{localProvinceId}|{x}|{y}` tile keys used by Economic /
/// Civilian / Tile dark-token suites that own a synthetic single-province map.
String overlayDarkTokenTileKey({
  required String regionId,
  required String localProvinceId,
  required int x,
  required int y,
}) => '$regionId|$localProvinceId|$x|$y';

/// Minimal land [RegionMapViewData] for Economic / Civilian / Tile dark-token
/// suites that do not use [demoRegionForOverlay].
RegionMapViewData regionMapWithLandCells({
  required String regionId,
  required String localProvinceId,
  required List<({int x, int y})> coords,
  required int width,
  required int height,
  required Set<String> greatPowerFactionIds,
  String? resourceId,
}) {
  final cells = <CellViewData>[
    for (final c in coords)
      CellViewData(
        x: c.x,
        y: c.y,
        regionCellId: localProvinceId,
        isSea: false,
        terrainTypeId: 'plains',
        resourceId: resourceId,
        visibility: TileVisibility.visible,
      ),
  ];
  return RegionMapViewData(
    regionId: regionId,
    width: width,
    height: height,
    cellSize: 32,
    cells: cells,
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: greatPowerFactionIds,
    terrainColors: const {},
  );
}

/// Synthetic game with grain tiles (and optional improvements) for Economic /
/// Tile ResourceLabelInline dark-token pins.
Game gameWithGrainTilesForOverlay({
  required String gameId,
  required String regionId,
  required String fullProvinceId,
  required String displayName,
  required String humanPlayerId,
  required List<String> tileKeys,
  Map<String, int> improvementByTile = const {},
  String? provinceOwnerId,
}) {
  final visibility = <String, String>{
    for (final tk in tileKeys) tk: 'fullyVisible',
  };
  final prospected = <String>{...tileKeys};
  return Game(
    id: gameId,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: fullProvinceId,
            regionId: regionId,
            ownerId: provinceOwnerId,
            displayName: displayName,
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: {
        regionId: {fullProvinceId: tileKeys},
      },
      resourceByTileKey: {for (final tk in tileKeys) tk: 'grain'},
      playerVisibilityByTile: {humanPlayerId: visibility},
      playerProspectedTiles: {humanPlayerId: prospected},
      tileState: TileMapState(improvementByTile: improvementByTile),
    ),
    players: [
      Player(
        id: humanPlayerId,
        displayName: 'Human',
        isHuman: true,
        treasury: 0,
      ),
    ],
  );
}

/// Synthetic game with civilian [units] for Civilian dark-token pins.
Game gameWithCivilianUnitsForOverlay({
  required String gameId,
  required String regionId,
  required String fullProvinceId,
  required String displayName,
  required String humanPlayerId,
  required String foreignPlayerId,
  required List<String> tileKeys,
  required List<Unit> units,
}) {
  final visibility = <String, String>{
    for (final tk in tileKeys) tk: 'fullyVisible',
  };
  return Game(
    id: gameId,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: fullProvinceId,
            regionId: regionId,
            ownerId: humanPlayerId,
            displayName: displayName,
          ),
        ],
        units: units,
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: {
        regionId: {fullProvinceId: tileKeys},
      },
      playerVisibilityByTile: {humanPlayerId: visibility},
    ),
    players: [
      Player(
        id: humanPlayerId,
        displayName: 'Human',
        isHuman: true,
        treasury: 0,
      ),
      Player(
        id: foreignPlayerId,
        displayName: 'Foreign',
        isHuman: false,
        treasury: 0,
      ),
    ],
  );
}

/// Omniscient [PlayerView] with every [keys] tile fully visible.
PlayerView omniscientPlayerViewForTiles({
  required String humanPlayerId,
  required Iterable<String> keys,
}) {
  return PlayerView(
    playerId: humanPlayerId,
    player: Player(
      id: humanPlayerId,
      displayName: 'Human',
      isHuman: true,
      treasury: 0,
    ),
    ownUnitsById: const {},
    provincesById: const {},
    visibilityByTile: {for (final k in keys) k: VisibilityLevel.fullyVisible},
    prospectedTiles: const {},
    diplomacyByOtherId: const {},
  );
}
