// Development panel overview live-update on draft churn while panel stays open
// (Refs #4175 Slice E AC4).

import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/screens/development/development_screen_body.dart';
import 'package:colonizethis_app/features/game/widgets/shell/shell_player_context.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetBuildImprovement;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
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
    gamesBox = await openDevelopmentPanelTestHiveBox(suiteId: 'assign_live');
  });

  tearDownAll(() async {
    await gamesBox.close();
  });

  testWidgets(
    'overview live-updates idle and assigned rows when drafts change with panel open (Refs #4175 Slice E)',
    (WidgetTester tester) async {
      final game = buildDevelopmentPanelGoldenGame();
      final ordersNotifier = CurrentOrdersNotifier(const Orders());
      final container = ProviderContainer(
        overrides: [
          gamesBoxProvider.overrideWith((ref) => gamesBox),
          gameServiceProvider.overrideWith(
            (ref) => DevelopmentPanelMapGameService(gamesBox, GameSaveAdapter()),
          ),
          currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
          currentOrdersProvider.overrideWith(() => ordersNotifier),
          shellPlayerContextProvider.overrideWithValue(
            const ShellPlayerContext(
              effectiveHumanPlayerId: kPanelTestHumanPlayerId,
              viewingPlayerId: kPanelTestHumanPlayerId,
              mapVisibilityMode: CtMapVisibilityMode.playerConstrained,
              playerView: null,
              omniscientDetail: false,
              showPlayerChrome: true,
              canMutateViaUi: true,
              debugCommandTargetPlayerId: kPanelTestHumanPlayerId,
              inObservePhase: false,
              observeBannerLabel: null,
              treasuryNotDefined: false,
              cargoNotDefined: false,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildAppShellWithContainer(
          container: container,
          child: SizedBox(
            width: 900,
            height: 760,
            child: DevelopmentScreenBody(
              game: game,
              humanPlayerId: kPanelTestHumanPlayerId,
            ),
          ),
          localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
        ),
      );

      await pumpDevelopmentPanelReady(tester);

      expect(find.textContaining('Idle Builders: 1'), findsOneWidget);
      expect(find.textContaining('ASSIGNED CIVILIANS'), findsNothing);

      ordersNotifier.state = Orders(
        workOrdersByPlayerId: {
          kPanelTestHumanPlayerId: const [
            WorkOrder(
              unitId: 'b1',
              target: kWorkTargetBuildImprovement,
              targetTileKey: 'oldWorld|p1|0|0',
            ),
          ],
        },
      );
      await tester.pump();

      expect(find.textContaining('Idle Builders: 0'), findsOneWidget);
      expect(find.textContaining('ASSIGNED CIVILIANS'), findsOneWidget);
      expect(find.textContaining('Build improvement'), findsOneWidget);
    },
  );
}
