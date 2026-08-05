// Golden + widget checks for MAP20001 Build road Engineer shortcut (Refs #4260).
// Wide side panel uses a pixel golden; narrow host asserts the enabled shortcut
// (avoids fragile cross-engine golden drift on CI). Hosts use AppThemes.editorialMonocle
// per MAP20001 dark-theme contract.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/game/flame/overlays/game_map_narrow_detail_overlay.dart';
import 'package:colonizethis_app/features/game/flame/overlays/game_map_province_detail_side_panel.dart';
import 'package:colonizethis_app/features/game/flame/caches/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_province_panel_provider.dart';
import 'package:colonizethis_app/widgets/ct_icon_action.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show PlayerView, buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'golden_capture_harness.dart';

const String _kGameId = 'g_br_golden';
const String _kHumanPlayerId = 'gp1';
const String _kProvinceId = 'oldWorld|p1';
const String _kTileKey = 'oldWorld|p1|0|0';

final MapTopology _goldenCombinedTopology = MapTopology(
  nodes: const [
    TopologyNode(
      id: 'oldWorld|p1',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'oldWorld|s1',
      regionId: 'oldWorld',
      type: TopologyNodeType.seaZone,
    ),
  ],
  edges: const [TopologyEdge(id1: 'oldWorld|p1', id2: 'oldWorld|s1')],
);

class _GameServiceBuildRoadGolden extends GameService {
  _GameServiceBuildRoadGolden(super.box, super.adapter);

  static final Map<String, MapTopology> _topologyByRegion = {
    'oldWorld': MapTopology(
      nodes: const [
        TopologyNode(
          id: 'p1',
          regionId: 'oldWorld',
          type: TopologyNodeType.province,
        ),
        TopologyNode(
          id: 's1',
          regionId: 'oldWorld',
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
        ['p1', 's1'],
        ['s1', 's1'],
      ],
      terrainGrid: const [
        [TerrainType.plains, TerrainType.plains],
        [TerrainType.plains, TerrainType.plains],
      ],
      resourceGrid: [
        [Resource.grain, Resource.meat],
        [Resource.meat, Resource.meat],
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
    if (gameId != _kGameId) return null;
    return (
      combinedTopology: _goldenCombinedTopology,
      tileMapByRegion: _tileMapByRegion,
      topologyByRegion: _topologyByRegion,
      warpLinks: null,
    );
  }
}

Game goldenBuildRoadGame() {
  return Game(
    id: _kGameId,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: _kProvinceId,
            regionId: 'oldWorld',
            ownerId: _kHumanPlayerId,
          ),
        ],
        units: [
          Unit(
            id: 'u_engineer',
            type: kUnitTypeEngineer,
            ownerId: _kHumanPlayerId,
            locationProvinceId: _kProvinceId,
            tileKey: _kTileKey,
            status: UnitStatus.idle,
          ),
        ],
      ),
      newWorld: const RegionData(provinces: [], units: []),
      resourceByTileKey: const {_kTileKey: 'grain'},
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          _kProvinceId: [_kTileKey],
        },
      },
      tileState: TileMapState(),
      playerVisibilityByTile: {
        _kHumanPlayerId: {_kTileKey: 'fullyVisible'},
      },
    ),
    players: [
      Player(
        id: _kHumanPlayerId,
        displayName: 'Human',
        isHuman: true,
        capitalProvinceId: _kProvinceId,
        stockpile: const Stockpile(quantities: {'lumber': 10, 'castIron': 10}),
      ),
    ],
    minorNations: const [],
    tribes: const [],
  );
}

RegionMapViewData goldenBuildRoadRegion() {
  return RegionMapViewData(
    regionId: 'oldWorld',
    width: 1,
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
        ownerFactionId: _kHumanPlayerId,
        provinceDisplayName: 'Golden Province',
        visibility: TileVisibility.visible,
      ),
    ],
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: {_kHumanPlayerId},
    terrainColors: const {},
    provincePoliticalOwnerByPrefixedProvinceId: const {
      'oldWorld|p1': _kHumanPlayerId,
    },
  );
}

PerPlayerWorkTargetSelectionCache _buildSelectionCache({
  required Game game,
  required String playerId,
  required PlayerView playerView,
}) {
  final cache = PerPlayerWorkTargetSelectionCache();
  cache.refresh(
    WorkTargetSelectionSnapshot(
      game: game,
      playerId: playerId,
      playerView: playerView,
      topology: _goldenCombinedTopology,
      currentOrders: const Orders(),
      tileMapByRegion: _GameServiceBuildRoadGolden._tileMapByRegion,
    ),
  );
  return cache;
}

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_province_br_golden');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  Future<void> pumpWideHost(WidgetTester tester) async {
    final game = goldenBuildRoadGame();
    final region = goldenBuildRoadRegion();
    final playerId = game.players.first.id;
    final playerView = buildPlayerView(game, _goldenCombinedTopology, playerId);
    final workTargetSelectionCache = _buildSelectionCache(
      game: game,
      playerId: playerId,
      playerView: playerView,
    );
    const boundaryKey = ValueKey('province_br_shortcut_wide_golden');

    await configureGoldenSurface(tester, size: const Size(360, 720));
    await tester.pumpWidget(
      wrapGoldenBoundary(
        boundaryKey: boundaryKey,
        wrapInProviderScope: true,
        overrides: [
          gamesBoxProvider.overrideWith((ref) => gamesBox),
          gameServiceProvider.overrideWith(
            (ref) =>
                _GameServiceBuildRoadGolden(gamesBox, GameSaveAdapter()),
          ),
          appEventBusProvider.overrideWith((ref) => AppEventBus.create()),
          currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
          currentOrdersProvider.overrideWith(
            () => CurrentOrdersNotifier(const Orders()),
          ),
        ],
        child: SizedBox(
          width: 320,
          child: GameMapProvinceDetailSidePanel(
            game: game,
            region: region,
            humanPlayerId: playerId,
            playerView: playerView,
            workTargetSelectionCache: workTargetSelectionCache,
          ),
        ),
      ),
    );
    final ctx = tester.element(find.byType(GameMapProvinceDetailSidePanel));
    final container = ProviderScope.containerOf(ctx);
    container
        .read(mapProvincePanelProvider.notifier)
        .reportMapTileTapped(_kTileKey);
    await pumpForGolden(tester);
  }

  Future<void> pumpNarrowHost(WidgetTester tester) async {
    final game = goldenBuildRoadGame();
    final region = goldenBuildRoadRegion();
    final playerId = game.players.first.id;
    final playerView = buildPlayerView(game, _goldenCombinedTopology, playerId);
    final workTargetSelectionCache = _buildSelectionCache(
      game: game,
      playerId: playerId,
      playerView: playerView,
    );
    const boundaryKey = ValueKey('province_br_shortcut_narrow_golden');

    await configureGoldenSurface(tester, size: const Size(400, 600));
    await tester.pumpWidget(
      wrapGoldenBoundary(
        boundaryKey: boundaryKey,
        center: false,
        alignment: Alignment.bottomCenter,
        wrapInProviderScope: true,
        overrides: [
          gamesBoxProvider.overrideWith((ref) => gamesBox),
          gameServiceProvider.overrideWith(
            (ref) =>
                _GameServiceBuildRoadGolden(gamesBox, GameSaveAdapter()),
          ),
          appEventBusProvider.overrideWith((ref) => AppEventBus.create()),
          currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
          currentOrdersProvider.overrideWith(
            () => CurrentOrdersNotifier(const Orders()),
          ),
        ],
        child: GameMapNarrowDetailOverlaySlot(
          game: game,
          region: region,
          humanPlayerId: playerId,
          playerView: playerView,
          workTargetSelectionCache: workTargetSelectionCache,
        ),
      ),
    );
    final ctx = tester.element(find.byType(GameMapNarrowDetailOverlaySlot));
    final container = ProviderScope.containerOf(ctx);
    container
        .read(mapProvincePanelProvider.notifier)
        .reportMapTileTapped(_kTileKey);
    await pumpForGolden(tester);
  }

  testWidgets(
    'golden: wide province side panel shows enabled Build road shortcut (Refs #4260)',
    (WidgetTester tester) async {
      await pumpWideHost(tester);
      await expectLater(
        find.byKey(const ValueKey('province_br_shortcut_wide_golden')),
        matchesGoldenFile('goldens/province_build_road_wide_panel.png'),
      );
    },
  );

  testWidgets(
    'narrow detail overlay shows enabled Build road shortcut (Refs #4260)',
    (WidgetTester tester) async {
      await pumpNarrowHost(tester);
      final buildRoadShortcut = find.byWidgetPredicate(
        (Widget w) =>
            w is CtIconAction &&
            w.onPressed != null &&
            w.icon == Icons.add_road,
      );
      expect(buildRoadShortcut, findsOneWidget);
    },
  );
}
