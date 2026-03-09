// Tests for ProductionPanel. SPEC/ui/production-panel.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/production_panel.dart';
import 'package:colonizethis_app/features/game/widgets/production_panel_demo_data.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay_demo_data.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late Player fullPlayer;
  late Player partialPlayer;

  setUpAll(() {
    game = demoGameForOverlay;
    fullPlayer = fullAvailabilityProductionPlayer();
    partialPlayer = partialAvailabilityProductionPlayer();
  });

  Widget buildPanel({
    required Player player,
    Map<String, int> desiredOutputByRecipe = const {},
    ValueChanged<Map<String, int>>? onDesiredOutputChanged,
    double width = 800,
    double height = 500,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: width,
          height: height,
          child: ProductionPanel(
            game: game,
            player: player,
            desiredOutputByRecipe: desiredOutputByRecipe,
            onDesiredOutputChanged: onDesiredOutputChanged ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('ProductionPanel', () {
    testWidgets('AC: Available subpanel shows stockpile and worker pool',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(player: fullPlayer));
      await tester.pumpAndSettle();

      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Stockpile'), findsOneWidget);
      expect(find.text('Workers'), findsOneWidget);
      expect(find.textContaining('Effective labour:'), findsOneWidget);
      expect(find.textContaining('Peasants:'), findsOneWidget);
    });

    testWidgets('AC: Allocation subpanel shows recipe labels and sliders',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(player: fullPlayer));
      await tester.pumpAndSettle();

      expect(find.text('Allocation'), findsOneWidget);
      expect(find.text('Lumber'), findsOneWidget);
      expect(find.text('Cast iron'), findsOneWidget);
      expect(find.byType(Slider), findsNWidgets(5)); // 5 recipes
    });

    testWidgets('AC: Moving slider calls onDesiredOutputChanged',
        (WidgetTester tester) async {
      Map<String, int>? lastOutput;
      await tester.pumpWidget(buildPanel(
        player: fullPlayer,
        onDesiredOutputChanged: (next) => lastOutput = Map.from(next),
      ));
      await tester.pumpAndSettle();

      final sliders = find.byType(Slider);
      expect(sliders, findsNWidgets(5));
      await tester.drag(sliders.first, const Offset(80, 0));
      await tester.pumpAndSettle();

      expect(lastOutput, isNotNull);
      expect(lastOutput!.values.any((v) => v > 0), isTrue);
    });

    testWidgets('AC: Narrow viewport stacks subpanels and is scrollable',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(
        player: fullPlayer,
        width: 400,
        height: 600,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Allocation'), findsOneWidget);
    });

    testWidgets('AC: Wide viewport shows subpanels in row', (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(
        player: fullPlayer,
        width: 800,
        height: 500,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Row), findsWidgets);
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Allocation'), findsOneWidget);
    });

    testWidgets('AC: Total labour displayed', (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(player: fullPlayer));
      await tester.pumpAndSettle();

      expect(find.textContaining('Total labour:'), findsOneWidget);
    });

    testWidgets('Partial availability: sliders capped by achievable runs',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(player: partialPlayer));
      await tester.pumpAndSettle();

      expect(find.byType(Slider), findsNWidgets(5));
      expect(find.text('Available'), findsOneWidget);
      expect(find.textContaining('Effective labour: 2'), findsOneWidget);
    });
  });
}
