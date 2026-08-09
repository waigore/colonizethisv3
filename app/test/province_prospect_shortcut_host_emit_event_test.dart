// Pins the host-level Prospect-with-explorer *shortcut-assignment* tap flow for
// both province detail hosts (`GameMapProvinceDetailSidePanel` wide,
// `GameMapNarrowDetailOverlaySlot` narrow).
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Tile inline actions — Prospect icon behavior:
//   "On tap, open Civilian Units panel in explorer-only shortcut mode targeting
//    prospect for the exact selected tile key."
// SPEC/ui/civilian-units-panel.md — explicit shortcut contract:
//   `prospectShortcutTargetTileKey` opens direct-assign `prospect`.
//
// Coverage gap closed here (Refs #2865):
//   - `province_overlay_tile_inline_action_non_clickable_test.dart` pins the
//     *overlay-level* callback contract (enabled fires / disabled does not).
//   - Neither asserts the *host wiring*: that tapping the enabled inline action
//     emits `OpenCivilianUnitsPanelEvent(explorerOnly: true,
//     prospectShortcutTargetTileKey: <exact tile key>)` on the app event bus.
//   - This file pins the positive path and the no-explorer negative.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/game/flame/map_state/map_state.dart';
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

const String _kGameId = 'g_prospect_shortcut_emit';
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
    width: 1,
    height: 1,
    grid: const [
      ['p1'],
    ],
    terrainGrid: const [
      [TerrainType.hills],
    ],
    resourceGrid: const [
      [Resource.iron],
    ],
  ),
};

class _GameServiceProspectShortcut extends GameService {
  _GameServiceProspectShortcut(super.box, super.adapter);

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
      resourceByTileKey: const {_kTileKey: 'iron'},
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          _kProvinceId: [_kTileKey],
        },
      },
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
      ),
    ],
    minorNations: const [],
    tribes: const [],
  );
}

RegionMapViewData _fullyVisibleRegion() {
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
        terrainType: TerrainType.hills,
        resourceId: 'iron',
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

Finder _prospectAction({required bool enabledOnly}) {
  return find.byWidgetPredicate(
    (Widget w) =>
        w is CtIconAction &&
        w.icon == Icons.travel_explore &&
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

  test('prospect action state fixture is enabled for host wiring', () {
    final game = _buildGame(withExplorer: true);
    final playerView = buildPlayerView(game, _combinedTopology, _kHumanPlayerId);
    final state = GameMapAreaStateLogic.provinceProspectActionState(
      game: game,
      humanPlayerId: _kHumanPlayerId,
      selectedTileKey: _kTileKey,
      playerView: playerView,
      topology: _combinedTopology,
      currentOrders: const Orders(),
      tileMapByRegion: _tileMapByRegion,
    );
    expect(state.showIcon, isTrue);
    expect(state.enabled, isTrue);
  });

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_province_prospect_shortcut_emit');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  Future<List<OpenCivilianUnitsPanelEvent>> pumpHostAndSelect(
    WidgetTester tester, {
    required Game game,
    required _HostCase host,
  }) async {
    final region = _fullyVisibleRegion();
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
          (ref) => _GameServiceProspectShortcut(gamesBox, GameSaveAdapter()),
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

  Future<void> expectProspectShortcutEmits(
    WidgetTester tester, {
    required List<OpenCivilianUnitsPanelEvent> opened,
    required String hostLabel,
  }) async {
    final shortcut = _prospectAction(enabledOnly: true);
    expect(
      shortcut,
      findsOneWidget,
      reason:
          '$hostLabel must render an enabled Prospect inline action for a '
          'fully visible mineral tile with an Explorer unit.',
    );
    await tester.ensureVisible(shortcut);
    await tester.tap(shortcut);
    await tester.pump();
    expect(opened, hasLength(1));
    final event = opened.single;
    expect(event.explorerOnly, isTrue);
    expect(event.builderOnly, isFalse);
    expect(event.prospectShortcutTargetTileKey, _kTileKey);
    expect(event.exploreShortcutTargetTileKey, isNull);
    expect(event.buildImprovementShortcutTargetTileKey, isNull);
  }

  for (final host in _hostCases) {
    testWidgets(
      '${host.wide ? 'wide' : 'narrow'} host: tapping the enabled Prospect '
      'shortcut emits an explorer-only OpenCivilianUnitsPanelEvent targeting '
      'the exact selected tile key '
      '(SPEC § Tile inline actions — Prospect shortcut assignment)',
      (WidgetTester tester) async {
        final opened = await pumpHostAndSelect(
          tester,
          game: _buildGame(withExplorer: true),
          host: host,
        );
        await expectProspectShortcutEmits(
          tester,
          opened: opened,
          hostLabel: host.label,
        );
      },
    );

    testWidgets(
      'negative — ${host.wide ? 'wide' : 'narrow'} host with no Explorer unit '
      'does not enable Prospect and emits no OpenCivilianUnitsPanelEvent',
      (WidgetTester tester) async {
        final opened = await pumpHostAndSelect(
          tester,
          game: _buildGame(withExplorer: false),
          // Narrow negative originally omitted selectTileTab; keep that when the
          // shortcut stays off so the assert does not depend on Tile-tab chrome.
          host: host.wide
              ? host
              : (
                  label: host.label,
                  hostType: host.hostType,
                  surfaceSize: host.surfaceSize,
                  selectTileTab: false,
                  wide: false,
                ),
        );
        expect(_prospectAction(enabledOnly: true), findsNothing);
        if (host.wide) {
          final anyShortcut = _prospectAction(enabledOnly: false);
          if (anyShortcut.evaluate().isNotEmpty) {
            await tester.tap(anyShortcut.first, warnIfMissed: false);
            await tester.pump();
          }
        }
        expect(opened, isEmpty);
      },
    );
  }
}
