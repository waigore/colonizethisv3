import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('resolveEngagementProbabilistic', () {
    test('same seed produces identical outcome', () {
      final attackerUnits = [
        Unit(
          id: 'a1',
          type: 'grenadiers',
          ownerId: 'att',
          locationProvinceId: 'p',
          medals: 1,
        ),
        Unit(
          id: 'a2',
          type: 'grenadiers',
          ownerId: 'att',
          locationProvinceId: 'p',
          medals: 0,
        ),
      ];
      final defenderUnits = [
        Unit(
          id: 'd1',
          type: 'peasant_levies',
          ownerId: 'def',
          locationProvinceId: 'p',
          medals: 0,
        ),
        Unit(
          id: 'd2',
          type: 'peasant_levies',
          ownerId: 'def',
          locationProvinceId: 'p',
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
      expect(r1.attackerCasualties, r2.attackerCasualties);
      expect(r1.defenderCasualties, r2.defenderCasualties);
      expect(r1.rounds.length, r2.rounds.length);
      for (var i = 0; i < r1.rounds.length; i++) {
        expect(r1.rounds[i].defenderCasualties, r2.rounds[i].defenderCasualties);
        expect(r1.rounds[i].attackerCasualties, r2.rounds[i].attackerCasualties);
      }
    });

    test('rounds bounded by maxCombatRounds', () {
      final attackerUnits = [
        Unit(id: 'a1', type: 'pikemen', ownerId: 'att', locationProvinceId: 'p', medals: 0),
        Unit(id: 'a2', type: 'pikemen', ownerId: 'att', locationProvinceId: 'p', medals: 0),
      ];
      final defenderUnits = [
        Unit(id: 'd1', type: 'pikemen', ownerId: 'def', locationProvinceId: 'p', medals: 0),
        Unit(id: 'd2', type: 'pikemen', ownerId: 'def', locationProvinceId: 'p', medals: 0),
      ];

      final outcome = resolveEngagementProbabilistic(
        attackerUnits: attackerUnits,
        defenderUnits: defenderUnits,
        fortLevel: 0,
        terrain: 'plains',
        seed: 999,
      );

      expect(outcome.rounds.length, lessThanOrEqualTo(maxCombatRounds));
    });

    test('strong attacker tends to win over many trials', () {
      final attackerUnits = [
        Unit(
          id: 'a1',
          type: 'grenadiers',
          ownerId: 'att',
          locationProvinceId: 'p',
          medals: 2,
        ),
        Unit(
          id: 'a2',
          type: 'grenadiers',
          ownerId: 'att',
          locationProvinceId: 'p',
          medals: 1,
        ),
      ];
      final defenderUnits = [
        Unit(
          id: 'd1',
          type: 'peasant_levies',
          ownerId: 'def',
          locationProvinceId: 'p',
          medals: 0,
        ),
      ];

      var attWins = 0;
      for (var i = 0; i < 100; i++) {
        final r = resolveEngagementProbabilistic(
          attackerUnits: attackerUnits,
          defenderUnits: defenderUnits,
          fortLevel: 0,
          terrain: 'plains',
          seed: 1000 + i,
        );
        if (r.result == EngagementResult.attackerVictory) attWins++;
      }
      expect(attWins, greaterThan(50), reason: 'Strong attacker should win majority');
    });

    test('outcome includes per-round details', () {
      final attackerUnits = [
        Unit(id: 'a1', type: 'grenadiers', ownerId: 'att', locationProvinceId: 'p', medals: 0),
      ];
      final defenderUnits = [
        Unit(id: 'd1', type: 'peasant_levies', ownerId: 'def', locationProvinceId: 'p', medals: 0),
      ];

      final outcome = resolveEngagementProbabilistic(
        attackerUnits: attackerUnits,
        defenderUnits: defenderUnits,
        fortLevel: 0,
        terrain: 'plains',
        seed: 123,
      );

      expect(outcome.rounds, isNotEmpty);
      for (final round in outcome.rounds) {
        expect(round.probabilityAttackerHits, inInclusiveRange(0.15, 0.85));
        expect(round.probabilityDefenderHits, inInclusiveRange(0.15, 0.85));
      }
    });

    test('can produce mutualAnnihilation when both sides eliminated', () {
      final attackerUnits = [
        Unit(id: 'a1', type: 'pikemen', ownerId: 'att', locationProvinceId: 'p', medals: 0),
        Unit(id: 'a2', type: 'pikemen', ownerId: 'att', locationProvinceId: 'p', medals: 0),
      ];
      final defenderUnits = [
        Unit(id: 'd1', type: 'pikemen', ownerId: 'def', locationProvinceId: 'p', medals: 0),
        Unit(id: 'd2', type: 'pikemen', ownerId: 'def', locationProvinceId: 'p', medals: 0),
      ];
      EngagementResult? mutualAnnihilationResult;
      for (var s = 0; s < 500; s++) {
        final outcome = resolveEngagementProbabilistic(
          attackerUnits: attackerUnits,
          defenderUnits: defenderUnits,
          fortLevel: 0,
          terrain: 'plains',
          seed: s,
        );
        if (outcome.result == EngagementResult.mutualAnnihilation) {
          mutualAnnihilationResult = outcome.result;
          break;
        }
      }
      expect(mutualAnnihilationResult, EngagementResult.mutualAnnihilation,
          reason: 'some seed should produce mutual annihilation');
    });

    test('can produce stalemate when rounds end with both sides remaining', () {
      final attackerUnits = [
        Unit(id: 'a1', type: 'pikemen', ownerId: 'att', locationProvinceId: 'p', medals: 0),
        Unit(id: 'a2', type: 'pikemen', ownerId: 'att', locationProvinceId: 'p', medals: 0),
        Unit(id: 'a3', type: 'pikemen', ownerId: 'att', locationProvinceId: 'p', medals: 0),
      ];
      final defenderUnits = [
        Unit(id: 'd1', type: 'pikemen', ownerId: 'def', locationProvinceId: 'p', medals: 0),
        Unit(id: 'd2', type: 'pikemen', ownerId: 'def', locationProvinceId: 'p', medals: 0),
        Unit(id: 'd3', type: 'pikemen', ownerId: 'def', locationProvinceId: 'p', medals: 0),
      ];
      EngagementResult? stalemateResult;
      for (var s = 0; s < 1000; s++) {
        final outcome = resolveEngagementProbabilistic(
          attackerUnits: attackerUnits,
          defenderUnits: defenderUnits,
          fortLevel: 0,
          terrain: 'plains',
          seed: s,
        );
        if (outcome.result == EngagementResult.stalemate) {
          stalemateResult = outcome.result;
          break;
        }
      }
      expect(stalemateResult, EngagementResult.stalemate,
          reason: 'some seed should produce stalemate after max rounds');
    });
  });
}
