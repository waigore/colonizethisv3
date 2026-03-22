import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'conflict_detection.dart';

/// Builds virtual emplaced gun entities for siege Quick Battle input.
/// SPEC/game/quick-battle.md, SPEC/program/quick-battle-resolution.md.
List<QuickBattleEmplacedGun> buildQuickBattleEmplacedGuns(
  Game game,
  BattleContext ctx,
) {
  final fl = ctx.fortLevel;
  if (fl < 1 || fl > 3) return [];

  final n = fortGunCount[fl];
  if (n <= 0) return [];

  Player? defender;
  for (final p in game.players) {
    if (p.id == ctx.defenderFactionId) {
      defender = p;
      break;
    }
  }
  final militaryLevel = (defender?.militaryLevel ?? 2).clamp(1, 4);
  final tier = emplacedVirtualGunTierMultiplier(defender?.techUnlocked);
  final baseHeavyRng = heavyArtilleryBaselineRngForMilitaryLevel(militaryLevel);
  final rng = emplacedVirtualGunRngForMilitaryLevel(militaryLevel);
  final maxHp = emplacedVirtualGunMaxHpByFortLevel[fl];
  final perGunBase = fortEmplacedStrength[fl] * tier;
  final rngBonus = (rng - baseHeavyRng) * kEmplacedRngStrengthWeight;
  final str = perGunBase * (1.0 + rngBonus);
  final half = str * 0.5;

  final guns = <QuickBattleEmplacedGun>[];
  for (var i = 0; i < n; i++) {
    final id = 'qb:emplaced:${ctx.regionId}:${ctx.provinceId}:$i';
    guns.add(
      QuickBattleEmplacedGun(
        id: id,
        maxHp: maxHp,
        hp: maxHp,
        attackStrength: half,
        defenseStrength: half,
        rng: rng,
      ),
    );
  }
  return guns;
}
