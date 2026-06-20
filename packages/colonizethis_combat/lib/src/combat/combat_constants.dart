/// Shared constants for combat resolution.
/// Kept separate from [combat_resolver.dart] to reduce compilation unit size.

const String kRecoveryUnitPrefix = 'recover_';
const double kGarrisonRecoveryFraction = 0.2;
const double kNoDefenderRatioFallback = 10.0;

/// When feeding coverage is omitted for a faction, treat as full supply.
const double kDefaultFeedingCoverageMultiplier = 1.0;

/// General medals: bounds and per-victory gain. SPEC/game/military-generals.md.
const int kGeneralMedalsMin = 0;
const int kGeneralMedalsMax = 4;
const int kGeneralMedalsGainedOnBattleWin = 1;

/// Morale aura from general medals: base multiplier plus per-medal increment.
const double kMoraleMultiplierBaseFromGenerals = 1.0;
const double kMoraleMultiplierPerGeneralMedal = 0.05;

/// Great Power / fallback effective era for regiment strength aggregation.
/// Matches [effectiveEraForFaction] default when faction is not minor/tribe.
const int kDefaultEffectiveMilitaryEra = 4;

/// Default multipliers when morale/leader bonuses are neutral in an engagement.
const double kNeutralMoraleMultiplier = 1.0;
const double kNeutralLeaderMultiplier = 1.0;

/// Terrain table fallback: no modifier when terrain key is unknown.
const double kNeutralTerrainAttackerModifier = 1.0;
const double kNeutralTerrainDefenderModifier = 1.0;

/// Fort levels that receive siege combat modifiers (walls, guns, reduction).
const int kMinFortLevelForCombatModifiers = 1;
const int kMaxFortLevelForCombatModifiers = 3;

/// Attacker effective strength is scaled by `(this - fortDamageReduction[level])`.
const double kUnityAttackerStrengthMultiplier = 1.0;

/// Lower bound when subtracting wall HP from attacker effective strength for ratio.
const double kEffectiveAttackForRatioClampMin = 0.0;
const double kEffectiveAttackForRatioClampMax = double.infinity;

/// RNG range for initiative tie-break (exclusive upper bound for Random.nextInt).
const int kInitiativeTieBreakRngUpperExclusive = 1 << 31;

/// Cavalry share when an army lists no regiments (sort key only).
const double kZeroCavalryShareWhenNoUnits = 0.0;
