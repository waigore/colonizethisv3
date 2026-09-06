// Fixtures for province_detail_overlay_host_support_test (Refs #4352).
// Extraction-preview games: province_detail_overlay_host_support_games.dart.

import 'package:colonizethis_app/features/game/flame/caches/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show PlayerView, buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

export 'province_detail_overlay_host_support_games.dart';

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
  bool isSeaZone = false,
  bool offerPeaceEnabled = false,
  bool offerPeacePending = false,
  DiplomaticOrder? offerPeaceOrder,
  String offerPeaceTargetName = '',
  String provinceId = provinceDetailSupportProvinceId,
  MapTopology? combinedTopology,
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
  mapData: combinedTopology == null
      ? null
      : (
          combinedTopology: combinedTopology,
          tileMapByRegion: const {},
          topologyByRegion: const {},
          warpLinks: null,
        ),
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
  isSeaZone: isSeaZone,
  offerPeaceEnabled: offerPeaceEnabled,
  offerPeacePending: offerPeacePending,
  offerPeaceOrder: offerPeaceOrder,
  offerPeaceTargetName: offerPeaceTargetName,
  bus: bus,
);
