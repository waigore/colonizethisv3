// UI path bleed isolation for session clear. SPEC/program/save-load-session-clear.md.
import 'dart:io';

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/shell/save_load/load_game_list_dialog.dart';
import 'package:colonizethis_app/features/shell/shell_screen.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/widgets/main_menu.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'app_test_hive_harness.dart';
import 'game_session_clear_ui_path_support.dart';

void main() {
  suppressLogsForTests();

  late Directory hiveDir;
  late Box<dynamic> gamesBox;
  late ProviderContainer container;
  late AppEventBus bus;
  late UiPathGameService service;

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('ct_session_clear_ui_');
    gamesBox = await openAppTestHiveBox(
      suiteId: 'game_session_clear_ui_path',
      directory: hiveDir,
    );
    AppEventBus.reset();
    bus = AppEventBus.create();
    service = UiPathGameService(gamesBox, GameSaveAdapter());
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

  testWidgets(
    'Load Game dialog path: pre-dirty A then select B yields B-only session',
    (tester) async {
      uiPathDirtySessionA(container);
      service.sessionToLoad = uiPathSessionB(
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
        buildAppShellWithContainer(
          container: container,
          localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          child: const Scaffold(
            body: LoadGameListDialog(fromPause: false),
          ),
        ),
      );
      await uiPathPumpFrames(tester);

      await tester.tap(find.byKey(LoadGameListDialog.rowKey('save_b')));
      await uiPathPumpFrames(tester);

      uiPathExpectSessionBProviders(
        container,
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
      uiPathDirtySessionA(container);
      service.sessionToLoad = uiPathSessionB(
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
        buildAppShellWithContainer(
          container: container,
          localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          child: const Scaffold(
            body: LoadGameListDialog(fromPause: true),
          ),
        ),
      );
      await uiPathPumpFrames(tester);

      await tester.tap(find.byKey(LoadGameListDialog.rowKey('save_b')));
      await uiPathPumpFrames(tester);
      expect(find.byKey(LoadGameListDialog.discardConfirmKey), findsOneWidget);

      await tester.tap(find.byKey(LoadGameListDialog.discardConfirmButtonKey));
      await uiPathPumpFrames(tester);

      uiPathExpectSessionBProviders(
        container,
        gameId: 'save_b',
        unitType: 'miner',
        desired: const {'coal': 3},
      );
      expect(events.whereType<ClosePanelEvent>(), isNotEmpty);
    },
  );

  testWidgets(
    'Resume path: pre-dirty session then resume auto-save yields envelope only',
    (tester) async {
      uiPathDirtySessionA(container);
      service.sessionToLoad = uiPathSessionB(
        id: 'auto_game',
        unitType: 'miner',
        desired: const {'iron': 7},
      );
      service.autoSaveValid = true;

      final events = <AppEvent>[];
      final sub = bus.stream.listen(events.add);
      addTearDown(sub.cancel);

      await tester.pumpWidget(
        buildAppShellWithContainer(
          container: container,
          localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          child: const ShellScreen(),
        ),
      );
      await uiPathPumpFrames(tester, count: 24);

      final menu = tester.widget<CtMainMenu>(find.byType(CtMainMenu));
      expect(menu.resumeGameVisible, isTrue);
      expect(menu.onResumeGame, isNotNull);
      menu.onResumeGame!();
      await uiPathPumpFrames(tester);

      uiPathExpectSessionBProviders(
        container,
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
