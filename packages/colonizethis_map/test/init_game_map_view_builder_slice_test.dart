import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

Game _minimalGame({
  required List<Province> oldWorldProvinces,
  required List<Province> newWorldProvinces,
  List<Unit> oldWorldUnits = const [],
  List<Unit> newWorldUnits = const [],
  List<Fleet> fleets = const [],
  List<Player> players = const [],
  Map<String, String> portsByProvinceSeaboard = const {},
}) {
  return Game(
    id: 'slice-test',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(provinces: oldWorldProvinces, units: oldWorldUnits),
      newWorld: RegionData(provinces: newWorldProvinces, units: newWorldUnits),
      fleets: fleets,
      portsByProvinceSeaboard: portsByProvinceSeaboard,
    ),
    players: players,
    minorNations: const [],
    tribes: const [],
  );
}

MapTopology _singleProvinceAndSeaTopology(String regionId) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: 'p1',
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 's1',
        regionId: regionId,
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
  );
}

void main() {
  group('buildInitGameMapViewData extracted slice coverage', () {
    test(
      'region setup maps owner/display and terrain palette from minimal data',
      () {
        final tileMap = TileMapResult(
          width: 1,
          height: 1,
          grid: [
            ['p1'],
          ],
          terrainGrid: [
            [TerrainType.hardwoodForest],
          ],
        );
        final seaOnly = TileMapResult(
          width: 1,
          height: 1,
          grid: [
            ['s1'],
          ],
        );
        final topology = _singleProvinceAndSeaTopology('oldWorld');
        final newWorldTopology = _singleProvinceAndSeaTopology('newWorld');
        final game = _minimalGame(
          oldWorldProvinces: const [
            Province(
              id: 'oldWorld|p1',
              regionId: 'oldWorld',
              ownerId: 'gp1',
              displayName: 'Alpha',
            ),
          ],
          newWorldProvinces: const [],
          players: const [
            Player(id: 'gp1', displayName: 'GP1', isHuman: false),
          ],
        );

        final view = buildInitGameMapViewData(
          game: game,
          tileMapByRegion: {'oldWorld': tileMap, 'newWorld': seaOnly},
          topologyByRegion: {
            'oldWorld': topology,
            'newWorld': newWorldTopology,
          },
          cellSize: 8,
        );

        final cell = view.oldWorld.cells.single;
        expect(cell.ownerFactionId, 'gp1');
        expect(cell.provinceDisplayName, 'Alpha');
        expect(
          view.oldWorld.terrainColors.containsKey(TerrainType.hardwoodForest),
          isTrue,
        );
        expect(
          view
              .oldWorld
              .provincePoliticalOwnerByPrefixedProvinceId['oldWorld|p1'],
          'gp1',
        );
      },
    );

    test('overlay setup counts regiments, civilians, and in-port ships', () {
      final tileMap = TileMapResult(
        width: 1,
        height: 1,
        grid: [
          ['p1'],
        ],
      );
      final seaOnly = TileMapResult(
        width: 1,
        height: 1,
        grid: [
          ['s1'],
        ],
      );
      final topology = _singleProvinceAndSeaTopology('oldWorld');
      final newWorldTopology = _singleProvinceAndSeaTopology('newWorld');
      final game = _minimalGame(
        oldWorldProvinces: const [
          Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
        ],
        newWorldProvinces: const [],
        oldWorldUnits: [
          Unit(
            id: 'u-builder',
            type: kUnitTypeBuilder,
            ownerId: 'gp1',
            locationProvinceId: 'oldWorld|p1',
          ),
          Unit(
            id: 'u-regiment',
            type: 'pikemen',
            ownerId: 'gp1',
            locationProvinceId: 'oldWorld|p1',
          ),
        ],
        fleets: [
          Fleet(
            id: 'f1',
            ownerId: 'gp1',
            regionId: 'oldWorld',
            inPortAtProvinceId: 'oldWorld|p1',
            ships: const [ShipInstance(id: 'ship-1', typeId: 'frigate')],
          ),
        ],
      );

      final view = buildInitGameMapViewData(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap, 'newWorld': seaOnly},
        topologyByRegion: {'oldWorld': topology, 'newWorld': newWorldTopology},
        cellSize: 8,
      );

      final presence =
          view.oldWorld.provinceUnitPresenceByProvinceId['oldWorld|p1']!;
      expect(presence.civilianCount, 1);
      expect(presence.regimentCount, 1);
      expect(presence.shipCount, 1);
      expect(presence.intelVisible, isTrue);
    });

    test('marker helpers expose capitals ports towns and warps', () {
      final tileMap = TileMapResult(
        width: 2,
        height: 1,
        grid: [
          ['p1', 's1'],
        ],
      );
      final newWorldSea = TileMapResult(
        width: 1,
        height: 1,
        grid: [
          ['s9'],
        ],
      );
      final topology = _singleProvinceAndSeaTopology('oldWorld');
      final newWorldTopology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 's9',
            regionId: 'newWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [],
      );
      final game = _minimalGame(
        oldWorldProvinces: const [
          Province(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            townTileKey: 'oldWorld|p1|0|0',
          ),
        ],
        newWorldProvinces: const [],
        players: const [
          Player(
            id: 'gp1',
            displayName: 'GP1',
            isHuman: true,
            capitalTile: CapitalTile(
              regionId: 'oldWorld',
              provinceId: 'oldWorld|p1',
              x: 0,
              y: 0,
            ),
          ),
        ],
        portsByProvinceSeaboard: const {'oldWorld|p1|s1': 'oldWorld|p1|0|0'},
      );

      final view = buildInitGameMapViewData(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap, 'newWorld': newWorldSea},
        topologyByRegion: {'oldWorld': topology, 'newWorld': newWorldTopology},
        cellSize: 8,
        warpLinks: const [
          WarpLink(
            regionId: 'oldWorld',
            seaZoneId: 's1',
            otherRegionId: 'newWorld',
            otherSeaZoneId: 's9',
          ),
        ],
      );

      expect(view.oldWorld.capitalMarkers.length, 1);
      expect(view.oldWorld.capitalMarkers.single.factionId, 'gp1');
      expect(view.oldWorld.portMarkers.length, 1);
      expect(view.oldWorld.portMarkers.single.provinceId, 'p1');
      expect(view.oldWorld.townMarkers.length, 1);
      expect(view.oldWorld.townMarkers.single.isPort, isTrue);
      expect(view.oldWorld.townMarkers.single.touchesSea, isTrue);
      expect(view.oldWorld.warpMarkers.length, 1);
      expect(view.oldWorld.warpMarkers.single.seaZoneId, 's1');
      expect(view.oldWorld.warpMarkers.single.otherRegionId, 'newWorld');
    });

    test('cell helper applies visibility and extraction overlays', () {
      final tileMap = TileMapResult(
        width: 1,
        height: 1,
        grid: [
          ['p1'],
        ],
      );
      final seaOnly = TileMapResult(
        width: 1,
        height: 1,
        grid: [
          ['s1'],
        ],
      );
      final topology = _singleProvinceAndSeaTopology('oldWorld');
      final newWorldTopology = _singleProvinceAndSeaTopology('newWorld');
      final game = _minimalGame(
        oldWorldProvinces: const [
          Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
        ],
        newWorldProvinces: const [],
      );

      final view = buildInitGameMapViewData(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap, 'newWorld': seaOnly},
        topologyByRegion: {'oldWorld': topology, 'newWorld': newWorldTopology},
        cellSize: 8,
        visibilityByTile: const {'oldWorld|p1|0|0': TileVisibility.fogged},
        resourceExtractionUnitsByTile: const {'oldWorld|p1|0|0': 9},
        resourceExtractionEffectiveUnitsByTile: const {'oldWorld|p1|0|0': 7},
        resourceExtractionBlockedUnitsByTile: const {'oldWorld|p1|0|0': 2},
      );

      final cell = view.oldWorld.cells.single;
      expect(cell.visibility, TileVisibility.fogged);
      expect(cell.resourceExtractionUnits, 9);
      expect(cell.resourceExtractionEffectiveUnits, 7);
      expect(cell.resourceExtractionBlockedUnits, 2);
    });

    test(
      'does not synthesize a Home Fleet marker when fleet entity is missing',
      () {
        final tileMap = TileMapResult(
          width: 2,
          height: 1,
          grid: [
            ['p1', 's1'],
          ],
        );
        final newWorldSea = TileMapResult(
          width: 1,
          height: 1,
          grid: [
            ['s9'],
          ],
        );
        final topology = _singleProvinceAndSeaTopology('oldWorld');
        final newWorldTopology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 's9',
              regionId: 'newWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [],
        );
        final game = _minimalGame(
          oldWorldProvinces: const [
            Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
          ],
          newWorldProvinces: const [],
          players: const [
            Player(
              id: 'gp1',
              displayName: 'GP1',
              isHuman: true,
              capitalTile: CapitalTile(
                regionId: 'oldWorld',
                provinceId: 'oldWorld|p1',
                x: 0,
                y: 0,
              ),
            ),
          ],
          portsByProvinceSeaboard: const {'oldWorld|p1|s1': 'oldWorld|p1|0|0'},
        );

        final view = buildInitGameMapViewData(
          game: game,
          tileMapByRegion: {'oldWorld': tileMap, 'newWorld': newWorldSea},
          topologyByRegion: {
            'oldWorld': topology,
            'newWorld': newWorldTopology,
          },
          cellSize: 8,
        );

        expect(view.oldWorld.fleetTileMarkers, isEmpty);
      },
    );

    test('keeps an empty Home Fleet marker when real fleet entity exists', () {
      final tileMap = TileMapResult(
        width: 2,
        height: 1,
        grid: [
          ['p1', 's1'],
        ],
      );
      final newWorldSea = TileMapResult(
        width: 1,
        height: 1,
        grid: [
          ['s9'],
        ],
      );
      final topology = _singleProvinceAndSeaTopology('oldWorld');
      final newWorldTopology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 's9',
            regionId: 'newWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [],
      );
      final game = _minimalGame(
        oldWorldProvinces: const [
          Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
        ],
        newWorldProvinces: const [],
        fleets: [
          Fleet(
            id: 'fleet_gp1',
            ownerId: 'gp1',
            regionId: 'oldWorld',
            inPortAtProvinceId: 'oldWorld|p1',
            ships: [],
            mission: FleetMission.none,
          ),
        ],
        players: const [
          Player(
            id: 'gp1',
            displayName: 'GP1',
            isHuman: true,
            capitalTile: CapitalTile(
              regionId: 'oldWorld',
              provinceId: 'oldWorld|p1',
              x: 0,
              y: 0,
            ),
          ),
        ],
        portsByProvinceSeaboard: const {'oldWorld|p1|s1': 'oldWorld|p1|0|0'},
      );

      final view = buildInitGameMapViewData(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap, 'newWorld': newWorldSea},
        topologyByRegion: {'oldWorld': topology, 'newWorld': newWorldTopology},
        cellSize: 8,
      );

      expect(view.oldWorld.fleetTileMarkers, hasLength(1));
      expect(view.oldWorld.fleetTileMarkers.single.fleetIds, ['fleet_gp1']);
      expect(view.oldWorld.fleetTileMarkers.single.stackCount, 1);
    });
  });
}
