// Quick Battle emplaced-gun builders for table-driven scenarios (Refs #3865).

import 'package:colonizethis_combat/src/combat/quick_battle_emplaced_guns.dart';

/// Mutable emplaced gun with tunable combat stats for scenario tables.
MutableEmplacedGun emplacedGun(
  String id,
  int hp, {
  double att = 2.0,
  double def = 3.0,
}) =>
    MutableEmplacedGun(
      id: id,
      maxHp: 4,
      hp: hp,
      attackStrength: att,
      defenseStrength: def,
    );
