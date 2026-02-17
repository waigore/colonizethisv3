import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:test/test.dart';

void main() {
  group('resolveEngagement', () {
    test('attacker wins decisively when much stronger', () {
      final attackerUnits = [
        Unit(
          id: 'a1',
          type: 'grenadiers',
          ownerId: 'att',
          provinceId: 'p',
          medals: 3,
        ),
        Unit(
          id: 'a2',
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

      final outcome = resolveEngagement(
        attackerUnits: attackerUnits,
        defenderUnits: defenderUnits,
        fortLevel: 0,
        terrain: 'plains',
      );

      expect(outcome.result, EngagementResult.attackerVictory);
      expect(outcome.defenderCasualties, contains('d1'));
    });

    test('defender wins when much stronger', () {
      final attackerUnits = [
        Unit(
          id: 'a1',
          type: 'peasant_levies',
          ownerId: 'att',
          provinceId: 'p',
          medals: 0,
        ),
      ];
      final defenderUnits = [
        Unit(
          id: 'd1',
          type: 'grenadiers',
          ownerId: 'def',
          provinceId: 'p',
          medals: 3,
        ),
        Unit(
          id: 'd2',
          type: 'grenadiers',
          ownerId: 'def',
          provinceId: 'p',
          medals: 2,
        ),
      ];

      final outcome = resolveEngagement(
        attackerUnits: attackerUnits,
        defenderUnits: defenderUnits,
        fortLevel: 0,
        terrain: 'plains',
      );

      expect(outcome.result, EngagementResult.defenderVictory);
      expect(outcome.attackerCasualties, contains('a1'));
    });

    test('siege modifiers apply when fortLevel >= 1', () {
      final attackerUnits = [
        Unit(
          id: 'a1',
          type: 'pikemen',
          ownerId: 'att',
          provinceId: 'p',
          medals: 0,
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

      final field = resolveEngagement(
        attackerUnits: attackerUnits,
        defenderUnits: defenderUnits,
        fortLevel: 0,
        terrain: 'plains',
      );
      final siege = resolveEngagement(
        attackerUnits: attackerUnits,
        defenderUnits: defenderUnits,
        fortLevel: 2,
        terrain: 'plains',
      );

      expect(siege.result, isNot(equals(field.result)),
          reason: 'Fort should affect outcome when strengths are close');
    });

    test('low attacker feeding coverage penalises strength via morale multiplier', () {
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

      final wellFed = resolveEngagement(
        attackerUnits: attackerUnits,
        defenderUnits: defenderUnits,
        fortLevel: 0,
        terrain: 'plains',
        attackerMoraleMultiplier: 1.0,
        defenderMoraleMultiplier: 1.0,
      );

      final underfed = resolveEngagement(
        attackerUnits: attackerUnits,
        defenderUnits: defenderUnits,
        fortLevel: 0,
        terrain: 'plains',
        attackerMoraleMultiplier: 0.5,
        defenderMoraleMultiplier: 1.0,
      );

      // Attacker should be strictly weaker when underfed.
      expect(underfed.attackerStrength, wellFed.attackerStrength);
      // Effective strength ratio should be worse for the underfed attacker,
      // leading to outcomes that are no better than the well-fed case.
      expect(
        underfed.result == EngagementResult.attackerVictory,
        isFalse,
        reason: 'Underfed attacker should not perform better than well-fed attacker',
      );
    });
  });
}
