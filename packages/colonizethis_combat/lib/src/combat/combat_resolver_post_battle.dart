import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'battle_general_assignment.dart';
import 'combat_constants.dart';
import 'combat_survivor_units.dart';
import 'conflict_detection.dart';

String? provinceOwnerIdAtBattleStart(Game game, BattleContext ctx) {
  final row = resolveProvinceRowForOwnershipTransfer(
    game.worldState,
    ctx.provinceId,
  );
  return row?.province.ownerId;
}

Game buildResolvedBattleGame({
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
({RegionData region, bool provinceChangedOwner}) buildPostBattleRegion({
  required RegionData region,
  required BattleContext ctx,
  required Set<String> allCasualties,
  required Map<String, Unit> unitsById,
  required String defenderFactionId,
  required String? survivingAttackerFactionId,
  required List<String> defenderUnitIds,
}) {
  final survivingUnits = unitsExcludingCasualtyIds(
    region.units,
    allCasualties,
  ).toList();

  var updatedProvinces = region.provinces;
  var provinceChangedOwner = false;
  if (defenderUnitIds.isEmpty && survivingAttackerFactionId != null) {
    provinceChangedOwner = provinceListContainsProvinceId(
      updatedProvinces,
      ctx.provinceId,
    );
  }

  final recoveredUnits = unitsExcludingCasualtyIds(
    unitsById.values.where((u) => u.id.startsWith(kRecoveryUnitPrefix)),
    allCasualties,
  ).toList();
  var finalUnits = [...survivingUnits, ...recoveredUnits];

  final newRegion = RegionData(provinces: updatedProvinces, units: finalUnits);
  return (region: newRegion, provinceChangedOwner: provinceChangedOwner);
}
