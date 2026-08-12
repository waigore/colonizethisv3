// Counsel screen Military tab integration (Refs #4307).
// SPEC/ui/counsel-panel.md — Military tab route args and read-only gating.

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/screens/counsel/counsel_screen.dart';
import 'package:colonizethis_app/features/game/screens/counsel/counsel_screen_tabs.dart';
import 'package:colonizethis_app/features/game/widgets/shell/shell_player_context.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'panel_fixtures/core.dart';
import 'widget_test_pumps.dart';

const _trainPanelGameId = 'train-panel-widget-test';

final MapTopology _trainCounselTopology = MapTopology(
  nodes: const [
    TopologyNode(
      id: 'oldWorld|cap',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
  ],
  edges: const [],
);

class CounselMilitaryTrainMapGameService extends GameService {
  CounselMilitaryTrainMapGameService(super.box, super.adapter);

  @override
  ({
    MapTopology combinedTopology,
    Map<String, TileMapResult> tileMapByRegion,
    Map<String, MapTopology> topologyByRegion,
    List<WarpLink>? warpLinks,
  })?
  getMapData(String gameId) {
    if (gameId != _trainPanelGameId) return null;
    return (
      combinedTopology: _trainCounselTopology,
      tileMapByRegion: const {},
      topologyByRegion: const {},
      warpLinks: null,
    );
  }
}

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_counsel_military_screen');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  tearDownAll(() async {
    await gamesBox.close();
  });

  List<Override> counselScreenOverrides({
    required Game game,
    required AppEventBus bus,
    Orders initialOrders = const Orders(),
    CurrentOrdersNotifier? ordersNotifier,
    GameService? gameService,
    bool canMutateViaUi = true,
  }) {
    final playerId = game.players.first.id;
    final ordersState =
        ordersNotifier ?? CurrentOrdersNotifier(initialOrders);
    return [
      gamesBoxProvider.overrideWith((ref) => gamesBox),
      gameServiceProvider.overrideWith(
        (ref) =>
            gameService ?? GameService(gamesBox, GameSaveAdapter()),
      ),
      currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
      currentOrdersProvider.overrideWith(() => ordersState),
      appEventBusProvider.overrideWith((ref) => bus),
      shellPlayerContextProvider.overrideWithValue(
        ShellPlayerContext(
          effectiveHumanPlayerId: playerId,
          viewingPlayerId: playerId,
          mapVisibilityMode: CtMapVisibilityMode.full,
          playerView: null,
          omniscientDetail: false,
          showPlayerChrome: true,
          canMutateViaUi: canMutateViaUi,
          debugCommandTargetPlayerId: playerId,
          inObservePhase: !canMutateViaUi,
          observeBannerLabel: canMutateViaUi ? null : 'Observing',
          treasuryNotDefined: false,
          cargoNotDefined: false,
        ),
      ),
    ];
  }

  Future<void> pumpCounselScreen(
    WidgetTester tester, {
    required Game game,
    required AppEventBus bus,
    CounselTab initialTab = CounselTab.industry,
    CurrentOrdersNotifier? ordersNotifier,
    GameService? gameService,
    bool canMutateViaUi = true,
  }) async {
    final playerId = game.players.first.id;
    await pumpAppShell(
      tester,
      overrides: counselScreenOverrides(
        game: game,
        bus: bus,
        ordersNotifier: ordersNotifier,
        gameService: gameService,
        canMutateViaUi: canMutateViaUi,
      ),
      navigatorKey: appNavigatorKey,
      onGenerateRoute: Routes.generate,
      shellWrapper: (app) => AppEventHandlerScope(child: app),
      child: CounselScreen(
        game: game,
        humanPlayerId: playerId,
        initialTab: initialTab,
      ),
    );
    await pumpSettleCapped(tester);
  }

  testWidgets(
    'Counsel opens on Military tab with title and empty-state copy (Refs #4307)',
    (WidgetTester tester) async {
      final game = buildPanelTestGame();
      final bus = AppEventBus.create();

      await pumpCounselScreen(
        tester,
        game: game,
        bus: bus,
        initialTab: CounselTab.military,
      );

      expect(find.text('Counsel'), findsOneWidget);
      expect(find.text('Military'), findsOneWidget);
      expect(
        find.text('No pressing military advice this turn.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Military tab hides Agree when turn resolution blocks UI mutation (Refs #4307)',
    (WidgetTester tester) async {
      final game = buildPanelTestGame();
      final bus = AppEventBus.create();

      await pumpCounselScreen(
        tester,
        game: game,
        bus: bus,
        initialTab: CounselTab.military,
        canMutateViaUi: false,
      );

      expect(find.byType(CtNinePatchButton), findsNothing);
    },
  );

  Game buildTrainCounselScreenGame({required int peasants}) {
    const human = kPanelTestHumanPlayerId;
    const capProvince = 'oldWorld|cap';
    const unitType = 'peasant_levies';
    final econ = RegimentEconomyCatalog.byId[unitType]!;
    var stockpile = const Stockpile();
    for (final entry in econ.buildInputs.entries) {
      stockpile = stockpile.applyDelta(entry.key, entry.value * 4);
    }
    final techUnlocked = <String, bool>{
      for (final techId in unlockingTechByRegimentId.values) techId: true,
    };
    return buildPanelTestGame(
      id: _trainPanelGameId,
      players: [
        Player(
          id: human,
          displayName: 'Train GP',
          isHuman: true,
          capitalProvinceId: capProvince,
          capitalTile: const CapitalTile(
            regionId: 'oldWorld',
            provinceId: capProvince,
            x: 0,
            y: 0,
          ),
          treasury: econ.buildTreasuryCost * 4,
          workerPool: WorkerPool(peasants: peasants),
          stockpile: stockpile,
          techUnlocked: techUnlocked,
        ),
      ],
      oldWorldProvinces: const [
        Province(
          id: capProvince,
          regionId: 'oldWorld',
          ownerId: human,
          townTileKey: 'oldWorld|cap|0|0',
        ),
      ],
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          capProvince: ['oldWorld|cap|0|0'],
        },
      },
    );
  }

  testWidgets(
    'train Agree stages BuildUnitOrders when still affordable (Refs #4307)',
    (WidgetTester tester) async {
      const human = kPanelTestHumanPlayerId;
      const unitType = 'peasant_levies';
      final game = buildTrainCounselScreenGame(peasants: 2);
      final bus = AppEventBus.create();
      final snackbars = <ShowSnackBarEvent>[];
      bus.on<ShowSnackBarEvent>().listen(snackbars.add);
      final container = ProviderContainer(
        overrides: counselScreenOverrides(
          game: game,
          bus: bus,
          gameService: CounselMilitaryTrainMapGameService(
            gamesBox,
            GameSaveAdapter(),
          ),
        ),
      );
      addTearDown(container.dispose);

      await pumpAppShellWithContainer(
        tester,
        container: container,
        navigatorKey: appNavigatorKey,
        onGenerateRoute: Routes.generate,
        shellWrapper: (app) => AppEventHandlerScope(child: app),
        child: CounselScreen(
          game: game,
          humanPlayerId: human,
          initialTab: CounselTab.military,
        ),
      );
      await pumpSettleCapped(tester);

      expect(find.textContaining('Peasant Levies'), findsWidgets);
      expect(find.textContaining('peasant_levies'), findsNothing);

      final agree = find.byKey(
        ValueKey<String>('counsel_agree_military_train_$unitType'),
      );
      expect(agree, findsOneWidget);

      await tester.tap(agree);
      await pumpSettleCapped(tester);

      expect(snackbars, isEmpty);
      final builds =
          container.read(currentOrdersProvider).buildUnitOrdersByPlayerId[human] ??
          const [];
      expect(builds, isNotEmpty);
      expect(builds.every((o) => o.unitType == unitType), isTrue);
      expect(builds.every((o) => o.isMilitary), isTrue);
      expect(
        builds.every((o) => o.spawnProvinceId == 'oldWorld|cap'),
        isTrue,
      );
    },
  );

  testWidgets(
    'train Agree emits snackbar when recommendation is no longer affordable (Refs #4307)',
    (WidgetTester tester) async {
      const human = kPanelTestHumanPlayerId;
      const capProvince = 'oldWorld|cap';
      const unitType = 'peasant_levies';
      final game = buildTrainCounselScreenGame(peasants: 2);
      final bus = AppEventBus.create();
      final snackbars = <ShowSnackBarEvent>[];
      bus.on<ShowSnackBarEvent>().listen(snackbars.add);
      final ordersNotifier = CurrentOrdersNotifier(const Orders());

      await pumpCounselScreen(
        tester,
        game: game,
        bus: bus,
        ordersNotifier: ordersNotifier,
        gameService: CounselMilitaryTrainMapGameService(
          gamesBox,
          GameSaveAdapter(),
        ),
        initialTab: CounselTab.military,
      );

      final agree = find.byKey(
        ValueKey<String>('counsel_agree_military_train_$unitType'),
      );
      expect(agree, findsOneWidget);

      ordersNotifier.replaceAll(
        Orders(
          buildUnitOrdersByPlayerId: {
            human: [
              BuildUnitOrder(
                unitType: unitType,
                isMilitary: true,
                spawnProvinceId: capProvince,
              ),
              BuildUnitOrder(
                unitType: unitType,
                isMilitary: true,
                spawnProvinceId: capProvince,
              ),
            ],
          },
        ),
      );

      await tester.tap(agree);
      await pumpSettleCapped(tester);

      expect(snackbars, hasLength(1));
      expect(
        snackbars.single.message,
        'Cannot raise those units right now — check treasury, stockpile, peasants, and queued orders.',
      );
    },
  );
}
