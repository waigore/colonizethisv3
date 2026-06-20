// Golden + widget checks per #1990 testing strategy branch (A): wide side panel uses a
// pixel golden; narrow host asserts the Build improvement shortcut (avoids fragile
// cross-engine / cross-arch golden drift on CI). Hosts use AppThemes.editorialMonocle
// per MAP20001 dark-theme contract (Refs #2865).
// Pipeline contract: SPEC/program/order-suggestions.md § Province Tile `Build improvement`
// shortcut enablement.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/features/game/flame/game_map_narrow_detail_overlay.dart';
import 'package:colonizethis_app/features/game/flame/game_map_province_detail_side_panel.dart';
import 'package:colonizethis_app/features/game/flame/per_player_work_target_selection_cache.dart';
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
    TopologyEdge(id1: 'oldWorld|p1', id2: 'oldWorld|s1'),
    TopologyEdge(id1: 'newWorld|p1', id2: 'newWorld|s1'),
  ],
);

/// Map topology + tile maps aligned with [goldenBuildImprovementGame] (Refs #1990 goldens).
class _GameServiceBuildImprovementGolden extends GameService {
  _GameServiceBuildImprovementGolden(super.box, super.adapter);

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
    'newWorld': TileMapResult(
      width: 2,
      height: 2,
      grid: const [
        ['p1', 's1'],
        ['s1', 's1'],
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
    if (gameId != 'g_bi_golden') return null;
    return (
      combinedTopology: _goldenCombinedTopology,
      tileMapByRegion: _tileMapByRegion,
      topologyByRegion: _topologyByRegion,
      warpLinks: null,
    );
  }
}

Game goldenBuildImprovementGame() {
  const humanPlayerId = 'gp1';
  const provinceId = 'oldWorld|p1';
  const tileKey = 'oldWorld|p1|0|0';
  return Game(
    id: 'g_bi_golden',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: provinceId,
            regionId: 'oldWorld',
            ownerId: humanPlayerId,
          ),
        ],
        units: [
          Unit(
            id: 'u_builder',
            type: kUnitTypeBuilder,
            ownerId: humanPlayerId,
            locationProvinceId: provinceId,
            tileKey: tileKey,
            status: UnitStatus.idle,
          ),
        ],
      ),
      newWorld: const RegionData(provinces: [], units: []),
      resourceByTileKey: const {tileKey: 'grain'},
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          provinceId: [tileKey],
        },
      },
      tileState: TileMapState(improvementByTile: {tileKey: 0}),
      playerVisibilityByTile: {
        humanPlayerId: {tileKey: 'fullyVisible'},
      },
    ),
    players: [
      Player(
        id: humanPlayerId,
        displayName: 'Human',
        isHuman: true,
        capitalProvinceId: provinceId,
        stockpile: const Stockpile(quantities: {'lumber': 10, 'castIron': 10}),
        techUnlocked: const {kTechIdCircularSaw: true},
      ),
    ],
    minorNations: const [],
    tribes: const [],
  );
}

RegionMapViewData goldenBuildImprovementRegion() {
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
        ownerFactionId: 'gp1',
        provinceDisplayName: 'Golden Province',
        visibility: TileVisibility.visible,
      ),
    ],
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: {'gp1'},
    terrainColors: const {},
    provincePoliticalOwnerByPrefixedProvinceId: const {'oldWorld|p1': 'gp1'},
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
      tileMapByRegion: _GameServiceBuildImprovementGolden._tileMapByRegion,
    ),
  );
  return cache;
}

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_province_bi_golden');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  Future<void> pumpWideHost(WidgetTester tester) async {
    final game = goldenBuildImprovementGame();
    final region = goldenBuildImprovementRegion();
    final playerId = game.players.first.id;
    final playerView = buildPlayerView(game, _goldenCombinedTopology, playerId);
    const tileKey = 'oldWorld|p1|0|0';

    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(360, 720));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gamesBoxProvider.overrideWith((ref) => gamesBox),
          gameServiceProvider.overrideWith(
            (ref) =>
                _GameServiceBuildImprovementGolden(gamesBox, GameSaveAdapter()),
          ),
          appEventBusProvider.overrideWith((ref) => AppEventBus.create()),
          currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
          currentOrdersProvider.overrideWith(
            () => CurrentOrdersNotifier(const Orders()),
          ),
        ],
        child: MaterialApp(
          theme: AppThemes.editorialMonocle,
          home: Scaffold(
            body: Center(
              child: RepaintBoundary(
                key: const ValueKey('province_bi_shortcut_wide_golden'),
                child: SizedBox(
                  width: 320,
                  child: GameMapProvinceDetailSidePanel(
                    game: game,
                    region: region,
                    humanPlayerId: playerId,
                    playerView: playerView,
                    workTargetSelectionCache: PerPlayerWorkTargetSelectionCache(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final ctx = tester.element(find.byType(GameMapProvinceDetailSidePanel));
    final container = ProviderScope.containerOf(ctx);
    container
        .read(mapProvincePanelProvider.notifier)
        .reportMapTileTapped(tileKey);
    await tester.pumpAndSettle();
  }

  Future<void> pumpNarrowHost(WidgetTester tester) async {
    final game = goldenBuildImprovementGame();
    final region = goldenBuildImprovementRegion();
    final playerId = game.players.first.id;
    final playerView = buildPlayerView(game, _goldenCombinedTopology, playerId);
    final workTargetSelectionCache = _buildSelectionCache(
      game: game,
      playerId: playerId,
      playerView: playerView,
    );
    const tileKey = 'oldWorld|p1|0|0';

    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(400, 600));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gamesBoxProvider.overrideWith((ref) => gamesBox),
          gameServiceProvider.overrideWith(
            (ref) =>
                _GameServiceBuildImprovementGolden(gamesBox, GameSaveAdapter()),
          ),
          appEventBusProvider.overrideWith((ref) => AppEventBus.create()),
          currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
          currentOrdersProvider.overrideWith(
            () => CurrentOrdersNotifier(const Orders()),
          ),
        ],
        child: MaterialApp(
          theme: AppThemes.editorialMonocle,
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: RepaintBoundary(
                key: const ValueKey('province_bi_shortcut_narrow_golden'),
                child: GameMapNarrowDetailOverlaySlot(
                  game: game,
                  region: region,
                  humanPlayerId: playerId,
                  playerView: playerView,
                  workTargetSelectionCache: workTargetSelectionCache,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final ctx = tester.element(find.byType(GameMapNarrowDetailOverlaySlot));
    final container = ProviderScope.containerOf(ctx);
    container
        .read(mapProvincePanelProvider.notifier)
        .reportMapTileTapped(tileKey);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'golden: wide province side panel shows enabled Build improvement shortcut (Refs #1990)',
    (WidgetTester tester) async {
      await pumpWideHost(tester);
      await expectLater(
        find.byKey(const ValueKey('province_bi_shortcut_wide_golden')),
        matchesGoldenFile('goldens/province_build_improvement_wide_panel.png'),
      );
    },
  );

  testWidgets(
    'narrow detail overlay shows enabled Build improvement shortcut (Refs #1990)',
    (WidgetTester tester) async {
      await pumpNarrowHost(tester);
      final buildImprovementShortcut = find.byWidgetPredicate(
        (Widget w) =>
            w is CtIconAction &&
            w.onPressed != null &&
            w.icon == Icons.handyman,
      );
      expect(buildImprovementShortcut, findsOneWidget);
    },
  );
}
