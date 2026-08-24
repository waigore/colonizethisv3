// Table-driven land resolver part-2 integration scenarios (Refs #3865).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'combat_resolver_test_support.dart';
import 'scenario_runner.dart';

List<RunnableScenario> combatResolverPart2TieBreakScenarios() => [
  RunnableScenario(
    scenarioId: 'crp2-tie-break-deterministic',
    label: 'battle tie-break is deterministic for same seed and context',
    run: () {
      Game makeGame() => landResolverTieBreakGame();
      const ctx = BattleContext(
        provinceId: 'p',
        regionId: 'oldWorld',
        defenderFactionId: 'def',
        defenderUnitIds: ['d1'],
        attackers: [
          AttackingSide(factionId: 'attA', unitIds: ['a1']),
          AttackingSide(factionId: 'attB', unitIds: ['a2']),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );

      final r1 = resolveBattleContext(makeGame(), ctx);
      final r2 = resolveBattleContext(makeGame(), ctx);
      expect(
        r1.worldState.oldWorld.provinces,
        r2.worldState.oldWorld.provinces,
      );
      expect(r1.worldState.oldWorld.units, r2.worldState.oldWorld.units);
      expect(r1.generals, r2.generals);
    },
  ),
];
