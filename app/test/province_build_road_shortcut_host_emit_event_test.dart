// Pins the host-level Build road *shortcut-assignment* tap flow for both
// province detail hosts (`GameMapProvinceDetailSidePanel` wide,
// `GameMapNarrowDetailOverlaySlot` narrow). Refs #4260.

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
import 'package:colonizethis_logic/colonizethis_logic.dart' show buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';

const String _kGameId = 'g_br_shortcut_emit';
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

class _GameServiceBuildRoad extends GameService {
  _GameServiceBuildRoad(super.box, super.adapter);

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

Game _buildGame({required bool withEngineer}) {
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
          if (withEngineer)
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

PerPlayerWorkTargetSelectionCache _refreshedCache(Game game) {
  final playerView = buildPlayerView(game, _combinedTopology, _kHumanPlayerId);
  return PerPlayerWorkTargetSelectionCache()
    ..refresh(
      WorkTargetSelectionSnapshot(
        game: game,
        playerId: _kHumanPlayerId,
        playerView: playerView,
        topology: _combinedTopology,
        currentOrders: const Orders(),
        tileMapByRegion: _tileMapByRegion,
      ),
    );
}

Finder _buildRoadAction({required bool enabledOnly}) {
  return find.byWidgetPredicate(
    (Widget w) =>
        w is CtIconAction &&
        w.icon == Icons.add_road &&
        (!enabledOnly || w.onPressed != null),
  );
}

typedef _HostCase = ({
  String label,
  Type hostType,
  Size surfaceSize,
  bool selectTileTab,
  bool wide,
});

const List<_HostCase> _hostCases = <_HostCase>[
  (
    label: 'The wide side panel',
    hostType: GameMapProvinceDetailSidePanel,
    surfaceSize: Size(720, 720),
    selectTileTab: false,
    wide: true,
  ),
  (
    label: 'The narrow bottom-slot host',
    hostType: GameMapNarrowDetailOverlaySlot,
    surfaceSize: Size(400, 600),
    selectTileTab: true,
    wide: false,
  ),
];

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_province_br_shortcut_emit');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  Future<List<OpenCivilianUnitsPanelEvent>> pumpHostAndSelect(
    WidgetTester tester, {
    required Game game,
    required _HostCase host,
  }) async {
    final region = _region();
    final playerView = buildPlayerView(game, _combinedTopology, _kHumanPlayerId);
    final cache = _refreshedCache(game);
    final Widget body = host.wide
        ? Center(
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
          )
        : Align(
            alignment: Alignment.bottomCenter,
            child: GameMapNarrowDetailOverlaySlot(
              game: game,
              region: region,
              humanPlayerId: _kHumanPlayerId,
              playerView: playerView,
              workTargetSelectionCache: cache,
            ),
          );

    final bus = AppEventBus.create();
    addTearDown(bus.dispose);
    final opened = <OpenCivilianUnitsPanelEvent>[];
    final sub = bus.on<OpenCivilianUnitsPanelEvent>().listen(opened.add);
    addTearDown(sub.cancel);

    await pumpAppShell(
      tester,
      viewport: host.surfaceSize,
      overrides: [
        gamesBoxProvider.overrideWith((ref) => gamesBox),
        gameServiceProvider.overrideWith(
          (ref) => _GameServiceBuildRoad(gamesBox, GameSaveAdapter()),
        ),
        appEventBusProvider.overrideWith((ref) => bus),
        currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
        currentOrdersProvider.overrideWith(
          () => CurrentOrdersNotifier(const Orders()),
        ),
      ],
      child: Scaffold(body: body),
    );

    final ctx = tester.element(find.byType(host.hostType));
    ProviderScope.containerOf(ctx)
        .read(mapProvincePanelProvider.notifier)
        .reportMapTileTapped(_kTileKey);
    await tester.pumpAndSettle();
    if (host.selectTileTab) {
      final tileTab = find.text('Tile');
      expect(tileTab, findsOneWidget);
      await tester.tap(tileTab);
      await tester.pumpAndSettle();
    }
    return opened;
  }

  Future<void> expectBuildRoadShortcutEmits(
    WidgetTester tester, {
    required List<OpenCivilianUnitsPanelEvent> opened,
    required String hostLabel,
  }) async {
    final shortcut = _buildRoadAction(enabledOnly: true);
    expect(
      shortcut,
      findsOneWidget,
      reason:
          '$hostLabel must render an enabled Build road inline action '
          'for a valid Engineer + affordable road tile.',
    );
    await tester.ensureVisible(shortcut);
    await tester.tap(shortcut);
    await tester.pump();
    expect(
      opened,
      hasLength(1),
      reason:
          'Tapping the enabled Build road shortcut must open the '
          'Civilian Units panel exactly once via OpenCivilianUnitsPanelEvent.',
    );
    final event = opened.single;
    expect(event.engineerOnly, isTrue);
    expect(event.builderOnly, isFalse);
    expect(event.explorerOnly, isFalse);
    expect(
      event.buildRoadShortcutTargetTileKey,
      _kTileKey,
      reason:
          'The shortcut must target the exact selected tile key so the '
          'Engineer-only panel can assign build_road to that tile.',
    );
    expect(event.exploreShortcutTargetTileKey, isNull);
    expect(event.prospectShortcutTargetTileKey, isNull);
    expect(event.buildImprovementShortcutTargetTileKey, isNull);
  }

  for (final host in _hostCases) {
    testWidgets(
      '${host.wide ? 'wide' : 'narrow'} host: tapping the enabled Build '
      'road shortcut emits an Engineer-only OpenCivilianUnitsPanelEvent '
      'targeting the exact selected tile key',
      (WidgetTester tester) async {
        final opened = await pumpHostAndSelect(
          tester,
          game: _buildGame(withEngineer: true),
          host: host,
        );
        await expectBuildRoadShortcutEmits(
          tester,
          opened: opened,
          hostLabel: host.label,
        );
      },
    );

    testWidgets(
      'negative — ${host.wide ? 'wide' : 'narrow'} host with no Engineer unit '
      'does not enable Build road and emits no '
      'OpenCivilianUnitsPanelEvent',
      (WidgetTester tester) async {
        final opened = await pumpHostAndSelect(
          tester,
          game: _buildGame(withEngineer: false),
          host: host,
        );
        expect(
          _buildRoadAction(enabledOnly: true),
          findsNothing,
          reason: host.wide
              ? 'Without an assignable Engineer the Build road inline '
                    'action must not be enabled.'
              : null,
        );
        if (host.wide) {
          final anyShortcut = _buildRoadAction(enabledOnly: false);
          if (anyShortcut.evaluate().isNotEmpty) {
            await tester.tap(anyShortcut.first, warnIfMissed: false);
            await tester.pump();
          }
          expect(
            opened,
            isEmpty,
            reason:
                'A disabled / absent Build road shortcut must never '
                'open the Civilian Units panel via OpenCivilianUnitsPanelEvent.',
          );
        } else {
          expect(opened, isEmpty);
        }
      },
    );
  }
}
