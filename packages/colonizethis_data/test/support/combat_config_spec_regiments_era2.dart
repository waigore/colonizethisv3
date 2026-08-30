// SPEC/game/military-units.md regiment table fixtures for combat_config_test.dart
// (Refs #4121 slice D, #4626 slice D era split).
import 'package:colonizethis_data/colonizethis_data.dart';

import 'combat_config_spec_regiment_row.dart';

const combatConfigMilitaryUnitsSpecByIdEra2 =
    <String, CombatConfigSpecRegimentRow>{
      'calivermen': (
        fpn: 3,
        fpm: 2,
        rng: 5,
        def: 5,
        mvr: 4,
        category: RegimentCategory.lightInfantry,
        era: 2,
      ),
      'halberdiers': (
        fpn: 0,
        fpm: 7,
        rng: 1,
        def: 6,
        mvr: 4,
        category: RegimentCategory.regularInfantry,
        era: 2,
      ),
      'musketeers': (
        fpn: 7,
        fpm: 2,
        rng: 4,
        def: 4,
        mvr: 3,
        category: RegimentCategory.heavyInfantry,
        era: 2,
      ),
      'cossacks': (
        fpn: 0,
        fpm: 5,
        rng: 1,
        def: 5,
        mvr: 8,
        category: RegimentCategory.lightCavalry,
        era: 2,
      ),
      'lancers': (
        fpn: 0,
        fpm: 8,
        rng: 1,
        def: 5,
        mvr: 6,
        category: RegimentCategory.spearCavalry,
        era: 2,
      ),
      'harquebusiers': (
        fpn: 2,
        fpm: 6,
        rng: 3,
        def: 5,
        mvr: 6,
        category: RegimentCategory.heavyCavalry,
        era: 2,
      ),
      'horse_artillery': (
        fpn: 5,
        fpm: 2,
        rng: 7,
        def: 2,
        mvr: 3,
        category: RegimentCategory.lightArtillery,
        era: 2,
      ),
      'royal_artillery': (
        fpn: 9,
        fpm: 2,
        rng: 8,
        def: 2,
        mvr: 2,
        category: RegimentCategory.heavyArtillery,
        era: 2,
      ),
    };
