// Pin the 320 dp minimum-viewport contract for `TechnologyScreen`
// (GAME40001) — default Slots path.
// Global-observe pins live in
// `technology_screen_320dp_min_viewport_observe_test.dart`.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7; `SPEC/ui/technology-panel.md`.
// Refs #2870 S10 + Req 15.

import 'package:colonizethis_app/features/game/screens/technology/technology_screen.dart';
import 'package:colonizethis_app/features/game/widgets/panels/observe_mode_not_defined_panel.dart';
import 'package:colonizethis_app/features/game/widgets/technology/technology_panel.dart';
import 'package:colonizethis_app/widgets/ct_top_bar.dart';
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

  group('SPEC/ui/mobile-adaptation.md § 7 — TechnologyScreen (default Slots) '
      '@ 320 dp (Refs #2870 S10 + Req 15)', () {
    testWidgets('AC (positive) TechnologyScreen default Slots @ 320×640: no '
        'RenderFlex overflow exception, dark CtTopBar (title `Technology`, '
        'back label `Map`) + Slots/Tree trailing toggles + Slots body '
        '(TechnologyPanel) all render', (WidgetTester tester) async {
      await pumpTechnologyScreen320(
        tester,
        size: kTechnologyScreen320MinViewport,
        game: game,
        player: humanPlayer,
      );

      expect(
        tester.takeException(),
        isNull,
        reason:
            'SPEC/ui/mobile-adaptation.md § 7: TechnologyScreen must '
            'not emit a RenderFlex overflow exception at '
            'kMinViewportWidth (320 dp). The dark CtTopBar '
            '(36 dp tall — back chevron + `Map` label + 18 × 18 px '
            'technology icon + `Technology` title + Slots/Tree '
            'toggle pair in the trailing slot) above the '
            '`SingleChildScrollView` > `TechnologyPanel` body must '
            'lay out within the 320 dp column.',
      );

      final topBarFinder = find.byKey(TechnologyScreen.topBarKey);
      expect(topBarFinder, findsOneWidget);
      final CtTopBar topBar = tester.widget<CtTopBar>(topBarFinder);
      expect(topBar.title, TechnologyScreen.topBarTitle);
      expect(topBar.backButtonLabel, TechnologyScreen.topBarBackLabel);
      expect(
        topBar.trailing,
        isNotNull,
        reason:
            'SPEC/ui/technology-panel.md § Top bar: the Slots/Tree '
            'toggle pair must live in the CtTopBar trailing slot '
            'even at 320 dp (Refs #2864 S1 + #2870 S10).',
      );

      expect(
        find.descendant(
          of: topBarFinder,
          matching: find.byKey(TechnologyScreen.slotsToggleKey),
        ),
        findsOneWidget,
        reason:
            'Slots toggle must remain mounted inside the top bar '
            'trailing slot at the minimum viewport so the Slots '
            'tab is still reachable on a 320 dp phone.',
      );
      expect(
        find.descendant(
          of: topBarFinder,
          matching: find.byKey(TechnologyScreen.treeToggleKey),
        ),
        findsOneWidget,
        reason:
            'Tree toggle must remain mounted inside the top bar '
            'trailing slot at the minimum viewport so the Tree '
            'tab is still reachable on a 320 dp phone.',
      );

      expect(
        find.byType(TechnologyPanel),
        findsOneWidget,
        reason:
            'Default Slots tab path must mount the live '
            '`TechnologyPanel` at 320 dp (Req 15 — slot cards and '
            'researched grid scroll vertically inside the parent '
            '`SingleChildScrollView`). SPEC/ui/technology-panel.md '
            '§ Slot behaviour.',
      );
      expect(
        find.byType(ObserveModeNotDefinedPanel),
        findsNothing,
        reason:
            'Default path must NOT render the observe sentinel — '
            'that is the global-observe variant covered by the '
            'observe group below.',
      );
    });

    testWidgets('Negative control: TechnologyScreen default Slots @ 1024×768 '
        'also pumps without exception (regression sentinel for the '
        'overflow contract — keeps the 320 dp positive pin meaningful)', (
      WidgetTester tester,
    ) async {
      await pumpTechnologyScreen320(
        tester,
        size: kTechnologyScreen320WideViewport,
        game: game,
        player: humanPlayer,
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(TechnologyScreen.topBarKey), findsOneWidget);
      expect(find.byType(TechnologyPanel), findsOneWidget);
    });
  });
}
