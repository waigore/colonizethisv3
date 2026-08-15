// Widget tests for Labour Controls cost / upkeep / Requires gists.
// SPEC/ui/production-panel.md § Labour Controls (12-A). Refs #4432.

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'production_labour_section_test_support.dart';
import 'production_labour_test_fixtures.dart';

void main() {
  suppressLogsForTests();
  final l10n = productionLabourSectionL10n;

  String costPlain(WidgetTester tester, WorkerTier tier) {
    final text = tester.widget<Text>(
      find.byKey(ValueKey<String>('production_labour_cost_${tier.id}')),
    );
    return text.textSpan!.toPlainText();
  }

  bool costHasDanger(WidgetTester tester, WorkerTier tier, String fragment) {
    final text = tester.widget<Text>(
      find.byKey(ValueKey<String>('production_labour_cost_${tier.id}')),
    );
    final span = text.textSpan! as TextSpan;
    var found = false;
    span.visitChildren((child) {
      if (child is! TextSpan) return true;
      if (child.text != fragment) return true;
      found = child.style?.color == EditorialMonoclePalette.danger;
      return false;
    });
    return found;
  }

  group('Labour Controls cost and upkeep gists (Refs #4432)', () {
    testWidgets(
      'peasant cost gist shows fabric display name ×2 and no (unlocked)',
      (tester) async {
        await pumpProductionLabourSection(
          tester,
          player: productionLabourSectionGpWithPool(
            stockpile: {CommodityCatalog.fabric.id: 2},
          ),
        );
        expect(costPlain(tester, WorkerTier.peasant), contains('Fabric ×2'));
        expect(
          costPlain(tester, WorkerTier.peasant),
          isNot(contains('fabric')),
        );
        expect(find.textContaining('(unlocked)'), findsNothing);
        expect(find.text(l10n.production_workers_peasants), findsOneWidget);
      },
    );

    testWidgets('apprentice cost gist shows treasury, paper, and 1 peasant', (
      tester,
    ) async {
      await pumpProductionLabourSection(
        tester,
        player: productionLabourSectionGpWithPool(
          peasants: 1,
          treasury: 200,
          stockpile: {CommodityCatalog.paper.id: 2},
          techUnlocked: productionLabourApprenticeTech,
        ),
      );
      final gist = costPlain(tester, WorkerTier.apprentice);
      expect(gist, contains('£200'));
      expect(gist, contains('Paper ×2'));
      expect(gist, contains('1 peasant'));
      expect(gist, isNot(contains('paper')));
    });

    testWidgets(
      'upkeep gist uses labour per turn and consumption food/luxury',
      (tester) async {
        await pumpProductionLabourSection(
          tester,
          player: productionLabourSectionGpWithPool(
            peasants: 1,
            techUnlocked: productionLabourFullLabourTech,
          ),
        );
        expect(
          tester
              .widget<Text>(
                find.byKey(
                  const ValueKey<String>('production_labour_upkeep_peasants'),
                ),
              )
              .data,
          '1 labour / turn · Grain or Meat',
        );
        expect(
          tester
              .widget<Text>(
                find.byKey(
                  const ValueKey<String>(
                    'production_labour_upkeep_apprentices',
                  ),
                ),
              )
              .data,
          '4 labour / turn · Grain + Meat · Refined sugar',
        );
        expect(
          tester
              .widget<Text>(
                find.byKey(
                  const ValueKey<String>('production_labour_upkeep_journeymen'),
                ),
              )
              .data,
          '6 labour / turn · Grain + Meat · Cigars',
        );
        expect(
          tester
              .widget<Text>(
                find.byKey(
                  const ValueKey<String>('production_labour_upkeep_masters'),
                ),
              )
              .data,
          '8 labour / turn · Grain + Meat · Fur hats',
        );
      },
    );

    testWidgets(
      'tech-locked trained tier shows Requires: display names, not ids or (locked)',
      (tester) async {
        await pumpProductionLabourSection(
          tester,
          player: productionLabourSectionGpWithPool(peasants: 1),
        );
        final requires = tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>(
                  'production_labour_requires_apprentices',
                ),
              ),
            )
            .data;
        expect(requires, startsWith('Requires: '));
        expect(requires, contains(techDisplayName(kTechIdApprenticeWorkers)));
        expect(requires, contains(techDisplayName(kTechIdSugarRefining)));
        expect(requires, isNot(contains(kTechIdApprenticeWorkers)));
        expect(find.textContaining('(locked)'), findsNothing);
        final plus = tester.widget<InkWell>(
          find.descendant(
            of: find.byKey(
              const ValueKey<String>('production_labour_plus_apprentices'),
            ),
            matching: find.byType(InkWell),
          ),
        );
        expect(plus.onTap, isNull);
      },
    );

    testWidgets(
      'disabled + for treasury paints £ in danger and names refusal',
      (tester) async {
        await pumpProductionLabourSection(
          tester,
          player: productionLabourSectionGpWithPool(
            peasants: 1,
            treasury: 50,
            stockpile: {CommodityCatalog.paper.id: 10},
            techUnlocked: productionLabourApprenticeTech,
          ),
        );
        expect(costHasDanger(tester, WorkerTier.apprentice, '£200'), isTrue);
        expect(
          costHasDanger(tester, WorkerTier.apprentice, 'Paper ×2'),
          isFalse,
        );
        expect(
          find.byTooltip(kRecruitWorkerInsufficientTreasury),
          findsOneWidget,
        );
      },
    );

    testWidgets('disabled + for materials paints fabric in danger', (
      tester,
    ) async {
      await pumpProductionLabourSection(
        tester,
        player: productionLabourSectionGpWithPool(
          stockpile: {CommodityCatalog.fabric.id: 1},
        ),
      );
      expect(costHasDanger(tester, WorkerTier.peasant, 'Fabric ×2'), isTrue);
      expect(
        find.byTooltip(kRecruitWorkerInsufficientMaterials),
        findsOneWidget,
      );
    });

    testWidgets('disabled + for reserved peasants paints 1 peasant in danger', (
      tester,
    ) async {
      await pumpProductionLabourSection(
        tester,
        player: productionLabourSectionGpWithPool(
          peasants: 1,
          treasury: 200,
          stockpile: {CommodityCatalog.paper.id: 2},
          techUnlocked: productionLabourApprenticeTech,
        ),
        currentOrders: productionLabourOrdersWithMilitaryBuilds(
          1,
          id: productionLabourSectionPlayerId,
        ),
      );
      expect(costHasDanger(tester, WorkerTier.apprentice, '1 peasant'), isTrue);
      expect(find.byTooltip(kRecruitWorkerInsufficientWorkers), findsOneWidget);
    });

    testWidgets(
      'affordable row keeps cost gist visible without danger colour',
      (tester) async {
        await pumpProductionLabourSection(
          tester,
          player: productionLabourSectionGpWithPool(
            stockpile: {CommodityCatalog.fabric.id: 2},
          ),
        );
        expect(costPlain(tester, WorkerTier.peasant), contains('Fabric ×2'));
        expect(costHasDanger(tester, WorkerTier.peasant, 'Fabric ×2'), isFalse);
      },
    );

    testWidgets('320 dp viewport wraps without overflow and keeps + aligned', (
      tester,
    ) async {
      await pumpProductionLabourSection(
        tester,
        player: productionLabourSectionGpWithPool(
          peasants: 1,
          apprentices: 1,
          treasury: 200,
          stockpile: {
            CommodityCatalog.fabric.id: 2,
            CommodityCatalog.paper.id: 2,
          },
          techUnlocked: productionLabourApprenticeTech,
        ),
        width: 320,
        height: 640,
      );
      expect(tester.takeException(), isNull);
      final peasantPlus = tester.getCenter(
        find.byKey(const ValueKey<String>('production_labour_plus_peasants')),
      );
      final apprenticePlus = tester.getCenter(
        find.byKey(
          const ValueKey<String>('production_labour_plus_apprentices'),
        ),
      );
      expect(apprenticePlus.dx, closeTo(peasantPlus.dx, 0.5));
    });
  });
}
