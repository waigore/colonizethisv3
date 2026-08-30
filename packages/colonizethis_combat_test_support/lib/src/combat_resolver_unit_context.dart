// Unit and battle-context builders for land resolver tests (Refs #4196 slice C).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Minimal [Unit] for probabilistic resolver scenario tables.
Unit probResolverUnit({
  required String id,
  required String type,
  String ownerId = 'att',
  String provinceId = 'p',
  int medals = 0,
}) {
  return Unit(
    id: id,
    type: type,
    ownerId: ownerId,
    locationProvinceId: provinceId,
    medals: medals,
  );
}

/// Standard single-province [BattleContext] for land resolver tests.
BattleContext landResolverBattleContext({
  String provinceId = 'p',
  String regionId = 'oldWorld',
  String defenderFactionId = 'def',
  required List<String> defenderUnitIds,
  required List<AttackingSide> attackers,
  int fortLevel = 0,
  String terrain = 'plains',
}) {
  return BattleContext(
    provinceId: provinceId,
    regionId: regionId,
    defenderFactionId: defenderFactionId,
    defenderUnitIds: defenderUnitIds,
    attackers: attackers,
    fortLevel: fortLevel,
    terrain: terrain,
  );
}
