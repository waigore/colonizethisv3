// Land / grain / civilian / omniscient Game and RegionMapViewData helpers for
// ProvinceSeaZoneDetailOverlay dark-token suites (Refs #4013, #4117).

import 'package:colonizethis_logic/colonizethis_logic.dart'
    show PlayerView, VisibilityLevel;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

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
