// Widget tests for Labour Controls cost / upkeep / Requires gists.
// Upkeep/requires: production_labour_tier_gist_upkeep_test.dart.
// SPEC/ui/production-panel.md § Labour Controls (12-A). Refs #4432.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart' show WorkerTier;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'production_labour_section_test_support.dart';
import 'production_labour_test_fixtures.dart';
import 'production_labour_tier_gist_support.dart';

void main() {
  suppressLogsForTests();
  final l10n = productionLabourSectionL10n;

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
        expect(
          productionLabourTierCostPlain(tester, WorkerTier.peasant),
          contains('Fabric ×2'),
        );
        expect(
          productionLabourTierCostPlain(tester, WorkerTier.peasant),
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
      final gist = productionLabourTierCostPlain(tester, WorkerTier.apprentice);
      expect(gist, contains('£200'));
      expect(gist, contains('Paper ×2'));
      expect(gist, contains('1 peasant'));
      expect(gist, isNot(contains('paper')));
    });

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
        expect(
          productionLabourTierCostHasDanger(tester, WorkerTier.apprentice, '£200'),
          isTrue,
        );
        expect(
          productionLabourTierCostHasDanger(
            tester,
            WorkerTier.apprentice,
            'Paper ×2',
          ),
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
      expect(
        productionLabourTierCostHasDanger(tester, WorkerTier.peasant, 'Fabric ×2'),
        isTrue,
      );
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
      expect(
        productionLabourTierCostHasDanger(
          tester,
          WorkerTier.apprentice,
          '1 peasant',
        ),
        isTrue,
      );
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
        expect(
          productionLabourTierCostPlain(tester, WorkerTier.peasant),
          contains('Fabric ×2'),
        );
        expect(
          productionLabourTierCostHasDanger(
            tester,
            WorkerTier.peasant,
            'Fabric ×2',
          ),
          isFalse,
        );
      },
    );
  });
}
