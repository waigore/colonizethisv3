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
}) {
  return Game(
    id: 'slice-test',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(provinces: oldWorldProvinces, units: oldWorldUnits),
      newWorld: RegionData(provinces: newWorldProvinces, units: newWorldUnits),
      fleets: fleets,
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
      TopologyNode(id: 's1', regionId: regionId, type: TopologyNodeType.seaZone),
    ],
    edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
  );
}

void main() {
  group('buildInitGameMapViewData extracted slice coverage', () {
    test('region setup maps owner/display and terrain palette from minimal data', () {
      final tileMap = TileMapResult(
        width: 1,
        height: 1,
        grid: [
          ['p1'],
        ],
        terrainGrid: [
          [TerrainType.forest],
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
        players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: false)],
      );

      final view = buildInitGameMapViewData(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap, 'newWorld': seaOnly},
        topologyByRegion: {'oldWorld': topology, 'newWorld': newWorldTopology},
        cellSize: 8,
      );

      final cell = view.oldWorld.cells.single;
      expect(cell.ownerFactionId, 'gp1');
      expect(cell.provinceDisplayName, 'Alpha');
      expect(view.oldWorld.terrainColors.containsKey(TerrainType.forest), isTrue);
      expect(
        view.oldWorld.provincePoliticalOwnerByPrefixedProvinceId['oldWorld|p1'],
        'gp1',
      );
    });

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
        oldWorldProvinces: const [Province(id: 'oldWorld|p1', regionId: 'oldWorld')],
        newWorldProvinces: const [],
        oldWorldUnits: [
          Unit(
            id: 'u-builder',
            type: 'Builder',
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

      final presence = view
          .oldWorld
          .provinceUnitPresenceByProvinceId['oldWorld|p1']!;
      expect(presence.civilianCount, 1);
      expect(presence.regimentCount, 1);
      expect(presence.shipCount, 1);
      expect(presence.intelVisible, isTrue);
    });
  });
}
