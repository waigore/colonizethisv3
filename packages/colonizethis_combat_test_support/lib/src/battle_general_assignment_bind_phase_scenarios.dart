// Table-driven bindGeneralsForCombatPhase scenarios (Refs #3865).

import 'package:colonizethis_combat/src/combat/leader_bonus_helpers.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart';

import 'combat_resolver_test_support.dart';
import 'scenario_runner.dart';

BattleContext _bindPhaseCtx(String provinceId) => BattleContext(
  provinceId: provinceId,
  regionId: 'oldWorld',
  defenderFactionId: 'def',
  defenderUnitIds: const ['d1'],
  attackers: const [
    AttackingSide(factionId: 'att', unitIds: ['a1']),
  ],
  fortLevel: 0,
  terrain: 'plains',
);



List<RunnableScenario>
battleGeneralAssignmentBindPhaseScenarios() => [
  RunnableScenario(
    scenarioId: 'bgb-binds-distinct-then-fallback',
    label:
        'binds distinct attacker/defender generals per context, then falls back '
        'when each faction pool is exhausted',
    run: () {
      final game = bindGeneralsPhaseGame();
      final ledger = CombatPhaseGeneralLedger();
      final bound = bindGeneralsForCombatPhase(
        game: game,
        contexts: [_bindPhaseCtx('p3'), _bindPhaseCtx('p1'), _bindPhaseCtx('p2')],
        ledger: ledger,
      );

      expect(
        bound.map((c) => c.provinceId).toList(),
        ['p1', 'p2', 'p3'],
      );

      final attackerGenerals = [
        for (final c in bound) c.attackers.single.generalId,
      ];
      expect(attackerGenerals[0], isNotNull);
      expect(attackerGenerals[1], isNotNull);
      expect(attackerGenerals[0], isNot(attackerGenerals[1]));
      expect(attackerGenerals[2], isNull);
      expect(
        {attackerGenerals[0], attackerGenerals[1]},
        {'gatt1', 'gatt2'},
      );

      expect(
        ledger.attackCommanderGeneralIdsByFaction['att'],
        {'gatt1', 'gatt2'},
      );

      for (final c in bound.take(2)) {
        expect(c.attackers.single.generalMedals, lessThanOrEqualTo(4));
      }
      expect(
        bound[2].attackers.single.generalMedals,
        fallbackGeneralMedalsFromLeader(game, 'att'),
      );

      expect(bound[0].defenderGeneralId, 'gdef1');
      expect(bound[0].defenderGeneralMedals, 3);
      expect(bound[1].defenderGeneralId, isNull);
      expect(
        bound[1].defenderGeneralMedals,
        fallbackGeneralMedalsFromLeader(game, 'def'),
      );
      expect(bound[2].defenderGeneralId, isNull);
    },
  ),
  RunnableScenario(
    scenarioId: 'bgb-respects-pre-bound-ledger',
    label: 'respects generals already bound in the ledger before this pass',
    run: () {
      final game = bindGeneralsPhaseGame();
      final ledger = CombatPhaseGeneralLedger()
        ..attackCommanderGeneralIdsByFaction['att'] = {'gatt1', 'gatt2'};
      final bound = bindGeneralsForCombatPhase(
        game: game,
        contexts: [_bindPhaseCtx('p1')],
        ledger: ledger,
      );
      expect(bound.single.attackers.single.generalId, isNull);
      expect(
        bound.single.attackers.single.generalMedals,
        fallbackGeneralMedalsFromLeader(game, 'att'),
      );
    },
  ),
];
