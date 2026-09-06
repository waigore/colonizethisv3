// Extraction-preview Game fixtures for province_detail_overlay_host_support_test.
// Refs #4352, #4734 densify province_detail_overlay_host_support_fixtures.dart.

import 'package:colonizethis_app/core/services/game_service/game_service.dart'
    show GameMapData;
import 'package:colonizethis_data/colonizethis_data.dart'
    show
        MapTopology,
        Resource,
        TileMapResult,
        TopologyNode,
        TopologyNodeType,
        kTechIdMoldboardPlow;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'province_detail_overlay_host_support_fixtures.dart';

Game provinceDetailGameWithImprovedGrain({required String ownerId}) {
  const provinceId = provinceDetailSupportProvinceId;
  const tk = provinceDetailSupportTileKey;
  return Game(
    id: 'g_extraction_preview',
    capitalTileGrainBonusPerTurn: 0,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: provinceId,
            regionId: 'oldWorld',
            ownerId: ownerId,
            townDevelopmentLevel: 4,
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileState: TileMapState().setImprovement(tk, 2).setRoadLevel(tk, 4),
      resourceByTileKey: const {tk: 'grain'},
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          'oldWorld|p1': [tk],
        },
      },
    ),
    players: [
      Player(
        id: ownerId,
        displayName: 'GP',
        isHuman: true,
        capitalProvinceId: provinceId,
        capitalTile: const CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'oldWorld|p1',
          x: 0,
          y: 0,
        ),
        techUnlocked: const {kTechIdMoldboardPlow: true},
      ),
    ],
  );
}

GameMapData provinceDetailMapDataForProjection() {
  final tileMap = TileMapResult(
    width: 1,
    height: 1,
    grid: const [
      ['p1'],
    ],
    resourceGrid: const [
      [Resource.grain],
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
      ],
      edges: [],
    ),
    tileMapByRegion: {'oldWorld': tileMap},
    topologyByRegion: const <String, MapTopology>{},
    warpLinks: null,
  );
}

Game provinceDetailUnresolvedExtractionGame() {
  const provinceId = provinceDetailSupportProvinceId;
  const tk = provinceDetailSupportTileKey;
  return Game(
    id: 'g_extraction_draft_ignore',
    capitalTileGrainBonusPerTurn: 0,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: provinceId,
            regionId: 'oldWorld',
            ownerId: 'gp1',
            townDevelopmentLevel: 4,
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileState: const TileMapState(),
      resourceByTileKey: const {tk: 'grain'},
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          'oldWorld|p1': [tk],
        },
      },
    ),
    players: [
      Player(
        id: 'gp1',
        displayName: 'GP',
        isHuman: true,
        capitalProvinceId: provinceId,
        capitalTile: const CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'oldWorld|p1',
          x: 0,
          y: 0,
        ),
        techUnlocked: const {kTechIdMoldboardPlow: true},
      ),
    ],
  );
}
