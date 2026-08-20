import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart'
    show kCargoHoldIndicatorKey, kGameMapNextTurnButtonKey, kTreasuryIndicatorKey;
import 'package:colonizethis_app/features/game/widgets/shell/cargo_hold_indicator_support.dart';
import 'package:colonizethis_app/features/game/widgets/shell/game_tab_bar.dart';
import 'package:colonizethis_app/features/game/widgets/shell/game_top_bar.dart';
import 'package:colonizethis_app/features/game/widgets/shell/treasury_committed_spend.dart';
import 'package:colonizethis_app/features/game/widgets/shell/treasury_details_indicator_support.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

/// Widget tests for the in-game shell tab bar (issue #2861 S2).
void main() {
  suppressLogsForTests();

  Widget hostFor({
    int regionIndex = 0,
    ValueChanged<int>? onRegionIndexChanged,
    int treasury = 12345,
    int? treasuryDelta,
    bool treasuryNotDefined = false,
    List<TreasuryCommittedSpendLine> treasuryCommittedLines =
        const <TreasuryCommittedSpendLine>[],
    String cargoHoldLabel = '3/12',
    int cargoUsed = 3,
    int cargoCapacity = 12,
    bool cargoNotDefined = false,
    bool isCargoUsedReliable = true,
    double width = 600,
    Widget? trailing,
  }) {
    return buildAppShell(
      child: Scaffold(
        body: SizedBox(
          width: width,
          height: 120,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              GameTabBar(
                regionIndex: regionIndex,
                onRegionIndexChanged: onRegionIndexChanged ?? (_) {},
                oldWorldLabel: 'Old World',
                newWorldLabel: 'New World',
                treasury: treasury,
                treasuryDelta: treasuryDelta,
                treasuryNotDefined: treasuryNotDefined,
                treasuryCommittedLines: treasuryCommittedLines,
                cargoUsed: cargoUsed,
                cargoCapacity: cargoCapacity,
                cargoNotDefined: cargoNotDefined,
                isCargoUsedReliable: isCargoUsedReliable,
                cargoHoldLabel: cargoHoldLabel,
                trailing: trailing ?? const SizedBox(width: 32, height: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('paints surface fill + 1 px border bottom edge', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hostFor());
    await tester.pump();

    final decoratedBox = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byKey(GameTabBar.surfaceKey),
        matching: find.byType(DecoratedBox),
      ).first,
    );
    final decoration = decoratedBox.decoration as BoxDecoration;
    expect(decoration.color, EditorialMonoclePalette.surface);
    final border = decoration.border as Border;
    expect(border.bottom.width, GameTabBar.borderWidth);
    expect(border.bottom.color, EditorialMonoclePalette.border);
  });
  testWidgets('pins the bar height to GameTabBar.height (34 dp)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hostFor());
    await tester.pump();

    final surfaceSize = tester.getSize(find.byKey(GameTabBar.surfaceKey));
    expect(surfaceSize.height, GameTabBar.height);
  });
  testWidgets('active region tab label uses --accent', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hostFor(regionIndex: 0));
    await tester.pump();

    final oldWorldLabel = tester.widget<Text>(find.text('Old World'));
    expect(oldWorldLabel.style?.color, EditorialMonoclePalette.accent);
  });
  testWidgets('inactive region tab label uses --muted', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hostFor(regionIndex: 0));
    await tester.pump();

    final newWorldLabel = tester.widget<Text>(find.text('New World'));
    expect(newWorldLabel.style?.color, EditorialMonoclePalette.muted);
  });
  testWidgets('positive treasury delta resolves to --success', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hostFor(treasuryDelta: 250));
    await tester.pump();

    final deltaText = tester.widget<Text>(find.text('+250'));
    expect(deltaText.style?.color, EditorialMonoclePalette.success);
  });
  testWidgets('negative treasury delta resolves to --danger', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hostFor(treasuryDelta: -400));
    await tester.pump();

    final deltaText = tester.widget<Text>(find.text('-400'));
    expect(deltaText.style?.color, EditorialMonoclePalette.danger);
  });
  testWidgets('tapping treasury opens details popover with forecast', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hostFor(
        treasury: 12345,
        treasuryDelta: -400,
        treasuryCommittedLines: const [
          TreasuryCommittedSpendLine(
            family: TreasuryCommittedSpendFamily.grantAid,
            amount: 1000,
          ),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('12,345'), findsOneWidget);

    await tester.tap(find.byKey(kTreasuryIndicatorKey));
    await tester.pumpAndSettle();

    expect(find.byKey(kTreasuryDetailsPanelKey), findsOneWidget);
    expect(find.text('Treasury: 12,345'), findsOneWidget);
    expect(find.text('Next-turn forecast: -400'), findsOneWidget);
    expect(find.text('Grant aid: £1,000'), findsOneWidget);
    expect(
      find.textContaining('extraction, riches converting to gold'),
      findsOneWidget,
    );
  });

  testWidgets('Exact/Compact inside popover updates chip formatting', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hostFor(treasury: 12345));
    await tester.pump();

    await tester.tap(find.byKey(kTreasuryIndicatorKey));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(TreasuryDetailsPanel.compactFormatKey));
    await tester.pumpAndSettle();
    expect(find.text('12.3k'), findsWidgets);

    await tester.tap(find.byKey(TreasuryDetailsPanel.closeButtonKey));
    await tester.pumpAndSettle();
    expect(find.byKey(kTreasuryDetailsPanelKey), findsNothing);
    expect(find.text('12.3k'), findsOneWidget);
  });

  testWidgets('observe treasury does not open details popover', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hostFor(treasuryNotDefined: true));
    await tester.pump();

    await tester.tap(find.byKey(kTreasuryIndicatorKey));
    await tester.pumpAndSettle();

    expect(find.byKey(kTreasuryDetailsPanelKey), findsNothing);
  });

  testWidgets('region tab tap calls onRegionIndexChanged', (
    WidgetTester tester,
  ) async {
    var selected = 0;
    await tester.pumpWidget(
      hostFor(
        onRegionIndexChanged: (index) => selected = index,
      ),
    );
    await tester.pump();

    await tester.tap(find.text('New World'));
    await tester.pump();
    expect(selected, 1);
  });
  testWidgets('cargo hold indicator renders supplied label', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hostFor(cargoHoldLabel: '7/20'));
    await tester.pump();

    expect(find.byKey(kCargoHoldIndicatorKey), findsOneWidget);
    expect(find.text('7/20'), findsOneWidget);
  });
  testWidgets('cargo numeric text uses accent at tight threshold', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hostFor(
        cargoHoldLabel: '10/12',
        cargoUsed: 10,
        cargoCapacity: 12,
      ),
    );
    await tester.pump();

    final label = tester.widget<Text>(find.text('10/12'));
    expect(label.style?.color, EditorialMonoclePalette.accent);
  });
  testWidgets('cargo numeric text uses danger when full', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hostFor(
        cargoHoldLabel: '12/12',
        cargoUsed: 12,
        cargoCapacity: 12,
      ),
    );
    await tester.pump();

    final label = tester.widget<Text>(find.text('12/12'));
    expect(label.style?.color, EditorialMonoclePalette.danger);
  });
  testWidgets('cargo tooltip exposes plain-language overseas vs holds', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hostFor());
    await tester.pump();

    expect(
      find.byTooltip('Cargo: 3 overseas of 12 Home Fleet holds'),
      findsOneWidget,
    );
  });
  testWidgets('tapping cargo opens details panel with breakdown rows', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hostFor());
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
    await tester.pumpWidget(hostFor());
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
      hostFor(
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
  testWidgets(
    'narrow viewport: cargo panel leaves Next turn tappable',
    (WidgetTester tester) async {
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
    },
  );

  testWidgets('negative: treasury delta does not use Material green/red', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hostFor(treasuryDelta: 100));
    await tester.pump();

    final deltaText = tester.widget<Text>(find.text('+100'));
    expect(deltaText.style?.color, isNot(Colors.green));
    expect(deltaText.style?.color, EditorialMonoclePalette.success);
  });
  testWidgets(
    'M1: region tabs start-aligned; treasury -> cargo -> news toggle '
    'end-aligned in order',
    (WidgetTester tester) async {
      const Key trailingKey = Key('test_trailing');
      await tester.pumpWidget(
        hostFor(
          treasuryDelta: 250,
          trailing: const SizedBox(key: trailingKey, width: 28, height: 22),
        ),
      );
      await tester.pump();

      final double oldWorldX = tester.getCenter(find.text('Old World')).dx;
      final double treasuryX =
          tester.getCenter(find.byKey(kTreasuryIndicatorKey)).dx;
      final double cargoX =
          tester.getCenter(find.byKey(kCargoHoldIndicatorKey)).dx;
      final double trailingX = tester.getCenter(find.byKey(trailingKey)).dx;

      expect(
        oldWorldX,
        lessThan(treasuryX),
        reason: 'Region tabs are start-aligned, left of the trailing group.',
      );
      expect(
        treasuryX,
        lessThan(cargoX),
        reason: 'Treasury precedes cargo in the trailing group.',
      );
      expect(
        cargoX,
        lessThan(trailingX),
        reason: 'Cargo precedes the news toggle in the trailing group.',
      );
    },
  );

  testWidgets(
    'M1/M3: news toggle has a 4 dp leading gap from the cargo hold indicator',
    (WidgetTester tester) async {
      const Key trailingKey = Key('test_trailing');
      await tester.pumpWidget(
        hostFor(
          trailing: const SizedBox(key: trailingKey, width: 28, height: 22),
        ),
      );
      await tester.pump();

      final double cargoRight =
          tester.getTopRight(find.byKey(kCargoHoldIndicatorKey)).dx;
      final double trailingLeft =
          tester.getTopLeft(find.byKey(trailingKey)).dx;
      expect(
        trailingLeft - cargoRight,
        moreOrLessEquals(GameTabBar.clusterTrailingGap, epsilon: 0.5),
      );
    },
  );
}
