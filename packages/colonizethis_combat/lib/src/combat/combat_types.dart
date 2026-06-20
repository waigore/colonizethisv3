/// Result of one engagement. SPEC/game/combat.md.
enum EngagementResult {
  attackerVictory,
  defenderVictory,
  stalemate,
  mutualAnnihilation,
}

/// Result of resolving one engagement. SPEC/program/combat-resolution.md.
class EngagementOutcome {
  const EngagementOutcome({
    required this.result,
    required this.attackerCasualties,
    required this.defenderCasualties,
    required this.attackerStrength,
    required this.defenderStrength,
  });

  final EngagementResult result;
  final List<String> attackerCasualties;
  final List<String> defenderCasualties;
  final double attackerStrength;
  final double defenderStrength;
}
