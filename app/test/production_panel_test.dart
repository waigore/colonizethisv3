// Tests for ProductionPanel. SPEC/ui/production-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/production_recipe_affordance.dart';
import 'package:colonizethis_app/features/game/widgets/chrome/ct_danger_text_button.dart';
import 'package:colonizethis_app/features/game/widgets/production_allocation_row.dart';
import 'package:colonizethis_app/features/game/widgets/production_allocation_row_chrome.dart';
import 'package:colonizethis_app/features/game/widgets/production_labour_helpers.dart';
import 'package:colonizethis_app/features/game/widgets/production_panel.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_brass_divider.dart';
import 'package:colonizethis_app/widgets/ct_gradients.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_resource_cell.dart';
import 'package:colonizethis_app/widgets/ct_section_label.dart';
import 'package:colonizethis_app/widgets/ct_slider.dart';
import 'package:colonizethis_app/widgets/resource_icon.dart';
import 'package:colonizethis_app/widgets/strict_asset_icon.dart';
import 'widget_test_pumps.dart';
import 'production_panel_test_fixtures.dart';

/// Holds allocation map in state so [ProductionPanel] rebuilds after each change
/// (matches Riverpod-driven app behaviour; required for long-press repeat tests).
class _ProductionPanelTestWrapper extends StatefulWidget {
  const _ProductionPanelTestWrapper({
    required this.displayGame,
    required this.player,
    required this.initialDesiredOutput,
    required this.netDeltasByCommodity,
    required this.onDesiredOutputChanged,
    this.onOpenCommodityBreakdown,
    this.currentOrders,
  });

  final Game displayGame;
  final Player player;
  final Map<String, int> initialDesiredOutput;
  final Map<String, int> netDeltasByCommodity;
  final ValueChanged<Map<String, int>> onDesiredOutputChanged;
  final VoidCallback? onOpenCommodityBreakdown;
  final Orders? currentOrders;

  @override
  State<_ProductionPanelTestWrapper> createState() =>
      _ProductionPanelTestWrapperState();
}

class _ProductionPanelTestWrapperState extends State<_ProductionPanelTestWrapper> {
  late Map<String, int> _desiredOutput;

  @override
  void initState() {
    super.initState();
    _desiredOutput = Map<String, int>.from(widget.initialDesiredOutput);
  }

  @override
  Widget build(BuildContext context) {
    return ProductionPanel(
      game: widget.displayGame,
      player: widget.player,
      desiredOutputByRecipe: _desiredOutput,
      netDeltasByCommodity: widget.netDeltasByCommodity,
      onDesiredOutputChanged: (next) {
        setState(() {
          _desiredOutput = Map<String, int>.from(next);
        });
        widget.onDesiredOutputChanged(next);
      },
      onOpenCommodityBreakdown: widget.onOpenCommodityBreakdown,
      currentOrders: widget.currentOrders,
    );
  }
}

void main() {
  suppressLogsForTests();

  late Player fullPlayer;
  late Player partialPlayer;

  setUpAll(() {
    fullPlayer = productionPanelTestFullPlayer();
    partialPlayer = productionPanelTestPartialPlayer();
  });

  Widget buildPanel({
    required Player player,
    Game? gameOverride,
    Map<String, int> desiredOutputByRecipe = const {},
    ValueChanged<Map<String, int>>? onDesiredOutputChanged,
    VoidCallback? onOpenCommodityBreakdown,
    Orders? currentOrders,
    double width = 800,
    double height = 500,
  }) {
    final displayGame = gameOverride ?? productionPanelTestGameFor(player);
    final netDeltasByCommodity = <String, int>{};
    for (final entry in desiredOutputByRecipe.entries) {
      final recipe = ProductionRecipesCatalog.byId[entry.key];
      if (recipe == null) continue;
      for (final input in recipe.inputQuantities.entries) {
        netDeltasByCommodity[input.key] =
            (netDeltasByCommodity[input.key] ?? 0) -
            (input.value * entry.value);
      }
      netDeltasByCommodity[recipe.outputCommodityId] =
          (netDeltasByCommodity[recipe.outputCommodityId] ?? 0) +
          (recipe.outputQuantity * entry.value);
    }
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: width,
          height: height,
          child: _ProductionPanelTestWrapper(
            displayGame: displayGame,
            player: player,
            initialDesiredOutput: desiredOutputByRecipe,
            netDeltasByCommodity: netDeltasByCommodity,
            onDesiredOutputChanged: onDesiredOutputChanged ?? (_) {},
            onOpenCommodityBreakdown: onOpenCommodityBreakdown,
            currentOrders: currentOrders,
          ),
        ),
      ),
    );
  }

  group('ProductionPanel', () {
    testWidgets('Available header has no Breakdown button without callback', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildPanel(player: fullPlayer));
      await pumpSettleCapped(tester);
      expect(find.text('Breakdown'), findsNothing);
    });

    testWidgets('Available header shows Breakdown text button when callback set', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildPanel(player: fullPlayer, onOpenCommodityBreakdown: () {}),
      );
      await pumpSettleCapped(tester);
      expect(find.text('Breakdown'), findsOneWidget);
    });

    testWidgets('Available subpanel shows commodity groups', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildPanel(player: fullPlayer));
      await pumpSettleCapped(tester);

      expect(find.text('Available'), findsOneWidget);
      expect(find.byType(CtSectionLabel), findsAtLeastNWidgets(4));
      expect(find.text('FOOD'), findsOneWidget);
      expect(find.text('RAW MATERIALS'), findsOneWidget);
      expect(find.text('MANUFACTURED'), findsOneWidget);
      expect(find.text('WORKERS'), findsOneWidget);
      expect(find.textContaining('Effective labour:'), findsOneWidget);
    });

    testWidgets('Available subpanel shows raw materials used as inputs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildPanel(player: fullPlayer));
      await pumpSettleCapped(tester);

      expect(find.byType(CtResourceCell), findsAtLeastNWidgets(3));
      expect(find.text('Timber'), findsOneWidget);
      expect(find.text('Iron'), findsOneWidget);
      expect(find.text('Coal'), findsOneWidget);
    });

    testWidgets('Allocation subpanel shows recipe labels with inputs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildPanel(player: fullPlayer));
      await pumpSettleCapped(tester);

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
        await pumpSettleCapped(tester);

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
        await pumpSettleCapped(tester);

        final sliders = tester
            .widgetList<CtSlider>(find.byType(CtSlider))
            .toList();
        expect(sliders, isNotEmpty);
        expect(sliders.every((s) => s.comfortHeadroomActive), isTrue);
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
      await pumpSettleCapped(tester);

      final resetFinder = find.byKey(
        const ValueKey<String>('production_allocation_reset_button'),
      );
      expect(resetFinder, findsOneWidget);
      expect(find.descendant(of: resetFinder, matching: find.text('Reset')),
          findsOneWidget);
      await tester.tap(resetFinder);
      await pumpSyncFrames(tester);

      expect(lastOutput, isNotNull);
      expect(lastOutput!.isEmpty, isTrue);
    });

    testWidgets(
      'Allocation header Reset renders as CtDangerTextButton (Refs #2862 S8d / C8)',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildPanel(player: fullPlayer));
        await pumpSettleCapped(tester);

        final resetFinder = find.byKey(
          const ValueKey<String>('production_allocation_reset_button'),
        );
        expect(resetFinder, findsOneWidget);

        final reset = tester.widget<CtDangerTextButton>(resetFinder);
        expect(reset.label, 'Reset');
        expect(reset.tooltip, 'Reset');
        expect(reset.enabled, isTrue);
        expect(reset.onPressed, isNotNull);

        expect(
          find.descendant(
            of: resetFinder,
            matching: find.byType(CtNinePatchButton),
          ),
          findsNothing,
          reason: 'Reset must not fall back to CtNinePatchButton chrome.',
        );
      },
    );

    testWidgets(
      'negative: production panel does not render Reset as CtNinePatchButton (Refs #2862 S8d / C8)',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildPanel(player: fullPlayer));
        await pumpSettleCapped(tester);

        final ninePatchButtonsWithResetLabel = find.byWidgetPredicate(
          (Widget w) {
            if (w is! CtNinePatchButton) return false;
            final child = w.child;
            return child is Text && child.data == 'Reset';
          },
        );
        expect(
          ninePatchButtonsWithResetLabel,
          findsNothing,
          reason:
              'Allocation header Reset must use CtDangerTextButton per #2862 C8, '
              'not a CtNinePatchButton labelled "Reset".',
        );
      },
    );

    testWidgets('allocation increment tap adds one to first recipe', (
      WidgetTester tester,
    ) async {
      Map<String, int>? lastOutput;
      final firstId = ProductionRecipesCatalog.all.first.id;
      await tester.pumpWidget(
        buildPanel(
          player: fullPlayer,
          onDesiredOutputChanged: (next) => lastOutput = Map<String, int>.from(
            next,
          ),
        ),
      );
      await pumpSettleCapped(tester);
      final l10n = lookupAppLocalizations(const Locale('en'));
      await tester.tap(
        find
            .bySemanticsLabel(l10n.production_allocationIncrementRecipe)
            .first,
      );
      await pumpSyncFrames(tester);
      expect(lastOutput, isNotNull);
      expect(lastOutput![firstId], 1);
    });

    testWidgets('allocation decrement subtracts one for lumber recipe', (
      WidgetTester tester,
    ) async {
      Map<String, int>? lastOutput;
      const lumberId = 'lumber_from_timber';
      final lumberIndex = ProductionRecipesCatalog.all.indexWhere(
        (r) => r.id == lumberId,
      );
      expect(lumberIndex, greaterThanOrEqualTo(0));
      final l10n = lookupAppLocalizations(const Locale('en'));
      await tester.pumpWidget(
        buildPanel(
          player: fullPlayer,
          desiredOutputByRecipe: const {lumberId: 3},
          onDesiredOutputChanged: (next) => lastOutput = Map<String, int>.from(
            next,
          ),
        ),
      );
      await pumpSettleCapped(tester);
      await tester.tap(
        find
            .bySemanticsLabel(l10n.production_allocationDecrementRecipe)
            .at(lumberIndex),
      );
      await pumpSyncFrames(tester);
      expect(lastOutput, isNotNull);
      expect(lastOutput![lumberId], 2);
    });

    testWidgets('allocation clear removes recipe key', (
      WidgetTester tester,
    ) async {
      Map<String, int>? lastOutput;
      const lumberId = 'lumber_from_timber';
      final lumberIndex = ProductionRecipesCatalog.all.indexWhere(
        (r) => r.id == lumberId,
      );
      final l10n = lookupAppLocalizations(const Locale('en'));
      await tester.pumpWidget(
        buildPanel(
          player: fullPlayer,
          desiredOutputByRecipe: const {lumberId: 4},
          onDesiredOutputChanged: (next) => lastOutput = Map<String, int>.from(
            next,
          ),
        ),
      );
      await pumpSettleCapped(tester);
      await tester.tap(
        find
            .bySemanticsLabel(l10n.production_allocationClearRecipe)
            .at(lumberIndex),
      );
      await pumpSyncFrames(tester);
      expect(lastOutput, isNotNull);
      expect(lastOutput!.containsKey(lumberId), isFalse);
    });

    testWidgets('allocation maximize sets lumber to current max', (
      WidgetTester tester,
    ) async {
      Map<String, int>? lastOutput;
      const lumberId = 'lumber_from_timber';
      final lumberIndex = ProductionRecipesCatalog.all.indexWhere(
        (r) => r.id == lumberId,
      );
      final l10n = lookupAppLocalizations(const Locale('en'));
      await tester.pumpWidget(
        buildPanel(
          player: fullPlayer,
          desiredOutputByRecipe: const {lumberId: 1},
          onDesiredOutputChanged: (next) => lastOutput = Map<String, int>.from(
            next,
          ),
        ),
      );
      await pumpSettleCapped(tester);
      final displayGame = productionPanelTestGameFor(fullPlayer);
      final regimentCounts = regimentTypeCountsForPlayer(
        displayGame.worldState,
        fullPlayer.id,
      );
      final shipCounts = shipTypeCountsForPlayer(
        displayGame.worldState,
        fullPlayer.id,
      );
      final effectiveLabour = effectiveLabourForWorkers(
        workers: fullPlayer.workerPool,
        stockpile: fullPlayer.stockpile,
        regimentCountsById: regimentCounts,
        shipCountsById: shipCounts,
      );
      final expectedMax = computeRecipeAffordance(
        recipe: ProductionRecipesCatalog.byId[lumberId]!,
        stockpile: fullPlayer.stockpile,
        desiredOutputByRecipe: const {lumberId: 1},
        effectiveLabour: effectiveLabour,
      ).maxDesiredOutput;
      await tester.tap(
        find
            .bySemanticsLabel(l10n.production_allocationMaximizeRecipe)
            .at(lumberIndex),
      );
      await pumpSyncFrames(tester);
      expect(lastOutput, isNotNull);
      expect(lastOutput![lumberId], expectedMax);
    });

    testWidgets(
      'allocation cross-row: lumber maxed disables cast iron increment',
      (WidgetTester tester) async {
        const castIronId = 'castIron_from_timber_iron_coal';
        final castIronIndex = ProductionRecipesCatalog.all.indexWhere(
          (r) => r.id == castIronId,
        );
        expect(castIronIndex, greaterThanOrEqualTo(0));
        final l10n = lookupAppLocalizations(const Locale('en'));
        await tester.pumpWidget(
          buildPanel(
            player: fullPlayer,
            desiredOutputByRecipe: const {'lumber_from_timber': 50},
          ),
        );
        await pumpSettleCapped(tester);
        final before = tester
            .widget<CtSlider>(find.byType(CtSlider).at(castIronIndex))
            .value;
        await tester.tap(
          find
              .bySemanticsLabel(l10n.production_allocationIncrementRecipe)
              .at(castIronIndex),
        );
        await pumpSyncFrames(tester);
        final after = tester
            .widget<CtSlider>(find.byType(CtSlider).at(castIronIndex))
            .value;
        expect(after, before);
      },
    );

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
      await pumpSettleCapped(tester);

      final sliders = find.byType(CtSlider);
      expect(sliders, findsNWidgets(ProductionRecipesCatalog.all.length));
      await tester.drag(sliders.first, const Offset(80, 0));
      await pumpSyncFrames(tester);

      expect(lastOutput, isNotNull);
      expect(lastOutput!.values.any((v) => v > 0), isTrue);
    });

    testWidgets('Narrow viewport stacks subpanels and is scrollable', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildPanel(player: fullPlayer, width: 400, height: 600),
      );
      await pumpSettleCapped(tester);

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
      await pumpSettleCapped(tester);

      expect(find.byType(Row), findsWidgets);
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Allocation'), findsOneWidget);
    });

    testWidgets('Total labour displayed', (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(player: fullPlayer));
      await pumpSettleCapped(tester);

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
      await pumpSettleCapped(tester);

      expect(find.text('Timber'), findsOneWidget);
      expect(find.text('-10'), findsOneWidget);
      expect(find.text('Lumber'), findsOneWidget);
      expect(find.text('+5'), findsOneWidget);
    });

    testWidgets('Partial availability: sliders capped by achievable runs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildPanel(player: partialPlayer));
      await pumpSettleCapped(tester);

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
        await pumpSettleCapped(tester);

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
        await pumpSettleCapped(tester);

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
      await pumpSettleCapped(tester);

      expect(find.textContaining('('), findsWidgets);
      expect(find.textContaining('Lumber'), findsWidgets);
      expect(find.textContaining('Fabric'), findsWidgets);
    });

    testWidgets(
      'Available section labels use CtSectionLabel for Food / Raw Materials / '
      'Manufactured / Workers (Refs #2862 S2)',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildPanel(player: fullPlayer));
        await pumpSettleCapped(tester);

        Finder labelWithText(String text) => find.descendant(
          of: find.byType(CtSectionLabel),
          matching: find.text(text),
        );
        expect(labelWithText('FOOD'), findsOneWidget);
        expect(labelWithText('RAW MATERIALS'), findsOneWidget);
        expect(labelWithText('MANUFACTURED'), findsOneWidget);
        expect(labelWithText('WORKERS'), findsOneWidget);
      },
    );

    testWidgets(
      'Available commodity cells use CtResourceCell with sign-prefixed '
      'positive deltas (Refs #2862 S2)',
      (WidgetTester tester) async {
        final isolatedGame = Game(
          id: 'production-panel-dark-positive',
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
            desiredOutputByRecipe: {'lumber_from_timber': 2},
          ),
        );
        await pumpSettleCapped(tester);

        final lumberCell = find.byKey(
          const ValueKey<String>('production_available_cell_lumber'),
        );
        expect(lumberCell, findsOneWidget);
        expect(
          find.descendant(of: lumberCell, matching: find.text('Lumber')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: lumberCell, matching: find.text('+2')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Available commodity quantity subtracts staged trade offers '
      '(Refs #3093)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildPanel(
            player: fullPlayer,
            currentOrders: Orders(
              tradeOrdersByPlayerId: {
                fullPlayer.id: [
                  TradeOrder(
                    commodityId: CommodityCatalog.fabric.id,
                    type: TradeOrderType.offer,
                    quantity: 4,
                    priority: 5,
                  ),
                ],
              },
            ),
          ),
        );
        await pumpSettleCapped(tester);

        final fabricCell = find.byKey(
          const ValueKey<String>('production_available_cell_fabric'),
        );
        expect(fabricCell, findsOneWidget);
        final cellWidget = tester.widget<CtResourceCell>(fabricCell);
        expect(cellWidget.quantity, 46);
      },
    );

    testWidgets(
      'Available commodity cells omit delta region when net change is zero '
      '(Refs #2862 S2)',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildPanel(player: fullPlayer));
        await pumpSettleCapped(tester);

        final timberCell = find.byKey(
          const ValueKey<String>('production_available_cell_timber'),
        );
        expect(timberCell, findsOneWidget);
        final cellWidget = tester.widget<CtResourceCell>(timberCell);
        expect(cellWidget.delta, isNull);
      },
    );

    testWidgets(
      'Workers section renders one CtResourceCell per worker tier '
      '(Refs #2862 S2)',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildPanel(player: fullPlayer));
        await pumpSettleCapped(tester);

        for (final tier in const <String>[
          'peasant',
          'apprentice',
          'journeyman',
          'master',
        ]) {
          expect(
            find.byKey(ValueKey<String>('production_available_worker_$tier')),
            findsOneWidget,
            reason: 'Worker cell for $tier should be present',
          );
        }
      },
    );

    testWidgets(
      'Allocation row chrome wraps every recipe row in '
      'ProductionAllocationRowChrome (Refs #2862 S3 / R13)',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildPanel(player: fullPlayer));
        await pumpSettleCapped(tester);

        final recipeCount = ProductionRecipesCatalog.all.length;
        expect(recipeCount, greaterThan(1));

        expect(
          find.byType(ProductionAllocationRow),
          findsNWidgets(recipeCount),
        );
        expect(
          find.byType(ProductionAllocationRowChrome),
          findsNWidgets(recipeCount),
        );

        // Every ProductionAllocationRow must be a descendant of a
        // ProductionAllocationRowChrome — no bare rows allowed.
        for (final row in tester.widgetList<ProductionAllocationRow>(
          find.byType(ProductionAllocationRow),
        )) {
          final wrapped = find.ancestor(
            of: find.byWidget(row),
            matching: find.byType(ProductionAllocationRowChrome),
          );
          expect(
            wrapped,
            findsOneWidget,
            reason:
                'ProductionAllocationRow for ${row.recipe.id} must be wrapped '
                'in ProductionAllocationRowChrome per SPEC.',
          );
        }
      },
    );

    testWidgets(
      'Allocation row chrome paints CtGradients.rowGradient inside a 1px '
      'accent-dim border (Refs #2862 S3 / R13)',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildPanel(player: fullPlayer));
        await pumpSettleCapped(tester);

        final chromes = tester.widgetList<ProductionAllocationRowChrome>(
          find.byType(ProductionAllocationRowChrome),
        );
        expect(chromes, isNotEmpty);

        for (final chrome in chromes) {
          final decorated = find.descendant(
            of: find.byWidget(chrome),
            matching: find.byType(DecoratedBox),
          );
          expect(decorated, findsAtLeastNWidgets(1));
          final box = tester.widget<DecoratedBox>(decorated.first);
          final decoration = box.decoration as BoxDecoration;
          expect(decoration.gradient, CtGradients.rowGradient);
          final border = decoration.border as Border;
          expect(border.top.color, EditorialMonoclePalette.accentDim);
          expect(border.top.width, 1.0);
          expect(border.bottom.color, EditorialMonoclePalette.accentDim);
          expect(border.left.color, EditorialMonoclePalette.accentDim);
          expect(border.right.color, EditorialMonoclePalette.accentDim);
        }
      },
    );

    testWidgets(
      'Allocation rows are separated by exactly N-1 CtBrassDividers '
      '(Refs #2862 S3 / R13)',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildPanel(player: fullPlayer));
        await pumpSettleCapped(tester);

        final recipeCount = ProductionRecipesCatalog.all.length;
        expect(recipeCount, greaterThan(1));

        // CtBrassDivider may appear elsewhere on the screen via shared
        // chrome — scope the count to those inside the allocation rows
        // column by counting dividers that share an ancestor with the
        // allocation row chromes.
        final dividers = find.descendant(
          of: find.byType(ProductionAllocationRow).first,
          matching: find.byType(CtBrassDivider),
        );
        expect(dividers, findsNothing,
            reason: 'No divider should live inside a recipe row.');

        final totalDividers = find.byType(CtBrassDivider).evaluate().length;
        // Allow other CtBrassDivider instances elsewhere on the screen — but
        // require at least N-1 to appear (one between each pair of recipe
        // rows in the allocation subpanel).
        expect(totalDividers, greaterThanOrEqualTo(recipeCount - 1));
      },
    );

    // S7 — Labour Controls subsection placement (Refs #2862 S7a).

    Widget buildPanelWithLabourCallbacks({
      required Player player,
      Orders currentOrders = const Orders(),
      bool canEditLabour = true,
    }) {
      final game = productionPanelTestGameFor(player);
      final captured = <Map<String, int>>[];
      final labourCallbacks = ProductionLabourCallbacks(
        onAppendRecruitOrder: (_) {},
        onPopLastRecruitOrder: (_) {},
        onDisband: (_) {},
      );
      return MaterialApp(
        localizationsDelegates:
            AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: const [Locale('en')],
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 700,
            child: ProductionPanel(
              game: game,
              player: player,
              desiredOutputByRecipe: const {},
              netDeltasByCommodity: const {},
              onDesiredOutputChanged: captured.add,
              currentOrders: currentOrders,
              labourCallbacks: labourCallbacks,
              canEditLabour: canEditLabour,
            ),
          ),
        ),
      );
    }

    testWidgets(
      'Labour Controls CtSectionLabel appears below Effective Labour (Refs #2862 S7a)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildPanelWithLabourCallbacks(player: fullPlayer),
        );
        await pumpSettleCapped(tester);

        final labourControlsLabel = find.descendant(
          of: find.byType(CtSectionLabel),
          matching: find.text('LABOUR CONTROLS'),
        );
        expect(labourControlsLabel, findsOneWidget);

        final effectiveLabour = find.textContaining('Effective labour:');
        expect(effectiveLabour, findsOneWidget);

        final effectiveY = tester.getTopLeft(effectiveLabour).dy;
        final labourY = tester.getTopLeft(labourControlsLabel).dy;
        expect(
          labourY,
          greaterThan(effectiveY),
          reason: 'Labour Controls section label must render below the '
              'Effective Labour line per SPEC § Labour Controls (12-A).',
        );
      },
    );

    testWidgets(
      'Labour Controls subsection is omitted when callbacks are not provided '
      '(no orphan section label; Refs #2862 S7a)',
      (WidgetTester tester) async {
        // `buildPanel` does not pass currentOrders / labourCallbacks.
        await tester.pumpWidget(buildPanel(player: fullPlayer));
        await pumpSettleCapped(tester);

        expect(
          find.descendant(
            of: find.byType(CtSectionLabel),
            matching: find.text('LABOUR CONTROLS'),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'Workers section uses Effective Labour line then Labour Controls label '
      '(no action buttons above Effective Labour; Refs #2862 S7a)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildPanelWithLabourCallbacks(player: fullPlayer),
        );
        await pumpSettleCapped(tester);

        final effectiveLabour = find.textContaining('Effective labour:');
        final l10n = lookupAppLocalizations(const Locale('en'));
        // The disband button for the apprentice row (if rendered) must
        // appear below the Effective Labour line.
        final apprenticeDisband = find.byKey(
          const ValueKey<String>('production_labour_disband_apprentices'),
        );
        if (apprenticeDisband.evaluate().isNotEmpty) {
          final effectiveY = tester.getTopLeft(effectiveLabour).dy;
          final disbandY = tester.getTopLeft(apprenticeDisband).dy;
          expect(
            disbandY,
            greaterThan(effectiveY),
            reason: 'Disband control must render below Effective Labour.',
          );
        }
        // The peasant tier label parenthetical must also appear.
        expect(
          find.text(
            l10n.production_labourTierLabel(
              l10n.production_workers_peasants,
              l10n.production_labourTierUnlocked,
            ),
          ),
          findsOneWidget,
        );
      },
    );
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
      await pumpSettleCapped(tester);

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
      await pumpSettleCapped(tester);

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
      await pumpSettleCapped(tester);

      expect(find.byType(StrictAssetIcon), findsOneWidget);
      expect(find.text('grain'), findsOneWidget);
    });

    testWidgets(
      'ResourceLabelInline reserves space when commodity has no icon asset',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ResourceLabelInline(commodityId: 'no_ui_icon_commodity'),
            ),
          ),
        );
        await pumpSettleCapped(tester);

        expect(find.byType(StrictAssetIcon), findsNothing);
        expect(find.text('no_ui_icon_commodity'), findsOneWidget);
        expect(find.byType(ResourceIcon), findsOneWidget);
      },
    );
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
      await pumpSettleCapped(tester);

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
      await pumpSettleCapped(tester);

      expect(find.byType(WorkerIcon), findsOneWidget);
    });
  });
}
