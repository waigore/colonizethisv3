const double _strongAttackerRatioThreshold = 1.5;
const double _bluntAttackerVictoryUpperRatio = 4.0;
const double _strongDefenderRatioThreshold = 0.67;
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
  if (ratio >= _strongAttackerRatioThreshold &&
      attackerLowMorale &&
      ratio < _bluntAttackerVictoryUpperRatio) {
    return const CombatLossProfile(
      attackerLossFraction: _bluntAttackerLossFraction,
      defenderLossFraction: _bluntDefenderLossFraction,
      bluntsAttackerVictory: true,
      mutualEliminationOutcome:
          CombatMutualEliminationOutcome.mutualAnnihilation,
    );
  }
  if (ratio >= _strongAttackerRatioThreshold) {
    return const CombatLossProfile(
      attackerLossFraction: _strongAttackerLossFraction,
      defenderLossFraction: _strongDefenderLossFraction,
      bluntsAttackerVictory: false,
      mutualEliminationOutcome: CombatMutualEliminationOutcome.attackerVictory,
    );
  }
  if (ratio <= _strongDefenderRatioThreshold) {
    return const CombatLossProfile(
      attackerLossFraction: _strongDefenderAttackerLossFraction,
      defenderLossFraction: _strongDefenderDefenderLossFraction,
      bluntsAttackerVictory: false,
      mutualEliminationOutcome: CombatMutualEliminationOutcome.defenderVictory,
    );
  }
  if (ratio >= _attackerEdgeRatioThreshold) {
    return const CombatLossProfile(
      attackerLossFraction: _attackerEdgeAttackerLossFraction,
      defenderLossFraction: _attackerEdgeDefenderLossFraction,
      bluntsAttackerVictory: false,
      mutualEliminationOutcome: CombatMutualEliminationOutcome.attackerVictory,
    );
  }
  return const CombatLossProfile(
    attackerLossFraction: _defaultAttackerLossFraction,
    defenderLossFraction: _defaultDefenderLossFraction,
    bluntsAttackerVictory: false,
    mutualEliminationOutcome: CombatMutualEliminationOutcome.mutualAnnihilation,
  );
}

int combatCasualtyCount({
  required int unitCount,
  required double lossFraction,
}) {
  return (unitCount * lossFraction).ceil().clamp(_minCasualtySlots, unitCount);
}
