import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('sim_combat', () {
    test('resolveEngagementProbabilistic is deterministic for same seed', () {
      final attackerUnits = [
        Unit(
          id: 'a1',
          type: 'grenadiers',
          ownerId: 'att',
          provinceId: 'p',
          medals: 2,
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

      final r1 = resolveEngagementProbabilistic(
        attackerUnits: attackerUnits,
        defenderUnits: defenderUnits,
        fortLevel: 0,
        terrain: 'plains',
        seed: 42,
      );
      final r2 = resolveEngagementProbabilistic(
        attackerUnits: attackerUnits,
        defenderUnits: defenderUnits,
        fortLevel: 0,
        terrain: 'plains',
        seed: 42,
      );

      expect(r1.result, r2.result);
      expect(r1.attackerStrength, r2.attackerStrength);
      expect(r1.defenderStrength, r2.defenderStrength);
      expect(r1.attackerCasualties, r2.attackerCasualties);
      expect(r1.defenderCasualties, r2.defenderCasualties);
      expect(r1.rounds.length, r2.rounds.length);
    });
  });
}
