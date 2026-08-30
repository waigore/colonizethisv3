// GameMapTileRadialHost open / suppress / More / Province details. Refs #4440.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/game/flame/caches/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/game_map_tile_radial_host.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_radial_keys.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_province_panel_provider.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'app_test_hive_harness.dart';

const String _kHumanPlayerId = 'gp1';
const String _kProvinceId = 'oldWorld|p1';
const String _kTileKey = 'oldWorld|p1|0|0';
const Key _kMapStubKey = Key('tile_radial_map_stub');

final MapTopology _topology = MapTopology(
  nodes: const [
    TopologyNode(
      id: 'oldWorld|p1',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
  ],
  edges: const [],
);

Game _game() {
  return Game(
    id: 'g_tile_radial_host',
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
        units: const [],
      ),
      newWorld: const RegionData(provinces: [], units: []),
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
        ownerFactionId: _kHumanPlayerId,
        provinceDisplayName: 'Wessex',
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

Future<void> _pumpHost(
  WidgetTester tester, {
  required bool canMutateViaUi,
  required Box<dynamic> gamesBox,
  AppEventBus? bus,
  Size viewport = const Size(400, 400),
}) {
  final game = _game();
  final region = _region();
  return pumpAppShell(
    tester,
    viewport: viewport,
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    overrides: [
      gamesBoxProvider.overrideWith((ref) => gamesBox),
      gameServiceProvider.overrideWith(
        (ref) => GameService(gamesBox, GameSaveAdapter()),
      ),
      currentOrdersProvider.overrideWith(
        () => CurrentOrdersNotifier(const Orders()),
      ),
    ],
    child: GameMapTileRadialHost(
      game: game,
      region: region,
      humanPlayerId: _kHumanPlayerId,
      playerView: buildPlayerView(game, _topology, _kHumanPlayerId),
      workTargetSelectionCache: PerPlayerWorkTargetSelectionCache(),
      canMutateViaUi: canMutateViaUi,
      bus: bus,
      mapBuilder: (onSecondary) {
        return GestureDetector(
          key: _kMapStubKey,
          onTap: onSecondary == null
              ? null
              : () => onSecondary(_kTileKey, const Offset(200, 200)),
          child: const SizedBox.expand(),
        );
      },
    ),
  );
}

void _openHost(WidgetTester tester, {Offset anchor = const Offset(200, 200)}) {
  tester
      .state<GameMapTileRadialHostState>(find.byType(GameMapTileRadialHost))
      .openFromSecondary(_kTileKey, anchor);
}

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(suiteId: 'tile_radial_host');
  });

  testWidgets('secondary stub opens MAP30001 when mutate is allowed', (
    tester,
  ) async {
    final bus = AppEventBus.create();
    addTearDown(bus.dispose);
    await _pumpHost(tester, canMutateViaUi: true, bus: bus, gamesBox: gamesBox);
    _openHost(tester);
    await tester.pump();
    expect(find.byKey(kTileContextRadialKey), findsOneWidget);
    expect(find.byKey(kTileRadialMoreKey), findsOneWidget);
  });

  testWidgets('canMutateViaUi false does not open the radial', (tester) async {
    final bus = AppEventBus.create();
    addTearDown(bus.dispose);
    await _pumpHost(
      tester,
      canMutateViaUi: false,
      bus: bus,
      gamesBox: gamesBox,
    );
    expect(
      tester.widget<GestureDetector>(find.byKey(_kMapStubKey)).onTap,
      isNull,
    );
    _openHost(tester);
    await tester.pump();
    expect(find.byKey(kTileContextRadialKey), findsNothing);
  });

  testWidgets('tiny viewport opens MAP30002 instead of the radial', (
    tester,
  ) async {
    final bus = AppEventBus.create();
    addTearDown(bus.dispose);
    await _pumpHost(
      tester,
      canMutateViaUi: true,
      bus: bus,
      gamesBox: gamesBox,
      viewport: const Size(120, 120),
    );
    _openHost(tester, anchor: const Offset(60, 60));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(kTileContextRadialKey), findsNothing);
    expect(find.byKey(kTileMoreActionsDialogKey), findsOneWidget);
    expect(find.byKey(kTileMoreProvinceDetailsKey), findsOneWidget);
  });

  testWidgets('More then Province details reports the map tile tap', (
    tester,
  ) async {
    final bus = AppEventBus.create();
    addTearDown(bus.dispose);
    await _pumpHost(tester, canMutateViaUi: true, bus: bus, gamesBox: gamesBox);
    _openHost(tester);
    await tester.pump();
    await tester.tap(find.byKey(kTileRadialMoreKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(kTileMoreProvinceDetailsKey), findsOneWidget);
    await tester.tap(find.byKey(kTileMoreProvinceDetailsKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final ctx = tester.element(find.byType(GameMapTileRadialHost));
    final panel = ProviderScope.containerOf(ctx).read(mapProvincePanelProvider);
    expect(panel.selectedTileKey, _kTileKey);
    expect(find.byKey(kTileContextRadialKey), findsNothing);
  });
}
