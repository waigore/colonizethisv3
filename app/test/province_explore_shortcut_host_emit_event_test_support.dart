import 'package:colonizethis_app/features/game/flame/caches/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_app/widgets/ct_icon_action.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show buildPlayerView, kWorkTargetExplore;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'province_shortcut_host_emit_test_support.dart';

export 'package:colonizethis_app/features/game/flame/caches/per_player_work_target_selection_cache.dart';
export 'package:colonizethis_app/widgets/ct_icon_action.dart';
export 'package:colonizethis_logic/colonizethis_logic.dart' show buildPlayerView;
export 'package:colonizethis_models/colonizethis_models.dart';
export 'package:flutter/material.dart';
export 'package:hive/hive.dart';
export 'province_shortcut_host_emit_test_support.dart';

const String kExploreShortcutGameId = 'g_explore_shortcut_emit';
const String kExploreShortcutHumanPlayerId = 'gp1';
const String kExploreShortcutProvinceId = 'oldWorld|p1';
const String kExploreShortcutTileKey = 'oldWorld|p1|0|0';
const String kExploreShortcutTargetTileKey = 'oldWorld|p1|1|0';

final MapTopology exploreShortcutCombinedTopology = provinceShortcutHostCombinedTopology();
final Map<String, MapTopology> exploreShortcutTopologyByRegion =
    provinceShortcutHostTopologyByRegion();

final Map<String, TileMapResult> exploreShortcutTileMapByRegion =
    provinceShortcutHostTileMapByRegion(
      width: 2,
      height: 1,
      grid: const [
        ['p1', 'p1'],
      ],
      terrainGrid: const [
        [TerrainType.plains, TerrainType.plains],
      ],
      resourceGrid: const [
        [Resource.grain, Resource.grain],
      ],
    );

/// Cache that can simulate click-time drift by clearing explore targets on the
/// next [get] after [armExploreDriftOnNextRead].
class ExploreDriftWorkTargetCache extends PerPlayerWorkTargetSelectionCache {
  ExploreDriftWorkTargetCache()
    : super(
        strategies: <String, WorkTargetSelectionPopulationStrategy>{
          kWorkTargetExplore: (_) => const <String>{
            kExploreShortcutTileKey,
            kExploreShortcutTargetTileKey,
          },
        },
      );

  bool _armDrift = false;

  void armExploreDriftOnNextRead() => _armDrift = true;

  @override
  Set<String> get(String playerId, String workTarget) {
    if (_armDrift && workTarget == kWorkTargetExplore) {
      _armDrift = false;
      return const <String>{};
    }
    return super.get(playerId, workTarget);
  }
}

Game buildExploreShortcutGame({required bool withExplorer}) {
  return Game(
    id: kExploreShortcutGameId,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: kExploreShortcutProvinceId,
            regionId: 'oldWorld',
            ownerId: kExploreShortcutHumanPlayerId,
          ),
        ],
        units: [
          if (withExplorer)
            Unit(
              id: 'u_explorer',
              type: kUnitTypeExplorer,
              ownerId: kExploreShortcutHumanPlayerId,
              locationProvinceId: kExploreShortcutProvinceId,
              tileKey: kExploreShortcutTileKey,
              status: UnitStatus.idle,
            ),
        ],
      ),
      newWorld: const RegionData(provinces: [], units: []),
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          kExploreShortcutProvinceId: [kExploreShortcutTileKey, kExploreShortcutTargetTileKey],
        },
      },
      playerVisibilityByTile: {
        kExploreShortcutHumanPlayerId: {
          kExploreShortcutTileKey: 'fullyVisible',
          kExploreShortcutTargetTileKey: 'unknown',
        },
      },
    ),
    players: [
      Player(
        id: kExploreShortcutHumanPlayerId,
        displayName: 'Human',
        isHuman: true,
        capitalProvinceId: kExploreShortcutProvinceId,
      ),
    ],
    minorNations: const [],
    tribes: const [],
  );
}

/// Partially revealed province: one fogged tile and one unrevealed tile in p1.
RegionMapViewData exploreShortcutPartiallyRevealedRegion() {
  return RegionMapViewData(
    regionId: 'oldWorld',
    width: 2,
    height: 1,
    cellSize: 16,
    cells: const [
      CellViewData(
        x: 0,
        y: 0,
        regionCellId: 'p1',
        isSea: false,
        terrainType: TerrainType.plains,
        resourceId: 'grain',
        ownerFactionId: kExploreShortcutHumanPlayerId,
        provinceDisplayName: 'Test Province',
        visibility: TileVisibility.fogged,
      ),
      CellViewData(
        x: 1,
        y: 0,
        regionCellId: 'p1',
        isSea: false,
        terrainType: TerrainType.plains,
        resourceId: 'grain',
        ownerFactionId: kExploreShortcutHumanPlayerId,
        provinceDisplayName: 'Test Province',
        visibility: TileVisibility.unrevealed,
      ),
    ],
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: {kExploreShortcutHumanPlayerId},
    terrainColors: const {},
    provincePoliticalOwnerByPrefixedProvinceId: const {
      'oldWorld|p1': kExploreShortcutHumanPlayerId,
    },
  );
}

PerPlayerWorkTargetSelectionCache exploreShortcutCache() {
  final game = buildExploreShortcutGame(withExplorer: true);
  return PerPlayerWorkTargetSelectionCache(
    strategies: <String, WorkTargetSelectionPopulationStrategy>{
      kWorkTargetExplore: (_) => const <String>{
        kExploreShortcutTileKey,
        kExploreShortcutTargetTileKey,
      },
    },
  )..refresh(
    WorkTargetSelectionSnapshot(
      game: game,
      playerId: kExploreShortcutHumanPlayerId,
      playerView: buildPlayerView(game, exploreShortcutCombinedTopology, kExploreShortcutHumanPlayerId),
      topology: exploreShortcutCombinedTopology,
      currentOrders: const Orders(),
      tileMapByRegion: exploreShortcutTileMapByRegion,
    ),
  );
}

Finder exploreShortcutAction({required bool enabled}) {
  return find.byWidgetPredicate(
    (Widget w) =>
        w is CtIconAction &&
        w.icon == Icons.explore &&
        (enabled ? w.onPressed != null : true),
  );
}
