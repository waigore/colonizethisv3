/// Combat configuration: regiment tactical stats, modifiers, initiative weights.
/// SPEC/game/military-units.md, SPEC/game/combat.md, SPEC/game/ruleset-config.md.
library;

/// Regiment tactical stats (FPN, FPM, RNG, DEF, MVR) per SPEC/game/military-units.md.
class RegimentStats {
  const RegimentStats({
    required this.id,
    required this.fpn,
    required this.fpm,
    required this.rng,
    required this.def,
    required this.mvr,
    required this.category,
    required this.era,
  });

  final String id;
  final int fpn;
  final int fpm;
  final int rng;
  final int def;
  final int mvr;
  final RegimentCategory category;
  final int era;

  bool get isCavalry =>
      category == RegimentCategory.lightCavalry ||
      category == RegimentCategory.spearCavalry ||
      category == RegimentCategory.heavyCavalry;
}

/// Regiment category per Imperialism II military roster.
enum RegimentCategory {
  lightInfantry,
  regularInfantry,
  heavyInfantry,
  bowmen,
  lightCavalry,
  spearCavalry,
  heavyCavalry,
  lightArtillery,
  heavyArtillery,
}

/// Full regiment table: 28 types across 8 categories and 4 eras.
/// SPEC/game/military-units.md.
const List<RegimentStats> regimentCatalog = [
  RegimentStats(
    id: 'peasant_levies',
    fpn: 0,
    fpm: 3,
    rng: 1,
    def: 3,
    mvr: 3,
    category: RegimentCategory.lightInfantry,
    era: 1,
  ),
  RegimentStats(
    id: 'pikemen',
    fpn: 0,
    fpm: 5,
    rng: 1,
    def: 5,
    mvr: 3,
    category: RegimentCategory.regularInfantry,
    era: 1,
  ),
  RegimentStats(
    id: 'arquebusiers',
    fpn: 5,
    fpm: 1,
    rng: 3,
    def: 3,
    mvr: 2,
    category: RegimentCategory.heavyInfantry,
    era: 1,
  ),
  RegimentStats(
    id: 'bowmen',
    fpn: 3,
    fpm: 1,
    rng: 4,
    def: 2,
    mvr: 3,
    category: RegimentCategory.bowmen,
    era: 1,
  ),
  RegimentStats(
    id: 'squires',
    fpn: 0,
    fpm: 4,
    rng: 1,
    def: 4,
    mvr: 6,
    category: RegimentCategory.lightCavalry,
    era: 1,
  ),
  RegimentStats(
    id: 'knights',
    fpn: 0,
    fpm: 6,
    rng: 1,
    def: 6,
    mvr: 4,
    category: RegimentCategory.spearCavalry,
    era: 1,
  ),
  RegimentStats(
    id: 'culverin',
    fpn: 8,
    fpm: 1,
    rng: 5,
    def: 2,
    mvr: 2,
    category: RegimentCategory.heavyArtillery,
    era: 1,
  ),
  RegimentStats(
    id: 'calivermen',
    fpn: 3,
    fpm: 2,
    rng: 5,
    def: 5,
    mvr: 4,
    category: RegimentCategory.lightInfantry,
    era: 2,
  ),
  RegimentStats(
    id: 'halberdiers',
    fpn: 0,
    fpm: 7,
    rng: 1,
    def: 6,
    mvr: 4,
    category: RegimentCategory.regularInfantry,
    era: 2,
  ),
  RegimentStats(
    id: 'musketeers',
    fpn: 7,
    fpm: 2,
    rng: 4,
    def: 4,
    mvr: 3,
    category: RegimentCategory.heavyInfantry,
    era: 2,
  ),
  RegimentStats(
    id: 'cossacks',
    fpn: 0,
    fpm: 5,
    rng: 1,
    def: 5,
    mvr: 8,
    category: RegimentCategory.lightCavalry,
    era: 2,
  ),
  RegimentStats(
    id: 'lancers',
    fpn: 0,
    fpm: 8,
    rng: 1,
    def: 5,
    mvr: 6,
    category: RegimentCategory.spearCavalry,
    era: 2,
  ),
  RegimentStats(
    id: 'harquebusiers',
    fpn: 2,
    fpm: 6,
    rng: 3,
    def: 5,
    mvr: 6,
    category: RegimentCategory.heavyCavalry,
    era: 2,
  ),
  RegimentStats(
    id: 'horse_artillery',
    fpn: 5,
    fpm: 2,
    rng: 7,
    def: 2,
    mvr: 3,
    category: RegimentCategory.lightArtillery,
    era: 2,
  ),
  RegimentStats(
    id: 'royal_artillery',
    fpn: 9,
    fpm: 2,
    rng: 8,
    def: 2,
    mvr: 2,
    category: RegimentCategory.heavyArtillery,
    era: 2,
  ),
  RegimentStats(
    id: 'skirmishers',
    fpn: 4,
    fpm: 3,
    rng: 5,
    def: 6,
    mvr: 6,
    category: RegimentCategory.lightInfantry,
    era: 3,
  ),
  RegimentStats(
    id: 'regulars',
    fpn: 7,
    fpm: 7,
    rng: 5,
    def: 5,
    mvr: 4,
    category: RegimentCategory.regularInfantry,
    era: 3,
  ),
  RegimentStats(
    id: 'grenadiers',
    fpn: 10,
    fpm: 8,
    rng: 5,
    def: 5,
    mvr: 4,
    category: RegimentCategory.heavyInfantry,
    era: 3,
  ),
  RegimentStats(
    id: 'hussars',
    fpn: 2,
    fpm: 8,
    rng: 3,
    def: 6,
    mvr: 11,
    category: RegimentCategory.lightCavalry,
    era: 3,
  ),
  RegimentStats(
    id: 'cuirassiers',
    fpn: 5,
    fpm: 13,
    rng: 3,
    def: 5,
    mvr: 9,
    category: RegimentCategory.heavyCavalry,
    era: 3,
  ),
  RegimentStats(
    id: 'light_artillery',
    fpn: 8,
    fpm: 3,
    rng: 9,
    def: 3,
    mvr: 4,
    category: RegimentCategory.lightArtillery,
    era: 3,
  ),
  RegimentStats(
    id: 'heavy_artillery',
    fpn: 13,
    fpm: 2,
    rng: 10,
    def: 2,
    mvr: 3,
    category: RegimentCategory.heavyArtillery,
    era: 3,
  ),
  RegimentStats(
    id: 'sharpshooters',
    fpn: 5,
    fpm: 4,
    rng: 7,
    def: 7,
    mvr: 7,
    category: RegimentCategory.lightInfantry,
    era: 4,
  ),
  RegimentStats(
    id: 'rifle_infantry',
    fpn: 9,
    fpm: 9,
    rng: 6,
    def: 6,
    mvr: 4,
    category: RegimentCategory.regularInfantry,
    era: 4,
  ),
  RegimentStats(
    id: 'guards',
    fpn: 12,
    fpm: 10,
    rng: 6,
    def: 6,
    mvr: 4,
    category: RegimentCategory.heavyInfantry,
    era: 4,
  ),
  RegimentStats(
    id: 'scouts',
    fpn: 5,
    fpm: 11,
    rng: 5,
    def: 6,
    mvr: 11,
    category: RegimentCategory.lightCavalry,
    era: 4,
  ),
  RegimentStats(
    id: 'carbine_cavalry',
    fpn: 7,
    fpm: 17,
    rng: 5,
    def: 5,
    mvr: 9,
    category: RegimentCategory.heavyCavalry,
    era: 4,
  ),
  RegimentStats(
    id: 'field_artillery',
    fpn: 10,
    fpm: 3,
    rng: 11,
    def: 4,
    mvr: 5,
    category: RegimentCategory.lightArtillery,
    era: 4,
  ),
  RegimentStats(
    id: 'siege_guns',
    fpn: 17,
    fpm: 2,
    rng: 12,
    def: 3,
    mvr: 3,
    category: RegimentCategory.heavyArtillery,
    era: 4,
  ),
];

/// Registry of regiment stats by id.
RegimentStats? regimentStatsById(String id) {
  for (final r in regimentCatalog) {
    if (r.id == id) return r;
  }
  return null;
}

/// Medal multipliers for FPN/FPM: 0→1.0, 1→1.1, 2→1.2, 3→1.3, 4→1.4.
const List<double> medalMultiplierValues = [1.0, 1.1, 1.2, 1.3, 1.4];

double medalMultiplierFor(int medals) {
  if (medals < 0 || medals > 4) return 1.0;
  return medalMultiplierValues[medals];
}

/// Difficulty level for combat modifiers.
enum DifficultyLevel {
  introductory,
  normal,
  hard,
  impossible,
}

/// Terrain modifier: multiplier applied to attacker or defender strength.
/// Key: terrain id (plains, forest, hills, mountain, swamp).
/// Values: attacker modifier, defender modifier (1.0 = no change).
const Map<String, (double attacker, double defender)> terrainModifiers = {
  'plains': (1.0, 1.0),
  'forest': (0.9, 1.1),
  'hills': (0.95, 1.05),
  'mountain': (0.8, 1.2),
  'swamp': (0.85, 1.15),
};

/// Fort level damage reduction (0–1): fraction of damage blocked for defenders.
const List<double> fortDamageReduction = [0.0, 0.2, 0.35, 0.5];

/// Fort level emplaced artillery strength contribution (baseline per gun).
const List<double> fortEmplacedStrength = [0.0, 3.0, 4.0, 5.0];

/// Number of emplaced guns per fort level.
const List<int> fortGunCount = [0, 1, 2, 3];

/// Difficulty multiplier: defender strength multiplier.
const Map<DifficultyLevel, double> difficultyDefenderMultiplier = {
  DifficultyLevel.introductory: 0.9,
  DifficultyLevel.normal: 1.0,
  DifficultyLevel.hard: 1.1,
  DifficultyLevel.impossible: 1.2,
};

/// Initiative weights for army initiative score.
/// cavalryShareWeight: weight for cavalry share (0–1) of army.
/// generalMedalWeight: weight per general medal.
const double initiativeCavalryShareWeight = 50.0;
const double initiativeGeneralMedalWeight = 10.0;
