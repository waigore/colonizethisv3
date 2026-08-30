// Widget tests for treasury details popover on GameTabBar (Refs #4560).

import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart'
    show kTreasuryIndicatorKey;
import 'package:colonizethis_app/features/game/widgets/shell/treasury_committed_spend.dart';
import 'package:colonizethis_app/features/game/widgets/shell/treasury_details_indicator_support.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'game_tab_bar_test_support.dart';

void main() {
  suppressLogsForTests();

  testWidgets('tapping treasury opens details popover with forecast', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hostGameTabBar(
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
    await tester.pumpWidget(hostGameTabBar(treasury: 12345));
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
    await tester.pumpWidget(hostGameTabBar(treasuryNotDefined: true));
    await tester.pump();

    await tester.tap(find.byKey(kTreasuryIndicatorKey));
    await tester.pumpAndSettle();

    expect(find.byKey(kTreasuryDetailsPanelKey), findsNothing);
  });
}
