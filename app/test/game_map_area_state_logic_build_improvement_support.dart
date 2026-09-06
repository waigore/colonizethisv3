import 'package:colonizethis_app/features/game/flame/map_state/map_state.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show PlayerView, VisibilityLevel;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter_test/flutter_test.dart';

import 'game_map_area_state_logic_test_support.dart';

const buildImprovementHumanPlayerId = 'gp1';
const buildImprovementSelectedTileKey = 'oldWorld|p1|0|0';
const buildImprovementSelectedProvinceId = 'oldWorld|p1';

const buildImprovementTopology = MapTopology(
  nodes: [
    TopologyNode(
      id: 'p1',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
  ],
  edges: [],
);

final buildImprovementTileMapByRegion = <String, TileMapResult>{
  'oldWorld': TileMapResult(
    width: 1,
    height: 1,
    grid: const [
      ['p1'],
    ],
    terrainGrid: const [
      [TerrainType.plains],
    ],
    resourceGrid: const [
      [Resource.grain],
    ],
  ),
};

PlayerView buildImprovementPlayerView() => PlayerView(
  playerId: buildImprovementHumanPlayerId,
  player: const ct_models.Player(
    id: buildImprovementHumanPlayerId,
    displayName: 'Human',
    isHuman: true,
  ),
  ownUnitsById: {},
  provincesById: {},
  visibilityByTile: const {
    buildImprovementSelectedTileKey: VisibilityLevel.fullyVisible,
  },
  prospectedTiles: {},
  diplomacyByOtherId: {},
);

ct_models.Game buildImprovementTestGame({
  bool includeBuilder = true,
  bool includeResource = true,
  Map<String, bool>? techUnlocked,
  String? ownerId,
  Map<String, int>? stockpileQuantities,
  bool circularSaw = false,
}) {
  final stockpile = ct_models.Stockpile(
    quantities: stockpileQuantities ?? const {'lumber': 999, 'castIron': 999},
  );
  return ct_models.Game(
    id: 'g',
    worldState: ct_models.WorldState(
      turnState: const ct_models.TurnState(
        phase: ct_models.TurnPhase.orders,
        turnNumber: 1,
      ),
      oldWorld: ct_models.RegionData(
        provinces: [
          ct_models.Province(
            id: buildImprovementSelectedProvinceId,
            regionId: 'oldWorld',
            ownerId: ownerId,
          ),
        ],
        units: includeBuilder
            ? [
                ct_models.Unit(
                  id: 'u_builder',
                  type: ct_models.kUnitTypeBuilder,
                  ownerId: buildImprovementHumanPlayerId,
                  locationProvinceId: buildImprovementSelectedProvinceId,
                  tileKey: buildImprovementSelectedTileKey,
                  status: ct_models.UnitStatus.idle,
                ),
              ]
            : const [],
      ),
      newWorld: const ct_models.RegionData(provinces: [], units: []),
      resourceByTileKey: includeResource
          ? const {buildImprovementSelectedTileKey: 'grain'}
          : const {},
      tileKeysByRegionAndProvince: ownerId == null
          ? const {}
          : {
              'oldWorld': {
                buildImprovementSelectedProvinceId: [
                  buildImprovementSelectedTileKey,
                ],
              },
            },
      tileState: ownerId == null
          ? const ct_models.TileMapState()
          : ct_models.TileMapState(
              improvementByTile: {buildImprovementSelectedTileKey: 0},
            ),
      playerVisibilityByTile: ownerId == null
          ? const {}
          : {
              buildImprovementHumanPlayerId: {
                buildImprovementSelectedTileKey: 'fullyVisible',
              },
            },
    ),
    players: [
      ct_models.Player(
        id: buildImprovementHumanPlayerId,
        displayName: 'Human',
        isHuman: true,
        capitalProvinceId: ownerId == null ? null : buildImprovementSelectedProvinceId,
        stockpile: stockpile,
        techUnlocked: circularSaw
            ? const {kTechIdCircularSaw: true}
            : techUnlocked,
      ),
    ],
    minorNations: const [],
    tribes: const [],
  );
}

({bool showIcon, bool enabled, bool hasMatchingUnits})
buildImprovementActionState({
  required ct_models.Game game,
  MapTopology? topology,
  PlayerView? playerView,
}) {
  return GameMapAreaStateLogicProvinceActions.provinceBuildImprovementActionState(
    game: game,
    humanPlayerId: buildImprovementHumanPlayerId,
    selectedTileKey: buildImprovementSelectedTileKey,
    playerView: playerView ?? buildImprovementPlayerView(),
    topology: topology,
    currentOrders: const ct_models.Orders(),
    tileMapByRegion: buildImprovementTileMapByRegion,
  );
}

void expectBuildImprovementMatchesPipeline({
  required ct_models.Game game,
  required MapTopology? topologyArg,
  required PlayerView view,
  required bool expectEnabled,
}) {
  final expected = expectedBuildImprovementEnabledFromPipeline(
    game: game,
    humanPlayerId: buildImprovementHumanPlayerId,
    selectedTileKey: buildImprovementSelectedTileKey,
    playerView: view,
    topology: topologyArg,
    currentOrders: const ct_models.Orders(),
    tileMapByRegion: buildImprovementTileMapByRegion,
  );
  final state = buildImprovementActionState(
    game: game,
    topology: topologyArg,
    playerView: view,
  );
  expect(state.enabled, expected);
  expect(expected, expectEnabled);
}
