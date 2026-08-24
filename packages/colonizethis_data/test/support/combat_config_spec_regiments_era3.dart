// SPEC/game/military-units.md regiment table fixtures for combat_config_test.dart
// (Refs #4121 slice D, #4626 slice D era split).
import 'package:colonizethis_data/colonizethis_data.dart';

import 'combat_config_spec_regiment_row.dart';

const combatConfigMilitaryUnitsSpecByIdEra3 =
    <String, CombatConfigSpecRegimentRow>{
      'skirmishers': (
        fpn: 4,
        fpm: 3,
        rng: 5,
        def: 6,
        mvr: 6,
        category: RegimentCategory.lightInfantry,
        era: 3,
      ),
      'regulars': (
        fpn: 7,
        fpm: 7,
        rng: 5,
        def: 5,
        mvr: 4,
        category: RegimentCategory.regularInfantry,
        era: 3,
      ),
      'grenadiers': (
        fpn: 10,
        fpm: 8,
        rng: 5,
        def: 5,
        mvr: 4,
        category: RegimentCategory.heavyInfantry,
        era: 3,
      ),
      'hussars': (
        fpn: 2,
        fpm: 8,
        rng: 3,
        def: 6,
        mvr: 11,
        category: RegimentCategory.lightCavalry,
        era: 3,
      ),
      'cuirassiers': (
        fpn: 5,
        fpm: 13,
        rng: 3,
        def: 5,
        mvr: 9,
        category: RegimentCategory.heavyCavalry,
        era: 3,
      ),
      'light_artillery': (
        fpn: 8,
        fpm: 3,
        rng: 9,
        def: 3,
        mvr: 4,
        category: RegimentCategory.lightArtillery,
        era: 3,
      ),
      'heavy_artillery': (
        fpn: 13,
        fpm: 2,
        rng: 10,
        def: 2,
        mvr: 3,
        category: RegimentCategory.heavyArtillery,
        era: 3,
      ),
    };
