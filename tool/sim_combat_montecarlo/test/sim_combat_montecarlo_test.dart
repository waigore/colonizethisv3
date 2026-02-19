import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('sim_combat_montecarlo', () {
    test('monte carlo aggregates wins and casualties correctly', () {
      final attackerUnits = [
        Unit(
          id: 'a1',
          type: 'grenadiers',
          ownerId: 'att',
          provinceId: 'p',
          medals: 1,
        ),
      ];
      final defenderUnits = [
        Unit(
          id: 'd1',
          type: 'peasant_levies',
          ownerId: 'def',
          provinceId: 'p',
          medals: 0,
        ),
      ];

      var attWins = 0;
      var defWins = 0;
      var totalAttCas = 0;
      var totalDefCas = 0;
      const trials = 50;

      for (var i = 0; i < trials; i++) {
        final outcome = resolveEngagementProbabilistic(
          attackerUnits: attackerUnits,
          defenderUnits: defenderUnits,
          fortLevel: 0,
          terrain: 'plains',
          seed: 100 + i,
        );

        if (outcome.result == EngagementResult.attackerVictory) attWins++;
        if (outcome.result == EngagementResult.defenderVictory) defWins++;
        totalAttCas += outcome.attackerCasualties.length;
        totalDefCas += outcome.defenderCasualties.length;
      }

      expect(attWins + defWins, lessThanOrEqualTo(trials));
      expect(totalAttCas, greaterThanOrEqualTo(0));
      expect(totalDefCas, greaterThanOrEqualTo(0));
      expect(totalAttCas / trials, lessThanOrEqualTo(1.0));
      expect(totalDefCas / trials, lessThanOrEqualTo(1.0));
    });
  });
}
