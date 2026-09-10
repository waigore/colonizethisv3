// Shared MAP20001 Military fort overlay fixture for siege gist tests (Refs #4764).

import 'package:colonizethis_data/colonizethis_data.dart' show TerrainType;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const kFortSiegeOverlayHumanId = 'gp_fort_overlay';
const kFortSiegeOverlayProvinceId = 'oldWorld|pFort';
const kFortSiegeOverlayTileKey = 'oldWorld|pFort|0|0';

Game fortSiegeOverlayGame({required int fortLevel}) {
  return Game(
    id: 'g_fort_overlay',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: kFortSiegeOverlayProvinceId,
            regionId: 'oldWorld',
            ownerId: kFortSiegeOverlayHumanId,
            townTileKey: kFortSiegeOverlayTileKey,
            fortLevel: fortLevel,
          ),
        ],
        units: const [],
      ),
      newWorld: const RegionData(provinces: [], units: []),
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          kFortSiegeOverlayProvinceId: [kFortSiegeOverlayTileKey],
        },
      },
      tileState: TileMapState(),
      playerVisibilityByTile: {
        kFortSiegeOverlayHumanId: {kFortSiegeOverlayTileKey: 'fullyVisible'},
      },
    ),
    players: [
      Player(
        id: kFortSiegeOverlayHumanId,
        displayName: 'Human',
        isHuman: true,
        capitalProvinceId: kFortSiegeOverlayProvinceId,
      ),
    ],
    minorNations: const [],
    tribes: const [],
  );
}

RegionMapViewData fortSiegeOverlayRegion() {
  return RegionMapViewData(
    regionId: 'oldWorld',
    width: 1,
    height: 1,
    cellSize: 16,
    cells: const [
      CellViewData(
        x: 0,
        y: 0,
        regionCellId: 'pFort',
        isSea: false,
        terrainType: TerrainType.plains,
        resourceId: 'grain',
        ownerFactionId: kFortSiegeOverlayHumanId,
        provinceDisplayName: 'Fort Province',
        visibility: TileVisibility.visible,
      ),
    ],
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: {kFortSiegeOverlayHumanId},
    terrainColors: const {},
    provincePoliticalOwnerByPrefixedProvinceId: const {
      kFortSiegeOverlayProvinceId: kFortSiegeOverlayHumanId,
    },
  );
}
