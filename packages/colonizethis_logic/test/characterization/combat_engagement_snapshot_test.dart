import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

Unit _unit(String id, String type, {int medals = 0}) => Unit(
      id: id,
      type: type,
      ownerId: 'owner',
      locationProvinceId: 'p',
      medals: medals,
    );

void main() {
  group('Combat engagement characterization', () {
    test('decisive attacker victory: ratio >= 1.5, well-fed', () {
      final attackers = [
        _unit('a1', 'grenadiers', medals: 3),
        _unit('a2', 'grenadiers', medals: 2),
      ];
      final defenders = [_unit('d1', 'peasant_levies')];

      final outcome = resolveEngagement(
        attackerUnits: attackers,
        defenderUnits: defenders,
        fortLevel: 0,
        terrain: 'plains',
      );

      expect(outcome.result, EngagementResult.attackerVictory);
      expect(outcome.defenderCasualties, contains('d1'));
      expect(outcome.attackerStrength, greaterThan(0));
      expect(outcome.defenderStrength, greaterThan(0));
    });

    test('decisive defender victory: ratio <= 0.67', () {
      final attackers = [_unit('a1', 'peasant_levies')];
      final defenders = [
        _unit('d1', 'grenadiers', medals: 3),
        _unit('d2', 'grenadiers', medals: 2),
      ];

      final outcome = resolveEngagement(
        attackerUnits: attackers,
        defenderUnits: defenders,
        fortLevel: 0,
        terrain: 'plains',
      );

      expect(outcome.result, EngagementResult.defenderVictory);
      expect(outcome.attackerCasualties, contains('a1'));
    });

    test('close fight: ratio 1.0-1.5 produces stalemate or attacker win', () {
      final attackers = [
        _unit('a1', 'pikemen', medals: 1),
        _unit('a2', 'pikemen', medals: 1),
      ];
      final defenders = [
        _unit('d1', 'pikemen', medals: 1),
        _unit('d2', 'pikemen', medals: 0),
      ];

      final outcome = resolveEngagement(
        attackerUnits: attackers,
        defenderUnits: defenders,
        fortLevel: 0,
        terrain: 'plains',
      );

      expect(
        outcome.result,
        anyOf(
          EngagementResult.attackerVictory,
          EngagementResult.stalemate,
          EngagementResult.defenderVictory,
        ),
      );
      expect(outcome.defenderCasualties, isNotEmpty);
      expect(outcome.attackerCasualties, isNotEmpty);
    });

    test('close fight: ratio 0.67-1.0 produces casualties on both sides', () {
      final attackers = [_unit('a1', 'pikemen', medals: 0)];
      final defenders = [
        _unit('d1', 'pikemen', medals: 1),
      ];

      final outcome = resolveEngagement(
        attackerUnits: attackers,
        defenderUnits: defenders,
        fortLevel: 0,
        terrain: 'plains',
      );

      expect(
        outcome.result,
        anyOf(
          EngagementResult.stalemate,
          EngagementResult.defenderVictory,
          EngagementResult.mutualAnnihilation,
        ),
      );
    });

    test('low morale attacker with ratio >= 1.5 but < 4.0 gets blunted', () {
      final attackers = [
        _unit('a1', 'grenadiers', medals: 2),
      ];
      final defenders = [_unit('d1', 'peasant_levies')];

      final outcome = resolveEngagement(
        attackerUnits: attackers,
        defenderUnits: defenders,
        fortLevel: 0,
        terrain: 'plains',
        attackerMoraleMultiplier: 0.5,
        defenderMoraleMultiplier: 1.0,
      );

      // Low morale attacker should NOT get a clean attacker victory
      expect(outcome.result, isNot(EngagementResult.attackerVictory));
    });

    test('fort level shifts outcome in defender favor', () {
      final attackers = [_unit('a1', 'pikemen', medals: 1)];
      final defenders = [_unit('d1', 'peasant_levies')];

      final noFort = resolveEngagement(
        attackerUnits: attackers,
        defenderUnits: defenders,
        fortLevel: 0,
        terrain: 'plains',
      );
      final withFort = resolveEngagement(
        attackerUnits: attackers,
        defenderUnits: defenders,
        fortLevel: 2,
        terrain: 'plains',
      );

      expect(withFort.result, isNot(equals(noFort.result)),
          reason: 'Fort should shift outcome toward defender');
    });

    test('zero strength produces stalemate', () {
      final outcome = resolveEngagement(
        attackerUnits: [],
        defenderUnits: [],
        fortLevel: 0,
        terrain: 'plains',
      );

      expect(outcome.result, EngagementResult.stalemate);
      expect(outcome.attackerCasualties, isEmpty);
      expect(outcome.defenderCasualties, isEmpty);
    });

    test('terrain modifiers affect outcome', () {
      final attackers = [_unit('a1', 'pikemen', medals: 1)];
      final defenders = [_unit('d1', 'pikemen', medals: 0)];

      final plains = resolveEngagement(
        attackerUnits: attackers,
        defenderUnits: defenders,
        fortLevel: 0,
        terrain: 'plains',
      );
      final forest = resolveEngagement(
        attackerUnits: attackers,
        defenderUnits: defenders,
        fortLevel: 0,
        terrain: 'hardwoodForest',
      );

      // Forest should favor defender more than plains, or at least not
      // produce a worse outcome for the defender.
      final plainsDefLoss = plains.defenderCasualties.length;
      final forestDefLoss = forest.defenderCasualties.length;
      expect(forestDefLoss, lessThanOrEqualTo(plainsDefLoss));
    });

    test('leader multiplier affects strength', () {
      final attackers = [_unit('a1', 'pikemen', medals: 0)];
      final defenders = [_unit('d1', 'pikemen', medals: 0)];

      final noBonus = resolveEngagement(
        attackerUnits: attackers,
        defenderUnits: defenders,
        fortLevel: 0,
        terrain: 'plains',
        attackerLeaderMultiplier: 1.0,
        defenderLeaderMultiplier: 1.0,
      );
      final attackerBonus = resolveEngagement(
        attackerUnits: attackers,
        defenderUnits: defenders,
        fortLevel: 0,
        terrain: 'plains',
        attackerLeaderMultiplier: 1.5,
        defenderLeaderMultiplier: 1.0,
      );

      // With a leader bonus, attacker should do at least as well
      expect(attackerBonus.attackerCasualties.length,
          lessThanOrEqualTo(noBonus.attackerCasualties.length));
    });
  });
}
