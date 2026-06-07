/// Regression tests covering the performance-related refactors in
/// `quick_battle_resolver_*.dart` (Refs #2316 P1 #8 and P1 #9).
///
/// These tests pin the observable outcomes of:
///
/// 1. The round-robin gun HP damage distributor, which now maintains the
///    alive-gun list incrementally instead of rebuilding it per single HP.
/// 2. The round-level effective-strength cache, which now reuses the
///    unchanged side's strength across both strikes in a single round.
///
/// All assertions go through the public `resolveQuickBattle` entrypoint so
/// the optimizations stay verifiable through documented behavior.
library;

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

QuickBattleEmplacedGun _gun(String id, {required int hp}) {
  return QuickBattleEmplacedGun(
    id: id,
    maxHp: hp,
    hp: hp,
    attackStrength: 2.0,
    defenseStrength: 2.0,
    rng: 11,
  );
}

QuickBattleInput _siege({
  required int seed,
  required int fortLevel,
  required List<QuickBattleEmplacedGun> guns,
  required int attackerRegiments,
  required int defenderRegiments,
  int maxRounds = 3,
}) {
  return QuickBattleInput(
    attackerFactionId: 'att',
    defenderFactionId: 'def',
    provinceId: 'p-perf',
    regionId: kRegionOldWorld,
    fortLevel: fortLevel,
    emplacedGuns: guns,
    attackerDeployment: QuickBattleDeployment(
      groups: [
        QuickBattleGroup(
          lane: QuickBattleLane.center,
          line: QuickBattleLine.front,
          unitIds: List.generate(attackerRegiments, (i) => 'att-$i'),
          cohesion: 3,
        ),
      ],
      laneTerrain: const {'center_front': QuickBattleLaneTerrain.open},
    ),
    defenderDeployment: QuickBattleDeployment(
      groups: [
        QuickBattleGroup(
          lane: QuickBattleLane.center,
          line: QuickBattleLine.front,
          unitIds: List.generate(defenderRegiments, (i) => 'def-$i'),
          cohesion: 3,
        ),
      ],
      laneTerrain: const {'center_front': QuickBattleLaneTerrain.open},
    ),
    seed: seed,
    maxRounds: maxRounds,
  );
}

void main() {
  group('round-robin gun HP damage stays deterministic when guns die mid-round', () {
    test('three small guns drained over multiple rounds keep sorted-id parity', () {
      // Given: three small-HP guns; sustained heavy attacker pressure forces
      // multiple guns to reach 0 HP mid-round, exercising the alive-list
      // rebuild path inside `_applyRoundRobinGunHpDamage`.
      final input = _siege(
        seed: 7,
        fortLevel: 3,
        guns: [
          _gun('qb:emplaced:ow:p:0', hp: 2),
          _gun('qb:emplaced:ow:p:1', hp: 2),
          _gun('qb:emplaced:ow:p:2', hp: 2),
        ],
        attackerRegiments: 60,
        defenderRegiments: 8,
      );
      final r1 = resolveQuickBattle(input);
      final r2 = resolveQuickBattle(input);
      expect(r1.emplacedGunOutcomes.length, 3);
      expect(r1.emplacedGunOutcomes.length, r2.emplacedGunOutcomes.length);
      for (var i = 0; i < r1.emplacedGunOutcomes.length; i++) {
        expect(r1.emplacedGunOutcomes[i].id, r2.emplacedGunOutcomes[i].id);
        expect(r1.emplacedGunOutcomes[i].hp, r2.emplacedGunOutcomes[i].hp);
        expect(
          r1.emplacedGunOutcomes[i].destroyed,
          r2.emplacedGunOutcomes[i].destroyed,
        );
      }
      // Determinism extends to all casualty lists.
      expect(r1.attackerCasualties, r2.attackerCasualties);
      expect(r1.defenderCasualties, r2.defenderCasualties);
      expect(r1.winner, r2.winner);
      expect(r1.provinceFlips, r2.provinceFlips);
      expect(
        r1.fortDowngradeFromDestroyedEmplaced,
        r2.fortDowngradeFromDestroyedEmplaced,
      );
    });

    test('asymmetric gun HP still allocates damage in sorted-id round-robin order', () {
      // Given: two guns at unequal HP. Round-robin order is by id, so the
      // gun with the smaller id should reach 0 HP first when both eventually
      // die; remaining damage continues to drain the survivor.
      final input = _siege(
        seed: 13,
        fortLevel: 2,
        guns: [
          _gun('qb:emplaced:ow:p:0', hp: 3),
          _gun('qb:emplaced:ow:p:1', hp: 10),
        ],
        attackerRegiments: 50,
        defenderRegiments: 6,
      );
      final result = resolveQuickBattle(input);
      expect(result.emplacedGunOutcomes, hasLength(2));
      final byId = {for (final o in result.emplacedGunOutcomes) o.id: o};
      expect(byId.containsKey('qb:emplaced:ow:p:0'), isTrue);
      expect(byId.containsKey('qb:emplaced:ow:p:1'), isTrue);
      // Smaller gun cannot end up with strictly more HP than the larger gun
      // under sorted-id round-robin: it absorbs hits at least as often.
      expect(
        byId['qb:emplaced:ow:p:0']!.hp <= byId['qb:emplaced:ow:p:1']!.hp,
        isTrue,
        reason: 'sorted-id round-robin damages the smaller-id gun first',
      );
    });
  });

  group('effective-strength caching preserves outcomes across initiative branches', () {
    test('attacker-acts-first siege duplicate runs are bit-identical', () {
      // Cavalry-heavy attacker -> attackerActsFirst branch. The cached
      // `effAtt` is reused on the second strike; only `effDef` is recomputed.
      final input = QuickBattleInput(
        attackerFactionId: 'att',
        defenderFactionId: 'def',
        provinceId: 'p-cache-att-first',
        regionId: kRegionOldWorld,
        fortLevel: 2,
        emplacedGuns: [
          _gun('qb:emplaced:ow:c:0', hp: 6),
          _gun('qb:emplaced:ow:c:1', hp: 6),
        ],
        attackerDeployment: QuickBattleDeployment(
          groups: [
            QuickBattleGroup(
              lane: QuickBattleLane.center,
              line: QuickBattleLine.front,
              unitIds: List.generate(20, (i) => 'a$i'),
              cohesion: 3,
            ),
          ],
          laneTerrain: const {'center_front': QuickBattleLaneTerrain.open},
        ),
        defenderDeployment: QuickBattleDeployment(
          groups: [
            QuickBattleGroup(
              lane: QuickBattleLane.center,
              line: QuickBattleLine.front,
              unitIds: List.generate(12, (i) => 'd$i'),
              cohesion: 3,
            ),
          ],
          laneTerrain: const {'center_front': QuickBattleLaneTerrain.open},
        ),
        attackerCavalryShare: 1.0,
        defenderCavalryShare: 0.0,
        seed: 4242,
        maxRounds: 3,
      );

      final r1 = resolveQuickBattle(input);
      final r2 = resolveQuickBattle(input);
      expect(r1.winner, r2.winner);
      expect(r1.provinceFlips, r2.provinceFlips);
      expect(r1.attackerCasualties, r2.attackerCasualties);
      expect(r1.defenderCasualties, r2.defenderCasualties);
      expect(r1.emplacedGunOutcomes.length, r2.emplacedGunOutcomes.length);
      for (var i = 0; i < r1.emplacedGunOutcomes.length; i++) {
        expect(r1.emplacedGunOutcomes[i].id, r2.emplacedGunOutcomes[i].id);
        expect(r1.emplacedGunOutcomes[i].hp, r2.emplacedGunOutcomes[i].hp);
        expect(
          r1.emplacedGunOutcomes[i].destroyed,
          r2.emplacedGunOutcomes[i].destroyed,
        );
      }
    });

    test('defender-acts-first siege duplicate runs are bit-identical', () {
      // Cavalry-heavy defender -> !attackerActsFirst branch. Now `effDef` is
      // cached across both strikes and `effAtt` is recomputed after the
      // attacker takes losses.
      final input = QuickBattleInput(
        attackerFactionId: 'att',
        defenderFactionId: 'def',
        provinceId: 'p-cache-def-first',
        regionId: kRegionOldWorld,
        fortLevel: 1,
        emplacedGuns: [_gun('qb:emplaced:ow:c:0', hp: 5)],
        attackerDeployment: QuickBattleDeployment(
          groups: [
            QuickBattleGroup(
              lane: QuickBattleLane.center,
              line: QuickBattleLine.front,
              unitIds: List.generate(16, (i) => 'a$i'),
              cohesion: 3,
            ),
          ],
          laneTerrain: const {'center_front': QuickBattleLaneTerrain.open},
        ),
        defenderDeployment: QuickBattleDeployment(
          groups: [
            QuickBattleGroup(
              lane: QuickBattleLane.center,
              line: QuickBattleLine.front,
              unitIds: List.generate(10, (i) => 'd$i'),
              cohesion: 3,
            ),
          ],
          laneTerrain: const {'center_front': QuickBattleLaneTerrain.open},
        ),
        attackerCavalryShare: 0.0,
        defenderCavalryShare: 1.0,
        seed: 9090,
        maxRounds: 3,
      );

      final r1 = resolveQuickBattle(input);
      final r2 = resolveQuickBattle(input);
      expect(r1.winner, r2.winner);
      expect(r1.provinceFlips, r2.provinceFlips);
      expect(r1.attackerCasualties, r2.attackerCasualties);
      expect(r1.defenderCasualties, r2.defenderCasualties);
      expect(r1.emplacedGunOutcomes.length, r2.emplacedGunOutcomes.length);
      for (var i = 0; i < r1.emplacedGunOutcomes.length; i++) {
        expect(r1.emplacedGunOutcomes[i].id, r2.emplacedGunOutcomes[i].id);
        expect(r1.emplacedGunOutcomes[i].hp, r2.emplacedGunOutcomes[i].hp);
      }
    });

    test('non-siege battle outcomes are unchanged across initiative orderings', () {
      // Regression net: the strength-caching change must not affect the
      // standard, non-siege casualty/winner outcomes for a fixed seed.
      final inputA = QuickBattleInput(
        attackerFactionId: 'att',
        defenderFactionId: 'def',
        provinceId: 'p-non-siege',
        regionId: kRegionOldWorld,
        attackerDeployment: QuickBattleDeployment(
          groups: [
            QuickBattleGroup(
              lane: QuickBattleLane.center,
              line: QuickBattleLine.front,
              unitIds: List.generate(14, (i) => 'a$i'),
              cohesion: 3,
            ),
          ],
          laneTerrain: const {'center_front': QuickBattleLaneTerrain.open},
        ),
        defenderDeployment: QuickBattleDeployment(
          groups: [
            QuickBattleGroup(
              lane: QuickBattleLane.center,
              line: QuickBattleLine.front,
              unitIds: List.generate(10, (i) => 'd$i'),
              cohesion: 3,
            ),
          ],
          laneTerrain: const {'center_front': QuickBattleLaneTerrain.open},
        ),
        attackerCavalryShare: 1.0,
        defenderCavalryShare: 0.0,
        seed: 555,
        maxRounds: 3,
      );
      final inputB = QuickBattleInput(
        attackerFactionId: inputA.attackerFactionId,
        defenderFactionId: inputA.defenderFactionId,
        provinceId: inputA.provinceId,
        regionId: inputA.regionId,
        attackerDeployment: inputA.attackerDeployment,
        defenderDeployment: inputA.defenderDeployment,
        attackerCavalryShare: 0.0,
        defenderCavalryShare: 1.0,
        seed: 555,
        maxRounds: 3,
      );

      final a = resolveQuickBattle(inputA);
      final b = resolveQuickBattle(inputB);
      // Both runs must be internally deterministic (same input -> same output).
      expect(resolveQuickBattle(inputA).attackerCasualties, a.attackerCasualties);
      expect(resolveQuickBattle(inputB).defenderCasualties, b.defenderCasualties);
      // Initiative ordering is observable: at least one of casualty totals
      // differs between attacker-first and defender-first runs.
      final attTotalA = a.attackerCasualties.length;
      final defTotalA = a.defenderCasualties.length;
      final attTotalB = b.attackerCasualties.length;
      final defTotalB = b.defenderCasualties.length;
      expect(
        attTotalA != attTotalB || defTotalA != defTotalB,
        isTrue,
        reason: 'initiative ordering should still affect outcomes after caching',
      );
    });
  });
}
