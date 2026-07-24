import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'game_screen_test_support.dart';
import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_game_screen_overture');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  testWidgets('GameScreen shows OvertureDialogueOverlay for pending overtures',
      (WidgetTester tester) async {
    // Refs #3656: the pending-overture overlay is GameScreen chrome driven by
    // `pendingDiplomacyProvider`, not generated map/topology data, so this pin
    // pumps GameScreen with the shared lightweight fixture and
    // `mapViewDataProvider` overridden to null (no map canvas mounted) instead
    // of the ~7-11s `getDebugInitGameResult()` map generator.
    final game = buildGameScreenSpecsTestGame();

    final pending = <OvertureOffer>[
      // Use the first player as offerer (and an invented id for target).
      OvertureOffer(
        offererGpId: game.players.first.id,
        targetFactionId: 'gp_target',
        stage: OvertureStage.embassy,
      ),
    ];

    await tester.pumpWidget(
      buildGameScreenHost(
        gamesBox: gamesBox,
        game: game,
        mapViewData: null,
        width: 900,
        height: 700,
        wrapAppEventHandler: false,
        includeHomeFleetCargo: false,
        includeTreasury: false,
        extraOverrides: [
          pendingDiplomacyProvider.overrideWith(
            () => PendingDiplomacyNotifier(
              PendingDiplomacyOvertures(pending),
            ),
          ),
        ],
      ),
    );

    // Jenny intro: pump/tap Continue until the offer list is shown.
    for (var i = 0; i < 12; i++) {
      if (find.text('Diplomatic overtures').evaluate().isNotEmpty) break;
      final continueFinder = find.text('Continue');
      if (continueFinder.evaluate().isNotEmpty) {
        await tester.tap(continueFinder.first, warnIfMissed: false);
      }
      await tester.pump(const Duration(milliseconds: 300));
    }

    expect(find.text('Diplomatic overtures'), findsOneWidget);
    expect(find.text('Submit'), findsOneWidget);
  });
}
