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

/// Player-facing rejection when an Explorer tries `explore`/`prospect` inside a
/// Minor/Tribe province without holding a Consulate (or higher) with that
/// faction (Refs #3753 R4/S4a; SPEC/game/civilian-units.md § Work Order Summary).
const String kReasonConsulateRequiredForExplore =
    'Establish a consulate before exploring or prospecting';

/// Refs #3753 R4/R4b: `true` when an Explorer `explore`/`prospect` work order in
/// a province owned by [provinceOwnerId] would be blocked by the Consulate gate,
/// i.e. the owner is a Minor/Tribe and [playerId] holds no Consulate (or higher)
/// overture with it.
///
/// Shared by the order-engine validator (submission/resolution gate) and the
/// province-overlay UI (R4b disabled-action + rejection tooltip), so both apply
/// one identical condition. Own/unowned provinces and GP-owned provinces are
/// never gated (the auto-embassy satisfies any GP case).
bool explorerConsulateGateBlocksMinorTribeProvince({
  required Game game,
  required String playerId,
  required String? provinceOwnerId,
  DiplomacyFactionMembership? factionMembership,
}) {
  if (provinceOwnerId == null || provinceOwnerId == playerId) return false;
  if (!isMinorOrTribe(
    game,
    provinceOwnerId,
    factionMembership: factionMembership,
  )) {
    return false;
  }
  final overture = getOverture(game, playerId, provinceOwnerId);
  return overture == null || !overture.hasConsulate;
}

/// Refs #3753 R4/S4a: an Explorer `explore`/`prospect` work order inside a
/// province owned by a Minor or Tribe requires the issuing GP to hold at least
/// a Consulate (an Embassy supersedes Consulate) with that Minor/Tribe.
///
/// Returns a rejection when the gate is not satisfied, otherwise `null`
/// (own/unowned provinces and GP-owned provinces are not gated — the auto-
/// embassy already satisfies any GP case, and Explorer work in GP provinces is
/// already blocked elsewhere). Spy work is never affected because no Spy work
/// target is a Minor/Tribe province in current product (R4.4 — inert gate).
OrderValidationResult? rejectExplorerWithoutConsulateInMinorTribeProvince({
  required Game game,
  required String playerId,
  required String unitType,
  required String workTarget,
  required String? provinceOwnerId,
  DiplomacyFactionMembership? factionMembership,
}) {
  if (!isExplorerUnit(unitType)) return null;
  if (workTarget != kWorkTargetExplore && workTarget != kWorkTargetProspect) {
    return null;
  }
  if (!explorerConsulateGateBlocksMinorTribeProvince(
    game: game,
    playerId: playerId,
    provinceOwnerId: provinceOwnerId,
    factionMembership: factionMembership,
  )) {
    return null;
  }
  return OrderValidationResult.rejected(kReasonConsulateRequiredForExplore);
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
