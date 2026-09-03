// Pin the 320 dp minimum-viewport contract for `TechnologyScreen`
// (GAME40001) — global-observe path.
// Default Slots pins live in
// `technology_screen_320dp_min_viewport_test.dart`.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7; `SPEC/ui/technology-panel.md`.
// Refs #2870 S10.

import 'package:colonizethis_app/features/game/screens/technology/technology_screen.dart';
import 'package:colonizethis_app/features/game/widgets/panels/observe_mode_not_defined_panel.dart';
import 'package:colonizethis_app/features/game/widgets/technology/technology_panel.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'panel_test_fixtures.dart';
import 'technology_screen_320dp_min_viewport_support.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late Player humanPlayer;

  setUpAll(() {
    game = buildTechnologyPanelTestGame();
    humanPlayer = game.players.firstWhere(
      (p) => p.isHuman,
      orElse: () => game.players.first,
    );
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — TechnologyScreen (global observe) '
      '@ 320 dp (Refs #2870 S10)', () {
    testWidgets('AC (positive) TechnologyScreen global-observe @ 320×640: no '
        'RenderFlex overflow exception, dark CtTopBar still paints, '
        '`ObserveModeNotDefinedPanel(title: "Technology")` sentinel '
        'renders, the live TechnologyPanel body is absent', (
      WidgetTester tester,
    ) async {
      await pumpTechnologyScreen320(
        tester,
        size: kTechnologyScreen320MinViewport,
        game: game,
        player: humanPlayer,
        globalObserve: true,
      );

      expect(
        tester.takeException(),
        isNull,
        reason:
            'SPEC/ui/mobile-adaptation.md § 7: TechnologyScreen '
            'global-observe body must not emit a RenderFlex '
            'overflow exception at kMinViewportWidth (320 dp). The '
            'dark CtTopBar plus the `ObserveModeNotDefinedPanel('
            "title: 'Technology')` sentinel must lay out within "
            'the 320 dp column.',
      );

      expect(
        find.byKey(TechnologyScreen.topBarKey),
        findsOneWidget,
        reason:
            'Observe override only swaps the body (see SPEC/ui/'
            'technology-panel.md § States and variants); the dark '
            'CtTopBar must still paint so the AC for the chrome '
            'is exercised at 320 dp under both variants.',
      );

      final observePanelFinder = find.byType(ObserveModeNotDefinedPanel);
      expect(observePanelFinder, findsOneWidget);
      final ObserveModeNotDefinedPanel observePanel = tester
          .widget<ObserveModeNotDefinedPanel>(observePanelFinder);
      // TechnologyScreen.bodyBuilder hard-codes the title literal
      // `Technology` for the observe sentinel (see screen source);
      // SPEC/ui/technology-panel.md § States and variants pins
      // that literal.
      // ignore: avoid_hardcoded_strings_in_widgets
      expect(observePanel.title, 'Technology');

      expect(
        find.byType(TechnologyPanel),
        findsNothing,
        reason:
            'Global-observe path MUST NOT mount the live '
            'TechnologyPanel — SPEC/ui/technology-panel.md § States '
            'and variants reserves the observe sentinel for that '
            'branch.',
      );
    });

    testWidgets('Negative control: TechnologyScreen global-observe @ 1024×768 '
        'also pumps without exception (regression sentinel for the '
        'overflow contract under the observe variant)', (
      WidgetTester tester,
    ) async {
      await pumpTechnologyScreen320(
        tester,
        size: kTechnologyScreen320WideViewport,
        game: game,
        player: humanPlayer,
        globalObserve: true,
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(TechnologyScreen.topBarKey), findsOneWidget);
      expect(find.byType(ObserveModeNotDefinedPanel), findsOneWidget);
    });
  });
}
