import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart'
    show kGameMapNextTurnButtonKey, kNextTurnDisabledOpacity;
import 'package:colonizethis_app/features/game/widgets/game_top_bar.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_gradients.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget tests for the in-game shell top bar (issue #2861 S1).
///
/// Pins the dark editorial-monocle chrome contract:
///   1. The bar paints [CtGradients.topBarGradient] with a 1 px
///      `--accent-dim` bottom border (#2861 R1).
///   2. The bar is a fixed 36 px high (#2861 R1).
///   3. The hamburger affordance is a 28 x 28 dp tap target that fires
///      `onToggleSideMenu` on tap (#2861 R1, SPEC/ui/in-game-shell-narrow.md).
///   4. The trailing [CtNinePatchButton] surfaces the supplied
///      `nextTurnText` and is wired to `onNextTurn` when enabled.
///   5. When `nextTurnEnabled: false`, the button passes
///      `enabled: false` and `onPressed: null` to [CtNinePatchButton] AND
///      an explicit `disabledOpacityOverride` equal to
///      [kNextTurnDisabledOpacity] (`0.35`) so the disabled wrapper
///      `Opacity` widget resolves to `0.35` — matching
///      `.next-turn.disabled { opacity: 0.35 }` in the GAME10001
///      mockup, issue #2861 R1 / AC#9 and the normative
///      `SPEC/ui/game-screen.md` AC. The default catalog
///      `CtNinePatchButton.disabledOpacity` (`0.4`) is left untouched
///      for every other call site (regression guard in
///      `widgets/ct_nine_patch_button_dark_test.dart`).
///   6. The optional observe-mode banner is shown only when supplied.
void _noop() {}

void main() {
  suppressLogsForTests();

  Widget hostFor({
    required VoidCallback onToggleSideMenu,
    VoidCallback onPausePressed = _noop,
    required Future<void> Function() onNextTurn,
    required bool nextTurnEnabled,
    String turnDisplayText = 'Turn 42 / Year 1650',
    required String nextTurnText,
    String menuTooltip = 'Menu',
    String pauseTooltip = 'Pause menu',
    String? observeBannerLabel,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 600,
          height: 200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              GameTopBar(
                onToggleSideMenu: onToggleSideMenu,
                onPausePressed: onPausePressed,
                onNextTurn: onNextTurn,
                nextTurnEnabled: nextTurnEnabled,
                turnDisplayText: turnDisplayText,
                nextTurnText: nextTurnText,
                menuTooltip: menuTooltip,
                pauseTooltip: pauseTooltip,
                observeBannerLabel: observeBannerLabel,
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets(
    'paints CtGradients.topBarGradient + 1 px accent-dim bottom border',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        hostFor(
          onToggleSideMenu: () {},
          onNextTurn: () async {},
          nextTurnEnabled: true,
          nextTurnText: 'Next turn (42 / 1650)',
        ),
      );
      await tester.pump();

      final decoratedBox = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byKey(GameTopBar.surfaceKey),
          matching: find.byType(DecoratedBox),
        ).first,
      );
      final decoration = decoratedBox.decoration as BoxDecoration;
      expect(decoration.gradient, isA<LinearGradient>());
      final actualColors = (decoration.gradient! as LinearGradient).colors;
      final expectedColors = CtGradients.topBarGradient.colors;
      expect(actualColors, expectedColors);

      final border = decoration.border as Border;
      expect(border.bottom.width, GameTopBar.borderWidth);
      expect(border.bottom.color, EditorialMonoclePalette.accentDim);
      expect(border.top, BorderSide.none);
      expect(border.left, BorderSide.none);
      expect(border.right, BorderSide.none);
    },
  );

  testWidgets('pins the bar height to GameTopBar.height (36 dp)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hostFor(
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
        hostFor(
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
        hostFor(
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
        hostFor(
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
      expect(
        widget.enabled,
        isFalse,
        reason:
            'Disabled Next-turn button must pass enabled: false to '
            'CtNinePatchButton so the disabled Opacity wrapper activates '
            '(issue #2861 R1 / AC#9).',
      );
      expect(
        widget.disabledOpacityOverride,
        kNextTurnDisabledOpacity,
        reason:
            'Next-turn button must pass kNextTurnDisabledOpacity (0.35) as '
            'the disabled opacity override per SPEC/ui/game-screen.md '
            'Acceptance Criteria + mockup .next-turn.disabled.',
      );

      await tester.tap(
        find.byKey(kGameMapNextTurnButtonKey),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(
        nextTurnCalls,
        0,
        reason:
            'Disabled Next-turn button must not invoke the host callback even '
            'when the tap finder is hit (#2861 R1 disabled-during-resolution).',
      );
    },
  );

  testWidgets(
    'disabled Next turn button wraps the surface in 0.35 Opacity (mockup '
    '.next-turn.disabled; issue #2861 R1 / AC#9)',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        hostFor(
          onToggleSideMenu: () {},
          onNextTurn: () async {},
          nextTurnEnabled: false,
          nextTurnText: 'Next turn (42 / 1650)',
        ),
      );
      await tester.pumpAndSettle();

      final Finder opacityFinder = find.descendant(
        of: find.byKey(kGameMapNextTurnButtonKey),
        matching: find.byWidgetPredicate(
          (Widget w) => w is Opacity && w.opacity == kNextTurnDisabledOpacity,
        ),
      );
      expect(
        opacityFinder,
        findsOneWidget,
        reason:
            'Disabled Next-turn button must wrap the chrome surface in an '
            'Opacity widget whose opacity equals kNextTurnDisabledOpacity '
            '(0.35) per SPEC/ui/game-screen.md AC and '
            '.next-turn.disabled { opacity: 0.35 } in '
            'SPEC/ui/mockups/GAME10001-game-screen.html. The catalog '
            'default CtNinePatchButton.disabledOpacity (0.4) is suppressed '
            'for this call site only.',
      );
      expect(kNextTurnDisabledOpacity, 0.35);
      expect(CtNinePatchButton.disabledOpacity, 0.4);

      final Finder defaultOpacityFinder = find.descendant(
        of: find.byKey(kGameMapNextTurnButtonKey),
        matching: find.byWidgetPredicate(
          (Widget w) =>
              w is Opacity && w.opacity == CtNinePatchButton.disabledOpacity,
        ),
      );
      expect(
        defaultOpacityFinder,
        findsNothing,
        reason:
            'Negative: the catalog-default 0.4 Opacity must not be applied '
            'when the explicit 0.35 override is in scope (regression guard '
            'against accidentally dropping the override).',
      );
    },
  );

  testWidgets(
    'enabled Next turn button does not wrap the surface in any Opacity dim',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        hostFor(
          onToggleSideMenu: () {},
          onNextTurn: () async {},
          nextTurnEnabled: true,
          nextTurnText: 'Next turn (42 / 1650)',
        ),
      );
      await tester.pumpAndSettle();

      final Finder opacityFinder = find.descendant(
        of: find.byKey(kGameMapNextTurnButtonKey),
        matching: find.byWidgetPredicate(
          (Widget w) =>
              w is Opacity &&
              (w.opacity == kNextTurnDisabledOpacity ||
                  w.opacity == CtNinePatchButton.disabledOpacity),
        ),
      );
      expect(
        opacityFinder,
        findsNothing,
        reason:
            'Negative: enabled Next-turn button must not paint any dimming '
            'Opacity wrapper — neither the 0.35 next-turn override nor the '
            '0.4 catalog default may activate when nextTurnEnabled: true '
            '(regression guard for the enabled visual state).',
      );
    },
  );

  testWidgets(
    'shows observe banner only when observeBannerLabel is non-null',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        hostFor(
          onToggleSideMenu: () {},
          onNextTurn: () async {},
          nextTurnEnabled: true,
          nextTurnText: 'Next turn (42 / 1650)',
        ),
      );
      await tester.pump();
      expect(find.byKey(GameTopBar.observeBannerKey), findsNothing);

      await tester.pumpWidget(
        hostFor(
          onToggleSideMenu: () {},
          onNextTurn: () async {},
          nextTurnEnabled: true,
          nextTurnText: 'Next turn (42 / 1650)',
          observeBannerLabel: 'Observe — gp1',
        ),
      );
      await tester.pump();
      expect(find.byKey(GameTopBar.observeBannerKey), findsOneWidget);
      expect(find.text('Observe — gp1'), findsOneWidget);
    },
  );

  testWidgets('hamburger tooltip surfaces the supplied menuTooltip label', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hostFor(
        onToggleSideMenu: () {},
        onNextTurn: () async {},
        nextTurnEnabled: true,
        nextTurnText: 'Next turn (42 / 1650)',
        menuTooltip: 'Open in-game menu',
      ),
    );
    await tester.pump();

    final tooltipFinder = find.descendant(
      of: find.byKey(GameTopBar.hamburgerKey),
      matching: find.byType(Tooltip),
    );
    expect(tooltipFinder, findsOneWidget);
    final tooltip = tester.widget<Tooltip>(tooltipFinder);
    expect(tooltip.message, 'Open in-game menu');
  });

  testWidgets(
    'center turn display renders turnDisplayText and pause fires onPausePressed',
    (WidgetTester tester) async {
      var pauseTaps = 0;
      await tester.pumpWidget(
        hostFor(
          onToggleSideMenu: () {},
          onPausePressed: () => pauseTaps += 1,
          onNextTurn: () async {},
          nextTurnEnabled: true,
          turnDisplayText: 'Turn 7 / Year 1605',
          nextTurnText: 'Next turn (7 / 1605)',
          pauseTooltip: 'Open pause menu',
        ),
      );
      await tester.pump();

      expect(find.byKey(GameTopBar.turnDisplayKey), findsOneWidget);
      expect(find.text('Turn 7 / Year 1605'), findsOneWidget);

      final pauseFinder = find.byKey(GameTopBar.pauseButtonKey);
      expect(tester.getSize(pauseFinder).width, GameTopBar.hamburgerSize);
      expect(tester.getSize(pauseFinder).height, GameTopBar.hamburgerSize);

      await tester.tap(pauseFinder);
      await tester.pump();
      expect(pauseTaps, 1);
    },
  );
}
