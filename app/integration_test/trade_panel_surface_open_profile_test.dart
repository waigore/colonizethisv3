import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_app/features/game/screens/trade/trade_screen_contract_market.dart';
import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/foundation.dart' show kProfileMode, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:integration_test/integration_test.dart';

import '../test/app_shell_harness.dart';
import '../test/app_test_hive_harness.dart';
import '../test/panel_test_fixtures.dart';
import '../test/trade_screen_scaffold_test_support.dart';
import '../test/widget_test_pumps.dart';

/// Profile/release open-to-interactive measurement for GAME60001 (Refs #4688).
///
/// Run on Linux desktop binding host:
/// `cd app && flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/trade_panel_surface_open_profile_test.dart \
///   --profile -d linux`
void main() {
  suppressLogsForTests();
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(suiteId: 'trade_profile_surface_open');
  });

  tearDownAll(() async {
    await gamesBox.close();
  });

  List<Override> overrides(Game game) => tradeScaffoldBaseOverrides(
        game: game,
        gamesBox: gamesBox,
      );

  testWidgets(
    'GAME60001 interactiveReady within 1s on profile/release Linux host',
    (WidgetTester tester) async {
      final game = buildTradePanelTestGame();
      final player = game.players.first;

      await tester.pumpWidget(
        buildAppShell(
          child: SizedBox(
            width: 900,
            height: 760,
            child: TradeScreen(game: game, player: player),
          ),
          overrides: overrides(game),
          localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
        ),
      );
      await pumpSettleCapped(tester);

      expect(find.byKey(TradeScreenMarketKeys.marketTabBodyKey), findsOneWidget);

      final elapsedMs = ctAppPerfSurfaceOpenElapsedMs('trade');
      expect(elapsedMs, isNotNull);

      if (kProfileMode || kReleaseMode) {
        expect(
          elapsedMs!,
          lessThanOrEqualTo(kUiSurfaceOpenBudgetMs),
          reason:
              'GAME60001 open-to-interactive exceeded $kUiSurfaceOpenBudgetMs ms',
        );
      }
    },
  );

  testWidgets(
    'GAME60001 same-turn re-open interactiveReady within 1s on profile/release',
    (WidgetTester tester) async {
      final game = buildTradePanelTestGame();
      final player = game.players.first;
      final panelOverrides = overrides(game);

      Future<int?> openOnce() async {
        await tester.pumpWidget(
          buildAppShell(
            child: SizedBox(
              width: 900,
              height: 760,
              child: TradeScreen(game: game, player: player),
            ),
            overrides: panelOverrides,
            localizationsDelegates:
                AppLocalizationsBinding.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
          ),
        );
        await pumpSettleCapped(tester);
        expect(find.byKey(TradeScreenMarketKeys.marketTabBodyKey), findsOneWidget);
        return ctAppPerfSurfaceOpenElapsedMs('trade');
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
