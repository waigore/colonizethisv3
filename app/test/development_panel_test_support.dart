// Shared map-backed fixtures for Development panel layout/golden tests (Refs #4175).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_test_hive_harness.dart';
import 'panel_fixtures/core.dart';

const String kDevelopmentPanelMapTestGameId = 'development-panel-golden-test';

final MapTopology developmentPanelMapCombinedTopology = MapTopology(
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
  ],
  edges: const [
    TopologyEdge(id1: 'oldWorld|p1', id2: 'oldWorld|p2'),
  ],
);

class DevelopmentPanelMapGameService extends GameService {
  DevelopmentPanelMapGameService(super.box, super.adapter);

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
      ],
      edges: const [TopologyEdge(id1: 'p1', id2: 'p2')],
    ),
    'newWorld': const MapTopology(nodes: [], edges: []),
  };

  static final Map<String, TileMapResult> _tileMapByRegion = {
    'oldWorld': TileMapResult(
      width: 2,
      height: 2,
      grid: const [
        ['p1', 'p1'],
        ['p2', 'p2'],
      ],
      terrainGrid: const [
        [TerrainType.plains, TerrainType.plains],
        [TerrainType.plains, TerrainType.plains],
      ],
      resourceGrid: [
        [Resource.grain, Resource.grain],
        [null, null],
      ],
    ),
    'newWorld': TileMapResult(
      width: 1,
      height: 1,
      grid: const [
        ['nw1'],
      ],
      terrainGrid: const [
        [TerrainType.plains],
      ],
    ),
  };

  @override
  ({
    MapTopology combinedTopology,
    Map<String, TileMapResult> tileMapByRegion,
    Map<String, MapTopology> topologyByRegion,
    List<WarpLink>? warpLinks,
  })?
  getMapData(String gameId) {
    if (gameId != kDevelopmentPanelMapTestGameId) return null;
    return (
      combinedTopology: developmentPanelMapCombinedTopology,
      tileMapByRegion: _tileMapByRegion,
      topologyByRegion: _topologyByRegion,
      warpLinks: null,
    );
  }
}

Game buildDevelopmentPanelGoldenGame() {
  const human = kPanelTestHumanPlayerId;
  const p1 = 'oldWorld|p1';
  const p2 = 'oldWorld|p2';
  const tileA = 'oldWorld|p1|0|0';
  const tileB = 'oldWorld|p1|1|0';
  const tileP2 = 'oldWorld|p2|0|1';

  final base = buildPanelTestGame(
    id: kDevelopmentPanelMapTestGameId,
    players: [
      Player(
        id: human,
        displayName: 'England',
        isHuman: true,
        capitalProvinceId: p1,
        capitalTile: const CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'p1',
          x: 0,
          y: 0,
        ),
        stockpile: const Stockpile(quantities: {'lumber': 20, 'castIron': 20}),
        techUnlocked: const {kTechIdCircularSaw: true},
      ),
    ],
    oldWorldProvinces: const [
      Province(
        id: p1,
        regionId: 'oldWorld',
        ownerId: human,
        displayName: 'Avalon',
        townTileKey: tileA,
      ),
      Province(
        id: p2,
        regionId: 'oldWorld',
        ownerId: human,
        displayName: 'Barren',
        townTileKey: tileP2,
      ),
    ],
    oldWorldUnits: [
      Unit(
        id: 'b1',
        type: kUnitTypeBuilder,
        ownerId: human,
        locationProvinceId: p1,
        tileKey: tileA,
        status: UnitStatus.idle,
      ),
      Unit(
        id: 'e1',
        type: kUnitTypeEngineer,
        ownerId: human,
        locationProvinceId: p1,
        tileKey: tileA,
        status: UnitStatus.idle,
      ),
    ],
    tileKeysByRegionAndProvince: {
      'oldWorld': {
        p1: [tileA, tileB],
        p2: [tileP2],
      },
    },
    resourceByTileKey: {
      tileA: 'grain',
      tileB: 'grain',
    },
    playerVisibilityByTile: {
      human: {
        tileA: 'fullyVisible',
        tileB: 'fullyVisible',
        tileP2: 'fullyVisible',
      },
    },
  );

  return base.copyWith(
    worldState: base.worldState.copyWith(
      tileState: const TileMapState(
        improvementByTile: {
          tileA: 0,
          tileB: 0,
        },
      ),
    ),
  );
}

/// Opens an isolated Hive games box for one Development panel test suite.
///
/// [suiteId] must be unique per `*_test.dart` file so parallel `flutter test`
/// shards do not contend on `games.lock` (Refs #4175 Slice E).
Future<Box<dynamic>> openDevelopmentPanelTestHiveBox({
  required String suiteId,
}) async {
  return openAppTestHiveBox(suiteId: 'development_panel_$suiteId');
}

/// Pumps post-frame gates for read-model and map deferral (Slice E).
Future<void> pumpDevelopmentPanelReady(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}
