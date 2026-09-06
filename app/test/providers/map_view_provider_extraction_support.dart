// Map extraction disc fixtures (Refs #4151).

import 'package:colonizethis_data/colonizethis_data.dart'
    show
        MapTopology,
        Resource,
        TileMapResult,
        TopologyNode,
        TopologyNodeType,
        kTechIdMoldboardPlow;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show ConnectivityResult, resolveConnectivity;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_app/providers/map_view_provider_extraction.dart';

const mapViewExtractionProvinceId = 'oldWorld|p1';
const mapViewExtractionOwnerId = 'gp1';
const mapViewExtractionDisconnectedTile = 'oldWorld|p1|0|0';
const mapViewExtractionConnectedTile = 'oldWorld|p1|1|0';

Game mapViewExtractionGameWithImprovedTile({
  required String improvedTileKey,
  required int improvementLevel,
}) {
  return Game(
    id: 'g_map_discs',
    capitalTileGrainBonusPerTurn: 0,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: mapViewExtractionProvinceId,
            regionId: 'oldWorld',
            ownerId: mapViewExtractionOwnerId,
            townDevelopmentLevel: 4,
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileState: TileMapState()
          .setImprovement(improvedTileKey, improvementLevel)
          .setRoadLevel(improvedTileKey, 4),
      resourceByTileKey: {improvedTileKey: 'grain'},
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          mapViewExtractionProvinceId: [
            mapViewExtractionDisconnectedTile,
            mapViewExtractionConnectedTile,
          ],
        },
      },
    ),
    players: [
      Player(
        id: mapViewExtractionOwnerId,
        displayName: 'GP',
        isHuman: true,
        capitalProvinceId: mapViewExtractionProvinceId,
        capitalTile: const CapitalTile(
          regionId: 'oldWorld',
          provinceId: mapViewExtractionProvinceId,
          x: 1,
          y: 1,
        ),
        techUnlocked: const {kTechIdMoldboardPlow: true},
      ),
    ],
  );
}

Map<String, TileMapResult> mapViewExtractionTileMapByRegion() {
  return {
    'oldWorld': TileMapResult(
      width: 3,
      height: 3,
      grid: const [
        ['p1', 'p1', 'p1'],
        ['p1', 'p1', 'p1'],
        ['p1', 'p1', 'p1'],
      ],
      resourceGrid: const [
        [Resource.grain, Resource.grain, Resource.grain],
        [Resource.grain, Resource.grain, Resource.grain],
        [Resource.grain, Resource.grain, Resource.grain],
      ],
    ),
  };
}

MapTopology mapViewExtractionTopology() {
  return const MapTopology(
    nodes: [
      TopologyNode(
        id: 'p1',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: [],
  );
}

MapResourceExtractionMaps mapViewExtractionBuildMaps(Game game) {
  final player = game.players.first;
  final tileMapByRegion = mapViewExtractionTileMapByRegion();
  final connectivity = resolveConnectivity(
    game: game,
    tileMapByRegion: tileMapByRegion,
    topology: mapViewExtractionTopology(),
  )[mapViewExtractionOwnerId]!;
  return mapViewBuildResourceExtractionMaps(
    game: game,
    mapPlayer: player,
    tileMapByRegion: tileMapByRegion,
    connectivityForHuman: connectivity,
  );
}
