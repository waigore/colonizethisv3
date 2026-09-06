import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart'
    show kGameMapNextTurnButtonKey, kNextTurnDisabledOpacity;
import 'package:colonizethis_app/features/game/widgets/shell/game_top_bar.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'game_top_bar_test_support.dart';

/// Widget tests for the in-game shell top bar (issue #2861 S1).
void main() {
  suppressLogsForTests();

  testWidgets(
    'paints CtGradients.topBarGradient + 1 px accent-dim bottom border',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildGameTopBarHost(
          onToggleSideMenu: () {},
          onNextTurn: () async {},
          nextTurnEnabled: true,
          nextTurnText: 'Next turn (42 / 1650)',
        ),
      );
      await tester.pump();
      expectGameTopBarGradientAndBorder(tester);
    },
  );

  testWidgets('pins the bar height to GameTopBar.height (36 dp)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildGameTopBarHost(
        onToggleSideMenu: () {},
        onNextTurn: () async {},
        nextTurnEnabled: true,
        nextTurnText: 'Next turn (42 / 1650)',
      ),
    );
    await tester.pump();

    final surfaceSize = tester.getSize(find.byKey(GameTopBar.surfaceKey));
    expect(surfaceSize.height, GameTopBar.height);
  });

  testWidgets(
    'hamburger fires onToggleSideMenu and renders a 28 x 28 tap target',
    (WidgetTester tester) async {
      var taps = 0;
      await tester.pumpWidget(
        buildGameTopBarHost(
          onToggleSideMenu: () => taps += 1,
          onNextTurn: () async {},
          nextTurnEnabled: true,
          nextTurnText: 'Next turn (42 / 1650)',
        ),
      );
      await tester.pump();

      final hamburgerFinder = find.byKey(GameTopBar.hamburgerKey);
      expect(hamburgerFinder, findsOneWidget);

      final hamburgerSize = tester.getSize(hamburgerFinder);
      expect(hamburgerSize.width, GameTopBar.hamburgerSize);
      expect(hamburgerSize.height, GameTopBar.hamburgerSize);

      await tester.tap(hamburgerFinder);
      await tester.pump();
      expect(taps, 1);
    },
  );

  testWidgets(
    'Next turn button shows label and fires onNextTurn when enabled',
    (WidgetTester tester) async {
      var nextTurnCalls = 0;
      await tester.pumpWidget(
        buildGameTopBarHost(
          onToggleSideMenu: () {},
          onNextTurn: () async {
            nextTurnCalls += 1;
          },
          nextTurnEnabled: true,
          nextTurnText: 'Next turn (42 / 1650)',
        ),
      );
      await tester.pump();

      final button = find.byKey(kGameMapNextTurnButtonKey);
      expect(button, findsOneWidget);
      final widget = tester.widget<CtNinePatchButton>(button);
      expect(widget.onPressed, isNotNull);

      await tester.tap(button);
      await tester.pump();
      expect(nextTurnCalls, 1);
      expect(find.text('Next turn (42 / 1650)'), findsOneWidget);
    },
  );

  testWidgets(
    'Next turn button renders disabled (onPressed null) when nextTurnEnabled: false',
    (WidgetTester tester) async {
      var nextTurnCalls = 0;
      await tester.pumpWidget(
        buildGameTopBarHost(
          onToggleSideMenu: () {},
          onNextTurn: () async {
            nextTurnCalls += 1;
          },
          nextTurnEnabled: false,
          nextTurnText: 'Next turn (42 / 1650)',
        ),
      );
      await tester.pump();

      final widget = tester.widget<CtNinePatchButton>(
        find.byKey(kGameMapNextTurnButtonKey),
      );
      expect(widget.onPressed, isNull);
      expect(widget.enabled, isFalse);
      expect(widget.disabledOpacityOverride, kNextTurnDisabledOpacity);

      await tester.tap(
        find.byKey(kGameMapNextTurnButtonKey),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(nextTurnCalls, 0);
    },
  );

  testWidgets(
    'disabled Next turn button wraps the surface in 0.35 Opacity (mockup '
    '.next-turn.disabled; issue #2861 R1 / AC#9)',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildGameTopBarHost(
          onToggleSideMenu: () {},
          onNextTurn: () async {},
          nextTurnEnabled: false,
          nextTurnText: 'Next turn (42 / 1650)',
        ),
      );
      await tester.pumpAndSettle();

      expect(gameTopBarNextTurnDisabledOpacityFinder(), findsOneWidget);
      expect(kNextTurnDisabledOpacity, 0.35);
      expect(CtNinePatchButton.disabledOpacity, 0.4);

      final Finder defaultOpacityFinder = find.descendant(
        of: find.byKey(kGameMapNextTurnButtonKey),
        matching: find.byWidgetPredicate(
          (Widget w) =>
              w is Opacity && w.opacity == CtNinePatchButton.disabledOpacity,
        ),
      );
      expect(defaultOpacityFinder, findsNothing);
    },
  );

  testWidgets(
    'enabled Next turn button does not wrap the surface in any Opacity dim',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildGameTopBarHost(
          onToggleSideMenu: () {},
          onNextTurn: () async {},
          nextTurnEnabled: true,
          nextTurnText: 'Next turn (42 / 1650)',
        ),
      );
      await tester.pumpAndSettle();
      expect(gameTopBarNextTurnDimmingOpacityFinder(), findsNothing);
    },
  );
}
