// GameTopBar observe-banner and narrow/wide layout pins (Refs #4352 Slice D).
// SPEC: SPEC/ui/game-screen.md; SPEC/ui/in-game-shell-narrow.md; SPEC/ui/mobile-adaptation.md.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart'
    show kGameMapNextTurnButtonKey;
import 'package:colonizethis_app/features/game/widgets/shell/game_top_bar.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'game_top_bar_test_support.dart';

void main() {
  suppressLogsForTests();

  testWidgets('shows observe banner only when observeBannerLabel is non-null', (
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
    expect(find.byKey(GameTopBar.observeBannerKey), findsNothing);

    await tester.pumpWidget(
      buildGameTopBarHost(
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
  });

  testWidgets('hamburger tooltip surfaces the supplied menuTooltip label', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildGameTopBarHost(
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
        buildGameTopBarHost(
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

  testWidgets(
    'narrow layout (< kNarrowBreakpoint) shows hamburger + pause + Next turn',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildGameTopBarHost(
          onToggleSideMenu: () {},
          onPausePressed: () {},
          onNextTurn: () async {},
          nextTurnEnabled: true,
          turnDisplayText: 'Turn 42 / Year 1650',
          nextTurnText: 'Next turn (42 / 1650)',
          observeBannerLabel: 'Observing: gp1',
          hostWidth: kMinViewportWidth,
        ),
      );
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason:
            'SPEC/ui/mobile-adaptation.md § 4 + § 7: narrow top bar must '
            'not overflow at kMinViewportWidth.',
      );

      expect(find.byKey(GameTopBar.hamburgerKey), findsOneWidget);
      expect(find.byKey(kGameMapNextTurnButtonKey), findsOneWidget);
      expect(find.textContaining('Next turn'), findsOneWidget);
      expect(find.byKey(GameTopBar.turnDisplayKey), findsNothing);
      expect(find.byKey(GameTopBar.pauseButtonKey), findsOneWidget);
      expect(find.byKey(GameTopBar.observeBannerKey), findsNothing);
    },
  );

  testWidgets(
    'wide layout (≥ kNarrowBreakpoint) still shows center turn + pause',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildGameTopBarHost(
          onToggleSideMenu: () {},
          onPausePressed: () {},
          onNextTurn: () async {},
          nextTurnEnabled: true,
          turnDisplayText: 'Turn 42 / Year 1650',
          nextTurnText: 'Next turn (42 / 1650)',
          hostWidth: kNarrowBreakpoint,
        ),
      );
      await tester.pump();

      expect(find.byKey(GameTopBar.turnDisplayKey), findsOneWidget);
      expect(find.byKey(GameTopBar.pauseButtonKey), findsOneWidget);
    },
  );
}
