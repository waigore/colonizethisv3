part of 'combat_resolver.dart';

/// Per-engagement outcome state transition for [resolveBattleContext].
///
/// Applies the [EngagementResult] of a single attacker-vs-defender engagement
/// to the running battle state (defender faction/owner, surviving attacker,
/// defender general + medals, defender unit ids) and returns the updated
/// snapshot consumed by the next loop iteration.
/// SPEC/program/combat-resolution.md.
({
  String defenderFactionId,
  String provinceOwnerId,
  String? survivingAttackerFactionId,
  String? currentDefenderGeneralId,
  int currentDefenderMedals,
  List<String> defenderUnitIds,
})
_applyEngagementOutcomeState({
  required EngagementResult outcomeResult,
  required _AttackingSideInBattle attacker,
  required String? currentDefenderGeneralId,
  required int currentDefenderMedals,
  required String provinceOwnerId,
  required String defenderFactionId,
  required String? survivingAttackerFactionId,
  required List<String> defenderUnitIds,
  required int attackerIndex,
  required List<_AttackingSideInBattle> attackerSidesWithMedals,
  required int initialDefenderCount,
  required int defenderEffectiveLevel,
  required Map<String, General> generalsById,
  required Map<String, Unit> unitsById,
  required BattleContext ctx,
}) {
  switch (outcomeResult) {
    case EngagementResult.attackerVictory:
      _incrementGeneralMedals(
        generalsById: generalsById,
        generalId: attacker.assignedGeneralId,
      );
      final medalsAfterWin =
          attacker.side.generalMedals +
          (attacker.assignedGeneralId != null
              ? kGeneralMedalsGainedOnBattleWin
              : 0);
      return (
        defenderFactionId: attacker.side.factionId,
        provinceOwnerId: attacker.side.factionId,
        survivingAttackerFactionId: attacker.side.factionId,
        currentDefenderGeneralId: attacker.assignedGeneralId,
        currentDefenderMedals: medalsAfterWin > kGeneralMedalsMax
            ? kGeneralMedalsMax
            : medalsAfterWin,
        defenderUnitIds: defenderUnitIds,
      );
    case EngagementResult.defenderVictory:
      _incrementGeneralMedals(
        generalsById: generalsById,
        generalId: currentDefenderGeneralId,
      );
      var updatedMedals = currentDefenderMedals;
      if (currentDefenderGeneralId != null) {
        final updatedGeneral = generalsById[currentDefenderGeneralId];
        if (updatedGeneral != null) {
          updatedMedals = updatedGeneral.medals;
        }
      }
      return (
        defenderFactionId: defenderFactionId,
        provinceOwnerId: provinceOwnerId,
        survivingAttackerFactionId: null,
        currentDefenderGeneralId: currentDefenderGeneralId,
        currentDefenderMedals: updatedMedals,
        defenderUnitIds: defenderUnitIds,
      );
    case EngagementResult.stalemate:
      return (
        defenderFactionId: defenderFactionId,
        provinceOwnerId: provinceOwnerId,
        survivingAttackerFactionId: survivingAttackerFactionId,
        currentDefenderGeneralId: currentDefenderGeneralId,
        currentDefenderMedals: currentDefenderMedals,
        defenderUnitIds: defenderUnitIds,
      );
    case EngagementResult.mutualAnnihilation:
      final updatedDefenderIds = _recoverDefenderGarrisonIfNeeded(
        attackerIndex: attackerIndex,
        attackerSidesWithMedals: attackerSidesWithMedals,
        initialDefenderCount: initialDefenderCount,
        defenderEffectiveLevel: defenderEffectiveLevel,
        defenderUnitIds: defenderUnitIds,
        provinceOwnerId: provinceOwnerId,
        unitsById: unitsById,
        provinceId: ctx.provinceId,
      );
      return (
        defenderFactionId: provinceOwnerId,
        provinceOwnerId: provinceOwnerId,
        survivingAttackerFactionId: null,
        currentDefenderGeneralId: currentDefenderGeneralId,
        currentDefenderMedals: currentDefenderMedals,
        defenderUnitIds: updatedDefenderIds,
      );
  }
}

List<String> _recoverDefenderGarrisonIfNeeded({
  required int attackerIndex,
  required List<_AttackingSideInBattle> attackerSidesWithMedals,
  required int initialDefenderCount,
  required int defenderEffectiveLevel,
  required List<String> defenderUnitIds,
  required String provinceOwnerId,
  required Map<String, Unit> unitsById,
  required String provinceId,
}) {
  final remainingAttackers = attackerSidesWithMedals.skip(attackerIndex + 1);
  if (remainingAttackers.isEmpty) {
    return defenderUnitIds;
  }
  final recoverCount = (initialDefenderCount * kGarrisonRecoveryFraction)
      .ceil()
      .clamp(1, initialDefenderCount);
  final recoveryType = garrisonRecoveryRegimentTypeForEra(
    defenderEffectiveLevel,
  );
  final updatedDefenderIds = List<String>.from(defenderUnitIds);
  for (
    var i = 0;
    i < recoverCount && updatedDefenderIds.length < recoverCount;
    i++
  ) {
    final id = '${kRecoveryUnitPrefix}${provinceId}_$i';
    updatedDefenderIds.add(id);
    unitsById[id] = Unit(
      id: id,
      type: recoveryType,
      ownerId: provinceOwnerId,
      locationProvinceId: provinceId,
      medals: 0,
    );
  }
  return updatedDefenderIds;
}
