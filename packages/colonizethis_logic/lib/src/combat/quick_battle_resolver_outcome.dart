part of 'quick_battle_resolver.dart';

QuickBattleResult _finishAndLogQuickBattleResult({
  required QuickBattleWinner winner,
  required List<String> attackerCasualties,
  required List<String> defenderCasualties,
  required bool provinceFlips,
  required QuickBattleInput input,
  required List<_MutableEmplacedGun> mutableGuns,
  required bool useVirtualEmplaced,
}) {
  final result = _finishResult(
    winner: winner,
    attackerCasualties: attackerCasualties,
    defenderCasualties: defenderCasualties,
    provinceFlips: provinceFlips,
    input: input,
    mutableGuns: mutableGuns,
    useVirtualEmplaced: useVirtualEmplaced,
  );
  logicLog.d(
    'quick_battle end winner=${result.winner.name} '
    'flip=${result.provinceFlips} fortDowngrade=${result.fortDowngradeFromDestroyedEmplaced}',
  );
  return result;
}

class _MutableEmplacedGun {
  _MutableEmplacedGun({
    required this.id,
    required this.maxHp,
    required this.hp,
    required this.attackStrength,
    required this.defenseStrength,
  });

  final String id;
  final int maxHp;
  int hp;
  final double attackStrength;
  final double defenseStrength;
}

QuickBattleResult _finishResult({
  required QuickBattleWinner winner,
  required List<String> attackerCasualties,
  required List<String> defenderCasualties,
  required bool provinceFlips,
  required QuickBattleInput input,
  required List<_MutableEmplacedGun> mutableGuns,
  required bool useVirtualEmplaced,
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

double _aliveGunStrengthSum(List<_MutableEmplacedGun> guns) {
  var s = 0.0;
  for (final g in guns) {
    if (g.hp > 0) {
      s += g.attackStrength + g.defenseStrength;
    }
  }
  return s;
}

int _sumAliveGunHp(List<_MutableEmplacedGun> guns) {
  var s = 0;
  for (final g in guns) {
    if (g.hp > 0) s += g.hp;
  }
  return s;
}

void _applyRoundRobinGunHpDamage(List<_MutableEmplacedGun> guns, int amount) {
  if (amount <= 0) return;
  // Sort once up front by id for determinism; then remove dead guns in-place
  // instead of rebuilding the whole list from [guns] on each death.
  final alive = guns.where((g) => g.hp > 0).toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  if (alive.isEmpty) return;
  var remaining = amount;
  var idx = 0;
  while (remaining > 0 && alive.isNotEmpty) {
    idx = idx % alive.length;
    final target = alive[idx];
    target.hp -= 1;
    remaining--;
    if (target.hp <= 0) {
      alive.removeAt(idx);
      // idx stays the same so the next gun (now shifted into this slot) is
      // processed next; no need to increment.
    } else {
      idx++;
    }
  }
}
