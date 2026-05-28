import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart'
    show kCargoHoldIndicatorKey, kTreasuryIndicatorKey;
import 'package:colonizethis_app/features/game/widgets/game_tab_bar.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget tests for the in-game shell tab bar (issue #2861 S2).
void main() {
  suppressLogsForTests();

  Widget hostFor({
    int regionIndex = 0,
    ValueChanged<int>? onRegionIndexChanged,
    int treasury = 12345,
    int? treasuryDelta,
    bool treasuryNotDefined = false,
    String cargoHoldLabel = '3/12',
    Widget? trailing,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 600,
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
            cargoUsed: 3,
            cargoCapacity: 12,
            cargoNotDefined: false,
            isCargoUsedReliable: true,
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

  testWidgets('tapping treasury toggles exact and abbreviated modes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hostFor(treasury: 12345));
    await tester.pump();

    expect(find.text('12,345'), findsOneWidget);

    await tester.tap(find.byKey(kTreasuryIndicatorKey));
    await tester.pump();
    expect(find.text('12.3k'), findsOneWidget);

    await tester.tap(find.byKey(kTreasuryIndicatorKey));
    await tester.pump();
    expect(find.text('12,345'), findsOneWidget);
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

  testWidgets('negative: treasury delta does not use Material green/red', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hostFor(treasuryDelta: 100));
    await tester.pump();

    final deltaText = tester.widget<Text>(find.text('+100'));
    expect(deltaText.style?.color, isNot(Colors.green));
    expect(deltaText.style?.color, EditorialMonoclePalette.success);
  });
}
