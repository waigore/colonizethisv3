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
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'panel_fixtures/core.dart';
import 'widget_test_pumps.dart';

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
    bool canMutateViaUi = true,
  }) {
    final playerId = game.players.first.id;
    return [
      gamesBoxProvider.overrideWith((ref) => gamesBox),
      gameServiceProvider.overrideWith(
        (ref) => GameService(gamesBox, GameSaveAdapter()),
      ),
      currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
      currentOrdersProvider.overrideWith(
        () => CurrentOrdersNotifier(initialOrders),
      ),
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
    bool canMutateViaUi = true,
  }) async {
    final playerId = game.players.first.id;
    await pumpAppShell(
      tester,
      overrides: counselScreenOverrides(
        game: game,
        bus: bus,
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
}
