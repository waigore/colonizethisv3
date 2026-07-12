import 'dart:math';

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_combat/src/combat/deterministic_rng.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'combat_resolver_test_support.dart';
import 'scenario_runner.dart';

class CombatRngScenario implements LabeledScenario {
  const CombatRngScenario({
    required this.scenarioId,
    required this.label,
    required this.run,
  });
  final String scenarioId;
  @override
  final String label;
  final void Function() run;
}

List<int> _take(Random rng, int n) =>
    List<int>.generate(n, (_) => rng.nextInt(1 << 30));
List<int> _takeDet(DeterministicRng rng, int n) =>
    List<int>.generate(n, (_) => rng.nextInt(1 << 30));
Game _buildGame({int? seed, required int turn}) =>
    landResolverSeededEmptyGame(globalGameSeed: seed, turnNumber: turn);
List<CombatRngScenario> combatRngScenarios() => [
  CombatRngScenario(
    scenarioId: 'crng-quick-seed',
    label: 'quickBattleRng matches Random(seed) sequence',
    run: () => expect(_take(quickBattleRng(42), 8), _take(Random(42), 8)),
  ),
  CombatRngScenario(
    scenarioId: 'crng-quick-deterministic',
    label: 'quickBattleRng is deterministic for a fixed seed',
    run: () => expect(_take(quickBattleRng(7), 8), _take(quickBattleRng(7), 8)),
  ),
  CombatRngScenario(
    scenarioId: 'crng-prob-null',
    label: 'probabilisticEngagementRng falls back to 0 for a null seed',
    run: () =>
        expect(_take(probabilisticEngagementRng(null), 8), _take(Random(0), 8)),
  ),
  CombatRngScenario(
    scenarioId: 'crng-prob-seed',
    label: 'probabilisticEngagementRng matches Random(seed) for non-null seed',
    run: () =>
        expect(_take(probabilisticEngagementRng(13), 8), _take(Random(13), 8)),
  ),
  CombatRngScenario(
    scenarioId: 'crng-naval-seed',
    label: 'navalCombatRng matches DeterministicRng(seed) sequence',
    run: () => expect(
      _takeDet(navalCombatRng(123), 8),
      _takeDet(DeterministicRng(123), 8),
    ),
  ),
  CombatRngScenario(
    scenarioId: 'crng-naval-deterministic',
    label: 'navalCombatRng is deterministic for a fixed seed',
    run: () =>
        expect(_takeDet(navalCombatRng(5), 8), _takeDet(navalCombatRng(5), 8)),
  ),
];
List<CombatRngScenario> gameSeededCombatRngScenarios() => [
  CombatRngScenario(
    scenarioId: 'crng-precombat-hash',
    label: 'preCombatBindingRng matches the SPEC §3 hash recipe',
    run: () {
      final game = _buildGame(seed: 99, turn: 4);
      expect(
        _take(preCombatBindingRng(game), 8),
        _take(Random(Object.hash(99, 4, kPreCombatBindingSeedToken)), 8),
      );
    },
  ),
  CombatRngScenario(
    scenarioId: 'crng-precombat-null',
    label: 'preCombatBindingRng treats a null globalGameSeed as 0',
    run: () {
      final game = _buildGame(turn: 1);
      expect(
        _take(preCombatBindingRng(game), 8),
        _take(Random(Object.hash(0, 1, kPreCombatBindingSeedToken)), 8),
      );
    },
  ),
  CombatRngScenario(
    scenarioId: 'crng-assignment-hash',
    label: 'battleAssignmentRng matches hash(seed, turn, region, province)',
    run: () {
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
      expect(
        _take(battleAssignmentRng(game, ctx), 8),
        _take(Random(Object.hash(12, 6, 'oldWorld', 'oldWorld|P3')), 8),
      );
    },
  ),
  CombatRngScenario(
    scenarioId: 'crng-assignment-province',
    label: 'battleAssignmentRng differs across provinces',
    run: () {
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
    },
  ),
];
