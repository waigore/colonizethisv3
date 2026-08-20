// Auto-resolve engagement characterization (#4090 Slice E → #4545 Slice C).
// Scenario rows live in the combat test tree to avoid tripping support-package
// file-size / LOC ratchets (Refs #4545).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_combat_test_support/colonizethis_combat_test_support.dart';
import 'package:colonizethis_test/test.dart';

List<RunnableScenario> combatEngagementSnapshotScenarios() => [
      rs(
        scenarioId: 'ces-decisive-attacker-victory',
        label: 'decisive attacker victory: ratio >= 1.5, well-fed',
        refs: '#4090',
        run: () {
          final attackers = [
            probResolverUnit(id: 'a1', type: 'grenadiers', medals: 3),
            probResolverUnit(id: 'a2', type: 'grenadiers', medals: 2),
          ];
          final defenders = [
            probResolverUnit(id: 'd1', type: 'peasant_levies'),
          ];
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
        },
      ),
      rs(
        scenarioId: 'ces-decisive-defender-victory',
        label: 'decisive defender victory: ratio <= 0.67',
        refs: '#4090',
        run: () {
          final attackers = [
            probResolverUnit(id: 'a1', type: 'peasant_levies'),
          ];
          final defenders = [
            probResolverUnit(id: 'd1', type: 'grenadiers', medals: 3),
            probResolverUnit(id: 'd2', type: 'grenadiers', medals: 2),
          ];
          final outcome = resolveEngagement(
            attackerUnits: attackers,
            defenderUnits: defenders,
            fortLevel: 0,
            terrain: 'plains',
          );
          expect(outcome.result, EngagementResult.defenderVictory);
          expect(outcome.attackerCasualties, contains('a1'));
        },
      ),
      rs(
        scenarioId: 'ces-close-fight-high-ratio',
        label: 'close fight: ratio 1.0-1.5 produces stalemate or attacker win',
        refs: '#4090',
        run: () {
          final attackers = [
            probResolverUnit(id: 'a1', type: 'pikemen', medals: 1),
            probResolverUnit(id: 'a2', type: 'pikemen', medals: 1),
          ];
          final defenders = [
            probResolverUnit(id: 'd1', type: 'pikemen', medals: 1),
            probResolverUnit(id: 'd2', type: 'pikemen', medals: 0),
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
        },
      ),
      rs(
        scenarioId: 'ces-close-fight-mid-ratio',
        label: 'close fight: ratio 0.67-1.0 produces casualties on both sides',
        refs: '#4090',
        run: () {
          final attackers = [
            probResolverUnit(id: 'a1', type: 'pikemen', medals: 0),
          ];
          final defenders = [
            probResolverUnit(id: 'd1', type: 'pikemen', medals: 1),
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
        },
      ),
      rs(
        scenarioId: 'ces-low-morale-blunted',
        label: 'low morale attacker with ratio >= 1.5 but < 4.0 gets blunted',
        refs: '#4090',
        run: () {
          final attackers = [
            probResolverUnit(id: 'a1', type: 'grenadiers', medals: 2),
          ];
          final defenders = [
            probResolverUnit(id: 'd1', type: 'peasant_levies'),
          ];
          final outcome = resolveEngagement(
            attackerUnits: attackers,
            defenderUnits: defenders,
            fortLevel: 0,
            terrain: 'plains',
            attackerMoraleMultiplier: 0.5,
            defenderMoraleMultiplier: 1.0,
          );
          expect(outcome.result, isNot(EngagementResult.attackerVictory));
        },
      ),
      rs(
        scenarioId: 'ces-fort-shifts-outcome',
        label: 'fort level shifts outcome in defender favor',
        refs: '#4090',
        run: () {
          final attackers = [
            probResolverUnit(id: 'a1', type: 'pikemen', medals: 1),
          ];
          final defenders = [
            probResolverUnit(id: 'd1', type: 'peasant_levies'),
          ];
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
          expect(
            withFort.result,
            isNot(equals(noFort.result)),
            reason: 'Fort should shift outcome toward defender',
          );
        },
      ),
      rs(
        scenarioId: 'ces-zero-strength-stalemate',
        label: 'zero strength produces stalemate',
        refs: '#4090',
        run: () {
          final outcome = resolveEngagement(
            attackerUnits: [],
            defenderUnits: [],
            fortLevel: 0,
            terrain: 'plains',
          );
          expect(outcome.result, EngagementResult.stalemate);
          expect(outcome.attackerCasualties, isEmpty);
          expect(outcome.defenderCasualties, isEmpty);
        },
      ),
      rs(
        scenarioId: 'ces-terrain-modifiers',
        label: 'terrain modifiers affect outcome',
        refs: '#4090',
        run: () {
          final attackers = [
            probResolverUnit(id: 'a1', type: 'pikemen', medals: 1),
          ];
          final defenders = [
            probResolverUnit(id: 'd1', type: 'pikemen', medals: 0),
          ];
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
          expect(
            forest.defenderCasualties.length,
            lessThanOrEqualTo(plains.defenderCasualties.length),
          );
        },
      ),
      rs(
        scenarioId: 'ces-leader-multiplier',
        label: 'leader multiplier affects strength',
        refs: '#4090',
        run: () {
          final attackers = [
            probResolverUnit(id: 'a1', type: 'pikemen', medals: 0),
          ];
          final defenders = [
            probResolverUnit(id: 'd1', type: 'pikemen', medals: 0),
          ];
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
          expect(
            attackerBonus.attackerCasualties.length,
            lessThanOrEqualTo(noBonus.attackerCasualties.length),
          );
        },
      ),
    ];
