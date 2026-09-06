// Treasury indicator ACs for in-game narrow shell. SPEC/ui/in-game-shell-narrow.md.
// Split from game_screen_narrow_shell_chrome_test.dart (Refs #4734 Slice H).

import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart'
    show kCargoHoldIndicatorKey, kTreasuryIndicatorKey;
import 'package:colonizethis_app/features/game/widgets/shell/treasury_details_indicator_support.dart';
import 'package:colonizethis_app/providers/treasury_summary_provider.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_test_hive_harness.dart';
import 'game_screen_narrow_shell_chrome_support.dart';
import 'game_screen_test_support.dart';
import 'map_view_test_fixtures.dart';
import 'panel_fixtures/game_map.dart' show buildPlayersBarTestGame;

void main() {
  suppressLogsForTests();

  final baseGame = buildPlayersBarTestGame();
  final lightMapViewData = buildLightweightMapViewData();
  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(suiteId: 'game_screen_narrow_shell_treasury');
  });

  group('GameScreen treasury indicator — SPEC/ui/in-game-shell-narrow.md', () {
    testWidgets(
      'AC: treasury indicator appears between New World and cargo with exact value and dedicated icon',
      (WidgetTester tester) async {
        await pumpGameScreenNarrowShellChrome(
          tester,
          gamesBox: gamesBox,
          baseGame: baseGame,
          lightMapViewData: lightMapViewData,
          bindWide: true,
          treasurySummary: const TreasurySummary(
            treasury: 12345,
            projectedDelta: 250,
          ),
        );

        final treasuryIndicator = find.byKey(kTreasuryIndicatorKey);
        expect(treasuryIndicator, findsOneWidget);
        expect(find.byKey(kCargoHoldIndicatorKey), findsOneWidget);
        expect(find.text('12,345'), findsOneWidget);
        expect(find.text('+250'), findsOneWidget);
        expect(
          strictAssetIconPathUnder(tester, treasuryIndicator),
          'assets/icons/32/ui_icon_treasury_coin.png',
        );
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets(
      'AC: tapping treasury indicator opens details; Exact/Compact inside popover',
      (WidgetTester tester) async {
        await pumpGameScreenNarrowShellChrome(
          tester,
          gamesBox: gamesBox,
          baseGame: baseGame,
          lightMapViewData: lightMapViewData,
        );
        final treasuryIndicator = find.byKey(kTreasuryIndicatorKey);
        expect(treasuryIndicator, findsOneWidget);
        expect(find.text('12,345'), findsOneWidget);

        await tester.tap(treasuryIndicator);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byKey(kTreasuryDetailsPanelKey), findsOneWidget);

        await tester.tap(find.byKey(TreasuryDetailsPanel.compactFormatKey));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('12.3k'), findsWidgets);

        await tester.tap(find.byKey(TreasuryDetailsPanel.closeButtonKey));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byKey(kTreasuryDetailsPanelKey), findsNothing);
        expect(find.text('12.3k'), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets(
      'AC: treasury delta shows signed text for positive values',
      (WidgetTester tester) async {
        await pumpGameScreenNarrowShellChrome(
          tester,
          gamesBox: gamesBox,
          baseGame: baseGame,
          lightMapViewData: lightMapViewData,
          treasurySummary: const TreasurySummary(
            treasury: 12345,
            projectedDelta: 250,
          ),
        );
        expect(find.text('+250'), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'AC: treasury delta shows signed text for negative values',
      (WidgetTester tester) async {
        await pumpGameScreenNarrowShellChrome(
          tester,
          gamesBox: gamesBox,
          baseGame: baseGame,
          lightMapViewData: lightMapViewData,
          treasurySummary: const TreasurySummary(
            treasury: 12345,
            projectedDelta: -400,
          ),
        );
        expect(find.textContaining('400'), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'AC: treasury delta hides when projected delta is zero',
      (WidgetTester tester) async {
        await pumpGameScreenNarrowShellChrome(
          tester,
          gamesBox: gamesBox,
          baseGame: baseGame,
          lightMapViewData: lightMapViewData,
          treasurySummary: const TreasurySummary(
            treasury: 12345,
            projectedDelta: 0,
          ),
        );
        expect(find.text('+250'), findsNothing);
        expect(find.text('-400'), findsNothing);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );
  });
}
