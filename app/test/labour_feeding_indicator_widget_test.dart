// Widget tests for map-shell labour/feeding indicator (Refs #4506).
// SPEC: SPEC/ui/empire-overview.md § Labour and feeding indicator.
// Indicator chrome, popover, observe, and next-turn hit-target pins.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart'
    show kGameMapNextTurnButtonKey, kLabourFeedingIndicatorKey;
import 'package:colonizethis_app/features/game/widgets/shell/game_tab_bar.dart';
import 'package:colonizethis_app/features/game/widgets/shell/game_top_bar.dart';
import 'package:colonizethis_app/features/game/widgets/shell/labour_feeding_indicator_support.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'labour_feeding_indicator_test_support.dart';

void main() {
  suppressLogsForTests();

  testWidgets('shows labour fraction when indicator enabled', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      labourFeedingHost(
        labourReadiness: labourFeedingReducedLabour,
        forcesFeeding: labourFeedingFullyFedForces,
        labourFeedingLabel: '12/20',
      ),
    );
    await tester.pump();

    expect(find.byKey(kLabourFeedingIndicatorKey), findsOneWidget);
    expect(find.text('12/20'), findsOneWidget);
  });

  testWidgets('shows muted 0/0 for empty worker pool', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      labourFeedingHost(
        labourReadiness: labourFeedingEmptyPoolLabour,
        forcesFeeding: labourFeedingFullyFedForces,
        labourFeedingLabel: '0/0',
      ),
    );
    await tester.pump();

    expect(find.byKey(kLabourFeedingIndicatorKey), findsOneWidget);
    expect(find.text('0/0'), findsOneWidget);
    expect(
      labourFeedingNumericColor(
        labourReadiness: labourFeedingEmptyPoolLabour,
        forcesFeeding: labourFeedingFullyFedForces,
        notDefined: false,
      ),
      EditorialMonoclePalette.muted,
    );
  });

  testWidgets('empty-pool popover has no-workers copy and no shortage reason', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      labourFeedingHost(
        labourReadiness: labourFeedingEmptyPoolLabour,
        forcesFeeding: labourFeedingFullyFedForces,
        labourFeedingLabel: '0/0',
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(kLabourFeedingIndicatorKey));
    await tester.pumpAndSettle();

    expect(find.byKey(kLabourFeedingDetailsPanelKey), findsOneWidget);
    expect(find.textContaining('Labour this turn: 0 of 0'), findsOneWidget);
    expect(find.textContaining('No workers trained yet'), findsOneWidget);
    expect(
      find.textContaining('Some workers are not working — food is short'),
      findsNothing,
    );
  });

  testWidgets('hides indicator when showLabourFeedingIndicator is false', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      labourFeedingHost(
        labourReadiness: labourFeedingFullLabour,
        forcesFeeding: labourFeedingFullyFedForces,
        showLabourFeedingIndicator: false,
      ),
    );
    await tester.pump();

    expect(find.byKey(kLabourFeedingIndicatorKey), findsNothing);
  });

  testWidgets('tap opens details with primary shortage reason', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      labourFeedingHost(
        labourReadiness: labourFeedingReducedLabour,
        forcesFeeding: labourFeedingFullyFedForces,
        labourFeedingLabel: '12/20',
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(kLabourFeedingIndicatorKey));
    await tester.pumpAndSettle();

    expect(find.byKey(kLabourFeedingDetailsPanelKey), findsOneWidget);
    expect(find.textContaining('Labour this turn: 12 of 20'), findsOneWidget);
    expect(
      find.textContaining('Some workers are not working — food is short'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Armies and fleets eat before workers'),
      findsOneWidget,
    );
  });

  testWidgets('observe not-defined label is not tappable', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      labourFeedingHost(
        labourReadiness: labourFeedingFullLabour,
        forcesFeeding: labourFeedingFullyFedForces,
        labourFeedingNotDefined: true,
        labourFeedingLabel: '—',
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(kLabourFeedingIndicatorKey));
    await tester.pumpAndSettle();

    expect(find.byKey(kLabourFeedingDetailsPanelKey), findsNothing);
  });

  testWidgets('narrow viewport: labour panel leaves Next turn tappable', (
    WidgetTester tester,
  ) async {
    var nextTurnTaps = 0;
    await tester.pumpWidget(
      buildAppShell(
        child: Scaffold(
          body: SizedBox(
            width: kMinViewportWidth,
            height: 120,
            child: Column(
              children: [
                GameTopBar(
                  onToggleSideMenu: () {},
                  onPausePressed: () {},
                  onNextTurn: () async => nextTurnTaps++,
                  nextTurnEnabled: true,
                  turnDisplayText: 'Turn 1',
                  nextTurnText: 'Next turn',
                  menuTooltip: 'Menu',
                  pauseTooltip: 'Pause',
                ),
                GameTabBar(
                  regionIndex: 0,
                  onRegionIndexChanged: (_) {},
                  oldWorldLabel: 'Old World',
                  newWorldLabel: 'New World',
                  treasury: 100,
                  treasuryDelta: null,
                  treasuryNotDefined: false,
                  cargoUsed: 3,
                  cargoCapacity: 12,
                  cargoNotDefined: false,
                  isCargoUsedReliable: true,
                  cargoHoldLabel: '3/12',
                  showLabourFeedingIndicator: true,
                  labourFeedingLabel: '0/20',
                  labourReadiness: labourFeedingZeroLabour,
                  forcesFeeding: labourFeedingUnderfedLandForces,
                  trailing: const SizedBox(width: 24, height: 24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(kLabourFeedingIndicatorKey));
    await tester.pumpAndSettle();
    expect(find.byKey(kLabourFeedingDetailsPanelKey), findsOneWidget);

    await tester.tap(find.byKey(kGameMapNextTurnButtonKey));
    await tester.pump();
    expect(nextTurnTaps, 1);
  });
}
