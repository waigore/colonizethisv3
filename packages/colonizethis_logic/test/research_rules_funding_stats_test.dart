import 'package:colonizethis_logic/src/turn/research_rules.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('fundingStats (Refs #2391 AC2)', () {
    test('none returns zero points and zero cost', () {
      final stats = fundingStats(ResearchFundingLevel.none);
      expect(stats.points, 0);
      expect(stats.cost, 0);
    });

    test('low returns documented points and cost', () {
      final stats = fundingStats(ResearchFundingLevel.low);
      expect(stats.points, researchPointsLow);
      expect(stats.cost, researchTreasuryCostLow);
    });

    test('medium returns documented points and cost', () {
      final stats = fundingStats(ResearchFundingLevel.medium);
      expect(stats.points, researchPointsMedium);
      expect(stats.cost, researchTreasuryCostMedium);
    });

    test('high returns documented points and cost', () {
      final stats = fundingStats(ResearchFundingLevel.high);
      expect(stats.points, researchPointsHigh);
      expect(stats.cost, researchTreasuryCostHigh);
    });

    test('maximum returns documented points and cost', () {
      final stats = fundingStats(ResearchFundingLevel.maximum);
      expect(stats.points, researchPointsMaximum);
      expect(stats.cost, researchTreasuryCostMaximum);
    });
  });

  group(
    'pointsForFunding / treasuryCostForFunding agree with fundingStats',
    () {
      test('pointsForFunding matches fundingStats.points for every level', () {
        for (final level in ResearchFundingLevel.values) {
          expect(pointsForFunding(level), fundingStats(level).points);
        }
      });

      test(
        'treasuryCostForFunding matches fundingStats.cost for every level',
        () {
          for (final level in ResearchFundingLevel.values) {
            expect(treasuryCostForFunding(level), fundingStats(level).cost);
          }
        },
      );
    },
  );
}
