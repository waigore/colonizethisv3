// Pins the host-level Upgrade town *shortcut-assignment* tap flow for
// both province detail hosts (`GameMapProvinceDetailSidePanel` wide,
// `GameMapNarrowDetailOverlaySlot` narrow).
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Political Upgrade town shortcut behavior:
//   On tap, open Civilian Units panel in Builder-only shortcut mode targeting
//   upgrade_town for the province town tile key.
// SPEC/ui/civilian-units-panel.md — explicit shortcut contract:
//   `upgradeTownShortcutTargetTileKey` opens direct-assign `upgrade_town`.
//
// Coverage gap closed here (Refs #4316):
//   - `province_overlay_political_upgrade_town_test.dart` pins gist helper copy.
//   - This file pins the *host wiring*: that tapping the enabled Political
//     Upgrade town control emits `OpenCivilianUnitsPanelEvent(builderOnly: true,
//     upgradeTownShortcutTargetTileKey: <province town tile key>)` on the app
//     event bus, plus the no-Builder negative.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/game/flame/map_state/game_map_area_state_logic.dart';
import 'package:colonizethis_app/features/game/flame/overlays/game_map_narrow_detail_overlay.dart';
import 'package:colonizethis_app/features/game/flame/overlays/game_map_province_detail_side_panel.dart';
import 'package:colonizethis_app/features/game/flame/caches/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_province_panel_provider.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
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

const String _kGameId = 'g_ut_shortcut_emit';
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
      [TerrainType.plains],
    ],
    resourceGrid: const [
      [Resource.grain],
    ],
  ),
};

class _GameServiceUpgradeTownShortcut extends GameService {
  _GameServiceUpgradeTownShortcut(super.box, super.adapter);

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
            townDevelopmentLevel: 2,
            townTileKey: _kTileKey,
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
        techUnlocked: const {kTechIdNationalBureaucracy: true},
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

Finder _upgradeTownAction({required bool enabledOnly}) {
  final l10n = AppLocalizationsEn();
  return find.byWidgetPredicate(
    (Widget w) =>
        w is CtActionTextButton &&
        w.label == l10n.provinceOverlay_upgradeTownAction &&
        (!enabledOnly || (w.enabled && w.onPressed != null)),
  );
}

typedef _HostCase = ({
  String label,
  Type hostType,
  Size surfaceSize,
  bool wide,
});

const List<_HostCase> _hostCases = <_HostCase>[
  (
    label: 'The wide side panel',
    hostType: GameMapProvinceDetailSidePanel,
    surfaceSize: Size(720, 720),
    wide: true,
  ),
  (
    label: 'The narrow bottom-slot host',
    hostType: GameMapNarrowDetailOverlaySlot,
    surfaceSize: Size(400, 600),
    wide: false,
  ),
];

void main() {
  suppressLogsForTests();

  test('upgrade town action state fixture is enabled for host wiring', () {
    final game = _buildGame(withBuilder: true);
    final playerView = buildPlayerView(game, _combinedTopology, _kHumanPlayerId);
    final state = GameMapAreaStateLogicProvinceActions.provinceUpgradeTownActionState(
      game: game,
      humanPlayerId: _kHumanPlayerId,
      provinceId: _kProvinceId,
      playerView: playerView,
      topology: _combinedTopology,
      currentOrders: const Orders(),
      tileMapByRegion: _tileMapByRegion,
    );
    expect(state.showControl, isTrue);
    expect(state.enabled, isTrue);
    expect(state.townTileKey, _kTileKey);
  });

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_province_ut_shortcut_emit');
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
          (ref) => _GameServiceUpgradeTownShortcut(gamesBox, GameSaveAdapter()),
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
    return opened;
  }

  Future<void> expectUpgradeTownShortcutEmits(
    WidgetTester tester, {
    required List<OpenCivilianUnitsPanelEvent> opened,
    required String hostLabel,
  }) async {
    final shortcut = _upgradeTownAction(enabledOnly: true);
    expect(
      shortcut,
      findsOneWidget,
      reason:
          '$hostLabel must render an enabled Upgrade town political control for '
          'a valid Builder + National Bureaucracy + upgradeable town.',
    );
    await tester.ensureVisible(shortcut);
    await tester.tap(shortcut);
    await tester.pump();
    expect(
      opened,
      hasLength(1),
      reason:
          'Tapping the enabled Upgrade town shortcut must open the Civilian '
          'Units panel exactly once via OpenCivilianUnitsPanelEvent.',
    );
    final event = opened.single;
    expect(event.builderOnly, isTrue);
    expect(event.explorerOnly, isFalse);
    expect(event.engineerOnly, isFalse);
    expect(event.merchantOnly, isFalse);
    expect(event.upgradeTownShortcutTargetTileKey, _kTileKey);
    expect(event.exploreShortcutTargetTileKey, isNull);
    expect(event.prospectShortcutTargetTileKey, isNull);
    expect(event.buildImprovementShortcutTargetTileKey, isNull);
    expect(event.buildRoadShortcutTargetTileKey, isNull);
    expect(event.buildFortShortcutTargetTileKey, isNull);
    expect(event.purchaseLandShortcutTargetTileKey, isNull);
  }

  for (final host in _hostCases) {
    testWidgets(
      '${host.wide ? 'wide' : 'narrow'} host: tapping the enabled Upgrade '
      'town shortcut emits a Builder-only OpenCivilianUnitsPanelEvent '
      'targeting the province town tile key (SPEC § Political Upgrade town '
      'shortcut assignment)',
      (WidgetTester tester) async {
        final opened = await pumpHostAndSelect(
          tester,
          game: _buildGame(withBuilder: true),
          host: host,
        );
        await expectUpgradeTownShortcutEmits(
          tester,
          opened: opened,
          hostLabel: host.label,
        );
      },
    );

    testWidgets(
      'negative — ${host.wide ? 'wide' : 'narrow'} host with no Builder unit '
      'does not enable Upgrade town and emits no '
      'OpenCivilianUnitsPanelEvent',
      (WidgetTester tester) async {
        final opened = await pumpHostAndSelect(
          tester,
          game: _buildGame(withBuilder: false),
          host: host,
        );
        expect(_upgradeTownAction(enabledOnly: true), findsNothing);
        final disabled = _upgradeTownAction(enabledOnly: false);
        if (disabled.evaluate().isNotEmpty) {
          await tester.tap(disabled.first, warnIfMissed: false);
          await tester.pump();
        }
        expect(opened, isEmpty);
      },
    );
  }
}
