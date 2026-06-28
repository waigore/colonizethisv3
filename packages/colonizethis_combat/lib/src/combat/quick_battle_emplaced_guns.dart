/// Virtual emplaced-gun subsystem for Quick Battle siege resolution.
///
/// SPEC/program/quick-battle-resolution.md (siege — defender damage split).
///
/// Parallels [buildQuickBattleEmplacedGuns] in `quick_battle_emplaced_builder.dart`
/// (which builds the immutable input guns); this module owns the mutable
/// in-battle gun state and the round-robin HP damage application used by the
/// resolver.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

/// Mutable per-battle state for a virtual emplaced gun. HP is decremented as the
/// siege progresses; seeded from an immutable [QuickBattleEmplacedGun].
class MutableEmplacedGun {
  MutableEmplacedGun({
    required this.id,
    required this.maxHp,
    required this.hp,
    required this.attackStrength,
    required this.defenseStrength,
  });

  /// Creates mutable battle state from an immutable input gun.
  factory MutableEmplacedGun.fromInput(QuickBattleEmplacedGun g) =>
      MutableEmplacedGun(
        id: g.id,
        maxHp: g.maxHp,
        hp: g.hp,
        attackStrength: g.attackStrength,
        defenseStrength: g.defenseStrength,
      );

  final String id;
  final int maxHp;
  int hp;
  final double attackStrength;
  final double defenseStrength;
}

/// Sum of attack+defense strength over guns still alive (`hp > 0`).
double aliveGunStrengthSum(List<MutableEmplacedGun> guns) {
  var s = 0.0;
  for (final g in guns) {
    if (g.hp > 0) {
      s += g.attackStrength + g.defenseStrength;
    }
  }
  return s;
}

/// Total remaining HP over guns still alive (`hp > 0`).
int sumAliveGunHp(List<MutableEmplacedGun> guns) {
  var s = 0;
  for (final g in guns) {
    if (g.hp > 0) s += g.hp;
  }
  return s;
}

/// Applies [amount] points of HP damage round-robin across alive guns, sorted
/// once by [MutableEmplacedGun.id] for determinism.
///
/// Dead guns are removed in-place from the working list as they fall instead of
/// rebuilding it from [guns] on each death.
void applyRoundRobinGunHpDamage(List<MutableEmplacedGun> guns, int amount) {
  if (amount <= 0) return;
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
