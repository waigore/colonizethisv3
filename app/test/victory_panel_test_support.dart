// Shared map-backed fixtures for Victory panel layout/golden tests.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:hive/hive.dart';

import 'panel_fixtures/core.dart';

const String kVictoryPanelMapTestGameId = 'victory-layout-test';

final MapTopology victoryPanelMapCombinedTopology = MapTopology(
  nodes: const [
    TopologyNode(
      id: 'oldWorld|p1',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'oldWorld|p2',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'oldWorld|s1',
      regionId: 'oldWorld',
      type: TopologyNodeType.seaZone,
    ),
    TopologyNode(
      id: 'newWorld|p1',
      regionId: 'newWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'newWorld|s1',
      regionId: 'newWorld',
      type: TopologyNodeType.seaZone,
    ),
  ],
  edges: const [
    TopologyEdge(id1: 'oldWorld|p1', id2: 'oldWorld|p2'),
    TopologyEdge(id1: 'oldWorld|p1', id2: 'oldWorld|s1'),
    TopologyEdge(id1: 'newWorld|p1', id2: 'newWorld|s1'),
  ],
);

class VictoryPanelMapGameService extends GameService {
  VictoryPanelMapGameService(super.box, super.adapter);

  static final Map<String, MapTopology> _topologyByRegion = {
    'oldWorld': MapTopology(
      nodes: const [
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
          id: 's1',
          regionId: 'oldWorld',
          type: TopologyNodeType.seaZone,
        ),
      ],
      edges: const [
        TopologyEdge(id1: 'p1', id2: 'p2'),
        TopologyEdge(id1: 'p1', id2: 's1'),
      ],
    ),
    'newWorld': MapTopology(
      nodes: const [
        TopologyNode(
          id: 'p1',
          regionId: 'newWorld',
          type: TopologyNodeType.province,
        ),
        TopologyNode(
          id: 's1',
          regionId: 'newWorld',
          type: TopologyNodeType.seaZone,
        ),
      ],
      edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
    ),
  };

  static final Map<String, TileMapResult> _tileMapByRegion = {
    'oldWorld': TileMapResult(
      width: 2,
      height: 2,
      grid: const [
        ['p1', 'p1'],
        ['p2', 's1'],
      ],
      terrainGrid: const [
        [TerrainType.plains, TerrainType.plains],
        [TerrainType.plains, TerrainType.plains],
      ],
      resourceGrid: [
        [Resource.grain, Resource.grain],
        [Resource.grain, Resource.meat],
      ],
    ),
    'newWorld': TileMapResult(
      width: 1,
      height: 1,
      grid: const [
        ['p1'],
      ],
    ),
  };

  @override
  GameMapData? getMapData(String gameId) {
    if (gameId != kVictoryPanelMapTestGameId) return null;
    return (
      combinedTopology: victoryPanelMapCombinedTopology,
      tileMapByRegion: _tileMapByRegion,
      topologyByRegion: _topologyByRegion,
      warpLinks: null,
    );
  }
}

Game buildVictoryPanelMapTestGame() {
  return buildPanelTestGame(
    id: kVictoryPanelMapTestGameId,
    players: [
      const Player(
        id: 'gp1',
        displayName: 'England',
        isHuman: true,
        capitalProvinceId: 'oldWorld|p1',
      ),
      const Player(id: 'gp2', displayName: 'France', isHuman: false),
    ],
    oldWorldProvinces: const [
      Province(
        id: 'oldWorld|p1',
        regionId: 'oldWorld',
        ownerId: 'gp1',
        displayName: 'London',
        townTileKey: 'oldWorld|p1|0|0',
      ),
      Province(
        id: 'oldWorld|p2',
        regionId: 'oldWorld',
        ownerId: 'gp2',
        displayName: 'Paris',
        townTileKey: 'oldWorld|p2|0|0',
      ),
    ],
  );
}

RegionMapViewData sampleVictoryAnnotatedOldWorldRegion() {
  return RegionMapViewData(
    regionId: 'oldWorld',
    width: 2,
    height: 2,
    cellSize: 8,
    cells: [
      const CellViewData(
        x: 0,
        y: 0,
        regionCellId: 'p1',
        isSea: false,
        ownerFactionId: 'gp1',
        provinceDisplayName: 'London',
      ),
      const CellViewData(
        x: 1,
        y: 0,
        regionCellId: 'p1',
        isSea: false,
        ownerFactionId: 'gp1',
        provinceDisplayName: 'London',
      ),
      const CellViewData(x: 0, y: 1, regionCellId: 'sea1', isSea: true),
      CellViewData(
        x: 1,
        y: 1,
        regionCellId: 'p2',
        isSea: false,
        ownerFactionId: 'gp2',
        provinceDisplayName: 'Yorkshire',
      ),
    ],
    capitalMarkers: const [
      CapitalMarkerView(
        factionId: 'gp1',
        displayName: 'England',
        x: 0,
        y: 0,
      ),
    ],
    portMarkers: const [],
    factionColors: {
      'gp1': (180, 80, 80),
      'gp2': (80, 80, 180),
    },
    greatPowerFactionIds: {'gp1', 'gp2'},
    terrainColors: const {},
    unitMarkers: const [],
    civilianTileMarkers: const [],
    fleetTileMarkers: const [],
    warpMarkers: const [],
    townMarkers: const [
      TownMarkerView(
        x: 1,
        y: 1,
        provinceId: 'p2',
        isCoastal: false,
        isPort: false,
        touchesSea: false,
        townDevelopmentLevel: 1,
        townIconStyle: 'euro',
      ),
    ],
    provinceUnitPresenceByProvinceId: const {},
    provincePoliticalOwnerByPrefixedProvinceId: const {},
    seaZoneDisplayNameByPrefixedId: const {},
  );
}

Future<Box<dynamic>> openVictoryPanelTestHiveBox() async {
  Hive.init('./.dart_tool/test_hive_victory_panel');
  return Hive.openBox<dynamic>(HiveBoxNames.games);
}
