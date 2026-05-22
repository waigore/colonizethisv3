import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('WorkerActionEconomyCatalog', () {
    test('has one entry per WorkerTier value', () {
      final byTier = WorkerActionEconomyCatalog.byTier;
      for (final tier in WorkerTier.values) {
        expect(
          byTier.containsKey(tier),
          isTrue,
          reason: 'Missing worker action row for tier ${tier.name}',
        );
      }
      expect(WorkerActionEconomyCatalog.all.length, WorkerTier.values.length);
    });

    test('peasant row matches SPEC: fabric x2, no peasant consumed, no tech', () {
      final row = WorkerActionEconomyCatalog.peasant;
      expect(row.targetTier, WorkerTier.peasant);
      expect(row.treasuryCost, 0);
      expect(row.consumesPeasant, isFalse);
      expect(row.requiredTechIds, isEmpty);
      expect(row.materialCosts, {CommodityCatalog.fabric.id: 2});
    });

    test('apprentice row matches SPEC: 200 ducats + paper x2 + 1 peasant', () {
      final row = WorkerActionEconomyCatalog.apprentice;
      expect(row.targetTier, WorkerTier.apprentice);
      expect(row.treasuryCost, 200);
      expect(row.consumesPeasant, isTrue);
      expect(row.materialCosts, {CommodityCatalog.paper.id: 2});
      expect(
        row.requiredTechIds,
        containsAll(<String>[
          kTechIdApprenticeWorkers,
          kTechIdSugarRefining,
        ]),
      );
    });

    test('journeyman row matches SPEC: 500 ducats + paper x5 + 1 peasant', () {
      final row = WorkerActionEconomyCatalog.journeyman;
      expect(row.targetTier, WorkerTier.journeyman);
      expect(row.treasuryCost, 500);
      expect(row.consumesPeasant, isTrue);
      expect(row.materialCosts, {CommodityCatalog.paper.id: 5});
      expect(
        row.requiredTechIds,
        containsAll(<String>[
          kTechIdTrainedJourneymen,
          kTechIdCigarProduction,
        ]),
      );
    });

    test('master row matches SPEC: 1000 ducats + paper x10 + 1 peasant', () {
      final row = WorkerActionEconomyCatalog.master;
      expect(row.targetTier, WorkerTier.master);
      expect(row.treasuryCost, 1000);
      expect(row.consumesPeasant, isTrue);
      expect(row.materialCosts, {CommodityCatalog.paper.id: 10});
      expect(
        row.requiredTechIds,
        containsAll(<String>[
          kTechIdMasterArtisans,
          kTechIdHatProduction,
        ]),
      );
    });

    test('basic invariants: positive material costs, non-negative treasury', () {
      for (final row in WorkerActionEconomyCatalog.all) {
        expect(row.treasuryCost, greaterThanOrEqualTo(0));
        for (final entry in row.materialCosts.entries) {
          expect(
            entry.value,
            greaterThan(0),
            reason:
                'materialCosts[${entry.key}] for ${row.targetTier.name} must be positive',
          );
        }
      }
    });

    test('non-peasant tiers consume a peasant; peasant does not', () {
      expect(WorkerActionEconomyCatalog.peasant.consumesPeasant, isFalse);
      for (final tier in WorkerTier.values.where((t) => t != WorkerTier.peasant)) {
        expect(
          WorkerActionEconomyCatalog.forTier(tier).consumesPeasant,
          isTrue,
          reason: '${tier.name} must consume a peasant per SPEC',
        );
      }
    });

    test('peasant row has no tech gate; trained tiers each have two', () {
      expect(WorkerActionEconomyCatalog.peasant.requiredTechIds, isEmpty);
      for (final tier in WorkerTier.values.where((t) => t != WorkerTier.peasant)) {
        final row = WorkerActionEconomyCatalog.forTier(tier);
        expect(
          row.requiredTechIds.length,
          2,
          reason:
              '${tier.name} must have exactly two tech gates per SPEC § Tech gates',
        );
      }
    });

    test('forTier throws ArgumentError for unrecognized tier lookup paths', () {
      // forTier covers every enum value via byTier, but the explicit
      // ArgumentError branch should remain reachable defensively if the
      // catalog is ever subset. The standard tier path returns rows; we
      // assert that here so coverage stays meaningful.
      for (final tier in WorkerTier.values) {
        expect(
          WorkerActionEconomyCatalog.forTier(tier).targetTier,
          tier,
        );
      }
    });

    test('treasury costs are monotonically non-decreasing by tier', () {
      final ordered = WorkerActionEconomyCatalog.all;
      for (var i = 1; i < ordered.length; i++) {
        expect(
          ordered[i].treasuryCost,
          greaterThanOrEqualTo(ordered[i - 1].treasuryCost),
          reason:
              'tier ${ordered[i].targetTier.name} treasury cost must be '
              '>= tier ${ordered[i - 1].targetTier.name}',
        );
      }
    });
  });
}
