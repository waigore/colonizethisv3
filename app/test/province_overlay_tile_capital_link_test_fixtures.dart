// Game/map fixtures for `province_overlay_tile_capital_link_test.dart`
// (Refs #4224 Slice D, #4305 — scenario tables live in *_test_cases.dart).

import 'package:colonizethis_app/core/services/game_service/game_service.dart'
    show GameMapData;
import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support.dart';
import 'package:colonizethis_data/colonizethis_data.dart'
    show
        MapTopology,
        Resource,
        TileMapResult,
        TopologyNode,
        TopologyNodeType,
        kTechIdMoldboardPlow;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show ConnectivityResult;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const kTileCapitalLinkProvinceId = 'oldWorld|p1';
const kTileCapitalLinkRemoteProvinceId = 'oldWorld|p2';
const kTileCapitalLinkCapitalTile = 'oldWorld|p1|0|0';
const kTileCapitalLinkRemoteTile = 'oldWorld|p2|1|0';
const kTileCapitalLinkHumanId = 'gp1';

GameMapData tileCapitalLinkMapData() {
  final tileMap = TileMapResult(
    width: 2,
    height: 1,
    grid: const [
      ['p1', 'p2'],
    ],
    resourceGrid: const [
      [Resource.grain, Resource.grain],
    ],
  );
  return (
    combinedTopology: const MapTopology(
      nodes: [
        TopologyNode(
          id: 'p1',
          regionId: 'oldWorld',
          type: TopologyNodeType.province,
        ),
        TopologyNode(
          id: 'p2',
          regionId: 'oldWorld',
          type: TopologyNodeType.province,
        ),
      ],
      edges: [],
    ),
    tileMapByRegion: {'oldWorld': tileMap},
    topologyByRegion: const <String, MapTopology>{},
    warpLinks: null,
  );
}

Game tileCapitalLinkGame({
  required int remoteImprovementLevel,
  required int remoteRoadLevel,
  Game? customizeFrom,
}) {
  final base = customizeFrom ??
      Game(
        id: 'g_tile_capital_link',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: kTileCapitalLinkProvinceId,
                regionId: 'oldWorld',
                ownerId: kTileCapitalLinkHumanId,
                townDevelopmentLevel: 4,
                townTileKey: kTileCapitalLinkCapitalTile,
              ),
              Province(
                id: kTileCapitalLinkRemoteProvinceId,
                regionId: 'oldWorld',
                ownerId: kTileCapitalLinkHumanId,
                townDevelopmentLevel: 4,
                townTileKey: kTileCapitalLinkRemoteTile,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileState: TileMapState()
              .setImprovement(kTileCapitalLinkCapitalTile, 1)
              .setRoadLevel(kTileCapitalLinkCapitalTile, 4)
              .setImprovement(
                kTileCapitalLinkRemoteTile,
                remoteImprovementLevel,
              )
              .setRoadLevel(kTileCapitalLinkRemoteTile, remoteRoadLevel),
          resourceByTileKey: const {
            kTileCapitalLinkCapitalTile: 'grain',
            kTileCapitalLinkRemoteTile: 'grain',
          },
          tileKeysByRegionAndProvince: const {
            'oldWorld': {
              kTileCapitalLinkProvinceId: [kTileCapitalLinkCapitalTile],
              kTileCapitalLinkRemoteProvinceId: [kTileCapitalLinkRemoteTile],
            },
          },
        ),
        players: [
          Player(
            id: kTileCapitalLinkHumanId,
            displayName: 'Human',
            isHuman: true,
            capitalProvinceId: kTileCapitalLinkProvinceId,
            capitalTile: const CapitalTile(
              regionId: 'oldWorld',
              provinceId: kTileCapitalLinkProvinceId,
              x: 0,
              y: 0,
            ),
            techUnlocked: const {kTechIdMoldboardPlow: true},
          ),
        ],
      );
  return base;
}

Game tileCapitalLinkForeignRemoteGame() {
  return tileCapitalLinkGame(
    remoteImprovementLevel: 2,
    remoteRoadLevel: 0,
  ).copyWith(
    worldState: tileCapitalLinkGame(
      remoteImprovementLevel: 2,
      remoteRoadLevel: 0,
    ).worldState.copyWith(
      oldWorld: RegionData(
        provinces: [
          Province(
            id: kTileCapitalLinkProvinceId,
            regionId: 'oldWorld',
            ownerId: kTileCapitalLinkHumanId,
            townDevelopmentLevel: 4,
          ),
          Province(
            id: kTileCapitalLinkRemoteProvinceId,
            regionId: 'oldWorld',
            ownerId: 'gp2',
            townDevelopmentLevel: 4,
          ),
        ],
      ),
    ),
  );
}

Game tileCapitalLinkPathCappedGame() {
  final base = tileCapitalLinkGame(
    remoteImprovementLevel: 3,
    remoteRoadLevel: 4,
  );
  return base.copyWith(
    worldState: base.worldState.copyWith(
      tileState: TileMapState()
          .setImprovement(kTileCapitalLinkCapitalTile, 3)
          .setRoadLevel(kTileCapitalLinkCapitalTile, 4)
          .setImprovement(kTileCapitalLinkRemoteTile, 3)
          .setRoadLevel(kTileCapitalLinkRemoteTile, 4),
    ),
  );
}

RegionMapViewData tileCapitalLinkRegionForGame(Game game) {
  return RegionMapViewData(
    regionId: 'oldWorld',
    width: 2,
    height: 1,
    cellSize: 16,
    cells: const [
      CellViewData(
        x: 0,
        y: 0,
        regionCellId: 'p1',
        isSea: false,
        terrainTypeId: 'plains',
        resourceId: 'grain',
        visibility: TileVisibility.visible,
      ),
      CellViewData(
        x: 1,
        y: 0,
        regionCellId: 'p2',
        isSea: false,
        terrainTypeId: 'plains',
        resourceId: 'grain',
        visibility: TileVisibility.visible,
      ),
    ],
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: const {},
    terrainColors: const {},
    provincePoliticalOwnerByPrefixedProvinceId: const {
      kTileCapitalLinkProvinceId: kTileCapitalLinkHumanId,
      kTileCapitalLinkRemoteProvinceId: kTileCapitalLinkHumanId,
    },
  );
}

ProvinceTileConnectivityDisplay? tileCapitalLinkPreview({
  required Game game,
  required String provinceId,
  required String selectedTileKey,
  required bool isSeaZoneContext,
  required bool tileIsSea,
  required bool tileRevealed,
  ConnectivityResult? connectivityForHuman,
}) {
  return provinceTileConnectivityDisplayPreview(
    game: game,
    humanPlayerId: kTileCapitalLinkHumanId,
    provinceId: provinceId,
    selectedTileKey: selectedTileKey,
    mapData: tileCapitalLinkMapData(),
    isSeaZoneContext: isSeaZoneContext,
    tileIsSea: tileIsSea,
    tileRevealed: tileRevealed,
    connectivityForHuman: connectivityForHuman,
  );
}
