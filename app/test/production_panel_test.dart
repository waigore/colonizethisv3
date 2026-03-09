// Tests for ProductionPanel. SPEC/ui/production-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
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
    testWidgets('Available subpanel shows commodity groups',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(player: fullPlayer));
      await tester.pumpAndSettle();

      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Raw Materials'), findsOneWidget);
      expect(find.text('Manufactured'), findsOneWidget);
      expect(find.text('Workers'), findsOneWidget);
      expect(find.textContaining('Effective labour:'), findsOneWidget);
    });

    testWidgets('Available subpanel shows raw materials used as inputs',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(player: fullPlayer));
      await tester.pumpAndSettle();

      expect(find.textContaining('Timber:'), findsOneWidget);
      expect(find.textContaining('Iron:'), findsOneWidget);
      expect(find.textContaining('Coal:'), findsOneWidget);
    });

    testWidgets('Allocation subpanel shows recipe labels with inputs',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(player: fullPlayer));
      await tester.pumpAndSettle();

      expect(find.text('Allocation'), findsOneWidget);
      expect(find.byType(Slider),
          findsNWidgets(ProductionRecipesCatalog.all.length));
      expect(find.textContaining('Lumber'), findsWidgets);
      expect(find.textContaining('Fabric'), findsWidgets);
    });

    testWidgets('Reset button clears all allocations',
        (WidgetTester tester) async {
      Map<String, int>? lastOutput;
      await tester.pumpWidget(buildPanel(
        player: fullPlayer,
        desiredOutputByRecipe: {'lumber_from_timber': 5},
        onDesiredOutputChanged: (next) => lastOutput = Map.from(next),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Reset'), findsOneWidget);
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(lastOutput, isNotNull);
      expect(lastOutput!.isEmpty, isTrue);
    });

    testWidgets('Moving slider calls onDesiredOutputChanged',
        (WidgetTester tester) async {
      Map<String, int>? lastOutput;
      await tester.pumpWidget(buildPanel(
        player: fullPlayer,
        onDesiredOutputChanged: (next) => lastOutput = Map.from(next),
      ));
      await tester.pumpAndSettle();

      final sliders = find.byType(Slider);
      expect(sliders, findsNWidgets(ProductionRecipesCatalog.all.length));
      await tester.drag(sliders.first, const Offset(80, 0));
      await tester.pumpAndSettle();

      expect(lastOutput, isNotNull);
      expect(lastOutput!.values.any((v) => v > 0), isTrue);
    });

    testWidgets('Narrow viewport stacks subpanels and is scrollable',
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

    testWidgets('Wide viewport shows subpanels in row',
        (WidgetTester tester) async {
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

    testWidgets('Total labour displayed', (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(player: fullPlayer));
      await tester.pumpAndSettle();

      expect(find.textContaining('Total labour:'), findsOneWidget);
    });

    testWidgets('Net changes shown when allocations exist',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(
        player: fullPlayer,
        desiredOutputByRecipe: {'lumber_from_timber': 5},
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Timber:'), findsOneWidget);
      expect(find.textContaining(RegExp(r'\(-10\)')), findsOneWidget);
      expect(find.textContaining('Lumber:'), findsOneWidget);
      expect(find.textContaining(r'(+5)'), findsOneWidget);
    });

    testWidgets('Partial availability: sliders capped by achievable runs',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(player: partialPlayer));
      await tester.pumpAndSettle();

      expect(find.byType(Slider),
          findsNWidgets(ProductionRecipesCatalog.all.length));
      expect(find.text('Available'), findsOneWidget);
      expect(find.textContaining('Effective labour: 2'), findsOneWidget);
    });

    testWidgets('Recipe labels show output with inputs in parentheses',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(player: fullPlayer));
      await tester.pumpAndSettle();

      expect(find.textContaining('('), findsWidgets);
      expect(find.textContaining('Lumber'), findsWidgets);
      expect(find.textContaining('Fabric'), findsWidgets);
    });
  });
}
