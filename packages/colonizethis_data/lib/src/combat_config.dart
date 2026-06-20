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

  bool get isArtillery =>
      category == RegimentCategory.lightArtillery ||
      category == RegimentCategory.heavyArtillery;

  /// Eligible for mutual-annihilation garrison recovery type: not cavalry, not artillery.
  /// SPEC/game/combat.md (bowmen and other non-cav / non-arty roster types count).
  bool get isEligibleGarrisonRecoveryInfantry => !isCavalry && !isArtillery;
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

/// Full regiment table: 29 types across 8 categories and 4 eras.
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

/// Deterministic pick for mutual-annihilation garrison recovery regiment type.
/// Chooses maximum `(FPN + FPM)` among [eligible]; tie-break: lexicographically
/// smallest `id`. Empty [eligible] is allowed (caller passes filtered catalog).
/// SPEC/game/combat.md § Garrison recovery type.
String selectGarrisonRecoveryRegimentType(Iterable<RegimentStats> eligible) {
  RegimentStats? best;
  for (final r in eligible) {
    if (best == null) {
      best = r;
      continue;
    }
    final bestSum = best.fpn + best.fpm;
    final sum = r.fpn + r.fpm;
    if (sum > bestSum) {
      best = r;
    } else if (sum == bestSum && r.id.compareTo(best.id) < 0) {
      best = r;
    }
  }
  if (best == null) return 'peasant_levies';
  return best.id;
}

/// Regiment id for recovered garrison units after mutual annihilation when the chain continues.
/// Uses [regimentCatalog] entries for `era` in 1..4: eligible types are [RegimentStats.isEligibleGarrisonRecoveryInfantry].
/// SPEC/game/combat.md § Garrison recovery type; implemented in `combat_resolver.dart`.
String garrisonRecoveryRegimentTypeForEra(int era) {
  final e = era.clamp(1, 4);
  final eligible = regimentCatalog.where(
    (r) => r.era == e && r.isEligibleGarrisonRecoveryInfantry,
  );
  return selectGarrisonRecoveryRegimentType(eligible);
}

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
enum DifficultyLevel { introductory, normal, hard, impossible }

/// Terrain modifier: multiplier applied to attacker or defender strength.
/// Key: terrain id (`TerrainType.name`): plains, hardwoodForest, scrubForest,
/// hills, mountain, swamp, desert.
/// Values: attacker modifier, defender modifier (1.0 = no change).
/// Hardwood forest gives a stronger defender bonus (dense cover, ×1.5) than
/// scrub forest (×1.1, same as the legacy forest). Issue #3573 R5.
const Map<String, (double attacker, double defender)> terrainModifiers = {
  'plains': (1.0, 1.0),
  'hardwoodForest': (0.9, 1.5),
  'scrubForest': (0.9, 1.1),
  'hills': (0.95, 1.05),
  'mountain': (0.8, 1.2),
  'swamp': (0.85, 1.15),
  'desert': (1.0, 1.0),
};

/// Fort level damage reduction (0–1): fraction of damage blocked for defenders.
/// SPEC/game/siege-mechanics.md: Fort 0: 0%, Wood: 25%, Stone: 45%, Modern: 60%.
const List<double> fortDamageReduction = [0.0, 0.25, 0.45, 0.60];

/// Fort level emplaced artillery strength contribution (baseline per gun).
const List<double> fortEmplacedStrength = [0.0, 3.0, 4.0, 5.0];

/// Number of emplaced guns per fort level.
const List<int> fortGunCount = [0, 1, 2, 3];

/// Max HP per virtual emplaced gun by fort level (index 0 unused). SPEC/game/siege-mechanics.md, quick-battle-resolution.md.
const List<int> emplacedVirtualGunMaxHpByFortLevel = [0, 6, 8, 10];

/// Tech ids for emplaced quality (Royal → Heavy → Siege). SPEC/game/tech-tree-military.md.
const String kTechHeavyEmplacedArtillery = 'heavy_emplaced_artillery';
const String kTechEmplacedSiegeGuns = 'emplaced_siege_guns';

/// Strength multiplier on virtual emplaced guns from emplaced-quality tech tier.
double emplacedVirtualGunTierMultiplier(Map<String, bool>? techUnlocked) {
  final m = techUnlocked;
  if (m != null && m[kTechEmplacedSiegeGuns] == true) return 1.30;
  if (m != null && m[kTechHeavyEmplacedArtillery] == true) return 1.15;
  return 1.0;
}

/// RNG of same-era heavy artillery regiment (baseline for +1 emplaced RNG). [militaryLevel] is 1–4.
int heavyArtilleryBaselineRngForMilitaryLevel(int militaryLevel) {
  final era = militaryLevel.clamp(1, 4);
  for (final r in regimentCatalog) {
    if (r.category == RegimentCategory.heavyArtillery && r.era == era) {
      return r.rng;
    }
  }
  return 10;
}

/// Resolved emplaced gun RNG: baseline + 1 per GDD.
int emplacedVirtualGunRngForMilitaryLevel(int militaryLevel) =>
    heavyArtilleryBaselineRngForMilitaryLevel(militaryLevel) + 1;

/// Per-point RNG above heavy-artillery baseline scales Quick Battle scalar strength (stub until FPN/FPM/RNG wired).
const double kEmplacedRngStrengthWeight = 0.04;

/// Wall HP per fort level (0 = no wall). Damage to defenders is applied after wall soaks this much.
/// SPEC/game/siege-mechanics.md (Wall Strength: Light / Medium / Heavy).
const List<double> wallHpByFortLevel = [0.0, 10.0, 20.0, 30.0];

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

/// Deployment limit per side in battle. SPEC/game/military-generals.md.
/// Base regiments per side; +1 per general medal (added in resolver).
const int deploymentLimitBase = 10;
const int deploymentLimitWithNationalism = 12;

/// Base deployment +2 when [kTechIdNationalism] is unlocked. SPEC/game/tech-tree-diplomacy-civilian.md.
/// Trade Consulate / Embassy / NAP tech: [kTechIdDiplomaticExpertise]. Builder upgrade_town: [kTechIdNationalBureaucracy].
/// War declaration optics: [kTechIdPropaganda]. Join Empire: [kTechIdEmpireBuilding].
