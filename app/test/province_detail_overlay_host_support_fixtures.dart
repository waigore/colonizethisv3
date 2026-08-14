// Fixtures for province_detail_overlay_host_support_test (Refs #4352).

import 'package:colonizethis_app/core/services/game_service/game_service.dart'
    show GameMapData;
import 'package:colonizethis_app/features/game/flame/caches/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support.dart';
import 'package:colonizethis_data/colonizethis_data.dart'
    show
        MapTopology,
        Resource,
        TileMapResult,
        TopologyNode,
        TopologyNodeType,
        kTechIdMoldboardPlow;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show PlayerView, buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const provinceDetailSupportPlayerId = 'gp1';
const provinceDetailSupportTileKey = 'oldWorld|p1|0|0';
const provinceDetailSupportProvinceId = 'oldWorld|p1';

Game provinceDetailMinimalGame() => Game(
  id: 'g_support',
  worldState: const WorldState(
    turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(provinces: [], units: []),
    newWorld: RegionData(provinces: [], units: []),
  ),
  players: const [
    Player(
      id: provinceDetailSupportPlayerId,
      displayName: 'Human',
      isHuman: true,
      capitalProvinceId: '',
    ),
  ],
  minorNations: const [],
  tribes: const [],
);

RegionMapViewData provinceDetailEmptyRegion() => const RegionMapViewData(
  regionId: 'oldWorld',
  width: 1,
  height: 1,
  cellSize: 16,
  cells: [],
  capitalMarkers: [],
  portMarkers: [],
  factionColors: {},
  greatPowerFactionIds: {},
  terrainColors: {},
  provincePoliticalOwnerByPrefixedProvinceId: {},
);

PlayerView provinceDetailPlayerView(Game game) => buildPlayerView(
  game,
  const MapTopology(nodes: [], edges: []),
  provinceDetailSupportPlayerId,
);

ProvinceDetailShortcutCallbacks provinceDetailCallbacks({
  required Game game,
  required String? selectedTileKey,
  required bool exploreEnabled,
  required bool prospectEnabled,
  required bool buildImprovementEnabled,
  required bool buildRoadEnabled,
  required bool buildFortEnabled,
  required bool buildPortEnabled,
  bool buildRailEnabled = false,
  required bool purchaseLandEnabled,
  bool upgradeTownEnabled = false,
  String? upgradeTownTargetTileKey,
  bool establishConsulateEnabled = false,
  bool establishConsulatePending = false,
  DiplomaticOrder? establishConsulateOrder,
  String establishConsulateTargetName = '',
  String provinceId = provinceDetailSupportProvinceId,
  required AppEventBus bus,
}) => buildProvinceDetailShortcutCallbacks(
  game: game,
  humanPlayerId: provinceDetailSupportPlayerId,
  region: provinceDetailEmptyRegion(),
  playerView: provinceDetailPlayerView(game),
  workTargetSelectionCache: PerPlayerWorkTargetSelectionCache(
    strategies: const {},
  ),
  draftOrders: const Orders(),
  mapData: null,
  selectedTileKey: selectedTileKey,
  exploreEnabled: exploreEnabled,
  prospectEnabled: prospectEnabled,
  buildImprovementEnabled: buildImprovementEnabled,
  buildRoadEnabled: buildRoadEnabled,
  buildFortEnabled: buildFortEnabled,
  buildPortEnabled: buildPortEnabled,
  buildRailEnabled: buildRailEnabled,
  purchaseLandEnabled: purchaseLandEnabled,
  provinceId: provinceId,
  upgradeTownEnabled: upgradeTownEnabled,
  upgradeTownTargetTileKey: upgradeTownTargetTileKey,
  establishConsulateEnabled: establishConsulateEnabled,
  establishConsulatePending: establishConsulatePending,
  establishConsulateOrder: establishConsulateOrder,
  establishConsulateTargetName: establishConsulateTargetName,
  bus: bus,
);

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
