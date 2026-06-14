import 'dart:math';

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_combat/src/combat/deterministic_rng.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

List<int> _take(Random rng, int n) =>
    List<int>.generate(n, (_) => rng.nextInt(1 << 30));

List<int> _takeDet(DeterministicRng rng, int n) =>
    List<int>.generate(n, (_) => rng.nextInt(1 << 30));

Game _buildGame({int? seed, required int turn}) => Game(
  id: 'g',
  globalGameSeed: seed,
  worldState: WorldState(
    turnState: TurnState(phase: TurnPhase.orders, turnNumber: turn),
    oldWorld: const RegionData(),
    newWorld: const RegionData(),
  ),
  players: const [],
);

void main() {
  group('combat_rng factories (#3448)', () {
    test('quickBattleRng matches Random(seed) sequence', () {
      expect(_take(quickBattleRng(42), 8), _take(Random(42), 8));
    });

    test('quickBattleRng is deterministic for a fixed seed', () {
      expect(_take(quickBattleRng(7), 8), _take(quickBattleRng(7), 8));
    });

    test('probabilisticEngagementRng falls back to 0 for a null seed', () {
      expect(_take(probabilisticEngagementRng(null), 8), _take(Random(0), 8));
    });

    test('probabilisticEngagementRng matches Random(seed) for non-null seed', () {
      expect(_take(probabilisticEngagementRng(13), 8), _take(Random(13), 8));
    });

    test('navalCombatRng matches DeterministicRng(seed) sequence', () {
      expect(
        _takeDet(navalCombatRng(123), 8),
        _takeDet(DeterministicRng(123), 8),
      );
    });

    test('navalCombatRng is deterministic for a fixed seed', () {
      expect(_takeDet(navalCombatRng(5), 8), _takeDet(navalCombatRng(5), 8));
    });

    group('game-seeded factories', () {
      test('preCombatBindingRng matches the SPEC §3 hash recipe', () {
        final game = _buildGame(seed: 99, turn: 4);
        final expected = Random(Object.hash(99, 4, kPreCombatBindingSeedToken));
        expect(_take(preCombatBindingRng(game), 8), _take(expected, 8));
      });

      test('preCombatBindingRng treats a null globalGameSeed as 0', () {
        final game = _buildGame(turn: 1);
        final expected = Random(Object.hash(0, 1, kPreCombatBindingSeedToken));
        expect(_take(preCombatBindingRng(game), 8), _take(expected, 8));
      });

      test('battleAssignmentRng matches hash(seed, turn, region, province)', () {
        final game = _buildGame(seed: 12, turn: 6);
        const ctx = BattleContext(
          provinceId: 'oldWorld|P3',
          regionId: 'oldWorld',
          defenderFactionId: 'd',
          defenderUnitIds: [],
          attackers: [
            AttackingSide(factionId: 'a', unitIds: ['u1']),
          ],
          fortLevel: 0,
          terrain: 'plains',
        );
        final expected = Random(Object.hash(12, 6, 'oldWorld', 'oldWorld|P3'));
        expect(_take(battleAssignmentRng(game, ctx), 8), _take(expected, 8));
      });

      test('battleAssignmentRng differs across provinces', () {
        final game = _buildGame(seed: 12, turn: 6);
        const ctxA = BattleContext(
          provinceId: 'oldWorld|P1',
          regionId: 'oldWorld',
          defenderFactionId: 'd',
          defenderUnitIds: [],
          attackers: [
            AttackingSide(factionId: 'a', unitIds: ['u1']),
          ],
          fortLevel: 0,
          terrain: 'plains',
        );
        const ctxB = BattleContext(
          provinceId: 'oldWorld|P2',
          regionId: 'oldWorld',
          defenderFactionId: 'd',
          defenderUnitIds: [],
          attackers: [
            AttackingSide(factionId: 'a', unitIds: ['u1']),
          ],
          fortLevel: 0,
          terrain: 'plains',
        );
        expect(
          _take(battleAssignmentRng(game, ctxA), 8),
          isNot(_take(battleAssignmentRng(game, ctxB), 8)),
        );
      });
    });
  });
}
