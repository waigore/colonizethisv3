/// Single source of truth for the attacker/defender strength-ratio breakpoints
/// shared by every combat resolver (Refs #3448, AC2).
///
/// Both the auto-resolve engagement loss profile
/// ([combatLossProfileForStrengthRatio]) and the Quick Battle engine
/// (`quick_battle_resolver_engine.dart`) classify the striker-to-target
/// strength ratio against these breakpoints via
/// [classifyCombatStrengthRatioBand], then layer their own loss fractions /
/// action modifiers on top. Keeping the thresholds in one place means the
/// `>= 1.5` / `<= 0.67` band edges can never silently drift between resolvers.
///
/// The probabilistic resolver (`combat_resolver_probabilistic.dart`) does not
/// use these bands: it samples casualties via clamped hit odds and a Poisson
/// model rather than a ratio classifier, so there is no shared breakpoint to
/// deduplicate there.

/// Striker is decisively stronger at or above this ratio.
const double kStrongStrikerStrengthRatioThreshold = 1.5;

/// Striker is decisively weaker at or below this ratio.
const double kStrongTargetStrengthRatioThreshold = 0.67;

/// Coarse classification of a striker-to-target effective-strength ratio against
/// the shared [kStrongStrikerStrengthRatioThreshold] /
/// [kStrongTargetStrengthRatioThreshold] breakpoints.
enum CombatStrengthRatioBand { strongStriker, strongTarget, even }

/// Classifies [ratio] (striker effective strength / target effective strength)
/// into a [CombatStrengthRatioBand] using the shared breakpoints.
///
/// `ratio >= 1.5` is [CombatStrengthRatioBand.strongStriker]; `ratio <= 0.67`
/// is [CombatStrengthRatioBand.strongTarget]; anything between is
/// [CombatStrengthRatioBand.even].
CombatStrengthRatioBand classifyCombatStrengthRatioBand(double ratio) {
  if (ratio >= kStrongStrikerStrengthRatioThreshold) {
    return CombatStrengthRatioBand.strongStriker;
  }
  if (ratio <= kStrongTargetStrengthRatioThreshold) {
    return CombatStrengthRatioBand.strongTarget;
  }
  return CombatStrengthRatioBand.even;
}

const double _bluntAttackerVictoryUpperRatio = 4.0;
const double _attackerEdgeRatioThreshold = 1.0;
const double _bluntAttackerLossFraction = 0.6;
const double _bluntDefenderLossFraction = 0.4;
const double _strongAttackerLossFraction = 0.15;
const double _strongDefenderLossFraction = 1.0;
const double _strongDefenderAttackerLossFraction = 1.0;
const double _strongDefenderDefenderLossFraction = 0.15;
const double _attackerEdgeAttackerLossFraction = 0.3;
const double _attackerEdgeDefenderLossFraction = 0.6;
const double _defaultAttackerLossFraction = 0.5;
const double _defaultDefenderLossFraction = 0.4;
const int _minCasualtySlots = 0;

enum CombatMutualEliminationOutcome {
  attackerVictory,
  defenderVictory,
  mutualAnnihilation,
}

class CombatLossProfile {
  const CombatLossProfile({
    required this.attackerLossFraction,
    required this.defenderLossFraction,
    required this.bluntsAttackerVictory,
    required this.mutualEliminationOutcome,
  });

  final double attackerLossFraction;
  final double defenderLossFraction;
  final bool bluntsAttackerVictory;
  final CombatMutualEliminationOutcome mutualEliminationOutcome;
}

CombatLossProfile combatLossProfileForStrengthRatio({
  required double attackerDefenderStrengthRatio,
  required bool attackerLowMorale,
}) {
  final ratio = attackerDefenderStrengthRatio;
  switch (classifyCombatStrengthRatioBand(ratio)) {
    case CombatStrengthRatioBand.strongStriker:
      if (attackerLowMorale && ratio < _bluntAttackerVictoryUpperRatio) {
        return const CombatLossProfile(
          attackerLossFraction: _bluntAttackerLossFraction,
          defenderLossFraction: _bluntDefenderLossFraction,
          bluntsAttackerVictory: true,
          mutualEliminationOutcome:
              CombatMutualEliminationOutcome.mutualAnnihilation,
        );
      }
      return const CombatLossProfile(
        attackerLossFraction: _strongAttackerLossFraction,
        defenderLossFraction: _strongDefenderLossFraction,
        bluntsAttackerVictory: false,
        mutualEliminationOutcome:
            CombatMutualEliminationOutcome.attackerVictory,
      );
    case CombatStrengthRatioBand.strongTarget:
      return const CombatLossProfile(
        attackerLossFraction: _strongDefenderAttackerLossFraction,
        defenderLossFraction: _strongDefenderDefenderLossFraction,
        bluntsAttackerVictory: false,
        mutualEliminationOutcome:
            CombatMutualEliminationOutcome.defenderVictory,
      );
    case CombatStrengthRatioBand.even:
      if (ratio >= _attackerEdgeRatioThreshold) {
        return const CombatLossProfile(
          attackerLossFraction: _attackerEdgeAttackerLossFraction,
          defenderLossFraction: _attackerEdgeDefenderLossFraction,
          bluntsAttackerVictory: false,
          mutualEliminationOutcome:
              CombatMutualEliminationOutcome.attackerVictory,
        );
      }
      return const CombatLossProfile(
        attackerLossFraction: _defaultAttackerLossFraction,
        defenderLossFraction: _defaultDefenderLossFraction,
        bluntsAttackerVictory: false,
        mutualEliminationOutcome:
            CombatMutualEliminationOutcome.mutualAnnihilation,
      );
  }
}

int combatCasualtyCount({
  required int unitCount,
  required double lossFraction,
}) {
  return (unitCount * lossFraction).ceil().clamp(_minCasualtySlots, unitCount);
}
