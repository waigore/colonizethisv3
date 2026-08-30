// Development header Counsel entry to GAME90001 Development tab.
// SPEC/ui/development-panel.md; SPEC/ui/counsel-panel.md (Refs #4332).

import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/screens/development/development_panel_keys.dart';
import 'package:colonizethis_app/features/game/screens/development/development_screen.dart';
import 'package:colonizethis_app/features/game/widgets/shell/shell_player_context.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'development_panel_test_support.dart';
import 'panel_fixtures/core.dart';
import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openDevelopmentPanelTestHiveBox(suiteId: 'counsel_entry');
  });

  tearDownAll(() async {
    await gamesBox.close();
  });

  testWidgets(
    'header Counsel emits NavigateToRouteEvent for Development tab on GAME90001',
    (WidgetTester tester) async {
      const playerId = kPanelTestHumanPlayerId;
      final game = buildDevelopmentPanelGoldenGame();
      final bus = AppEventBus.create();
      NavigateToRouteEvent? navigateEvent;
      bus.on<NavigateToRouteEvent>().listen((event) {
        navigateEvent = event;
      });

      await pumpAppShell(
        tester,
        child: DevelopmentScreen(
          game: game,
          humanPlayerId: playerId,
        ),
        overrides: [
          gamesBoxProvider.overrideWith((ref) => gamesBox),
          gameServiceProvider.overrideWith(
            (ref) => DevelopmentPanelMapGameService(gamesBox, GameSaveAdapter()),
          ),
          currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
          currentOrdersProvider.overrideWith(
            () => CurrentOrdersNotifier(const Orders()),
          ),
          appEventBusProvider.overrideWith((ref) => bus),
          shellPlayerContextProvider.overrideWithValue(
            const ShellPlayerContext(
              effectiveHumanPlayerId: playerId,
              viewingPlayerId: playerId,
              mapVisibilityMode: CtMapVisibilityMode.playerConstrained,
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
        ],
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        viewport: const Size(900, 760),
      );

      expect(DevelopmentScreen.screenId, UiScreenIds.developmentScreen);
      await tester.tap(find.byKey(DevelopmentPanelKeys.counselButtonKey));
      await pumpSettleCapped(tester);

      expect(navigateEvent, isNotNull);
      expect(navigateEvent!.route, Routes.counsel);
      final args = navigateEvent!.arguments as Map<String, Object?>?;
      expect(args?['counselTab'], 'development');
      expect(args?['humanPlayerId'], playerId);
      expect(args?['game'], isA<Game>());

      // Allow DevelopmentShellMapPauseScope post-frame release while the
      // ProviderScope from pumpAppShell is still mounted (Refs #4687).
      await pumpAppShell(
        tester,
        child: const SizedBox.shrink(),
        overrides: [
          gamesBoxProvider.overrideWith((ref) => gamesBox),
          gameServiceProvider.overrideWith(
            (ref) => DevelopmentPanelMapGameService(gamesBox, GameSaveAdapter()),
          ),
          currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
          currentOrdersProvider.overrideWith(
            () => CurrentOrdersNotifier(const Orders()),
          ),
          appEventBusProvider.overrideWith((ref) => bus),
          shellPlayerContextProvider.overrideWithValue(
            const ShellPlayerContext(
              effectiveHumanPlayerId: playerId,
              viewingPlayerId: playerId,
              mapVisibilityMode: CtMapVisibilityMode.playerConstrained,
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
        ],
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        viewport: const Size(900, 760),
      );
      await pumpSyncFrames(tester);
    },
  );
}
