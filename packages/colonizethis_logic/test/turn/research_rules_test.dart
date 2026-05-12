import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../../lib/src/turn/research_rules.dart';

void main() {
  group('fundingStatsForLevel', () {
    test('none yields zero points and cost', () {
      final s = fundingStatsForLevel(ResearchFundingLevel.none);
      expect(s.points, 0);
      expect(s.cost, 0);
    });

    test('low/medium/high/maximum match legacy constants', () {
      expect(
        fundingStatsForLevel(ResearchFundingLevel.low),
        (points: researchPointsLow, cost: researchTreasuryCostLow),
      );
      expect(
        fundingStatsForLevel(ResearchFundingLevel.medium),
        (points: researchPointsMedium, cost: researchTreasuryCostMedium),
      );
      expect(
        fundingStatsForLevel(ResearchFundingLevel.high),
        (points: researchPointsHigh, cost: researchTreasuryCostHigh),
      );
      expect(
        fundingStatsForLevel(ResearchFundingLevel.maximum),
        (points: researchPointsMaximum, cost: researchTreasuryCostMaximum),
      );
    });

    test('legacy wrappers delegate to fundingStatsForLevel', () {
      for (final level in ResearchFundingLevel.values) {
        final s = fundingStatsForLevel(level);
        expect(pointsForFunding(level), s.points);
        expect(treasuryCostForFunding(level), s.cost);
      }
    });
  });
}
