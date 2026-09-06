// Pin the 320 dp minimum-viewport contract for VictoryOverlay (OVL20001).
// SPEC: SPEC/ui/mobile-adaptation.md § 7; SPEC/ui/victory-overlay.md.

import 'package:colonizethis_app/features/game/flame/overlays/victory_overlay.dart';
import 'package:colonizethis_app_ui_chrome/widgets/ct_brass_divider.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'victory_overlay_320dp_min_viewport_harness.dart';

void main() {
  suppressLogsForTests();

  late ct_models.Game game;
  late String winnerPlayerId;
  late ct_models.AppEventBus victoryTestBus;

  setUp(() {
    ct_models.AppEventBus.reset();
    victoryTestBus = ct_models.AppEventBus.create();
    game = buildVictoryOverlayTestGame();
    winnerPlayerId = game.players.first.id;
  });

  tearDown(() {
    ct_models.AppEventBus.reset();
  });

  ct_models.VictoryState victory({int turnNumber = 7}) =>
      buildVictoryOverlayTestVictory(
        winnerPlayerId: winnerPlayerId,
        turnNumber: turnNumber,
      );

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — VictoryOverlay @ 320 dp (Refs #2870)',
    () {
      testWidgets(
        'VictoryOverlay @ 320×640: no overflow; title, body, both actions render',
        (WidgetTester tester) async {
          await pumpVictoryOverlayAtViewport(
            tester,
            Stack(
              children: <Widget>[
                VictoryOverlay(
                  game: game,
                  victory: victory(),
                  bus: victoryTestBus,
                ),
              ],
            ),
            size: kVictoryOverlayMinViewport,
          );

          expect(tester.takeException(), isNull);
          expect(find.text('MILITARY VICTORY'), findsOneWidget);
          expect(find.textContaining('wins on turn 7'), findsOneWidget);
          expect(find.text('Return to main menu'), findsOneWidget);
          expect(find.text('View final state'), findsOneWidget);
          expect(find.byType(CtNinePatchButton), findsNWidgets(2));
          expect(find.byType(CtBrassDivider), findsOneWidget);
        },
      );

      testWidgets(
        'VictoryPanel (no scrim) @ 320×640: no overflow; same labels render',
        (WidgetTester tester) async {
          await pumpVictoryOverlayAtViewport(
            tester,
            Center(
              child: VictoryPanel(
                game: game,
                victory: victory(turnNumber: 12),
                bus: victoryTestBus,
              ),
            ),
            size: kVictoryOverlayMinViewport,
          );

          expect(tester.takeException(), isNull);
          expect(find.text('MILITARY VICTORY'), findsOneWidget);
          expect(find.textContaining('wins on turn 12'), findsOneWidget);
          expect(find.text('Return to main menu'), findsOneWidget);
          expect(find.text('View final state'), findsOneWidget);
          expect(find.byType(CtNinePatchButton), findsNWidgets(2));
          expect(find.byType(CtBrassDivider), findsOneWidget);
        },
      );

      testWidgets(
        'Negative control: VictoryOverlay @ 1024×768 pumps without exception',
        (WidgetTester tester) async {
          await pumpVictoryOverlayAtViewport(
            tester,
            Stack(
              children: <Widget>[
                VictoryOverlay(
                  game: game,
                  victory: victory(),
                  bus: victoryTestBus,
                ),
              ],
            ),
            size: kVictoryOverlayWideRegressionViewport,
          );

          expect(tester.takeException(), isNull);
          expect(find.text('MILITARY VICTORY'), findsOneWidget);
          expect(find.textContaining('wins on turn 7'), findsOneWidget);
          expect(find.text('Return to main menu'), findsOneWidget);
          expect(find.text('View final state'), findsOneWidget);
          expect(find.byType(CtNinePatchButton), findsNWidgets(2));
        },
      );
    },
  );
}
