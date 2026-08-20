import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

BattleContext _ctx({
  List<String> attackerUnits = const ['a1', 'a2'],
  List<String> defenderUnits = const ['d1', 'd2', 'd3'],
}) {
  return BattleContext(
    provinceId: 'oldWorld|p1',
    regionId: 'oldWorld',
    defenderFactionId: 'def',
    defenderUnitIds: defenderUnits,
    attackers: [
      AttackingSide(factionId: 'att', unitIds: attackerUnits),
    ],
    fortLevel: 0,
    terrain: 'plains',
  );
}

void main() {
  group('landBattleSummaryFromQuickBattle', () {
    test('attacker victory maps outcome and counts', () {
      final summary = landBattleSummaryFromQuickBattle(
        ctx: _ctx(),
        qbResult: const QuickBattleResult(
          winner: QuickBattleWinner.attacker,
          attackerCasualties: ['a1'],
          defenderCasualties: ['d1', 'd2'],
          provinceFlips: true,
        ),
      );
      expect(summary.outcomeName, EngagementResult.attackerVictory.name);
      expect(summary.attackerCasualtyCount, 1);
      expect(summary.defenderCasualtyCount, 2);
      expect(summary.winnerFactionId, 'att');
    });

    test('mutual exhaustion with survivors is stalemate', () {
      final summary = landBattleSummaryFromQuickBattle(
        ctx: _ctx(),
        qbResult: const QuickBattleResult(
          winner: QuickBattleWinner.mutualExhaustion,
          attackerCasualties: ['a1'],
          defenderCasualties: ['d1'],
          provinceFlips: false,
        ),
      );
      expect(summary.outcomeName, EngagementResult.stalemate.name);
      expect(summary.winnerFactionId, isNull);
    });

    test('mutual exhaustion wiping both sides is mutual annihilation', () {
      final summary = landBattleSummaryFromQuickBattle(
        ctx: _ctx(
          attackerUnits: const ['a1'],
          defenderUnits: const ['d1'],
        ),
        qbResult: const QuickBattleResult(
          winner: QuickBattleWinner.mutualExhaustion,
          attackerCasualties: ['a1'],
          defenderCasualties: ['d1'],
          provinceFlips: false,
        ),
      );
      expect(summary.outcomeName, EngagementResult.mutualAnnihilation.name);
      expect(summary.winnerFactionId, isNull);
    });
  });

  group('deriveLandBattleOutcomeName', () {
    test('stalemate when both sides survive without flip', () {
      expect(
        deriveLandBattleOutcomeName(
          ctx: _ctx(
            attackerUnits: const ['a1'],
            defenderUnits: const ['d1'],
          ),
          allCasualties: const {},
          defenderUnitIdsAfterLoop: const ['d1'],
          provinceChangedOwner: false,
        ),
        EngagementResult.stalemate.name,
      );
    });
  });
}
