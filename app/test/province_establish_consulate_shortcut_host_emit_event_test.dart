import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/config/constants.dart' show HiveBoxNames;
import 'package:colonizethis_app/features/game/flame/caches/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_app/features/game/flame/overlays/game_map_narrow_detail_overlay.dart';
import 'package:colonizethis_app/features/game/flame/overlays/game_map_province_detail_side_panel.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_province_panel_provider.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart' show buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';

const _gameId = 'g_consulate_shortcut';
const _humanId = 'gp1';
const _minorId = 'minor1';
const _provinceId = 'oldWorld|p1';
const _tileKey = 'oldWorld|p1|0|0';

final _topology = MapTopology(
  nodes: const [
    TopologyNode(
      id: _provinceId,
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
  ],
);

final _tileMaps = {
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
      [null],
    ],
  ),
};

class _ConsulateGameService extends GameService {
  _ConsulateGameService(super.box, super.adapter);

  @override
  GameMapData? getMapData(String gameId) {
    if (gameId != _gameId) return null;
    return (
      combinedTopology: _topology,
      tileMapByRegion: _tileMaps,
      topologyByRegion: {'oldWorld': _topology},
      warpLinks: null,
    );
  }
}

Game _game({bool expertise = true}) => Game(
  id: _gameId,
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(
      provinces: const [
        Province(
          id: _provinceId,
          regionId: 'oldWorld',
          ownerId: _minorId,
          displayName: 'Bavaria Province',
        ),
      ],
      units: const [],
    ),
    newWorld: const RegionData(provinces: [], units: []),
    tileKeysByRegionAndProvince: const {
      'oldWorld': {
        _provinceId: [_tileKey],
      },
    },
    playerVisibilityByTile: const {
      _humanId: {_tileKey: 'fullyVisible'},
    },
  ),
  players: [
    Player(
      id: _humanId,
      displayName: 'Human',
      isHuman: true,
      treasury: 5000,
      techUnlocked: expertise
          ? const {kTechIdDiplomaticExpertise: true}
          : const {},
    ),
  ],
  minorNations: const [MinorNation(id: _minorId, displayName: 'Bavaria')],
  tribes: const [],
);

RegionMapViewData _region() => RegionMapViewData(
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
      ownerFactionId: _minorId,
      provinceDisplayName: 'Bavaria Province',
      visibility: TileVisibility.visible,
    ),
  ],
  capitalMarkers: const [],
  portMarkers: const [],
  factionColors: const {},
  greatPowerFactionIds: const {_humanId},
  terrainColors: const {},
  provincePoliticalOwnerByPrefixedProvinceId: const {_provinceId: _minorId},
);

const _consulateOrder = DiplomaticOrder(
  type: DiplomaticOrderType.establishOverture,
  targetFactionId: _minorId,
  overtureStage: OvertureStage.tradeConsulate,
);

Orders _pending() => const Orders(
  diplomaticOrdersByPlayerId: {
    _humanId: [_consulateOrder],
  },
);

typedef _HostCase = ({bool wide, Size size, Type type});

const _hosts = [
  (wide: true, size: Size(720, 720), type: GameMapProvinceDetailSidePanel),
  (wide: false, size: Size(360, 640), type: GameMapNarrowDetailOverlaySlot),
];

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();
  late Box<dynamic> gamesBox;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_province_consulate_shortcut');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  Future<AppEventBus> pumpHost(
    WidgetTester tester, {
    required _HostCase host,
    required Game game,
    Orders orders = const Orders(),
  }) async {
    final bus = AppEventBus.create();
    addTearDown(bus.dispose);
    final view = buildPlayerView(game, _topology, _humanId);
    final body = host.wide
        ? Center(
            child: SizedBox(
              width: 320,
              child: GameMapProvinceDetailSidePanel(
                game: game,
                region: _region(),
                humanPlayerId: _humanId,
                playerView: view,
                workTargetSelectionCache: PerPlayerWorkTargetSelectionCache(),
              ),
            ),
          )
        : Align(
            alignment: Alignment.bottomCenter,
            child: GameMapNarrowDetailOverlaySlot(
              game: game,
              region: _region(),
              humanPlayerId: _humanId,
              playerView: view,
              workTargetSelectionCache: PerPlayerWorkTargetSelectionCache(),
            ),
          );
    await pumpAppShell(
      tester,
      viewport: host.size,
      overrides: [
        gamesBoxProvider.overrideWith((ref) => gamesBox),
        gameServiceProvider.overrideWith(
          (ref) => _ConsulateGameService(gamesBox, GameSaveAdapter()),
        ),
        appEventBusProvider.overrideWith((ref) => bus),
        currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
        currentOrdersProvider.overrideWith(() => CurrentOrdersNotifier(orders)),
      ],
      child: Scaffold(body: body),
    );
    final context = tester.element(find.byType(host.type));
    ProviderScope.containerOf(
      context,
    ).read(mapProvincePanelProvider.notifier).reportMapTileTapped(_tileKey);
    await tester.pumpAndSettle();
    return bus;
  }

  Finder action(String label) => find.byWidgetPredicate(
    (widget) => widget is CtActionTextButton && widget.label == label,
  );

  for (final host in _hosts) {
    testWidgets(
      '${host.wide ? 'wide' : 'narrow'} host emits confirm then appends Consulate',
      (tester) async {
        final bus = await pumpHost(tester, host: host, game: _game());
        final confirmFuture = bus
            .on<ConfirmDialogEvent>()
            .first
            .timeout(const Duration(seconds: 2));
        final appendFuture = bus
            .on<AppendDiplomaticOrderRequestedEvent>()
            .first
            .timeout(const Duration(seconds: 2));

        final establish = action(l10n.provinceOverlay_establishConsulateAction);
        await tester.ensureVisible(establish);
        await tester.tap(establish);
        await tester.pump();
        final confirm = await confirmFuture;
        expect(confirm.message, contains('Cost:'));
        expect(confirm.message, contains('Effect:'));

        confirm.result(true);
        final append = await appendFuture;
        expect(append.playerId, _humanId);
        expect(append.order.type, DiplomaticOrderType.establishOverture);
        expect(append.order.overtureStage, OvertureStage.tradeConsulate);
        expect(append.order.targetFactionId, _minorId);
        expect(find.byType(host.type), findsOneWidget);
      },
    );
  }

  testWidgets('dismissing Consulate confirm appends nothing', (tester) async {
    final bus = await pumpHost(tester, host: _hosts.first, game: _game());
    final confirms = <ConfirmDialogEvent>[];
    final appends = <AppendDiplomaticOrderRequestedEvent>[];
    final confirmSub = bus.on<ConfirmDialogEvent>().listen(confirms.add);
    final appendSub = bus.on<AppendDiplomaticOrderRequestedEvent>().listen(
      appends.add,
    );
    addTearDown(confirmSub.cancel);
    addTearDown(appendSub.cancel);

    await tester.tap(action(l10n.provinceOverlay_establishConsulateAction));
    await tester.pump();
    confirms.single.result(false);
    await tester.pump();
    expect(appends, isEmpty);
  });

  testWidgets('pending control emits remove without confirm', (tester) async {
    final bus = await pumpHost(
      tester,
      host: _hosts.first,
      game: _game(),
      orders: _pending(),
    );
    final removes = <RemoveDiplomaticOrderRequestedEvent>[];
    final confirms = <ConfirmDialogEvent>[];
    final removeSub = bus.on<RemoveDiplomaticOrderRequestedEvent>().listen(
      removes.add,
    );
    final confirmSub = bus.on<ConfirmDialogEvent>().listen(confirms.add);
    addTearDown(removeSub.cancel);
    addTearDown(confirmSub.cancel);

    await tester.tap(
      action(l10n.provinceOverlay_cancelEstablishConsulateAction),
    );
    await tester.pump();
    expect(confirms, isEmpty);
    expect(removes, hasLength(1));
    expect(removes.single.playerId, _humanId);
    expect(removes.single.type, DiplomaticOrderType.establishOverture);
    expect(removes.single.targetFactionId, _minorId);
  });

  testWidgets(
    'disabled host control shows validator reason and emits nothing',
    (tester) async {
      final bus = await pumpHost(
        tester,
        host: _hosts.first,
        game: _game(expertise: false),
      );
      final confirms = <ConfirmDialogEvent>[];
      final sub = bus.on<ConfirmDialogEvent>().listen(confirms.add);
      addTearDown(sub.cancel);
      final button = tester.widget<CtActionTextButton>(
        action(l10n.provinceOverlay_establishConsulateAction),
      );
      expect(button.enabled, isFalse);
      expect(button.tooltip, contains('Diplomatic Expertise'));
      expect(button.semanticLabel, contains('Diplomatic Expertise'));
      expect(confirms, isEmpty);
    },
  );
}
