// Development inbound feedstock highlight. SPEC/ui/development-panel.md Refs #4725.

import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/screens/development/development_inbound_highlight.dart';
import 'package:colonizethis_app/features/game/screens/development/development_screen.dart';
import 'package:colonizethis_app/features/game/screens/development/development_screen_body.dart';
import 'package:colonizethis_app/features/game/widgets/shell/shell_player_context.dart';
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
    gamesBox = await openDevelopmentPanelTestHiveBox(suiteId: 'inbound_highlight');
  });

  tearDownAll(() async {
    await gamesBox.close();
  });

  Future<void> pumpDevelopmentBody({
    required WidgetTester tester,
    required Game game,
    String? highlightCommodityId,
    String? highlightTileKey,
    bool canMutateViaUi = true,
  }) async {
    const playerId = kPanelTestHumanPlayerId;
    final shell = ShellPlayerContext(
      effectiveHumanPlayerId: playerId,
      viewingPlayerId: playerId,
      mapVisibilityMode: CtMapVisibilityMode.playerConstrained,
      playerView: null,
      omniscientDetail: false,
      showPlayerChrome: true,
      canMutateViaUi: canMutateViaUi,
      debugCommandTargetPlayerId: playerId,
      inObservePhase: !canMutateViaUi,
      observeBannerLabel: canMutateViaUi ? null : 'Observing',
      treasuryNotDefined: false,
      cargoNotDefined: false,
    );
    await pumpAppShell(
      tester,
      child: SizedBox(
        width: 900,
        height: 760,
        child: DevelopmentScreenBody(
          game: game,
          humanPlayerId: playerId,
          highlightCommodityId: highlightCommodityId,
          highlightTileKey: highlightTileKey,
        ),
      ),
      overrides: [
        gamesBoxProvider.overrideWith((ref) => gamesBox),
        currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
        currentOrdersProvider.overrideWith(
          () => CurrentOrdersNotifier(const Orders()),
        ),
        shellPlayerContextProvider.overrideWithValue(shell),
        gameServiceProvider.overrideWith(
          (ref) => DevelopmentPanelMapGameService(
            gamesBox,
            GameSaveAdapter(),
          ),
        ),
      ],
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      viewport: const Size(900, 760),
    );
    await pumpDevelopmentPanelReady(tester);
    await pumpSettleCapped(tester);
  }

  testWidgets(
    'inbound highlightCommodityId paints Show chrome and does not Assign',
    (tester) async {
      final game = buildDevelopmentPanelGoldenGame();
      await pumpDevelopmentBody(
        tester: tester,
        game: game,
        highlightCommodityId: 'grain',
        highlightTileKey: 'oldWorld|p1|0|0',
      );

      expect(DevelopmentScreen.screenId, UiScreenIds.developmentScreen);
      expect(
        find.byKey(DevelopmentInboundCommodityHighlight.highlightKey('grain')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('development_inbound_no_match_banner')),
        findsNothing,
      );
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets('inbound miss shows named empty copy and stages no order', (
    tester,
  ) async {
    final game = buildDevelopmentPanelGoldenGame();
    await pumpDevelopmentBody(
      tester: tester,
      game: game,
      highlightCommodityId: 'timber',
    );

    expect(
      find.byKey(const ValueKey<String>('development_inbound_no_match_banner')),
      findsOneWidget,
    );
    expect(find.textContaining('Timber'), findsOneWidget);
    expect(
      find.byKey(DevelopmentInboundCommodityHighlight.highlightKey('timber')),
      findsNothing,
    );
  });

  testWidgets('observe mode still lands inbound highlight read-only', (
    tester,
  ) async {
    final game = buildDevelopmentPanelGoldenGame();
    await pumpDevelopmentBody(
      tester: tester,
      game: game,
      highlightCommodityId: 'grain',
      canMutateViaUi: false,
    );

    expect(
      find.byKey(DevelopmentInboundCommodityHighlight.highlightKey('grain')),
      findsOneWidget,
    );
  });
}
