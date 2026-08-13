import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'diplomacy_relation_constants.dart';
import 'diplomacy_relation_lookup.dart';
import 'diplomacy_shared_helpers.dart';
import 'overture_stage_helpers.dart';

/// Validated, applicable establish-overture order: the resolved stage, target
/// classification, and stage cost. Null when the order is not applicable (no
/// state change), letting [processEstablishOvertureOrderIfApplicable] skip it.
typedef ValidatedOverture = ({
  OvertureStage stage,
  bool targetIsMinorOrTribe,
  bool targetIsGp,
  int cost,
});

int? overtureCostForStage(OvertureStage stage) {
  if (stage == OvertureStage.tradeConsulate) return overtureConsulateCost;
  if (stage == OvertureStage.embassy) return overtureEmbassyCost;
  if (stage == OvertureStage.nap) return 0;
  return null;
}

/// Validates an establish-overture [order] against stage progression, target
/// membership, war state, tech prerequisites, and affordability.
///
/// Returns null when the order should be skipped without changing state;
/// otherwise the resolved stage/target/cost for acceptance resolution.
ValidatedOverture? validateEstablishOvertureOrder({
  required Game state,
  required Player player,
  required String gpId,
  required DiplomaticOrder order,
  required List<OvertureState> overtures,
  required DiplomacyFactionMembership factionMembership,
}) {
  if (order.type != DiplomaticOrderType.establishOverture) return null;
  final stage = order.overtureStage;
  if (stage == null || stage == OvertureStage.none) return null;

  final targetId = order.targetFactionId;
  final targetIsMinorOrTribe = factionMembership.isMinorOrTribe(targetId);
  final targetIsGp = factionMembership.isGreatPower(targetId);
  if (!targetIsMinorOrTribe && !targetIsGp) return null;

  final rel = getRelation(state, gpId, targetId);
  if (rel != null && rel.atWar) return null;

  final existing = findOvertureForGpTarget(overtures, gpId, targetId);
  final prevStage = stage.previous;
  final atPrevStage =
      (existing == null && prevStage == OvertureStage.none) ||
      (existing != null && existing.stage == prevStage);
  if (!atPrevStage) return null;

  if (targetIsMinorOrTribe &&
      (stage == OvertureStage.tradeConsulate ||
          stage == OvertureStage.embassy ||
          stage == OvertureStage.nap) &&
      player.techUnlocked?[kTechIdDiplomaticExpertise] != true) {
    return null;
  }

  final cost = overtureCostForStage(stage);
  if (cost == null) return null;
  if (player.treasury < cost && cost > 0) return null;

  return (
    stage: stage,
    targetIsMinorOrTribe: targetIsMinorOrTribe,
    targetIsGp: targetIsGp,
    cost: cost,
  );
}
