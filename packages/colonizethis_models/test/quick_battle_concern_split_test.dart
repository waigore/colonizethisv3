import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Barrel / concern-split smoke for Refs #4136 Slice C.
void main() {
  group('quick battle concern split barrel', () {
    test('positive: types construct via barrel', () {
      const group = QuickBattleGroup(
        lane: QuickBattleLane.center,
        line: QuickBattleLine.front,
      );
      const gun = QuickBattleEmplacedGun(
        id: 'g1',
        maxHp: 10,
        hp: 10,
        attackStrength: 1.0,
        defenseStrength: 1.0,
        rng: 2,
      );
      const deployment = QuickBattleDeployment(groups: [group]);
      final input = QuickBattleInput(
        attackerFactionId: 'a1',
        defenderFactionId: 'd1',
        provinceId: 'oldWorld|p1',
        regionId: 'oldWorld',
        attackerDeployment: deployment,
        defenderDeployment: deployment,
        emplacedGuns: const [gun],
      );
      const result = QuickBattleResult(
        winner: QuickBattleWinner.attacker,
        attackerCasualties: const [],
        defenderCasualties: const ['u1'],
        provinceFlips: true,
      );

      expect(group.lane, QuickBattleLane.center);
      expect(input.emplacedGuns.single.id, 'g1');
      expect(result.winner, QuickBattleWinner.attacker);
    });

    test('negative: QuickBattleEmplacedGun rejects missing required JSON keys', () {
      expect(
        () => QuickBattleEmplacedGun.fromJson(<String, dynamic>{}),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
