import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart'
    show kGameMapNextTurnButtonKey;
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
///   5. When `nextTurnEnabled: false`, the button passes `onPressed: null`
///      so it renders the disabled state (`disabledOpacity` 0.4)
///      during turn resolution (#2861 R1, negative path).
///   6. The optional observe-mode banner is shown only when supplied.
void main() {
  suppressLogsForTests();

  Widget hostFor({
    required VoidCallback onToggleSideMenu,
    required Future<void> Function() onNextTurn,
    required bool nextTurnEnabled,
    required String nextTurnText,
    String menuTooltip = 'Menu',
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
                onNextTurn: onNextTurn,
                nextTurnEnabled: nextTurnEnabled,
                nextTurnText: nextTurnText,
                menuTooltip: menuTooltip,
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
}
