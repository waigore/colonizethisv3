import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'order_validation_result.dart';
import 'order_work_constants.dart';

/// Returns true when [unitType] may perform civilian work in a Minor/Tribe
/// province owned by [provinceOwnerId] (embassy + Diplomatic Expertise).
/// SPEC/game/tech-tree-diplomacy-civilian.md.
bool civilianEmbassyWorkAllowedInMinorTribeProvince({
  required Game game,
  required String playerId,
  required Player player,
  required String unitType,
  required String? provinceOwnerId,
  DiplomacyFactionMembership? factionMembership,
}) {
  if (provinceOwnerId == null || provinceOwnerId == playerId) {
    return false;
  }
  if (unitType != kUnitTypeBuilder &&
      unitType != kUnitTypeEngineer &&
      unitType != kUnitTypeMerchant) {
    return false;
  }
  if (!isMinorOrTribe(
    game,
    provinceOwnerId,
    factionMembership: factionMembership,
  )) {
    return false;
  }
  final rel = getRelation(game, playerId, provinceOwnerId);
  if (rel?.atWar == true) return false;
  final overture = getOverture(game, playerId, provinceOwnerId);
  if (overture == null || !overture.hasEmbassy) return false;
  return player.techUnlocked?[kTechIdDiplomaticExpertise] == true;
}

/// Rejects when [resourceId] is mineral and [tileKey] is not prospected for
/// [playerId]; returns `null` when the check passes or does not apply.
OrderValidationResult? rejectIfMineralTileNotProspected({
  required Game game,
  required String playerId,
  required String tileKey,
  required String? resourceId,
}) {
  if (resourceId == null || resourceId.isEmpty) return null;
  if (!kMineralResourceIds.contains(resourceId)) return null;
  final prospected = game.worldState.prospectedTilesForPlayer(playerId);
  if (!prospected.contains(tileKey)) {
    return OrderValidationResult.rejected(
      'Mineral tile must be prospected first',
    );
  }
  return null;
}
