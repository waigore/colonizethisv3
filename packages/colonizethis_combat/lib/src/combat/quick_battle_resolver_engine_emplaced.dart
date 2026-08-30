/// Quick Battle emplaced-gun mixed casualty selection.
///
/// SPEC/program/quick-battle-resolution.md.
library;

import 'dart:math';

import 'package:colonizethis_models/colonizethis_models.dart';

import 'quick_battle_emplaced_guns.dart';
import 'quick_battle_resolver_engine_groups.dart';

List<String> pickDefenderLosses({
  required List<QuickBattleGroup> groups,
  required double fraction,
  required Random rng,
  required List<MutableEmplacedGun> mutableGuns,
  required bool useVirtualEmplaced,
}) {
  if (!useVirtualEmplaced) return pickCasualties(groups, fraction, rng);
  final regimentCount = totalUnitCount(groups);
  final gunHpPool = sumAliveGunHp(mutableGuns);
  final totalSlots = regimentCount + gunHpPool;
  final gunHpLoss = totalSlots > 0 && gunHpPool > 0
      ? min(gunHpPool, max(0, (fraction * gunHpPool).round()))
      : 0;
  applyRoundRobinGunHpDamage(mutableGuns, gunHpLoss);
  final regFrac = regimentCount > 0 && totalSlots > 0
      ? (fraction * regimentCount / totalSlots).clamp(0.0, 1.0)
      : 0.0;
  return pickCasualties(groups, regFrac, rng);
}
