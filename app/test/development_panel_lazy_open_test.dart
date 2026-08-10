// Lazy region open-path tests for Development panel (Refs #4175 Slice E).

import 'package:colonizethis_app/features/game/screens/development/development_panel_keys.dart';
import 'package:colonizethis_app/features/game/screens/development/development_screen_body.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'development_panel_test_support.dart';
import 'panel_fixtures/core.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openDevelopmentPanelTestHiveBox();
  });

  tearDownAll(() async {
    await gamesBox.close();
  });

  _developmentOverrides(Game game) => [
    gamesBoxProvider.overrideWith((ref) => gamesBox),
    gameServiceProvider.overrideWith(
      (ref) => DevelopmentPanelMapGameService(gamesBox, GameSaveAdapter()),
    ),
    currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
    currentOrdersProvider.overrideWith(() => CurrentOrdersNotifier(const Orders())),
  ];

  Widget _bodyHost(Game game) => SizedBox(
    width: 900,
    height: 760,
    child: DevelopmentScreenBody(
      game: game,
      humanPlayerId: kPanelTestHumanPlayerId,
    ),
  );

  testWidgets(
    'first frame builds Old World map only when New World tab is unvisited (Refs #4175 Slice E)',
    (WidgetTester tester) async {
      final game = buildDevelopmentPanelGoldenGame();
      await pumpAppShell(
        tester,
        child: _bodyHost(game),
        overrides: _developmentOverrides(game),
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
      );

      expect(
        find.byKey(DevelopmentPanelKeys.panelMapKeyForRegion(kRegionOldWorld)),
        findsOneWidget,
      );
      expect(
        find.byKey(DevelopmentPanelKeys.panelMapKeyForRegion(kRegionNewWorld)),
        findsNothing,
      );
    },
  );

  testWidgets(
    'selecting New World tab builds New World map on first visit (Refs #4175 Slice E)',
    (WidgetTester tester) async {
      final game = buildDevelopmentPanelGoldenGame();
      await pumpAppShell(
        tester,
        child: _bodyHost(game),
        overrides: _developmentOverrides(game),
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
      );

      await tester.tap(find.text('New World'));
      await tester.pump();

      expect(
        find.byKey(DevelopmentPanelKeys.panelMapKeyForRegion(kRegionNewWorld)),
        findsOneWidget,
      );
    },
  );
}
