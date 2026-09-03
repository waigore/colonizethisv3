import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart'
    show kCargoHoldIndicatorKey;
import 'package:colonizethis_app/features/game/widgets/shell/game_tab_bar.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'game_tab_bar_test_support.dart';

/// Widget tests for the in-game shell tab bar (issue #2861 S2 / #4720 Slice G).
void main() {
  suppressLogsForTests();

  testWidgets('paints surface fill + 1 px border bottom edge', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hostGameTabBar());
    await tester.pump();

    final decoratedBox = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byKey(GameTabBar.surfaceKey),
            matching: find.byType(DecoratedBox),
          )
          .first,
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
    await tester.pumpWidget(hostGameTabBar());
    await tester.pump();

    final surfaceSize = tester.getSize(find.byKey(GameTabBar.surfaceKey));
    expect(surfaceSize.height, GameTabBar.height);
  });
  testWidgets('active region tab label uses --accent', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hostGameTabBar(regionIndex: 0));
    await tester.pump();

    final oldWorldLabel = tester.widget<Text>(find.text('Old World'));
    expect(oldWorldLabel.style?.color, EditorialMonoclePalette.accent);
  });
  testWidgets('inactive region tab label uses --muted', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hostGameTabBar(regionIndex: 0));
    await tester.pump();

    final newWorldLabel = tester.widget<Text>(find.text('New World'));
    expect(newWorldLabel.style?.color, EditorialMonoclePalette.muted);
  });
  testWidgets('positive treasury delta resolves to --success', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hostGameTabBar(treasuryDelta: 250));
    await tester.pump();

    final deltaText = tester.widget<Text>(find.text('+250'));
    expect(deltaText.style?.color, EditorialMonoclePalette.success);
  });
  testWidgets('negative treasury delta resolves to --danger', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hostGameTabBar(treasuryDelta: -400));
    await tester.pump();

    final deltaText = tester.widget<Text>(find.text('-400'));
    expect(deltaText.style?.color, EditorialMonoclePalette.danger);
  });

  testWidgets('region tab tap calls onRegionIndexChanged', (
    WidgetTester tester,
  ) async {
    var selected = 0;
    await tester.pumpWidget(
      hostGameTabBar(onRegionIndexChanged: (index) => selected = index),
    );
    await tester.pump();

    await tester.tap(find.text('New World'));
    await tester.pump();
    expect(selected, 1);
  });
  testWidgets('cargo hold indicator renders supplied label', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hostGameTabBar(cargoHoldLabel: '7/20'));
    await tester.pump();

    expect(find.byKey(kCargoHoldIndicatorKey), findsOneWidget);
    expect(find.text('7/20'), findsOneWidget);
  });
  testWidgets('cargo numeric text uses accent at tight threshold', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hostGameTabBar(cargoHoldLabel: '10/12', cargoUsed: 10, cargoCapacity: 12),
    );
    await tester.pump();

    final label = tester.widget<Text>(find.text('10/12'));
    expect(label.style?.color, EditorialMonoclePalette.accent);
  });
  testWidgets('cargo numeric text uses danger when full', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hostGameTabBar(cargoHoldLabel: '12/12', cargoUsed: 12, cargoCapacity: 12),
    );
    await tester.pump();

    final label = tester.widget<Text>(find.text('12/12'));
    expect(label.style?.color, EditorialMonoclePalette.danger);
  });
  testWidgets('cargo tooltip exposes plain-language overseas vs holds', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hostGameTabBar());
    await tester.pump();

    expect(
      find.byTooltip('Cargo: 3 overseas of 12 Home Fleet holds'),
      findsOneWidget,
    );
  });

  testWidgets('negative: treasury delta does not use Material green/red', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hostGameTabBar(treasuryDelta: 100));
    await tester.pump();

    final deltaText = tester.widget<Text>(find.text('+100'));
    expect(deltaText.style?.color, isNot(Colors.green));
    expect(deltaText.style?.color, EditorialMonoclePalette.success);
  });
}
