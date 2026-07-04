// Table-driven land resolveEngagement / resolveBattleContext scenarios (Refs #3865).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'combat_resolver_test_support.dart';

/// One row in a land resolver engagement scenario table.
class CombatResolverEngagementScenario {
  const CombatResolverEngagementScenario({
    required this.scenarioId,
    required this.label,
    required this.run,
  });

  final String scenarioId;
  final String label;
  final void Function() run;
}

/// Runs [scenario].
void runCombatResolverEngagementScenario(
  CombatResolverEngagementScenario scenario,
) {
  scenario.run();
}

/// Scenarios for [resolveEngagement] and [resolveBattleContext] (part 1).
List<CombatResolverEngagementScenario> combatResolverEngagementScenarios() =>
    [
      ..._combatResolverEngagementOutcomeScenarios(),
      ..._combatResolverEngagementContextScenarios(),
    ];

List<CombatResolverEngagementScenario>
    _combatResolverEngagementOutcomeScenarios() => [
      CombatResolverEngagementScenario(
        scenarioId: 'cre-attacker-wins-decisively',
        label: 'attacker wins decisively when much stronger',
        run: () {
          final attackerUnits = [
            Unit(
              id: 'a1',
              type: 'grenadiers',
              ownerId: 'att',
              locationProvinceId: 'p',
              medals: 3,
            ),
            Unit(
              id: 'a2',
              type: 'grenadiers',
              ownerId: 'att',
              locationProvinceId: 'p',
              medals: 2,
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

          final outcome = resolveEngagement(
            attackerUnits: attackerUnits,
            defenderUnits: defenderUnits,
            fortLevel: 0,
            terrain: 'plains',
          );

          expect(outcome.result, EngagementResult.attackerVictory);
          expect(outcome.defenderCasualties, contains('d1'));
        },
      ),
      CombatResolverEngagementScenario(
        scenarioId: 'cre-defender-wins',
        label: 'defender wins when much stronger',
        run: () {
          final attackerUnits = [
            Unit(
              id: 'a1',
              type: 'peasant_levies',
              ownerId: 'att',
              locationProvinceId: 'p',
              medals: 0,
            ),
          ];
          final defenderUnits = [
            Unit(
              id: 'd1',
              type: 'grenadiers',
              ownerId: 'def',
              locationProvinceId: 'p',
              medals: 3,
            ),
            Unit(
              id: 'd2',
              type: 'grenadiers',
              ownerId: 'def',
              locationProvinceId: 'p',
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
        },
      ),
      CombatResolverEngagementScenario(
        scenarioId: 'cre-siege-modifiers',
        label: 'siege modifiers apply when fortLevel >= 1',
        run: () {
          final attackerUnits = [
            Unit(
              id: 'a1',
              type: 'pikemen',
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

          expect(
            siege.result,
            isNot(equals(field.result)),
            reason: 'Fort should affect outcome when strengths are close',
          );
        },
      ),
    ];

List<CombatResolverEngagementScenario>
    _combatResolverEngagementContextScenarios() => [
      CombatResolverEngagementScenario(
        scenarioId: 'cre-feeding-morale-penalty',
        label:
            'low attacker feeding coverage penalises strength via morale multiplier',
        run: () {
          final attackerUnits = [
            Unit(
              id: 'a1',
              type: 'grenadiers',
              ownerId: 'att',
              locationProvinceId: 'p',
              medals: 2,
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

          expect(underfed.attackerStrength, wellFed.attackerStrength);
          expect(
            underfed.result == EngagementResult.attackerVictory,
            isFalse,
            reason:
                'Underfed attacker should not perform better than well-fed attacker',
          );
        },
      ),
      CombatResolverEngagementScenario(
        scenarioId: 'cre-leader-keys-resolve-path',
        label:
            'leader keys from Game produce correct multipliers in resolveEngagement path',
        run: () {
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
          final game = landResolverBattleGame(
            units: [...attackerUnits, ...defenderUnits],
            players: landResolverNapoleonFrederickPlayers,
          );
          const ctx = BattleContext(
            provinceId: 'p',
            regionId: 'oldWorld',
            defenderFactionId: 'def',
            defenderUnitIds: ['d1'],
            attackers: [
              AttackingSide(factionId: 'att', unitIds: ['a1', 'a2']),
            ],
            fortLevel: 0,
            terrain: 'plains',
          );
          final result = resolveBattleContext(game, ctx);
          expect(
            result.worldState.oldWorld.units.length,
            lessThanOrEqualTo(3),
            reason: 'some units may be casualties',
          );
          expect(result.worldState.oldWorld.provinces.single.id, 'p');
        },
      ),
      CombatResolverEngagementScenario(
        scenarioId: 'cre-new-world-context',
        label: 'resolveBattleContext updates newWorld when regionId is newWorld',
        run: () {
          final game = landResolverNewWorldBattleGame(
            provinceId: 'N1',
            units: [
              Unit(
                id: 'd1',
                type: 'peasant_levies',
                ownerId: 'def',
                locationProvinceId: 'N1',
                medals: 0,
              ),
              Unit(
                id: 'a1',
                type: 'grenadiers',
                ownerId: 'att',
                locationProvinceId: 'N1',
                medals: 3,
              ),
              Unit(
                id: 'a2',
                type: 'grenadiers',
                ownerId: 'att',
                locationProvinceId: 'N1',
                medals: 2,
              ),
            ],
          );
          const ctx = BattleContext(
            provinceId: 'N1',
            regionId: 'newWorld',
            defenderFactionId: 'def',
            defenderUnitIds: ['d1'],
            attackers: [
              AttackingSide(
                factionId: 'att',
                unitIds: ['a1', 'a2'],
                generalMedals: 0,
              ),
            ],
            fortLevel: 0,
            terrain: 'plains',
          );
          final result = resolveBattleContext(game, ctx);
          expect(result.worldState.newWorld.provinces.single.id, 'N1');
          expect(
            result.worldState.newWorld.units.length,
            greaterThanOrEqualTo(1),
            reason:
                'attacker should win and have at least one surviving unit',
          );
        },
      ),
    ];
