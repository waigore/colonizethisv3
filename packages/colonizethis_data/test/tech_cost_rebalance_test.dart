import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

/// Verifies the rebalanced tech RP costs.
/// SPEC/game/tech-tree.md § Research Model (Research point costs). Refs #3512.
void main() {
  group('tech cost rebalance', () {
    int expectedCostForTier(int tier) => 1800 + (tier - 1) * 600;

    test('every tech cost equals 1800 + (tier - 1) * 600 for its era', () {
      for (final tech in techCatalog.values) {
        expect(
          tech.cost,
          expectedCostForTier(tech.era),
          reason:
              'tech ${tech.id} (era ${tech.era}) should cost '
              '${expectedCostForTier(tech.era)} RP',
        );
      }
    });

    test('tier costs are exactly 1800 / 2400 / 3000 / 3600', () {
      expect(expectedCostForTier(1), 1800);
      expect(expectedCostForTier(2), 2400);
      expect(expectedCostForTier(3), 3000);
      expect(expectedCostForTier(4), 3600);
    });

    test('the set of distinct catalog costs is exactly {1800,2400,3000,3600}',
        () {
      final distinctCosts = techCatalog.values.map((t) => t.cost).toSet();
      expect(distinctCosts, <int>{1800, 2400, 3000, 3600});
    });

    test('no tech keeps a legacy cost (120/160/200/240)', () {
      final legacyCosts = <int>{120, 160, 200, 240};
      for (final tech in techCatalog.values) {
        expect(
          legacyCosts.contains(tech.cost),
          isFalse,
          reason: 'tech ${tech.id} still uses a legacy cost ${tech.cost}',
        );
      }
    });
  });
}
