/// Quick Battle terminal-outcome construction and logging.
///
/// SPEC/program/quick-battle-resolution.md.
///
/// Hosts [QuickBattleFinisher], which bundles the battle-invariant inputs
/// (input, accumulated casualty lists, mutable emplaced guns) so each of the
/// resolver's terminal outcomes only supplies the varying `winner` and
/// `provinceFlips`.
library;

import 'package:colonizethis_combat/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'quick_battle_emplaced_guns.dart';

/// Builds and logs the final [QuickBattleResult] from the battle-invariant
/// state captured once per resolution.
///
/// Previously each of the seven terminal outcomes called a free function with
/// the same five-argument invariant set repeated inline; capturing those once
/// here removes that duplication.
class QuickBattleFinisher {
  QuickBattleFinisher({
    required this.input,
    required this.attackerCasualties,
    required this.defenderCasualties,
    required this.mutableGuns,
    required this.useVirtualEmplaced,
  });

  final QuickBattleInput input;
  final List<String> attackerCasualties;
  final List<String> defenderCasualties;
  final List<MutableEmplacedGun> mutableGuns;
  final bool useVirtualEmplaced;

  /// Constructs the result for [winner]/[provinceFlips] and logs the outcome.
  QuickBattleResult finish({
    required QuickBattleWinner winner,
    required bool provinceFlips,
  }) {
    final result = _buildResult(winner: winner, provinceFlips: provinceFlips);
    combatLog.d(
      'quick_battle end winner=${result.winner.name} '
      'flip=${result.provinceFlips} fortDowngrade=${result.fortDowngradeFromDestroyedEmplaced}',
    );
    return result;
  }

  QuickBattleResult _buildResult({
    required QuickBattleWinner winner,
    required bool provinceFlips,
  }) {
    final outcomes = useVirtualEmplaced
        ? mutableGuns
              .map(
                (g) => QuickBattleEmplacedGunOutcome(
                  id: g.id,
                  hp: g.hp.clamp(0, g.maxHp),
                  destroyed: g.hp <= 0,
                ),
              )
              .toList()
        : const <QuickBattleEmplacedGunOutcome>[];
    final downgrade =
        useVirtualEmplaced &&
        input.emplacedGuns.isNotEmpty &&
        mutableGuns.isNotEmpty &&
        mutableGuns.every((g) => g.hp <= 0);
    return QuickBattleResult(
      winner: winner,
      attackerCasualties: attackerCasualties,
      defenderCasualties: defenderCasualties,
      provinceFlips: provinceFlips,
      fortDowngradeFromDestroyedEmplaced: downgrade,
      emplacedGunOutcomes: outcomes,
    );
  }
}
