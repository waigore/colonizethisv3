// Build-fort golden Game/Region fixtures (Refs #4280, #4734 densify).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'province_shortcut_host_emit_fixtures.dart';

const String kBuildFortGoldenGameId = 'g_bf_golden';
const String kBuildFortGoldenHumanPlayerId = 'gp1';
const String kBuildFortGoldenProvinceId = 'oldWorld|p1';
const String kBuildFortGoldenTileKey = 'oldWorld|p1|0|0';

MapTopology buildFortGoldenCombinedTopology() =>
    provinceShortcutHostCombinedTopology();

Game goldenBuildFortGame() {
  return Game(
    id: kBuildFortGoldenGameId,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: kBuildFortGoldenProvinceId,
            regionId: 'oldWorld',
            ownerId: kBuildFortGoldenHumanPlayerId,
            townTileKey: kBuildFortGoldenTileKey,
            fortLevel: 0,
          ),
        ],
        units: [
          Unit(
            id: 'u_engineer',
            type: kUnitTypeEngineer,
            ownerId: kBuildFortGoldenHumanPlayerId,
            locationProvinceId: kBuildFortGoldenProvinceId,
            tileKey: kBuildFortGoldenTileKey,
            status: UnitStatus.idle,
          ),
        ],
      ),
      newWorld: const RegionData(provinces: [], units: []),
      resourceByTileKey: const {kBuildFortGoldenTileKey: 'grain'},
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          kBuildFortGoldenProvinceId: [kBuildFortGoldenTileKey],
        },
      },
      tileState: TileMapState(),
      playerVisibilityByTile: {
        kBuildFortGoldenHumanPlayerId: {kBuildFortGoldenTileKey: 'fullyVisible'},
      },
    ),
    players: [
      Player(
        id: kBuildFortGoldenHumanPlayerId,
        displayName: 'Human',
        isHuman: true,
        capitalProvinceId: kBuildFortGoldenProvinceId,
        stockpile: const Stockpile(quantities: {'lumber': 10, 'bronze': 10}),
      ),
    ],
    minorNations: const [],
    tribes: const [],
  );
}

RegionMapViewData goldenBuildFortRegion() {
  return RegionMapViewData(
    regionId: 'oldWorld',
    width: 1,
    height: 1,
    cellSize: 16,
    cells: const [
      CellViewData(
        x: 0,
        y: 0,
        regionCellId: 'p1',
        isSea: false,
        terrainType: TerrainType.plains,
        resourceId: 'grain',
        ownerFactionId: kBuildFortGoldenHumanPlayerId,
        provinceDisplayName: 'Golden Province',
        visibility: TileVisibility.visible,
      ),
    ],
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: {kBuildFortGoldenHumanPlayerId},
    terrainColors: const {},
    provincePoliticalOwnerByPrefixedProvinceId: const {
      'oldWorld|p1': kBuildFortGoldenHumanPlayerId,
    },
  );
}
