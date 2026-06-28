// Covers bindGeneralsForCombatPhase pre-combat binding across multiple battle
// contexts (Refs #3290 Phase 1 combat extraction; test additions to reach the
// >=90% per-package coverage gate are in scope per issue F5).
import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_combat/src/combat/leader_bonus_helpers.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

BattleContext _ctx(String provinceId) => BattleContext(
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

Game _game() => Game(
  id: 'g1',
  globalGameSeed: 7,
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
    oldWorld: RegionData(
      provinces: const [
        Province(id: 'p1', regionId: 'oldWorld', ownerId: 'def'),
        Province(id: 'p2', regionId: 'oldWorld', ownerId: 'def'),
        Province(id: 'p3', regionId: 'oldWorld', ownerId: 'def'),
      ],
      units: const [],
    ),
    newWorld: const RegionData(),
  ),
  players: const [
    Player(id: 'att', displayName: 'Att', isHuman: true),
    Player(id: 'def', displayName: 'Def', isHuman: true),
  ],
  // medals 9 must clamp to the 0..4 range on assignment.
  generals: const [
    General(id: 'gatt1', ownerId: 'att', medals: 9),
    General(id: 'gatt2', ownerId: 'att', medals: 2),
    General(id: 'gdef1', ownerId: 'def', medals: 3),
  ],
);

void main() {
  group('bindGeneralsForCombatPhase', () {
    test(
      'binds distinct attacker/defender generals per context, then falls back '
      'when each faction pool is exhausted',
      () {
        final game = _game();
        final ledger = CombatPhaseGeneralLedger();
        // Pass contexts out of order to exercise the deterministic region/
        // province ordering inside the binder.
        final bound = bindGeneralsForCombatPhase(
          game: game,
          contexts: [_ctx('p3'), _ctx('p1'), _ctx('p2')],
          ledger: ledger,
        );

        // Returned contexts are sorted by (regionId, provinceId).
        expect(
          bound.map((c) => c.provinceId).toList(),
          ['p1', 'p2', 'p3'],
        );

        final attackerGenerals = [
          for (final c in bound) c.attackers.single.generalId,
        ];
        // Two attacker generals exist, so the first two contexts each bind a
        // distinct one and the third exhausts the pool (null + fallback).
        expect(attackerGenerals[0], isNotNull);
        expect(attackerGenerals[1], isNotNull);
        expect(attackerGenerals[0], isNot(attackerGenerals[1]));
        expect(attackerGenerals[2], isNull);
        expect(
          {attackerGenerals[0], attackerGenerals[1]},
          {'gatt1', 'gatt2'},
        );

        // Ledger now records both attacker generals as used this phase.
        expect(
          ledger.attackCommanderGeneralIdsByFaction['att'],
          {'gatt1', 'gatt2'},
        );

        // Medals are clamped to the 0..4 range (gatt1 has 9).
        for (final c in bound.take(2)) {
          expect(c.attackers.single.generalMedals, lessThanOrEqualTo(4));
        }
        // Exhausted attacker falls back to the leader-derived medal value.
        expect(
          bound[2].attackers.single.generalMedals,
          fallbackGeneralMedalsFromLeader(game, 'att'),
        );

        // The single defender general is consumed by the first context; later
        // contexts exhaust the defender pool and fall back.
        expect(bound[0].defenderGeneralId, 'gdef1');
        expect(bound[0].defenderGeneralMedals, 3);
        expect(bound[1].defenderGeneralId, isNull);
        expect(
          bound[1].defenderGeneralMedals,
          fallbackGeneralMedalsFromLeader(game, 'def'),
        );
        expect(bound[2].defenderGeneralId, isNull);
      },
    );

    test('respects generals already bound in the ledger before this pass', () {
      final game = _game();
      final ledger = CombatPhaseGeneralLedger()
        ..attackCommanderGeneralIdsByFaction['att'] = {'gatt1', 'gatt2'};
      final bound = bindGeneralsForCombatPhase(
        game: game,
        contexts: [_ctx('p1')],
        ledger: ledger,
      );
      // Both attacker generals are pre-used, so the only context falls back.
      expect(bound.single.attackers.single.generalId, isNull);
      expect(
        bound.single.attackers.single.generalMedals,
        fallbackGeneralMedalsFromLeader(game, 'att'),
      );
    });
  });
}
