import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/features/game/screens/development/development_panel_keys.dart';
import 'package:colonizethis_app/features/game/screens/development/development_screen_body.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_world/colonizethis_world.dart' show kRegionOldWorld;
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/foundation.dart' show kProfileMode, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:integration_test/integration_test.dart';

import '../test/app_shell_harness.dart';
import '../test/ct_region_map_test_support_core.dart';
import '../test/development_panel_test_support.dart';
import '../test/panel_fixtures/core.dart';

/// Profile/release open-to-interactive measurement for GAME80001 (Refs #4687).
///
/// Run on Linux desktop binding host:
/// `cd app && flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/development_panel_surface_open_profile_test.dart \
///   --profile -d linux`
void main() {
  suppressLogsForTests();
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openDevelopmentPanelTestHiveBox(
      suiteId: 'profile_surface_open',
    );
    await warmCtRegionMapCachesForTests();
  });

  tearDownAll(() async {
    await gamesBox.close();
  });

  testWidgets(
    'GAME80001 interactiveReady within 1s on profile/release Linux host',
    (WidgetTester tester) async {
      final game = buildDevelopmentPanelGoldenGame();
      final overrides = <Override>[
        gamesBoxProvider.overrideWith((ref) => gamesBox),
        gameServiceProvider.overrideWith(
          (ref) => DevelopmentPanelMapGameService(gamesBox, GameSaveAdapter()),
        ),
        currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
        currentOrdersProvider.overrideWith(
          () => CurrentOrdersNotifier(const Orders()),
        ),
      ];

      await tester.pumpWidget(
        buildAppShell(
          child: SizedBox(
            width: 900,
            height: 760,
            child: DevelopmentScreenBody(
              game: game,
              humanPlayerId: kPanelTestHumanPlayerId,
            ),
          ),
          overrides: overrides,
          localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
        ),
      );
      await pumpDevelopmentPanelReady(tester);

      expect(find.byKey(DevelopmentPanelKeys.overviewKey), findsOneWidget);
      expect(find.byKey(DevelopmentPanelKeys.scopeListKey), findsOneWidget);
      expect(
        find.byKey(DevelopmentPanelKeys.panelMapKeyForRegion(kRegionOldWorld)),
        findsOneWidget,
      );

      final elapsedMs = ctAppPerfSurfaceOpenElapsedMs('development');
      expect(elapsedMs, isNotNull);

      if (kProfileMode || kReleaseMode) {
        expect(
          elapsedMs!,
          lessThanOrEqualTo(kUiSurfaceOpenBudgetMs),
          reason:
              'GAME80001 open-to-interactive exceeded $kUiSurfaceOpenBudgetMs ms',
        );
      }
    },
  );

  testWidgets(
    'GAME80001 same-turn re-open interactiveReady within 1s on profile/release',
    (WidgetTester tester) async {
      final game = buildDevelopmentPanelGoldenGame();
      final overrides = <Override>[
        gamesBoxProvider.overrideWith((ref) => gamesBox),
        gameServiceProvider.overrideWith(
          (ref) => DevelopmentPanelMapGameService(gamesBox, GameSaveAdapter()),
        ),
        currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
        currentOrdersProvider.overrideWith(
          () => CurrentOrdersNotifier(const Orders()),
        ),
      ];

      Future<int?> openOnce() async {
        await tester.pumpWidget(
          buildAppShell(
            child: SizedBox(
              width: 900,
              height: 760,
              child: DevelopmentScreenBody(
                game: game,
                humanPlayerId: kPanelTestHumanPlayerId,
              ),
            ),
            overrides: overrides,
            localizationsDelegates:
                AppLocalizationsBinding.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
          ),
        );
        await pumpDevelopmentPanelReady(tester);
        expect(find.byKey(DevelopmentPanelKeys.overviewKey), findsOneWidget);
        return ctAppPerfSurfaceOpenElapsedMs('development');
      }

      await openOnce();

      await tester.pumpWidget(
        buildAppShell(
          child: const SizedBox.shrink(),
          overrides: overrides,
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
