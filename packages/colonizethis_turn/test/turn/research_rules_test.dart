import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../../lib/src/turn/research_rules.dart';

void main() {
  group('fundingStats', () {
    test('none yields zero points and cost', () {
      final s = fundingStats(ResearchFundingLevel.none);
      expect(s.points, 0);
      expect(s.cost, 0);
    });

    test('low/medium/high/maximum match legacy constants', () {
      expect(
        fundingStats(ResearchFundingLevel.low),
        (points: researchPointsLow, cost: researchTreasuryCostLow),
      );
      expect(
        fundingStats(ResearchFundingLevel.medium),
        (points: researchPointsMedium, cost: researchTreasuryCostMedium),
      );
      expect(
        fundingStats(ResearchFundingLevel.high),
        (points: researchPointsHigh, cost: researchTreasuryCostHigh),
      );
      expect(
        fundingStats(ResearchFundingLevel.maximum),
        (points: researchPointsMaximum, cost: researchTreasuryCostMaximum),
      );
    });

    test('legacy wrappers delegate to fundingStats', () {
      for (final level in ResearchFundingLevel.values) {
        final s = fundingStats(level);
        expect(pointsForFunding(level), s.points);
        expect(treasuryCostForFunding(level), s.cost);
      }
    });
  });
}
