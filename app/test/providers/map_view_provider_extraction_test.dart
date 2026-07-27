// Map extraction disc maps for disconnected improved tiles (Refs #4151).

import 'package:colonizethis_data/colonizethis_data.dart'
    show
        MapTopology,
        Resource,
        TileMapResult,
        TopologyNode,
        TopologyNodeType,
        kTechIdMoldboardPlow;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show resolveConnectivity;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/providers/map_view_provider_extraction.dart';

const _provinceId = 'oldWorld|p1';
const _ownerId = 'gp1';
const _disconnectedTile = 'oldWorld|p1|0|0';
const _connectedTile = 'oldWorld|p1|1|0';

Game _gameWithImprovedTile({
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
            id: _provinceId,
            regionId: 'oldWorld',
            ownerId: _ownerId,
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
          _provinceId: [_disconnectedTile, _connectedTile],
        },
      },
    ),
    players: [
      Player(
        id: _ownerId,
        displayName: 'GP',
        isHuman: true,
        capitalProvinceId: _provinceId,
        capitalTile: const CapitalTile(
          regionId: 'oldWorld',
          provinceId: _provinceId,
          x: 1,
          y: 1,
        ),
        techUnlocked: const {kTechIdMoldboardPlow: true},
      ),
    ],
  );
}

Map<String, TileMapResult> _tileMapByRegion() {
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

MapTopology _topology() {
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

MapResourceExtractionMaps _buildMaps(Game game) {
  final player = game.players.first;
  final tileMapByRegion = _tileMapByRegion();
  final connectivity = resolveConnectivity(
    game: game,
    tileMapByRegion: tileMapByRegion,
    topology: _topology(),
  )[_ownerId]!;
  return mapViewBuildResourceExtractionMaps(
    game: game,
    mapPlayer: player,
    tileMapByRegion: tileMapByRegion,
    connectivityForHuman: connectivity,
  );
}

void main() {
  suppressLogsForTests();

  group('mapViewBuildResourceExtractionMaps (Refs #4151)', () {
    test('disconnected improved tile gets E=0 and B=production', () {
      final game = _gameWithImprovedTile(
        improvedTileKey: _disconnectedTile,
        improvementLevel: 2,
      );
      final maps = _buildMaps(game);

      expect(maps.unitsByTile[_disconnectedTile], 2);
      expect(maps.effectiveUnitsByTile[_disconnectedTile], 0);
      expect(maps.blockedUnitsByTile[_disconnectedTile], 2);
    });

    test('capital-connected improved tile keeps effective discs', () {
      const tileKey = 'oldWorld|p1|1|0';
      final game = Game(
        id: 'g_map_discs_connected',
        capitalTileGrainBonusPerTurn: 0,
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: _provinceId,
                regionId: 'oldWorld',
                ownerId: _ownerId,
                townDevelopmentLevel: 4,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileState: TileMapState()
              .setImprovement(tileKey, 2)
              .setRoadLevel(tileKey, 4),
          resourceByTileKey: const {tileKey: 'grain'},
          tileKeysByRegionAndProvince: const {
            'oldWorld': {
              _provinceId: [tileKey],
            },
          },
        ),
        players: [
          Player(
            id: _ownerId,
            displayName: 'GP',
            isHuman: true,
            capitalProvinceId: _provinceId,
            capitalTile: const CapitalTile(
              regionId: 'oldWorld',
              provinceId: _provinceId,
              x: 1,
              y: 0,
            ),
            techUnlocked: const {kTechIdMoldboardPlow: true},
          ),
        ],
      );
      final maps = _buildMaps(game);

      expect(maps.effectiveUnitsByTile[tileKey], 2);
      expect(maps.blockedUnitsByTile[tileKey], 0);
    });

    test('unimproved disconnected tile omits discs', () {
      final game = _gameWithImprovedTile(
        improvedTileKey: _disconnectedTile,
        improvementLevel: 0,
      );
      final maps = _buildMaps(game);

      expect(maps.unitsByTile.containsKey(_disconnectedTile), isFalse);
      expect(maps.effectiveUnitsByTile.containsKey(_disconnectedTile), isFalse);
      expect(maps.blockedUnitsByTile.containsKey(_disconnectedTile), isFalse);
    });
  });
}
