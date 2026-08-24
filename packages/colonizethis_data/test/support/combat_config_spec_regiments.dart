// SPEC/game/military-units.md regiment table fixtures for combat_config_test.dart
// (Refs #4121 slice D, #4626 slice D era split).
import 'combat_config_spec_regiment_row.dart';
import 'combat_config_spec_regiments_era1.dart';
import 'combat_config_spec_regiments_era2.dart';
import 'combat_config_spec_regiments_era3.dart';
import 'combat_config_spec_regiments_era4.dart';

export 'combat_config_spec_regiment_row.dart';

/// Keys: regiment id. Values: FPN, FPM, RNG, DEF, MVR, category, era.
const combatConfigMilitaryUnitsSpecById = <String, CombatConfigSpecRegimentRow>{
  ...combatConfigMilitaryUnitsSpecByIdEra1,
  ...combatConfigMilitaryUnitsSpecByIdEra2,
  ...combatConfigMilitaryUnitsSpecByIdEra3,
  ...combatConfigMilitaryUnitsSpecByIdEra4,
};

/// Table order in SPEC/game/military-units.md (must match [regimentCatalog] order).
const combatConfigMilitaryUnitsSpecTableOrderIds = <String>[
  'peasant_levies',
  'pikemen',
  'arquebusiers',
  'bowmen',
  'squires',
  'knights',
  'culverin',
  'calivermen',
  'halberdiers',
  'musketeers',
  'cossacks',
  'lancers',
  'harquebusiers',
  'horse_artillery',
  'royal_artillery',
  'skirmishers',
  'regulars',
  'grenadiers',
  'hussars',
  'cuirassiers',
  'light_artillery',
  'heavy_artillery',
  'sharpshooters',
  'rifle_infantry',
  'guards',
  'scouts',
  'carbine_cavalry',
  'field_artillery',
  'siege_guns',
];
