// Pins the host-level Build improvement *shortcut-assignment* tap flow for the
// wide province side panel (`GameMapProvinceDetailSidePanel`).
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Tile inline actions:
//   - "Given the user taps an enabled `Build improvement` and click-time state
//      remains valid, when the Civilian Units panel opens, then The UI layer
//      opens it in Builder-only shortcut mode targeting the exact selected tile
//      key for direct `WorkOrder(target: build_improvement,
//      targetTileKey: <exact selected tile key>)`."
//
// Coverage gap closed here (Refs #2865):
//   - `province_overlay_tile_inline_action_non_clickable_test.dart` pins the
//     *overlay-level* callback contract (enabled fires / disabled does not).
//   - `province_build_improvement_shortcut_host_goldens_test.dart` pins that the
//     host *renders* the enabled shortcut.
//   - Neither asserts the *host wiring*: that tapping the enabled inline action
//     emits `OpenCivilianUnitsPanelEvent(builderOnly: true,
//     buildImprovementShortcutTargetTileKey: <exact tile key>)` on the app event
//     bus. This file pins that positive path plus the negative (no Builder →
//     disabled → no event).

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
    show PlayerView, buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

const String _kGameId = 'g_bi_shortcut_emit';
const String _kHumanPlayerId = 'gp1';
const String _kProvinceId = 'oldWorld|p1';
const String _kTileKey = 'oldWorld|p1|0|0';

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

/// GameService returning the static map data aligned with the test game.
class _GameServiceBuildImprovement extends GameService {
  _GameServiceBuildImprovement(super.box, super.adapter);

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

/// Game where the human GP owns the province and (when [withBuilder]) has an
/// idle Builder on the resource tile so `build_improvement` can be assigned.
Game _buildGame({required bool withBuilder}) {
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
          if (withBuilder)
            Unit(
              id: 'u_builder',
              type: kUnitTypeBuilder,
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
      tileState: TileMapState(improvementByTile: {_kTileKey: 0}),
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
        techUnlocked: const {kTechIdCircularSaw: true},
      ),
    ],
    minorNations: const [],
    tribes: const [],
  );
}

RegionMapViewData _region() {
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
        provinceDisplayName: 'Test Province',
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

PerPlayerWorkTargetSelectionCache _refreshedCache({
  required Game game,
  required PlayerView playerView,
}) {
  final cache = PerPlayerWorkTargetSelectionCache();
  cache.refresh(
    WorkTargetSelectionSnapshot(
      game: game,
      playerId: _kHumanPlayerId,
      playerView: playerView,
      topology: _combinedTopology,
      currentOrders: const Orders(),
      tileMapByRegion: _tileMapByRegion,
    ),
  );
  return cache;
}

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_province_bi_shortcut_emit');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  Future<List<OpenCivilianUnitsPanelEvent>> pumpHostAndSelect(
    WidgetTester tester, {
    required Game game,
  }) async {
    final region = _region();
    final playerView = buildPlayerView(game, _combinedTopology, _kHumanPlayerId);
    final cache = _refreshedCache(game: game, playerView: playerView);
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
            (ref) => _GameServiceBuildImprovement(gamesBox, GameSaveAdapter()),
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
                  workTargetSelectionCache: cache,
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
    'tapping the enabled Build improvement shortcut emits a Builder-only '
    'OpenCivilianUnitsPanelEvent targeting the exact selected tile key '
    '(SPEC § Tile inline actions — Build improvement shortcut assignment)',
    (WidgetTester tester) async {
      final opened = await pumpHostAndSelect(
        tester,
        game: _buildGame(withBuilder: true),
      );

      final shortcut = find.byWidgetPredicate(
        (Widget w) =>
            w is CtIconAction &&
            w.icon == Icons.handyman &&
            w.onPressed != null,
      );
      expect(
        shortcut,
        findsOneWidget,
        reason:
            'The wide side panel must render an enabled Build improvement '
            'inline action for a valid Builder + affordable improvement tile.',
      );

      await tester.ensureVisible(shortcut);
      await tester.tap(shortcut);
      await tester.pump();

      expect(
        opened,
        hasLength(1),
        reason:
            'Tapping the enabled Build improvement shortcut must open the '
            'Civilian Units panel exactly once via OpenCivilianUnitsPanelEvent.',
      );
      final event = opened.single;
      expect(event.builderOnly, isTrue);
      expect(event.explorerOnly, isFalse);
      expect(
        event.buildImprovementShortcutTargetTileKey,
        _kTileKey,
        reason:
            'The shortcut must target the exact selected tile key so the '
            'Builder-only panel can assign build_improvement to that tile.',
      );
      expect(event.exploreShortcutTargetTileKey, isNull);
      expect(event.prospectShortcutTargetTileKey, isNull);
    },
  );

  testWidgets(
    'negative — with no Builder unit the Build improvement shortcut is not '
    'enabled and tapping emits no OpenCivilianUnitsPanelEvent',
    (WidgetTester tester) async {
      final opened = await pumpHostAndSelect(
        tester,
        game: _buildGame(withBuilder: false),
      );

      // No enabled (tappable) Build improvement shortcut may exist.
      final enabledShortcut = find.byWidgetPredicate(
        (Widget w) =>
            w is CtIconAction &&
            w.icon == Icons.handyman &&
            w.onPressed != null,
      );
      expect(
        enabledShortcut,
        findsNothing,
        reason:
            'Without an assignable Builder the Build improvement inline action '
            'must not be enabled (SPEC AC L401 — disabled, non-clickable).',
      );

      // Attempt to tap any rendered (disabled) Build improvement action; it must
      // remain a no-op on the event bus.
      final anyShortcut = find.byWidgetPredicate(
        (Widget w) => w is CtIconAction && w.icon == Icons.handyman,
      );
      if (anyShortcut.evaluate().isNotEmpty) {
        await tester.tap(anyShortcut.first, warnIfMissed: false);
        await tester.pump();
      }

      expect(
        opened,
        isEmpty,
        reason:
            'A disabled / absent Build improvement shortcut must never open the '
            'Civilian Units panel via OpenCivilianUnitsPanelEvent.',
      );
    },
  );
}
