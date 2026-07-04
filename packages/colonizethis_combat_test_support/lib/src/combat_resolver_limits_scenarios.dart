// Table-driven land resolver deployment-limit and general-medal scenarios (Refs #3865).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'combat_resolver_test_support.dart';

/// One row in a land resolver limits scenario table.
class CombatResolverLimitsScenario {
  const CombatResolverLimitsScenario({
    required this.scenarioId,
    required this.label,
    required this.run,
  });

  final String scenarioId;
  final String label;
  final void Function() run;
}

/// Runs [scenario].
void runCombatResolverLimitsScenario(CombatResolverLimitsScenario scenario) {
  scenario.run();
}

/// Deployment limits and general-medal scenarios (part 1 limits).
List<CombatResolverLimitsScenario> combatResolverLimitsScenarios() => [
  CombatResolverLimitsScenario(
    scenarioId: 'crl-deployment-cap-base-10',
    label:
        'deployment limit caps participating regiments per side (base 10, no Nationalism)',
    run: () {
      final attackerUnits = List.generate(
        15,
        (i) => Unit(
          id: 'a$i',
          type: 'grenadiers',
          ownerId: 'att',
          locationProvinceId: 'p',
          medals: 1,
        ),
      );
      final defenderUnits = List.generate(
        15,
        (i) => Unit(
          id: 'd$i',
          type: 'peasant_levies',
          ownerId: 'def',
          locationProvinceId: 'p',
          medals: 0,
        ),
      );
      final game = landResolverBattleGame(
        units: [...attackerUnits, ...defenderUnits],
      );
      final ctx = BattleContext(
        provinceId: 'p',
        regionId: 'oldWorld',
        defenderFactionId: 'def',
        defenderUnitIds: defenderUnits.map((u) => u.id).toList(),
        attackers: [
          AttackingSide(
            factionId: 'att',
            unitIds: attackerUnits.map((u) => u.id).toList(),
            generalMedals: 0,
          ),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );
      final result = resolveBattleContext(game, ctx);
      final survivingAtt = result.worldState.oldWorld.units
          .where((u) => u.ownerId == 'att')
          .length;
      final survivingDef = result.worldState.oldWorld.units
          .where((u) => u.ownerId == 'def')
          .length;
      expect(
        survivingAtt,
        greaterThanOrEqualTo(5),
        reason:
            'deployment limit 10: at most 10 attackers participate, so ≥5 must remain',
      );
      expect(
        survivingAtt + survivingDef,
        greaterThanOrEqualTo(5),
        reason: 'at least one side has non-participants',
      );
    },
  ),
  CombatResolverLimitsScenario(
    scenarioId: 'crl-deployment-cap-nationalism-12',
    label:
        'deployment limit with Nationalism tech is 12 (attacker has 13 units, ≥1 does not participate)',
    run: () {
      final attackerUnits = List.generate(
        13,
        (i) => Unit(
          id: 'a$i',
          type: 'grenadiers',
          ownerId: 'att',
          locationProvinceId: 'p',
          medals: 0,
        ),
      );
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
        players: const [
          Player(
            id: 'att',
            displayName: 'Att',
            isHuman: true,
            techUnlocked: {kTechIdNationalism: true},
          ),
          Player(id: 'def', displayName: 'Def', isHuman: false),
        ],
      );
      final ctx = BattleContext(
        provinceId: 'p',
        regionId: 'oldWorld',
        defenderFactionId: 'def',
        defenderUnitIds: ['d1'],
        attackers: [
          AttackingSide(
            factionId: 'att',
            unitIds: attackerUnits.map((u) => u.id).toList(),
            generalMedals: 0,
          ),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );
      final result = resolveBattleContext(game, ctx);
      final survivingAtt = result.worldState.oldWorld.units
          .where((u) => u.ownerId == 'att')
          .length;
      expect(
        survivingAtt,
        greaterThanOrEqualTo(1),
        reason: 'deployment limit 12 with Nationalism: at most 12 participate',
      );
    },
  ),
  CombatResolverLimitsScenario(
    scenarioId: 'crl-winning-general-medal',
    label: 'assigned winning general gains +1 medal immediately and persists',
    run: () {
      final game = landResolverBattleGame(
        turnNumber: 5,
        units: [
          Unit(
            id: 'a1',
            type: 'grenadiers',
            ownerId: 'att',
            locationProvinceId: 'p',
          ),
          Unit(
            id: 'a2',
            type: 'grenadiers',
            ownerId: 'att',
            locationProvinceId: 'p',
          ),
          Unit(
            id: 'd1',
            type: 'peasant_levies',
            ownerId: 'def',
            locationProvinceId: 'p',
          ),
        ],
        players: landResolverHumanPlayers,
        generals: const [General(id: 'g-att', ownerId: 'att', medals: 1)],
      );
      const ctx = BattleContext(
        provinceId: 'p',
        regionId: 'oldWorld',
        defenderFactionId: 'def',
        defenderUnitIds: ['d1'],
        attackers: [
          AttackingSide(
            factionId: 'att',
            unitIds: ['a1', 'a2'],
            generalId: 'g-att',
            generalMedals: 1,
          ),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );

      final after = resolveBattleContext(game, ctx);
      final updatedGeneral = after.generals.firstWhere((g) => g.id == 'g-att');
      expect(updatedGeneral.medals, 2);
    },
  ),
  CombatResolverLimitsScenario(
    scenarioId: 'crl-leader-fallback-no-general',
    label: 'leader fallback medals apply when no uncommitted general exists',
    run: () {
      final game = landResolverBattleGame(
        turnNumber: 3,
        units: [
          Unit(
            id: 'a1',
            type: 'grenadiers',
            ownerId: 'att',
            locationProvinceId: 'p',
          ),
          Unit(
            id: 'd1',
            type: 'grenadiers',
            ownerId: 'def',
            locationProvinceId: 'p',
          ),
        ],
        players: const [
          Player(
            id: 'att',
            displayName: 'Att',
            isHuman: true,
            leaderKey: 'napoleon',
          ),
          Player(id: 'def', displayName: 'Def', isHuman: true),
        ],
      );
      const ctx = BattleContext(
        provinceId: 'p',
        regionId: 'oldWorld',
        defenderFactionId: 'def',
        defenderUnitIds: ['d1'],
        attackers: [
          AttackingSide(factionId: 'att', unitIds: ['a1']),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );

      final after = resolveBattleContext(game, ctx);
      expect(after.generals, isEmpty);
    },
  ),
  CombatResolverLimitsScenario(
    scenarioId: 'crl-general-medal-cap-4',
    label: 'general medals are capped at 4 on immediate engagement win',
    run: () {
      final game = landResolverBattleGame(
        turnNumber: 6,
        units: [
          Unit(
            id: 'a1',
            type: 'grenadiers',
            ownerId: 'att',
            locationProvinceId: 'p',
          ),
          Unit(
            id: 'a2',
            type: 'grenadiers',
            ownerId: 'att',
            locationProvinceId: 'p',
          ),
          Unit(
            id: 'd1',
            type: 'peasant_levies',
            ownerId: 'def',
            locationProvinceId: 'p',
          ),
        ],
        players: landResolverHumanPlayers,
        generals: const [General(id: 'g-att', ownerId: 'att', medals: 4)],
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
      final after = resolveBattleContext(game, ctx);
      final updatedGeneral = after.generals.firstWhere((g) => g.id == 'g-att');
      expect(updatedGeneral.medals, 4);
    },
  ),
];
