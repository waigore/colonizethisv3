// Tests for ProductionPanel. SPEC/ui/production-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/production_panel.dart';
import 'package:colonizethis_app/widgets/ct_slider.dart';
import 'package:colonizethis_app/widgets/resource_icon.dart';
import 'package:colonizethis_app/widgets/strict_asset_icon.dart';
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
    Game? gameOverride,
    Map<String, int> desiredOutputByRecipe = const {},
    ValueChanged<Map<String, int>>? onDesiredOutputChanged,
    double width = 800,
    double height = 500,
  }) {
    final displayGame = gameOverride ?? game;
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: width,
          height: height,
          child: ProductionPanel(
            game: displayGame,
            player: player,
            topology: const MapTopology(),
            tileMapByRegion: null,
            desiredOutputByRecipe: desiredOutputByRecipe,
            onDesiredOutputChanged: onDesiredOutputChanged ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('ProductionPanel', () {
    testWidgets('Available subpanel shows commodity groups', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildPanel(player: fullPlayer));
      await tester.pumpAndSettle();

      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Raw Materials'), findsOneWidget);
      expect(find.text('Manufactured'), findsOneWidget);
      expect(find.text('Workers'), findsOneWidget);
      expect(find.textContaining('Effective labour:'), findsOneWidget);
    });

    testWidgets('Available subpanel shows raw materials used as inputs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildPanel(player: fullPlayer));
      await tester.pumpAndSettle();

      expect(find.textContaining('Timber:'), findsOneWidget);
      expect(find.textContaining('Iron:'), findsOneWidget);
      expect(find.textContaining('Coal:'), findsOneWidget);
    });

    testWidgets('Allocation subpanel shows recipe labels with inputs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildPanel(player: fullPlayer));
      await tester.pumpAndSettle();

      expect(find.text('Allocation'), findsOneWidget);
      expect(
        find.byType(CtSlider),
        findsNWidgets(ProductionRecipesCatalog.all.length),
      );
      expect(find.textContaining('Lumber'), findsWidgets);
      expect(find.textContaining('Fabric'), findsWidgets);
    });

    testWidgets(
      'Allocation rows show right-aligned affordance max · bottleneck',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildPanel(player: fullPlayer));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('·'),
          findsAtLeastNWidgets(ProductionRecipesCatalog.all.length),
        );
      },
    );

    testWidgets(
      'Full availability: sliders enable comfort headroom at default allocation',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildPanel(player: fullPlayer));
        await tester.pumpAndSettle();

        final sliders = tester
            .widgetList<CtSlider>(find.byType(CtSlider))
            .toList();
        expect(sliders, isNotEmpty);
        expect(
          sliders.every((s) => s.comfortHeadroomActive),
          isTrue,
        );
      },
    );

    testWidgets('Reset button clears all allocations', (
      WidgetTester tester,
    ) async {
      Map<String, int>? lastOutput;
      await tester.pumpWidget(
        buildPanel(
          player: fullPlayer,
          desiredOutputByRecipe: {'lumber_from_timber': 5},
          onDesiredOutputChanged: (next) => lastOutput = Map.from(next),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reset'), findsOneWidget);
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(lastOutput, isNotNull);
      expect(lastOutput!.isEmpty, isTrue);
    });

    testWidgets('Moving slider calls onDesiredOutputChanged', (
      WidgetTester tester,
    ) async {
      Map<String, int>? lastOutput;
      await tester.pumpWidget(
        buildPanel(
          player: fullPlayer,
          onDesiredOutputChanged: (next) => lastOutput = Map.from(next),
        ),
      );
      await tester.pumpAndSettle();

      final sliders = find.byType(CtSlider);
      expect(sliders, findsNWidgets(ProductionRecipesCatalog.all.length));
      await tester.drag(sliders.first, const Offset(80, 0));
      await tester.pumpAndSettle();

      expect(lastOutput, isNotNull);
      expect(lastOutput!.values.any((v) => v > 0), isTrue);
    });

    testWidgets('Narrow viewport stacks subpanels and is scrollable', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildPanel(player: fullPlayer, width: 400, height: 600),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Allocation'), findsOneWidget);
    });

    testWidgets('Wide viewport shows subpanels in row', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildPanel(player: fullPlayer, width: 800, height: 500),
      );
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

    testWidgets('Net changes shown when allocations exist', (
      WidgetTester tester,
    ) async {
      final isolatedGame = Game(
        id: 'production-panel-net',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: [fullPlayer],
      );
      await tester.pumpWidget(
        buildPanel(
          player: fullPlayer,
          gameOverride: isolatedGame,
          desiredOutputByRecipe: {'lumber_from_timber': 5},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Timber:'), findsOneWidget);
      expect(find.textContaining(RegExp(r'\(-10\)')), findsOneWidget);
      expect(find.textContaining('Lumber:'), findsOneWidget);
      expect(find.textContaining(RegExp(r'\(\+5\)')), findsOneWidget);
    });

    testWidgets('Partial availability: sliders capped by achievable runs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildPanel(player: partialPlayer));
      await tester.pumpAndSettle();

      expect(
        find.byType(CtSlider),
        findsNWidgets(ProductionRecipesCatalog.all.length),
      );
      expect(find.text('Available'), findsOneWidget);
      expect(find.textContaining('Effective labour: 2'), findsOneWidget);
    });

    testWidgets(
      'Over-allocating labour shows insufficient labour warning in summary',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildPanel(
            player: fullPlayer,
            desiredOutputByRecipe: {
              // Choose a recipe and deliberately over-allocate beyond what labour allows.
              'lumber_from_timber': 999,
            },
          ),
        );
        await tester.pumpAndSettle();

        // Summary line should turn into an error-coloured warning with explanatory text.
        expect(find.textContaining('Total labour:'), findsOneWidget);
        expect(
          find.text(
            'Insufficient labour — production will be capped next turn',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Unknown recipe ids are ignored when computing total labour (no warning)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildPanel(
            player: fullPlayer,
            desiredOutputByRecipe: {
              // Not a real production recipe id; should be ignored by the panel.
              'definitely_not_a_recipe_id': 5,
            },
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Total labour:'), findsOneWidget);
        expect(
          find.text(
            'Insufficient labour — production will be capped next turn',
          ),
          findsNothing,
        );
      },
    );

    testWidgets('Recipe labels show output with inputs in parentheses', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildPanel(player: fullPlayer));
      await tester.pumpAndSettle();

      expect(find.textContaining('('), findsWidgets);
      expect(find.textContaining('Lumber'), findsWidgets);
      expect(find.textContaining('Fabric'), findsWidgets);
    });
  });

  group('ResourceIcon', () {
    testWidgets('ResourceIcon displays for known commodities', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ResourceIcon(commodityId: 'grain', size: 16),
                ResourceIcon(commodityId: 'timber', size: 16),
                ResourceIcon(commodityId: 'lumber', size: 16),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ResourceIcon), findsNWidgets(3));
    });

    testWidgets('ResourceIcon returns empty for unknown commodity', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResourceIcon(commodityId: 'unknown_commodity', size: 16),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ResourceIcon), findsOneWidget);
    });

    testWidgets('ResourceLabelInline shows icon and label text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResourceLabelInline(commodityId: 'grain', label: 'grain'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StrictAssetIcon), findsOneWidget);
      expect(find.text('grain'), findsOneWidget);
    });

    testWidgets('ResourceLabelInline reserves space when commodity has no icon asset', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResourceLabelInline(commodityId: 'no_ui_icon_commodity'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StrictAssetIcon), findsNothing);
      expect(find.text('no_ui_icon_commodity'), findsOneWidget);
      expect(find.byType(ResourceIcon), findsOneWidget);
    });
  });

  group('WorkerIcon', () {
    testWidgets('WorkerIcon displays for known worker types', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                WorkerIcon(workerType: 'peasant', size: 16),
                WorkerIcon(workerType: 'apprentice', size: 16),
                WorkerIcon(workerType: 'journeyman', size: 16),
                WorkerIcon(workerType: 'master', size: 16),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(WorkerIcon), findsNWidgets(4));
    });

    testWidgets('WorkerIcon returns empty for unknown type', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WorkerIcon(workerType: 'unknown', size: 16)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(WorkerIcon), findsOneWidget);
    });
  });
}
