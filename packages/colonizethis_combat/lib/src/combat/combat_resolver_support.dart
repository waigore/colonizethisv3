part of 'combat_resolver.dart';

void _sortAttackersByInitiative(
  List<_AttackingSideInBattle> attackers,
  Map<String, Unit> unitsById,
  Random rng,
) {
  final tieBreakRoll = rng.nextInt(kInitiativeTieBreakRngUpperExclusive);
  int tieRank(String factionId) => Object.hash(factionId, tieBreakRoll);
  final initiativeByAttacker = <_AttackingSideInBattle, double>{};
  for (final attacker in attackers) {
    final cavalryShare = attacker.side.unitIds.isEmpty
        ? kZeroCavalryShareWhenNoUnits
        : cavalryFraction(attacker.side.unitIds, unitsById);
    initiativeByAttacker[attacker] =
        cavalryShare * initiativeCavalryShareWeight +
        attacker.side.generalMedals * initiativeGeneralMedalWeight;
  }

  attackers.sort((a, b) {
    final initA = initiativeByAttacker[a]!;
    final initB = initiativeByAttacker[b]!;
    final cmp = initB.compareTo(initA);
    if (cmp != 0) return cmp;
    return tieRank(a.side.factionId).compareTo(tieRank(b.side.factionId));
  });
}

class _AttackingSideInBattle {
  const _AttackingSideInBattle({
    required this.side,
    required this.assignedGeneralId,
  });

  final AttackingSide side;
  final String? assignedGeneralId;
}

void _incrementGeneralMedals({
  required Map<String, General> generalsById,
  required String? generalId,
}) {
  if (generalId == null) return;
  final current = generalsById[generalId];
  if (current == null) return;
  generalsById[generalId] = current.copyWith(
    medals: (current.medals + kGeneralMedalsGainedOnBattleWin).clamp(
      kGeneralMedalsMin,
      kGeneralMedalsMax,
    ),
  );
}

/// Max regiments that can participate per side in one engagement.
/// SPEC/game/military-generals.md: base 10; Nationalism tech → 12; +1 per general medal.
int _deploymentLimitForFaction(Game game, String factionId, int generalMedals) {
  final baseLimit =
      game.playerById(factionId)?.techUnlocked?[kTechIdNationalism] == true
      ? deploymentLimitWithNationalism
      : deploymentLimitBase;
  return baseLimit + generalMedals;
}

/// Morale aura from general medals. SPEC/game/military-generals.md:
/// 5% per general medal, up to 20% (at 4 medals).
double moraleMultiplierForGeneralMedals(int generalMedals) {
  final capped = generalMedals.clamp(kGeneralMedalsMin, kGeneralMedalsMax);
  return kMoraleMultiplierBaseFromGenerals +
      (capped * kMoraleMultiplierPerGeneralMedal);
}
