part of 'combat_resolver.dart';

String? _provinceOwnerIdAtBattleStart(Game game, BattleContext ctx) {
  final row = resolveProvinceRowForOwnershipTransfer(
    game.worldState,
    ctx.provinceId,
  );
  return row?.province.ownerId;
}

Game _buildResolvedBattleGame({
  required Game game,
  required BattleContext ctx,
  required ({RegionData region, bool provinceChangedOwner}) post,
  required String? survivingAttackerFactionId,
  required Map<String, General> generalsById,
  required CombatPhaseGeneralLedger ledger,
  required String provinceOwnerAtBattleStart,
}) {
  var newWorldState = game.worldState.updateRegionById(
    ctx.regionId,
    (_) => post.region,
  );

  recordAttackCommandersForResolvedBattle(ctx, null, ledger);

  var result = game.copyWith(
    worldState: newWorldState,
    generals: game.generals
        .map((g) => generalsById[g.id] ?? g)
        .toList(growable: false),
  );
  if (post.provinceChangedOwner && survivingAttackerFactionId != null) {
    result = applyCanonicalSingleProvinceOwnershipTransfer(
      result,
      targetProvinceId: ctx.provinceId,
      oldOwnerId: provinceOwnerAtBattleStart,
      newOwnerId: survivingAttackerFactionId,
    );
  } else {
    result = result.copyWith(
      worldState: reconcileArmiesAfterUnitsChanged(result.worldState, result),
    );
  }
  return result;
}

/// Builds post-battle region state: applies casualties, garrison recovery,
/// province ownership change, and civilian cleanup when province changes hands.
({RegionData region, bool provinceChangedOwner}) _buildPostBattleRegion({
  required RegionData region,
  required BattleContext ctx,
  required Set<String> allCasualties,
  required Map<String, Unit> unitsById,
  required String defenderFactionId,
  required String? survivingAttackerFactionId,
  required List<String> defenderUnitIds,
}) {
  final survivingUnits = region.units
      .where((u) => !allCasualties.contains(u.id))
      .toList();

  var updatedProvinces = region.provinces;
  var provinceChangedOwner = false;
  if (defenderUnitIds.isEmpty && survivingAttackerFactionId != null) {
    provinceChangedOwner = provinceListContainsProvinceId(
      updatedProvinces,
      ctx.provinceId,
    );
  }

  final recoveredUnits = unitsById.values
      .where(
        (u) =>
            u.id.startsWith(kRecoveryUnitPrefix) &&
            !allCasualties.contains(u.id),
      )
      .toList();
  var finalUnits = [...survivingUnits, ...recoveredUnits];

  final newRegion = RegionData(provinces: updatedProvinces, units: finalUnits);
  return (region: newRegion, provinceChangedOwner: provinceChangedOwner);
}
