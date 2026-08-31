import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/features/game/screens/production/production_screen.dart';
import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/foundation.dart' show kProfileMode, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:integration_test/integration_test.dart';

import '../test/app_shell_harness.dart';
import '../test/app_test_hive_harness.dart';
import '../test/development_panel_test_support.dart';
import '../test/empire_rail_panel_open_surface_budget_support.dart';
import '../test/panel_test_fixtures.dart';
import '../test/widget_test_pumps.dart';

/// Profile/release open-to-interactive measurement for GAME20001 (Refs #4688).
///
/// **Linux desktop binding host:**
/// `cd app && xvfb-run -a flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/production_panel_surface_open_profile_test.dart \
///   --profile -d linux`
///
/// **Android emulator binding host:**
/// `cd app && flutter emulators --launch <avd_name>`
/// `flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/production_panel_surface_open_profile_test.dart \
/// `flutter drive … --profile -d emulator_device_id`
///
/// Attach `ui_surface_open surface=production … host=linux_desktop_profile` or
/// `host=android_emulator_profile` from drive output / logcat for PR evidence.
void main() {
  suppressLogsForTests();
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(suiteId: 'production_profile_surface_open');
  });

  tearDownAll(() async {
    await gamesBox.close();
  });

  List<Override> overrides(Game game) => productionPanelOverrides(game, gamesBox);

  testWidgets(
    'GAME20001 interactiveReady within 1s on profile/release binding host',
    (WidgetTester tester) async {
      final game = buildDevelopmentPanelGoldenGame();
      final player = game.playerById(kPanelTestHumanPlayerId)!;

      await tester.pumpWidget(
        buildAppShell(
          child: SizedBox(
            width: 900,
            height: 760,
            child: ProductionScreen(
              game: game,
              player: player,
              attachGameToUiListener: false,
            ),
          ),
          overrides: overrides(game),
          localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
        ),
      );
      await pumpSettleCapped(tester);

      expect(find.text('Available'), findsOneWidget);

      final elapsedMs = ctAppPerfSurfaceOpenElapsedMs('production');
      expect(elapsedMs, isNotNull);

      if (kProfileMode || kReleaseMode) {
        expect(
          elapsedMs!,
          lessThanOrEqualTo(kUiSurfaceOpenBudgetMs),
          reason:
              'GAME20001 open-to-interactive exceeded $kUiSurfaceOpenBudgetMs ms',
        );
      }
    },
  );

  testWidgets(
    'GAME20001 same-turn re-open interactiveReady within 1s on profile/release',
    (WidgetTester tester) async {
      final game = buildDevelopmentPanelGoldenGame();
      final player = game.playerById(kPanelTestHumanPlayerId)!;
      final panelOverrides = overrides(game);

      Future<int?> openOnce() async {
        await tester.pumpWidget(
          buildAppShell(
            child: SizedBox(
              width: 900,
              height: 760,
              child: ProductionScreen(
                game: game,
                player: player,
                attachGameToUiListener: false,
              ),
            ),
            overrides: panelOverrides,
            localizationsDelegates:
                AppLocalizationsBinding.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
          ),
        );
        await pumpSettleCapped(tester);
        expect(find.text('Available'), findsOneWidget);
        return ctAppPerfSurfaceOpenElapsedMs('production');
      }

      await openOnce();

      await tester.pumpWidget(
        buildAppShell(
          child: const SizedBox.shrink(),
          overrides: panelOverrides,
          localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
        ),
      );
      await tester.pump();

      final warmMs = await openOnce();
      expect(warmMs, isNotNull);
      if (kProfileMode || kReleaseMode) {
        expect(
          warmMs!,
          lessThanOrEqualTo(kUiSurfaceOpenBudgetMs),
        );
      }
    },
  );
}
