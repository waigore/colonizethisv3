import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

Game _gameWithGeneral({required int medals}) {
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: const [Player(id: 'att', displayName: 'Att', isHuman: true)],
    generals: [General(id: 'g-att', ownerId: 'att', medals: medals)],
  );
}

void main() {
  group('awardWinningGeneralMedal', () {
    test('increments winning attacker general medals', () {
      final game = _gameWithGeneral(medals: 1);
      const ctx = BattleContext(
        provinceId: 'oldWorld|p1',
        regionId: 'oldWorld',
        defenderFactionId: 'def',
        defenderUnitIds: ['d1'],
        attackers: [
          AttackingSide(
            factionId: 'att',
            unitIds: ['a1'],
            generalId: 'g-att',
          ),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );
      final after = awardWinningGeneralMedal(game, ctx, 'att');
      expect(after.generals.single.medals, 2);
    });

    test('does not increment at medal cap', () {
      final game = _gameWithGeneral(medals: 4);
      const ctx = BattleContext(
        provinceId: 'oldWorld|p1',
        regionId: 'oldWorld',
        defenderFactionId: 'def',
        defenderUnitIds: ['d1'],
        attackers: [
          AttackingSide(
            factionId: 'att',
            unitIds: ['a1'],
            generalId: 'g-att',
          ),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );
      final after = awardWinningGeneralMedal(game, ctx, 'att');
      expect(after.generals.single.medals, 4);
      expect(identical(after, game), isTrue);
    });
  });

  test(
    'applyQuickBattleResultToGame awards medal on attacker Quick Battle win',
    () {
      final game = _gameWithGeneral(medals: 0);
      const ctx = BattleContext(
        provinceId: 'oldWorld|p1',
        regionId: 'oldWorld',
        defenderFactionId: 'def',
        defenderUnitIds: ['d1'],
        attackers: [
          AttackingSide(
            factionId: 'att',
            unitIds: ['a1'],
            generalId: 'g-att',
          ),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );
      const result = QuickBattleResult(
        winner: QuickBattleWinner.attacker,
        attackerCasualties: const [],
        defenderCasualties: const ['d1'],
        provinceFlips: false,
      );
      final after = applyQuickBattleResultToGame(game, ctx, result);
      expect(after.generals.single.medals, 1);
    },
  );
}
