import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/ftp_dialogue_overlay.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
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
    Hive.init('./.dart_tool/test_hive_game_screen_ftp');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  testWidgets('GameScreen shows FtpDialogueOverlay for pending FTP offers', (
    WidgetTester tester,
  ) async {
    final game = buildGameScreenSpecsTestGame();
    final pending = <FtpOffer>[
      FtpOffer(
        proposerGpId: game.players.last.id,
        targetGpId: game.players.first.id,
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
            () => PendingDiplomacyNotifier(PendingDiplomacyFtp(pending)),
          ),
        ],
      ),
    );
    await tester.pump();

    expect(find.byType(FtpDialogueOverlay), findsOneWidget);
    expect(find.text('Favored Trading Partner'), findsOneWidget);
    expect(find.text('Submit'), findsOneWidget);
  });

  testWidgets('GameScreen does not mount FtpDialogueOverlay for empty offers', (
    WidgetTester tester,
  ) async {
    final game = buildGameScreenSpecsTestGame();

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
            () => PendingDiplomacyNotifier(const PendingDiplomacyFtp([])),
          ),
        ],
      ),
    );
    await tester.pump();

    expect(find.byType(FtpDialogueOverlay), findsNothing);
  });
}
