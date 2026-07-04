// Table-driven resolveEngagementProbabilistic scenarios (Refs #3865).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart';

import 'combat_resolver_test_support.dart';

/// One row in a probabilistic engagement scenario table.
class CombatResolverProbabilisticScenario {
  const CombatResolverProbabilisticScenario({
    required this.scenarioId,
    required this.label,
    required this.run,
  });

  final String scenarioId;
  final String label;
  final void Function() run;
}

/// Runs [scenario].
void runCombatResolverProbabilisticScenario(
  CombatResolverProbabilisticScenario scenario,
) {
  scenario.run();
}

/// Scenarios for [resolveEngagementProbabilistic].
List<CombatResolverProbabilisticScenario>
    combatResolverProbabilisticScenarios() => [
          ..._combatResolverProbabilisticCoreScenarios(),
          ..._combatResolverProbabilisticOutcomeScenarios(),
        ];

List<CombatResolverProbabilisticScenario>
    _combatResolverProbabilisticCoreScenarios() => [
          CombatResolverProbabilisticScenario(
            scenarioId: 'crp-same-seed-identical',
            label: 'same seed produces identical outcome',
            run: () {
              final attackerUnits = [
                probResolverUnit(
                  id: 'a1',
                  type: 'grenadiers',
                  medals: 1,
                ),
                probResolverUnit(id: 'a2', type: 'grenadiers'),
              ];
              final defenderUnits = [
                probResolverUnit(
                  id: 'd1',
                  type: 'peasant_levies',
                  ownerId: 'def',
                ),
                probResolverUnit(
                  id: 'd2',
                  type: 'peasant_levies',
                  ownerId: 'def',
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
                expect(
                  r1.rounds[i].defenderCasualties,
                  r2.rounds[i].defenderCasualties,
                );
                expect(
                  r1.rounds[i].attackerCasualties,
                  r2.rounds[i].attackerCasualties,
                );
              }
            },
          ),
          CombatResolverProbabilisticScenario(
            scenarioId: 'crp-rounds-bounded',
            label: 'rounds bounded by maxCombatRounds',
            run: () {
              final attackerUnits = [
                probResolverUnit(id: 'a1', type: 'pikemen'),
                probResolverUnit(id: 'a2', type: 'pikemen'),
              ];
              final defenderUnits = [
                probResolverUnit(
                  id: 'd1',
                  type: 'pikemen',
                  ownerId: 'def',
                ),
                probResolverUnit(
                  id: 'd2',
                  type: 'pikemen',
                  ownerId: 'def',
                ),
              ];

              final outcome = resolveEngagementProbabilistic(
                attackerUnits: attackerUnits,
                defenderUnits: defenderUnits,
                fortLevel: 0,
                terrain: 'plains',
                seed: 999,
              );

              expect(outcome.rounds.length, lessThanOrEqualTo(maxCombatRounds));
            },
          ),
          CombatResolverProbabilisticScenario(
            scenarioId: 'crp-strong-attacker-wins-majority',
            label: 'strong attacker tends to win over many trials',
            run: () {
              final attackerUnits = [
                probResolverUnit(
                  id: 'a1',
                  type: 'grenadiers',
                  medals: 2,
                ),
                probResolverUnit(
                  id: 'a2',
                  type: 'grenadiers',
                  medals: 1,
                ),
              ];
              final defenderUnits = [
                probResolverUnit(
                  id: 'd1',
                  type: 'peasant_levies',
                  ownerId: 'def',
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
              expect(
                attWins,
                greaterThan(50),
                reason: 'Strong attacker should win majority',
              );
            },
          ),
        ];

List<CombatResolverProbabilisticScenario>
    _combatResolverProbabilisticOutcomeScenarios() => [
          CombatResolverProbabilisticScenario(
            scenarioId: 'crp-per-round-details',
            label: 'outcome includes per-round details',
            run: () {
              final attackerUnits = [
                probResolverUnit(id: 'a1', type: 'grenadiers'),
              ];
              final defenderUnits = [
                probResolverUnit(
                  id: 'd1',
                  type: 'peasant_levies',
                  ownerId: 'def',
                ),
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
                expect(
                  round.probabilityAttackerHits,
                  inInclusiveRange(0.15, 0.85),
                );
                expect(
                  round.probabilityDefenderHits,
                  inInclusiveRange(0.15, 0.85),
                );
              }
            },
          ),
          CombatResolverProbabilisticScenario(
            scenarioId: 'crp-mutual-annihilation-possible',
            label:
                'can produce mutualAnnihilation when both sides eliminated',
            run: () {
              final attackerUnits = [
                probResolverUnit(id: 'a1', type: 'pikemen'),
                probResolverUnit(id: 'a2', type: 'pikemen'),
              ];
              final defenderUnits = [
                probResolverUnit(
                  id: 'd1',
                  type: 'pikemen',
                  ownerId: 'def',
                ),
                probResolverUnit(
                  id: 'd2',
                  type: 'pikemen',
                  ownerId: 'def',
                ),
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
              expect(
                mutualAnnihilationResult,
                EngagementResult.mutualAnnihilation,
                reason: 'some seed should produce mutual annihilation',
              );
            },
          ),
          CombatResolverProbabilisticScenario(
            scenarioId: 'crp-stalemate-possible',
            label:
                'can produce stalemate when rounds end with both sides remaining',
            run: () {
              final attackerUnits = [
                probResolverUnit(id: 'a1', type: 'pikemen'),
                probResolverUnit(id: 'a2', type: 'pikemen'),
                probResolverUnit(id: 'a3', type: 'pikemen'),
              ];
              final defenderUnits = [
                probResolverUnit(
                  id: 'd1',
                  type: 'pikemen',
                  ownerId: 'def',
                ),
                probResolverUnit(
                  id: 'd2',
                  type: 'pikemen',
                  ownerId: 'def',
                ),
                probResolverUnit(
                  id: 'd3',
                  type: 'pikemen',
                  ownerId: 'def',
                ),
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
              expect(
                stalemateResult,
                EngagementResult.stalemate,
                reason: 'some seed should produce stalemate after max rounds',
              );
            },
          ),
        ];
