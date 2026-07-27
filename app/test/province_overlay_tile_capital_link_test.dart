// Tile capital-link and per-tile extraction preview pins (Refs #4149).

import 'package:colonizethis_logic/colonizethis_logic.dart'
    show provinceTileCapitalLinkPreview;
import 'package:colonizethis_data/colonizethis_data.dart'
    show
        MapTopology,
        Resource,
        TileMapResult,
        TopologyNode,
        TopologyNodeType,
        kTechIdMoldboardPlow;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/core/services/game_service/game_service.dart'
    show GameMapData;

const _provinceId = 'oldWorld|p1';
const _ownerId = 'gp1';
const _disconnectedTile = 'oldWorld|p1|0|0';
const _connectedTile = 'oldWorld|p1|1|0';

Game _gameWithTiles({
  required String ownerId,
  required String improvedTileKey,
  required int improvementLevel,
}) {
  return Game(
    id: 'g_tile_capital_link',
    capitalTileGrainBonusPerTurn: 0,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: _provinceId,
            regionId: 'oldWorld',
            ownerId: ownerId,
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
        id: ownerId,
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

GameMapData _mapData() {
  final tileMap = TileMapResult(
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

void main() {
  suppressLogsForTests();

  group('provinceTileCapitalLinkPreview (Refs #4149)', () {
    test('disconnected improved tile shows not connected and 0 of full', () {
      final preview = provinceTileCapitalLinkPreview(
        game: _gameWithTiles(
          ownerId: _ownerId,
          improvedTileKey: _disconnectedTile,
          improvementLevel: 2,
        ),
        humanPlayerId: _ownerId,
        selectedTileKey: _disconnectedTile,
        isLandTile: true,
        tileMapByRegion: _mapData().tileMapByRegion,
        topology: _mapData().combinedTopology,
      );
      expect(preview, isNotNull);
      expect(preview!.isCapitalConnected, isFalse);
      expect(preview.extractionFull, 2);
      expect(preview.extractionEffective, 0);
      expect(preview.showExtraction, isTrue);
    });

    test('capital-connected tile shows connected and E equals F', () {
      const tk = 'oldWorld|p1|0|0';
      final game = Game(
        id: 'g_tile_capital_link_connected',
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
              .setImprovement(tk, 2)
              .setRoadLevel(tk, 4),
          resourceByTileKey: const {tk: 'grain'},
          tileKeysByRegionAndProvince: const {
            'oldWorld': {
              _provinceId: [tk],
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
              x: 0,
              y: 0,
            ),
            techUnlocked: const {kTechIdMoldboardPlow: true},
          ),
        ],
      );
      final mapData = (
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
        tileMapByRegion: {
          'oldWorld': TileMapResult(
            width: 1,
            height: 1,
            grid: const [
              ['p1'],
            ],
            resourceGrid: const [
              [Resource.grain],
            ],
          ),
        },
        topologyByRegion: const <String, MapTopology>{},
        warpLinks: null,
      );
      final preview = provinceTileCapitalLinkPreview(
        game: game,
        humanPlayerId: _ownerId,
        selectedTileKey: tk,
        isLandTile: true,
        tileMapByRegion: mapData.tileMapByRegion,
        topology: mapData.combinedTopology,
      );
      expect(preview, isNotNull);
      expect(preview!.isCapitalConnected, isTrue);
      expect(preview.extractionFull, 2);
      expect(preview.extractionEffective, 2);
    });

    test('returns null for foreign-owned province tile', () {
      final preview = provinceTileCapitalLinkPreview(
        game: _gameWithTiles(
          ownerId: 'gp2',
          improvedTileKey: _connectedTile,
          improvementLevel: 2,
        ),
        humanPlayerId: _ownerId,
        selectedTileKey: _connectedTile,
        isLandTile: true,
        tileMapByRegion: _mapData().tileMapByRegion,
        topology: _mapData().combinedTopology,
      );
      expect(preview, isNull);
    });

    test('returns null for sea tile', () {
      final preview = provinceTileCapitalLinkPreview(
        game: _gameWithTiles(
          ownerId: _ownerId,
          improvedTileKey: _connectedTile,
          improvementLevel: 2,
        ),
        humanPlayerId: _ownerId,
        selectedTileKey: _connectedTile,
        isLandTile: false,
        tileMapByRegion: _mapData().tileMapByRegion,
        topology: _mapData().combinedTopology,
      );
      expect(preview, isNull);
    });

    test('unimproved tile shows capital link without extraction row', () {
      final game = _gameWithTiles(
        ownerId: _ownerId,
        improvedTileKey: _connectedTile,
        improvementLevel: 0,
      );
      final preview = provinceTileCapitalLinkPreview(
        game: game,
        humanPlayerId: _ownerId,
        selectedTileKey: _connectedTile,
        isLandTile: true,
        tileMapByRegion: _mapData().tileMapByRegion,
        topology: _mapData().combinedTopology,
      );
      expect(preview, isNotNull);
      expect(preview!.isCapitalConnected, isTrue);
      expect(preview.extractionFull, 0);
      expect(preview.showExtraction, isFalse);
    });
  });
}
