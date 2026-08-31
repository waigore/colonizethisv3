import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/screens/counsel/counsel_screen.dart';
import 'package:colonizethis_app/features/game/widgets/shell/shell_player_context.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
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
import '../test/widget_test_pumps.dart';

/// Profile/release open-to-interactive measurement for GAME90001 (Refs #4688).
///
/// **Linux desktop binding host:**
/// `cd app && xvfb-run -a flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/counsel_panel_surface_open_profile_test.dart \
///   --profile -d linux`
///
/// **Android emulator binding host:**
/// `cd app && flutter emulators --launch <avd_name>`
/// `flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/counsel_panel_surface_open_profile_test.dart \
///   --profile -d <emulator_device_id>`
///
/// Attach `ui_surface_open surface=counsel … host=linux_desktop_profile` or
/// `host=android_emulator_profile` from drive output / logcat for PR evidence.
void main() {
  suppressLogsForTests();
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(suiteId: 'counsel_profile_surface_open');
  });

  tearDownAll(() async {
    await gamesBox.close();
  });

  List<Override> overrides(Game game, AppEventBus bus) {
    final playerId = game.players.first.id;
    return [
      gamesBoxProvider.overrideWith((ref) => gamesBox),
      gameServiceProvider.overrideWith(
        (ref) => GameService(gamesBox, GameSaveAdapter()),
      ),
      currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
      currentOrdersProvider.overrideWith(
        () => CurrentOrdersNotifier(const Orders()),
      ),
      appEventBusProvider.overrideWith((ref) {
        ref.onDispose(bus.dispose);
        return bus;
      }),
      shellPlayerContextProvider.overrideWithValue(
        ShellPlayerContext(
          effectiveHumanPlayerId: playerId,
          viewingPlayerId: playerId,
          mapVisibilityMode: CtMapVisibilityMode.full,
          playerView: null,
          omniscientDetail: false,
          showPlayerChrome: true,
          canMutateViaUi: true,
          debugCommandTargetPlayerId: playerId,
          inObservePhase: false,
          observeBannerLabel: null,
          treasuryNotDefined: false,
          cargoNotDefined: false,
        ),
      ),
    ];
  }

  Future<void> mountCounsel(WidgetTester tester, {required Game game}) async {
    final bus = AppEventBus.create();
    await pumpAppShell(
      tester,
      overrides: overrides(game, bus),
      navigatorKey: appNavigatorKey,
      onGenerateRoute: Routes.generate,
      shellWrapper: (app) => AppEventHandlerScope(child: app),
      child: CounselScreen(
        game: game,
        humanPlayerId: game.players.first.id,
      ),
    );
    await pumpSettleCapped(tester);
  }

  testWidgets(
    'GAME90001 interactiveReady within 1s on profile/release binding host',
    (WidgetTester tester) async {
      final game = buildPanelTestGame();

      await mountCounsel(tester, game: game);

      expect(find.text('Counsel'), findsOneWidget);

      final elapsedMs = ctAppPerfSurfaceOpenElapsedMs('counsel');
      expect(elapsedMs, isNotNull);

      if (kProfileMode || kReleaseMode) {
        expect(
          elapsedMs!,
          lessThanOrEqualTo(kUiSurfaceOpenBudgetMs),
          reason:
              'GAME90001 open-to-interactive exceeded $kUiSurfaceOpenBudgetMs ms',
        );
      }
    },
  );

  testWidgets(
    'GAME90001 same-turn re-open interactiveReady within 1s on profile/release',
    (WidgetTester tester) async {
      final game = buildPanelTestGame();
      final bus = AppEventBus.create();
      final panelOverrides = overrides(game, bus);

      Future<int?> openOnce() async {
        await mountCounsel(tester, game: game);
        expect(find.text('Counsel'), findsOneWidget);
        return ctAppPerfSurfaceOpenElapsedMs('counsel');
      }

      await openOnce();

      await pumpAppShell(
        tester,
        overrides: panelOverrides,
        navigatorKey: appNavigatorKey,
        onGenerateRoute: Routes.generate,
        shellWrapper: (app) => AppEventHandlerScope(child: app),
        child: const SizedBox.shrink(),
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
