// Cargo-hold details panel ACs for the in-game shell tab bar
// (issue #2861 S2 / #4720 Slice G).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart'
    show kCargoHoldIndicatorKey, kGameMapNextTurnButtonKey;
import 'package:colonizethis_app/features/game/widgets/shell/cargo_hold_indicator_support.dart';
import 'package:colonizethis_app/features/game/widgets/shell/game_tab_bar.dart';
import 'package:colonizethis_app/features/game/widgets/shell/game_top_bar.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'game_tab_bar_test_support.dart';

void main() {
  suppressLogsForTests();

  testWidgets('tapping cargo opens details panel with breakdown rows', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hostGameTabBar());
    await tester.pump();

    await tester.tap(find.byKey(kCargoHoldIndicatorKey));
    await tester.pumpAndSettle();

    expect(find.byKey(kCargoHoldDetailsPanelKey), findsOneWidget);
    expect(find.text('Overseas extraction: 3'), findsOneWidget);
    expect(find.text('Home Fleet holds: 12'), findsOneWidget);
    expect(find.text('Free for trade bids: 9'), findsOneWidget);
    expect(
      find.textContaining('Merchant ships in your Home Fleet'),
      findsOneWidget,
    );
  });
  testWidgets('dismiss cargo panel via close and reopen on next tap', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hostGameTabBar());
    await tester.pump();

    await tester.tap(find.byKey(kCargoHoldIndicatorKey));
    await tester.pumpAndSettle();
    expect(find.byKey(kCargoHoldDetailsPanelKey), findsOneWidget);

    await tester.tap(find.byKey(CargoHoldDetailsPanel.closeButtonKey));
    await tester.pumpAndSettle();
    expect(find.byKey(kCargoHoldDetailsPanelKey), findsNothing);

    await tester.tap(find.byKey(kCargoHoldIndicatorKey));
    await tester.pumpAndSettle();
    expect(find.byKey(kCargoHoldDetailsPanelKey), findsOneWidget);
  });
  testWidgets('unreliable cargo used shows em dash in panel overseas row', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hostGameTabBar(
        cargoHoldLabel: '—/12',
        cargoUsed: 0,
        cargoCapacity: 12,
        isCargoUsedReliable: false,
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(kCargoHoldIndicatorKey));
    await tester.pumpAndSettle();

    expect(find.text('Overseas extraction: —'), findsOneWidget);
    expect(find.text('Free for trade bids: —'), findsOneWidget);
  });
  testWidgets('narrow viewport: cargo panel leaves Next turn tappable', (
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
                  cargoUsed: 10,
                  cargoCapacity: 12,
                  cargoNotDefined: false,
                  isCargoUsedReliable: true,
                  cargoHoldLabel: '10/12',
                  trailing: const SizedBox(width: 24, height: 24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(kCargoHoldIndicatorKey));
    await tester.pumpAndSettle();
    expect(find.byKey(kCargoHoldDetailsPanelKey), findsOneWidget);

    await tester.tap(find.byKey(kGameMapNextTurnButtonKey));
    await tester.pump();
    expect(nextTurnTaps, 1);
  });
}
