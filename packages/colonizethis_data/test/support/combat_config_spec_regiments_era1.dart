// SPEC/game/military-units.md regiment table fixtures for combat_config_test.dart
// (Refs #4121 slice D, #4626 slice D era split).
import 'package:colonizethis_data/colonizethis_data.dart';

import 'combat_config_spec_regiment_row.dart';

const combatConfigMilitaryUnitsSpecByIdEra1 =
    <String, CombatConfigSpecRegimentRow>{
      'peasant_levies': (
        fpn: 0,
        fpm: 3,
        rng: 1,
        def: 3,
        mvr: 3,
        category: RegimentCategory.lightInfantry,
        era: 1,
      ),
      'pikemen': (
        fpn: 0,
        fpm: 5,
        rng: 1,
        def: 5,
        mvr: 3,
        category: RegimentCategory.regularInfantry,
        era: 1,
      ),
      'arquebusiers': (
        fpn: 5,
        fpm: 1,
        rng: 3,
        def: 3,
        mvr: 2,
        category: RegimentCategory.heavyInfantry,
        era: 1,
      ),
      'bowmen': (
        fpn: 3,
        fpm: 1,
        rng: 4,
        def: 2,
        mvr: 3,
        category: RegimentCategory.bowmen,
        era: 1,
      ),
      'squires': (
        fpn: 0,
        fpm: 4,
        rng: 1,
        def: 4,
        mvr: 6,
        category: RegimentCategory.lightCavalry,
        era: 1,
      ),
      'knights': (
        fpn: 0,
        fpm: 6,
        rng: 1,
        def: 6,
        mvr: 4,
        category: RegimentCategory.spearCavalry,
        era: 1,
      ),
      'culverin': (
        fpn: 8,
        fpm: 1,
        rng: 5,
        def: 2,
        mvr: 2,
        category: RegimentCategory.heavyArtillery,
        era: 1,
      ),
    };
