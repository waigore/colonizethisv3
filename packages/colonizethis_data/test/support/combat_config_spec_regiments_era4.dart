// SPEC/game/military-units.md regiment table fixtures for combat_config_test.dart
// (Refs #4121 slice D, #4626 slice D era split).
import 'package:colonizethis_data/colonizethis_data.dart';

import 'combat_config_spec_regiment_row.dart';

const combatConfigMilitaryUnitsSpecByIdEra4 =
    <String, CombatConfigSpecRegimentRow>{
      'sharpshooters': (
        fpn: 5,
        fpm: 4,
        rng: 7,
        def: 7,
        mvr: 7,
        category: RegimentCategory.lightInfantry,
        era: 4,
      ),
      'rifle_infantry': (
        fpn: 9,
        fpm: 9,
        rng: 6,
        def: 6,
        mvr: 4,
        category: RegimentCategory.regularInfantry,
        era: 4,
      ),
      'guards': (
        fpn: 12,
        fpm: 10,
        rng: 6,
        def: 6,
        mvr: 4,
        category: RegimentCategory.heavyInfantry,
        era: 4,
      ),
      'scouts': (
        fpn: 5,
        fpm: 11,
        rng: 5,
        def: 6,
        mvr: 11,
        category: RegimentCategory.lightCavalry,
        era: 4,
      ),
      'carbine_cavalry': (
        fpn: 7,
        fpm: 17,
        rng: 5,
        def: 5,
        mvr: 9,
        category: RegimentCategory.heavyCavalry,
        era: 4,
      ),
      'field_artillery': (
        fpn: 10,
        fpm: 3,
        rng: 11,
        def: 4,
        mvr: 5,
        category: RegimentCategory.lightArtillery,
        era: 4,
      ),
      'siege_guns': (
        fpn: 17,
        fpm: 2,
        rng: 12,
        def: 3,
        mvr: 3,
        category: RegimentCategory.heavyArtillery,
        era: 4,
      ),
    };
