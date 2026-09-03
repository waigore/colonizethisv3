// Pin the 320 dp minimum-viewport contract for `DiplomacyScreen`
// (GAME30001) — global-observe path.
// Default pins live in `diplomacy_screen_320dp_min_viewport_test.dart`.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7; `SPEC/ui/diplomacy-panel.md`.
// Refs #2870 S10.

import 'package:colonizethis_app/features/game/screens/diplomacy/diplomacy_screen.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';
import 'package:colonizethis_app/features/game/widgets/panels/observe_mode_not_defined_panel.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'diplomacy_screen_320dp_min_viewport_support.dart';
import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late String humanPlayerId;

  setUpAll(() {
    game = buildDiplomacyScreenTestGame();
    humanPlayerId = game.players
        .firstWhere((p) => p.isHuman, orElse: () => game.players.first)
        .id;
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — DiplomacyScreen (global '
      'observe) @ 320 dp (Refs #2870 S10)', () {
    testWidgets('AC (positive) DiplomacyScreen global-observe @ 320×640: no '
        'RenderFlex overflow exception, dark CtTopBar still paints, '
        'ObserveModeNotDefinedPanel sentinel renders, DiplomacyPanel '
        'body is absent', (WidgetTester tester) async {
      await pumpDiplomacyScreen320(
        tester,
        size: kDiplomacyScreen320MinViewport,
        game: game,
        humanPlayerId: humanPlayerId,
        globalObserve: true,
      );

      expect(
        tester.takeException(),
        isNull,
        reason:
            'SPEC/ui/mobile-adaptation.md § 7: DiplomacyScreen '
            'global-observe body must not emit a RenderFlex '
            'overflow exception at kMinViewportWidth (320 dp). '
            'The dark CtTopBar plus the '
            "`ObserveModeNotDefinedPanel(title: 'Diplomacy')` "
            'sentinel must lay out within the 320 dp column.',
      );

      expect(
        find.byKey(DiplomacyScreen.topBarKey),
        findsOneWidget,
        reason:
            'Observe override only swaps the body (see SPEC/ui/'
            'diplomacy-panel.md § States and variants); the dark '
            'CtTopBar must still paint so the AC for the chrome is '
            'exercised at 320 dp under both variants.',
      );

      final observePanelFinder = find.byType(ObserveModeNotDefinedPanel);
      expect(observePanelFinder, findsOneWidget);
      final ObserveModeNotDefinedPanel observePanel = tester
          .widget<ObserveModeNotDefinedPanel>(observePanelFinder);
      // SPEC/ui/diplomacy-panel.md § States and variants requires
      // the literal `Diplomacy` title under the observe sentinel.
      // ignore: avoid_hardcoded_strings_in_widgets
      expect(observePanel.title, 'Diplomacy');

      expect(
        find.byType(DiplomacyPanel),
        findsNothing,
        reason:
            'Global-observe path MUST NOT mount the DiplomacyPanel '
            'body — SPEC/ui/diplomacy-panel.md § States and '
            'variants reserves the observe sentinel for that '
            'branch.',
      );
    });

    testWidgets('Negative control: DiplomacyScreen global-observe @ 1024×768 '
        'also pumps without exception (regression sentinel for the '
        'overflow contract under the observe variant)', (
      WidgetTester tester,
    ) async {
      await pumpDiplomacyScreen320(
        tester,
        size: kDiplomacyScreen320WideViewport,
        game: game,
        humanPlayerId: humanPlayerId,
        globalObserve: true,
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(DiplomacyScreen.topBarKey), findsOneWidget);
      expect(find.byType(ObserveModeNotDefinedPanel), findsOneWidget);
      expect(find.byType(DiplomacyPanel), findsNothing);
    });
  });
}
