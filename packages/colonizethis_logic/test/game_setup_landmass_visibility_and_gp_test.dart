import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('GameSetup', () {
    test('each GP stays on a single landmass (no cross-continent assignment)', () {
      // Create a map with 2 disconnected landmasses:
      // Landmass A: p1 (sea-bound), p2, p3
      // Landmass B: p4 (sea-bound), p5, p6
      // With 2 GPs, each should get one landmass
      // Each province needs coastal access via sea zones.
      // Grid: p1 adjacent to sea1, p4 adjacent to sea2 (p1 and sea1 must be adjacent in grid).
      final owGrid = [
        ['p1', 'sea1', 'p2'],
        ['p3', 'p4', 'sea2'],
        ['p5', 'p6', 'sea3'],
      ];
      final owTopology = MapTopology(
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
          TopologyNode(
            id: 'p3',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'p4',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'p5',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'p6',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'sea1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'sea2',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'sea3',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [
          // Landmass A: p1 is coastal (sea1), p1-p2, p2-p3
          TopologyEdge(id1: 'p1', id2: 'sea1'),
          TopologyEdge(id1: 'p1', id2: 'p2'),
          TopologyEdge(id1: 'p2', id2: 'p3'),
          // Landmass B: p4 is coastal (sea2), p4-p5, p5-p6
          TopologyEdge(id1: 'p4', id2: 'sea2'),
          TopologyEdge(id1: 'p4', id2: 'p5'),
          TopologyEdge(id1: 'p5', id2: 'p6'),
          // p3 and p6 connect to sea3 for coastal access
          TopologyEdge(id1: 'p3', id2: 'sea3'),
          TopologyEdge(id1: 'p6', id2: 'sea3'),
        ],
      );
      final owTileMap = TileMapResult(width: 3, height: 3, grid: owGrid);

      // NW: 1 province
      final nwGrid = [
        ['nw1', 'sea1'],
        ['nw1', 'nw1'],
      ];
      final nwTopology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'nw1',
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'sea1',
            regionId: 'newWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [TopologyEdge(id1: 'nw1', id2: 'sea1')],
      );
      final nwTileMap = TileMapResult(width: 2, height: 2, grid: nwGrid);

      final config = GameSetupConfig(
        selectedGreatPowerIds: ['england', 'france'],
        continentCount: 2,
        minorNationCount: 0,
        tribeCount: 1,
        numProvincesOldWorld: 6,
        numProvincesNewWorld: 1,
        minProvincesPerMinor: 0,
      );

      final result = createGameFromGeneratedMaps(
        config: config,
        tileMapOldWorld: owTileMap,
        topologyOldWorld: owTopology,
        tileMapNewWorld: nwTileMap,
        topologyNewWorld: nwTopology,
        gameId: 'single-landmass-test',
      );

      // Get GP province IDs (extract just the province part from "oldWorld|p1" format)
      final gp1Provinces = result.game.worldState.oldWorld.provinces
          .where((p) => p.ownerId == 'gp1')
          .map((p) => p.id.split('|').last)
          .toList();
      final gp2Provinces = result.game.worldState.oldWorld.provinces
          .where((p) => p.ownerId == 'gp2')
          .map((p) => p.id.split('|').last)
          .toList();

      // Each GP should have provinces
      expect(
        gp1Provinces.isNotEmpty,
        true,
        reason: 'GP1 should have provinces',
      );
      expect(
        gp2Provinces.isNotEmpty,
        true,
        reason: 'GP2 should have provinces',
      );

      // Compute landmass IDs for each province
      // Landmass A: p1, p2, p3 (connected via p1-p2-p3)
      // Landmass B: p4, p5, p6 (connected via p4-p5-p6)
      final landmassAPart1 = {'p1', 'p2', 'p3'};
      final landmassBPart1 = {'p4', 'p5', 'p6'};

      // Check that each GP's provinces are all on the same landmass
      final gp1OnLandmassA = gp1Provinces.any(
        (p) => landmassAPart1.contains(p),
      );
      final gp1OnLandmassB = gp1Provinces.any(
        (p) => landmassBPart1.contains(p),
      );
      final gp2OnLandmassA = gp2Provinces.any(
        (p) => landmassAPart1.contains(p),
      );
      final gp2OnLandmassB = gp2Provinces.any(
        (p) => landmassBPart1.contains(p),
      );

      // Each GP should be on exactly one landmass
      expect(
        gp1OnLandmassA && !gp1OnLandmassB || !gp1OnLandmassA && gp1OnLandmassB,
        true,
        reason: 'GP1 should be on exactly one landmass, got: $gp1Provinces',
      );
      expect(
        gp2OnLandmassA && !gp2OnLandmassB || !gp2OnLandmassA && gp2OnLandmassB,
        true,
        reason: 'GP2 should be on exactly one landmass, got: $gp2Provinces',
      );

      // GPs should be on different landmasses
      expect(
        gp1OnLandmassA != gp2OnLandmassA || gp1OnLandmassB != gp2OnLandmassB,
        true,
        reason: 'GPs should be on different landmasses',
      );
    });

    test('sea tiles have visibility set (OW fogged, NW unknown)', () {
      // OW: 1 province (p1) + 1 sea zone (sea1)
      // NW:1 province (nw1) + 1 sea zone (sea1)
      final owGrid = [
        ['p1', 'sea1'],
      ];
      final owTopology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'sea1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [TopologyEdge(id1: 'p1', id2: 'sea1')],
      );
      final owTileMap = TileMapResult(width: 2, height: 1, grid: owGrid);

      final nwGrid = [
        ['nw1', 'sea1'],
      ];
      final nwTopology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'nw1',
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'sea1',
            regionId: 'newWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [TopologyEdge(id1: 'nw1', id2: 'sea1')],
      );
      final nwTileMap = TileMapResult(width: 2, height: 1, grid: nwGrid);

      final config = GameSetupConfig(
        selectedGreatPowerIds: ['england'],
        continentCount: 1,
        minorNationCount: 0,
        tribeCount: 1,
        numProvincesOldWorld: 1,
        numProvincesNewWorld: 1,
        minProvincesPerMinor: 0,
      );

      final result = createGameFromGeneratedMaps(
        config: config,
        tileMapOldWorld: owTileMap,
        topologyOldWorld: owTopology,
        tileMapNewWorld: nwTileMap,
        topologyNewWorld: nwTopology,
        gameId: 'sea-visibility-test',
      );

      final vis = result.game.worldState.playerVisibilityByTile;
      final gpId = result.game.players.first.id;

      // Old World sea tile (sea1) should be fullyVisible because it's adjacent
      // to the GP's province (p1). Coastal sea zone visibility is applied at
      // game setup per SPEC/program/fog-and-exploration-resolution.md.
      final owSeaTileKey = 'oldWorld|sea1|1|0';
      expect(
        vis[gpId],
        contains(owSeaTileKey),
        reason: 'OW sea tile must be in visibility map',
      );
      expect(
        vis[gpId]![owSeaTileKey],
        'fullyVisible',
        reason:
            'OW sea tile adjacent to owned province should be fullyVisible'
            ' at game setup (coastal sea zone visibility)',
      );

      // New World sea tile (sea1) should be unknown (no GP owns adjacent province)
      final nwSeaTileKey = 'newWorld|sea1|1|0';
      expect(
        vis[gpId],
        contains(nwSeaTileKey),
        reason: 'NW sea tile must be in visibility map',
      );
      expect(
        vis[gpId]![nwSeaTileKey],
        'unknown',
        reason: 'NW sea tile should be unknown (no GP owns adjacent province)',
      );

      // Verify land tiles also have visibility
      final owLandTileKey = 'oldWorld|p1|0|0';
      expect(
        vis[gpId],
        contains(owLandTileKey),
        reason: 'OW land tile must be in visibility map',
      );
      // Own province should be fullyVisible
      expect(
        vis[gpId]![owLandTileKey],
        'fullyVisible',
        reason: 'OW own province should be fully visible',
      );

      final nwLandTileKey = 'newWorld|nw1|0|0';
      expect(
        vis[gpId],
        contains(nwLandTileKey),
        reason: 'NW land tile must be in visibility map',
      );
      // New World should be unknown
      expect(
        vis[gpId]![nwLandTileKey],
        'unknown',
        reason: 'NW land tile should be unknown',
      );
    });
  });
}
