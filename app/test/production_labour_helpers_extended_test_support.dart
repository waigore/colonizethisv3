// Extended row/tech pins for production labour helpers (Refs #4352).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/production/production_labour_helpers.dart';
import 'production_labour_test_fixtures.dart';

void registerProductionLabourRowAndTechTests() {
  group('buildProductionLabourRowData', () {
    test('returns one row per tier in canonical order', () {
      expect(
        buildProductionLabourRowData(
          player: productionLabourGpWithPool(),
          currentOrders: const Orders(),
          canEdit: true,
        ).map((r) => r.tier).toList(),
        kProductionLabourTierOrder,
      );
    });

    test('canEdit=false disables every append, pop, and disband action', () {
      final rows = buildProductionLabourRowData(
        player: productionLabourGpWithPool(
          peasants: 5,
          masters: 3,
          treasury: 5000,
          stockpile: {
            CommodityCatalog.fabric.id: 10,
            CommodityCatalog.paper.id: 50,
          },
          techUnlocked: productionLabourFullLabourTech,
        ),
        currentOrders: productionLabourOrdersWithRecruits([WorkerTier.master]),
        canEdit: false,
      );
      for (final row in rows) {
        expect(row.canAppend, isFalse);
        expect(row.canPop, isFalse);
        expect(row.canDisband, isFalse);
      }
    });

    test('disband / pop / techUnlocked pins for peasant and trained rows', () {
      final peasantRow = buildProductionLabourRowData(
        player: productionLabourGpWithPool(peasants: 5),
        currentOrders: const Orders(),
        canEdit: true,
      ).firstWhere((r) => r.tier == WorkerTier.peasant);
      expect(peasantRow.canDisband, isFalse);
      expect(peasantRow.techUnlocked, isTrue);

      final jmRow = buildProductionLabourRowData(
        player: productionLabourGpWithPool(journeymen: 2),
        currentOrders: productionLabourOrdersWithRecruits([WorkerTier.journeyman]),
        canEdit: true,
      ).firstWhere((r) => r.tier == WorkerTier.journeyman);
      expect(jmRow.queuedCount, 1);
      expect(jmRow.canPop, isTrue);
      expect(jmRow.canDisband, isTrue);

      final byTierNull = {
        for (final r in buildProductionLabourRowData(
          player: productionLabourGpWithPool(),
          currentOrders: const Orders(),
        canEdit: true,
        ))
          r.tier: r,
      };
      for (final tier in productionLabourTrainedTiers) {
        expect(byTierNull[tier]!.techUnlocked, isFalse);
      }

      final byTierPartial = {
        for (final r in buildProductionLabourRowData(
          player: productionLabourGpWithPool(
            techUnlocked: productionLabourTrainedThroughJourneymanTech,
          ),
          currentOrders: const Orders(),
        canEdit: true,
        ))
          r.tier: r,
      };
      expect(byTierPartial[WorkerTier.peasant]!.techUnlocked, isTrue);
      expect(byTierPartial[WorkerTier.apprentice]!.techUnlocked, isTrue);
      expect(byTierPartial[WorkerTier.journeyman]!.techUnlocked, isTrue);
      expect(byTierPartial[WorkerTier.master]!.techUnlocked, isFalse);

      final apprenticeRow = buildProductionLabourRowData(
        player: productionLabourGpWithPool(
          techUnlocked: const {
            kTechIdApprenticeWorkers: true,
            kTechIdSugarRefining: false,
          },
        ),
        currentOrders: const Orders(),
        canEdit: true,
      ).firstWhere((r) => r.tier == WorkerTier.apprentice);
      expect(apprenticeRow.techUnlocked, isFalse);
    });
  });

  group('isWorkerTierTechUnlocked', () {
    test('returns true for peasant regardless of techUnlocked', () {
      for (final tech in <Map<String, bool>?>[null, const {}]) {
        expect(
          isWorkerTierTechUnlocked(
            player: productionLabourGpWithPool(techUnlocked: tech),
            tier: WorkerTier.peasant,
          ),
          isTrue,
        );
      }
    });

    for (final case_ in <
      ({
        String name,
        Player player,
        WorkerTier tier,
        bool expected,
      })
    >[
      (
        name: 'trained tier unlocked when every required tech id is true',
        player: productionLabourGpWithPool(
          techUnlocked: const {
            kTechIdMasterArtisans: true,
            kTechIdHatProduction: true,
          },
        ),
        tier: WorkerTier.master,
        expected: true,
      ),
      (
        name: 'trained tier locked when a required tech id is missing',
        player: productionLabourGpWithPool(
          techUnlocked: const {kTechIdMasterArtisans: true},
        ),
        tier: WorkerTier.master,
        expected: false,
      ),
      (
        name: 'returns false when techUnlocked is null and tier has tech gate',
        player: productionLabourGpWithPool(),
        tier: WorkerTier.journeyman,
        expected: false,
      ),
      (
        name: 'returns false when a required tech entry is present but false',
        player: productionLabourGpWithPool(
          techUnlocked: const {
            kTechIdTrainedJourneymen: false,
            kTechIdCigarProduction: true,
          },
        ),
        tier: WorkerTier.journeyman,
        expected: false,
      ),
    ]) {
      test(case_.name, () {
        expect(
          isWorkerTierTechUnlocked(
            player: case_.player,
            tier: case_.tier,
          ),
          case_.expected,
        );
      });
    }
  });
}
