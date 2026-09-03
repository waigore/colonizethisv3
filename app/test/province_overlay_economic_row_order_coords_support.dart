// Game/region/view builders for Economic-section row CONTENT contracts
// (Refs #2865 S6). Overlay pump and row finders stay in the test file.

import 'package:colonizethis_logic/colonizethis_logic.dart'
    show PlayerView, VisibilityLevel;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const String kEconRowOrderRegionId = 'oldWorld';
const String kEconRowOrderLocalProvinceId = 'pEconRowOrder';
const String kEconRowOrderHumanPlayerId = 'gp1';

String get kEconRowOrderFullProvinceId =>
    '$kEconRowOrderRegionId|$kEconRowOrderLocalProvinceId';

String econRowOrderTileKey(int x, int y) =>
    '$kEconRowOrderFullProvinceId|$x|$y';

RegionMapViewData econRowOrderRegionWithGrainCells(
  List<({int x, int y})> coords, {
  required int width,
  required int height,
}) {
  final cells = <CellViewData>[
    for (final c in coords)
      CellViewData(
        x: c.x,
        y: c.y,
        regionCellId: kEconRowOrderLocalProvinceId,
        isSea: false,
        terrainTypeId: 'plains',
        resourceId: 'grain',
        visibility: TileVisibility.visible,
      ),
  ];
  return RegionMapViewData(
    regionId: kEconRowOrderRegionId,
    width: width,
    height: height,
    cellSize: 32,
    cells: cells,
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: const {kEconRowOrderHumanPlayerId},
    terrainColors: const {},
  );
}

Game econRowOrderGameWithGrainTiles({
  required List<String> tileKeys,
  required Map<String, int> improvementByTile,
}) {
  final visibility = <String, String>{
    for (final tk in tileKeys) tk: 'fullyVisible',
  };
  final prospected = <String>{...tileKeys};
  return Game(
    id: 'economic_row_order_test',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: kEconRowOrderFullProvinceId,
            regionId: kEconRowOrderRegionId,
            ownerId: kEconRowOrderHumanPlayerId,
            displayName: 'EconRowOrder',
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: {
        kEconRowOrderRegionId: {kEconRowOrderFullProvinceId: tileKeys},
      },
      resourceByTileKey: {for (final tk in tileKeys) tk: 'grain'},
      playerVisibilityByTile: {kEconRowOrderHumanPlayerId: visibility},
      playerProspectedTiles: {kEconRowOrderHumanPlayerId: prospected},
      tileState: TileMapState(improvementByTile: improvementByTile),
    ),
    players: const [
      Player(
        id: kEconRowOrderHumanPlayerId,
        displayName: 'Human',
        isHuman: true,
        treasury: 0,
      ),
    ],
  );
}

PlayerView econRowOrderOmniscientViewForTiles(Iterable<String> keys) {
  return PlayerView(
    playerId: kEconRowOrderHumanPlayerId,
    player: const Player(
      id: kEconRowOrderHumanPlayerId,
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
