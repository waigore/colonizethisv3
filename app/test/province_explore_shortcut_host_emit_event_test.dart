// Pins the host-level Explore-with-explorer *shortcut-assignment* tap flow for the
// wide province side panel (`GameMapProvinceDetailSidePanel`).
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Tile inline actions:
//   - "Given the user taps an enabled `Explore with explorer` and click-time
//      state remains valid, when the explorer shortcut assign is triggered,
//      then the system commits a pending `WorkOrder(target: explore,
//      targetTileKey: <exact selected tile key>)` and The UI layer does not
//      enter generic work-target selection mode."
//   - "Given the user taps `Explore with explorer` and click-time state drift
//      has invalidated assignment, when the tap fires, then The UI layer
//      performs a silent no-op and the system commits no pending work order."
//
// Coverage gap closed here (Refs #2865):
//   - `province_overlay_tile_inline_action_non_clickable_test.dart` pins the
//     *overlay-level* callback contract (enabled fires / disabled does not).
//   - Neither asserts the *host wiring*: that tapping the enabled inline action
//     emits `OpenCivilianUnitsPanelEvent(explorerOnly: true,
//     exploreShortcutTargetTileKey: <exact tile key>)` on the app event bus.
//   - This file pins the positive path, the no-explorer negative, and the
//     click-time revalidation drift silent no-op.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
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
    show PlayerView, buildPlayerView, kWorkTargetExplore;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

const String _kGameId = 'g_explore_shortcut_emit';
const String _kHumanPlayerId = 'gp1';
const String _kProvinceId = 'oldWorld|p1';
const String _kTileKey = 'oldWorld|p1|0|0';
const String _kExploreTargetTileKey = 'oldWorld|p1|1|0';

final MapTopology _combinedTopology = MapTopology(
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

final Map<String, MapTopology> _topologyByRegion = {
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

final Map<String, TileMapResult> _tileMapByRegion = {
  'oldWorld': TileMapResult(
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
  ),
};

/// Cache that can simulate click-time drift by clearing explore targets on the
/// next [get] after [armExploreDriftOnNextRead].
class _ExploreDriftWorkTargetCache extends PerPlayerWorkTargetSelectionCache {
  _ExploreDriftWorkTargetCache()
      : super(
          strategies: <String, WorkTargetSelectionPopulationStrategy>{
            kWorkTargetExplore: (_) => const <String>{
              _kTileKey,
              _kExploreTargetTileKey,
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

class _GameServiceExploreShortcut extends GameService {
  _GameServiceExploreShortcut(super.box, super.adapter);

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
      combinedTopology: _combinedTopology,
      tileMapByRegion: _tileMapByRegion,
      topologyByRegion: _topologyByRegion,
      warpLinks: null,
    );
  }
}

Game _buildGame({required bool withExplorer}) {
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
          if (withExplorer)
            Unit(
              id: 'u_explorer',
              type: kUnitTypeExplorer,
              ownerId: _kHumanPlayerId,
              locationProvinceId: _kProvinceId,
              tileKey: _kTileKey,
              status: UnitStatus.idle,
            ),
        ],
      ),
      newWorld: const RegionData(provinces: [], units: []),
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          _kProvinceId: [_kTileKey, _kExploreTargetTileKey],
        },
      },
      playerVisibilityByTile: {
        _kHumanPlayerId: {
          _kTileKey: 'fullyVisible',
          _kExploreTargetTileKey: 'unknown',
        },
      },
    ),
    players: [
      Player(
        id: _kHumanPlayerId,
        displayName: 'Human',
        isHuman: true,
        capitalProvinceId: _kProvinceId,
      ),
    ],
    minorNations: const [],
    tribes: const [],
  );
}

/// Partially revealed province: one fogged tile and one unrevealed tile in p1.
RegionMapViewData _partiallyRevealedRegion() {
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
        ownerFactionId: _kHumanPlayerId,
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
        ownerFactionId: _kHumanPlayerId,
        provinceDisplayName: 'Test Province',
        visibility: TileVisibility.unrevealed,
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

PerPlayerWorkTargetSelectionCache _exploreCache() {
  return PerPlayerWorkTargetSelectionCache(
    strategies: <String, WorkTargetSelectionPopulationStrategy>{
      kWorkTargetExplore: (_) => const <String>{
        _kTileKey,
        _kExploreTargetTileKey,
      },
    },
  )..refresh(
      WorkTargetSelectionSnapshot(
        game: _buildGame(withExplorer: true),
        playerId: _kHumanPlayerId,
        playerView: buildPlayerView(
          _buildGame(withExplorer: true),
          _combinedTopology,
          _kHumanPlayerId,
        ),
        topology: _combinedTopology,
        currentOrders: const Orders(),
        tileMapByRegion: _tileMapByRegion,
      ),
    );
}

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_province_explore_shortcut_emit');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  Future<List<OpenCivilianUnitsPanelEvent>> pumpHostAndSelect(
    WidgetTester tester, {
    required Game game,
    required PerPlayerWorkTargetSelectionCache workTargetSelectionCache,
  }) async {
    final region = _partiallyRevealedRegion();
    final playerView = buildPlayerView(game, _combinedTopology, _kHumanPlayerId);
    final bus = AppEventBus.create();
    addTearDown(bus.dispose);

    final opened = <OpenCivilianUnitsPanelEvent>[];
    final sub = bus.on<OpenCivilianUnitsPanelEvent>().listen(opened.add);
    addTearDown(sub.cancel);

    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(360, 720));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gamesBoxProvider.overrideWith((ref) => gamesBox),
          gameServiceProvider.overrideWith(
            (ref) => _GameServiceExploreShortcut(gamesBox, GameSaveAdapter()),
          ),
          appEventBusProvider.overrideWith((ref) => bus),
          currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
          currentOrdersProvider.overrideWith(
            () => CurrentOrdersNotifier(const Orders()),
          ),
        ],
        child: MaterialApp(
          theme: AppThemes.editorialMonocle,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: GameMapProvinceDetailSidePanel(
                  game: game,
                  region: region,
                  humanPlayerId: _kHumanPlayerId,
                  playerView: playerView,
                  workTargetSelectionCache: workTargetSelectionCache,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final ctx = tester.element(find.byType(GameMapProvinceDetailSidePanel));
    ProviderScope.containerOf(ctx)
        .read(mapProvincePanelProvider.notifier)
        .reportMapTileTapped(_kTileKey);
    await tester.pumpAndSettle();
    return opened;
  }

  testWidgets(
    'tapping the enabled Explore shortcut emits an explorer-only '
    'OpenCivilianUnitsPanelEvent targeting the exact selected tile key '
    '(SPEC § Tile inline actions — Explore shortcut assignment)',
    (WidgetTester tester) async {
      final game = _buildGame(withExplorer: true);
      final opened = await pumpHostAndSelect(
        tester,
        game: game,
        workTargetSelectionCache: _exploreCache(),
      );

      final shortcut = find.byWidgetPredicate(
        (Widget w) =>
            w is CtIconAction &&
            w.icon == Icons.explore &&
            w.onPressed != null,
      );
      expect(
        shortcut,
        findsOneWidget,
        reason:
            'The wide side panel must render an enabled Explore inline action '
            'for a partially revealed province with an explorer and a cached '
            'explore-eligible target.',
      );

      await tester.ensureVisible(shortcut);
      await tester.tap(shortcut);
      await tester.pump();

      expect(opened, hasLength(1));
      final event = opened.single;
      expect(event.explorerOnly, isTrue);
      expect(event.builderOnly, isFalse);
      expect(event.exploreShortcutTargetTileKey, _kTileKey);
      expect(event.buildImprovementShortcutTargetTileKey, isNull);
      expect(event.prospectShortcutTargetTileKey, isNull);
    },
  );

  testWidgets(
    'negative — with no Explorer unit the Explore shortcut is not enabled '
    'and tapping emits no OpenCivilianUnitsPanelEvent',
    (WidgetTester tester) async {
      final opened = await pumpHostAndSelect(
        tester,
        game: _buildGame(withExplorer: false),
        workTargetSelectionCache: _exploreCache(),
      );

      final enabledShortcut = find.byWidgetPredicate(
        (Widget w) =>
            w is CtIconAction &&
            w.icon == Icons.explore &&
            w.onPressed != null,
      );
      expect(enabledShortcut, findsNothing);

      final anyShortcut = find.byWidgetPredicate(
        (Widget w) => w is CtIconAction && w.icon == Icons.explore,
      );
      if (anyShortcut.evaluate().isNotEmpty) {
        await tester.tap(anyShortcut.first, warnIfMissed: false);
        await tester.pump();
      }

      expect(opened, isEmpty);
    },
  );

  testWidgets(
    'negative — click-time drift invalidates explore assignment and the tap '
    'is a silent no-op on the event bus (SPEC § Tile inline actions)',
    (WidgetTester tester) async {
      final game = _buildGame(withExplorer: true);
      final driftCache = _ExploreDriftWorkTargetCache()
        ..refresh(
          WorkTargetSelectionSnapshot(
            game: game,
            playerId: _kHumanPlayerId,
            playerView: buildPlayerView(game, _combinedTopology, _kHumanPlayerId),
            topology: _combinedTopology,
            currentOrders: const Orders(),
            tileMapByRegion: _tileMapByRegion,
          ),
        );

      final opened = await pumpHostAndSelect(
        tester,
        game: game,
        workTargetSelectionCache: driftCache,
      );

      final shortcut = find.byWidgetPredicate(
        (Widget w) =>
            w is CtIconAction &&
            w.icon == Icons.explore &&
            w.onPressed != null,
      );
      expect(shortcut, findsOneWidget);

      driftCache.armExploreDriftOnNextRead();

      await tester.ensureVisible(shortcut);
      await tester.tap(shortcut);
      await tester.pump();

      expect(
        opened,
        isEmpty,
        reason:
            'When click-time revalidation finds explore no longer enabled, '
            'the host must not emit OpenCivilianUnitsPanelEvent.',
      );
    },
  );
}
