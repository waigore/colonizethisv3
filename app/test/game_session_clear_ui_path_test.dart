// UI path bleed isolation for session clear. SPEC/program/save-load-session-clear.md.
// Refs #3989: Load Game dialog, Resume, Load from pause — provider asserts post-load
// (uses a load/list fake so createNewGame is not required under testWidgets).

import 'dart:io';

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/shell/save_load/load_game_list_dialog.dart';
import 'package:colonizethis_app/features/shell/shell_screen.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/offline_queue_provider.dart';
import 'package:colonizethis_app/providers/production_allocation_provider.dart';
import 'package:colonizethis_app/widgets/main_menu.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'app_test_hive_harness.dart';

class _UiPathGameService extends GameService {
  _UiPathGameService(super.box, super.adapter);

  GameSaveSession? sessionToLoad;
  List<LoadableSaveEntry> entries = const [];
  bool autoSaveValid = false;

  @override
  List<LoadableSaveEntry> listLoadableSaves() => entries;

  @override
  bool hasValidAutoSave() => autoSaveValid;

  @override
  GameSaveSession? loadGameSession(String gameId) =>
      sessionToLoad != null && sessionToLoad!.game.id == gameId
      ? sessionToLoad
      : null;

  @override
  GameSaveSession? loadAutoSaveSession() =>
      autoSaveValid ? sessionToLoad : null;
}

Orders _draftOrders({required String unitType}) => Orders(
  buildUnitOrdersByPlayerId: {
    'england': [
      BuildUnitOrder(
        unitType: unitType,
        isMilitary: false,
        spawnProvinceId: 'oldWorld|p0',
      ),
    ],
  },
);

GameSaveSession _sessionB({
  required String id,
  required String unitType,
  required Map<String, int> desired,
}) {
  return GameSaveSession(
    game: Game(
      id: id,
      worldState: const WorldState(
        turnState: TurnState(phase: TurnPhase.orders, turnNumber: 3),
        oldWorld: RegionData(),
        newWorld: RegionData(),
      ),
      players: const [
        Player(id: 'england', displayName: 'England', isHuman: true),
      ],
    ),
    draftOrders: _draftOrders(unitType: unitType),
    productionDesiredOutputByRecipe: desired,
    displayName: 'Save $id',
  );
}

void main() {
  suppressLogsForTests();

  late Directory hiveDir;
  late Box<dynamic> gamesBox;
  late ProviderContainer container;
  late AppEventBus bus;
  late _UiPathGameService service;

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('ct_session_clear_ui_');
    gamesBox = await openAppTestHiveBox(suiteId: 'game_session_clear_ui_path', directory: hiveDir);
    AppEventBus.reset();
    bus = AppEventBus.create();
    service = _UiPathGameService(gamesBox, GameSaveAdapter());
    container = ProviderContainer(
      overrides: [
        gamesBoxProvider.overrideWithValue(gamesBox),
        appEventBusProvider.overrideWithValue(bus),
        gameServiceProvider.overrideWith((ref) => service),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    bus.dispose();
    AppEventBus.reset();
    await gamesBox.clear();
    await gamesBox.close();
    await Hive.close();
    await hiveDir.delete(recursive: true);
  });

  Future<void> pumpFrames(WidgetTester tester, {int count = 8}) async {
    for (var i = 0; i < count; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  void dirtyA() {
    final gameA = Game(
      id: 'save_a',
      worldState: const WorldState(
        turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(),
        newWorld: RegionData(),
      ),
      players: const [
        Player(id: 'england', displayName: 'England', isHuman: true),
      ],
    );
    container.read(currentGameProvider.notifier).setGame(gameA);
    container
        .read(currentOrdersProvider.notifier)
        .replaceAll(_draftOrders(unitType: 'farmer'));
    container
        .read(productionDesiredOutputProvider.notifier)
        .replaceAll(const {'grain': 9});
    container.read(tribeFirstContactHeraldQueueProvider.notifier).enqueue(
      const TribeFirstContactHeraldPayload(
        tribeId: 'tribe_from_a',
        tribeName: 'From A',
        capitalName: 'A Cap',
      ),
    );
    container.read(pendingDiplomacyProvider.notifier).setOvertures(const [
      OvertureOffer(
        offererGpId: 'england',
        targetFactionId: 'from_a',
        stage: OvertureStage.embassy,
      ),
    ]);
    container
        .read(tribeFirstContactHeraldsShownProvider.notifier)
        .markShown(gameA.id, 'tribe_from_a');
    container.read(gameIdsWithIntroShownProvider.notifier).markShown(gameA.id);
    container.read(offlineQueueProvider.notifier).enqueueAll([Object()]);
  }

  void expectBProviders({
    required String gameId,
    required String unitType,
    required Map<String, int> desired,
  }) {
    expect(container.read(currentGameProvider)?.id, gameId);
    expect(
      container
          .read(currentOrdersProvider)
          .buildUnitOrdersByPlayerId['england']!
          .single
          .unitType,
      unitType,
    );
    expect(container.read(productionDesiredOutputProvider), desired);
    expect(container.read(tribeFirstContactHeraldQueueProvider), isEmpty);
    expect(container.read(pendingDiplomacyProvider), isNull);
    expect(container.read(tribeFirstContactHeraldsShownProvider), isEmpty);
    expect(container.read(gameIdsWithIntroShownProvider), isEmpty);
    expect(container.read(offlineQueueProvider), isEmpty);
  }

  testWidgets(
    'Load Game dialog path: pre-dirty A then select B yields B-only session',
    (tester) async {
      dirtyA();
      service.sessionToLoad = _sessionB(
        id: 'save_b',
        unitType: 'miner',
        desired: const {'iron': 1},
      );
      service.entries = [
        const LoadableSaveEntry(
          storageId: 'save_b',
          label: 'Save B',
          kind: LoadableSaveKind.manual,
          turnNumber: 3,
        ),
      ];

      final events = <AppEvent>[];
      final sub = bus.stream.listen(events.add);
      addTearDown(sub.cancel);

      await tester.pumpWidget(
        // Editorial shell via buildAppShellWithContainer (Refs #4035).
        buildAppShellWithContainer(
          container: container,
          localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          child: const Scaffold(
            body: LoadGameListDialog(fromPause: false),
          ),
        ),
      );
      await pumpFrames(tester);

      await tester.tap(find.byKey(LoadGameListDialog.rowKey('save_b')));
      await pumpFrames(tester);

      expectBProviders(
        gameId: 'save_b',
        unitType: 'miner',
        desired: const {'iron': 1},
      );
      expect(
        events.whereType<NavigateToRouteEvent>().single.route,
        Routes.game,
      );
    },
  );

  testWidgets(
    'Load from pause path: dirty A then confirm B emits ClosePanel and isolates',
    (tester) async {
      dirtyA();
      service.sessionToLoad = _sessionB(
        id: 'save_b',
        unitType: 'miner',
        desired: const {'coal': 3},
      );
      service.entries = [
        const LoadableSaveEntry(
          storageId: 'save_b',
          label: 'Save B',
          kind: LoadableSaveKind.manual,
          turnNumber: 3,
        ),
      ];

      final events = <AppEvent>[];
      final sub = bus.stream.listen(events.add);
      addTearDown(sub.cancel);

      await tester.pumpWidget(
        // Editorial shell via buildAppShellWithContainer (Refs #4035).
        buildAppShellWithContainer(
          container: container,
          localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          child: const Scaffold(
            body: LoadGameListDialog(fromPause: true),
          ),
        ),
      );
      await pumpFrames(tester);

      await tester.tap(find.byKey(LoadGameListDialog.rowKey('save_b')));
      await pumpFrames(tester);
      expect(find.byKey(LoadGameListDialog.discardConfirmKey), findsOneWidget);

      await tester.tap(find.byKey(LoadGameListDialog.discardConfirmButtonKey));
      await pumpFrames(tester);

      expectBProviders(
        gameId: 'save_b',
        unitType: 'miner',
        desired: const {'coal': 3},
      );
      expect(events.whereType<ClosePanelEvent>(), isNotEmpty);
      // Dialog is mounted as shell home (not a pushed route), so pop may
      // leave the widget mounted — ClosePanel + provider isolation is the AC.
    },
  );

  testWidgets(
    'Resume path: pre-dirty session then resume auto-save yields envelope only',
    (tester) async {
      dirtyA();
      service.sessionToLoad = _sessionB(
        id: 'auto_game',
        unitType: 'miner',
        desired: const {'iron': 7},
      );
      service.autoSaveValid = true;

      final events = <AppEvent>[];
      final sub = bus.stream.listen(events.add);
      addTearDown(sub.cancel);

      await tester.pumpWidget(
        // Editorial shell via buildAppShellWithContainer (Refs #4035).
        buildAppShellWithContainer(
          container: container,
          localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          child: const ShellScreen(),
        ),
      );
      await pumpFrames(tester, count: 24);

      final menu = tester.widget<CtMainMenu>(find.byType(CtMainMenu));
      expect(menu.resumeGameVisible, isTrue);
      expect(menu.onResumeGame, isNotNull);
      menu.onResumeGame!();
      await pumpFrames(tester);

      expectBProviders(
        gameId: 'auto_game',
        unitType: 'miner',
        desired: const {'iron': 7},
      );
      expect(
        events.whereType<NavigateToRouteEvent>().single.route,
        Routes.game,
      );
    },
  );
}
