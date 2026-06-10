import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import '../../order_validation_result.dart';
import 'diplomatic_sub_validator.dart';

/// [OvertureStage.joinEmpire] rules for [DiplomaticOrderType.establishOverture]
/// orders (Refs #2391 AC10, SPEC/program/orders.md § Diplomatic orders).
///
/// Mirrors the factory shape of the other diplomatic sub-validators
/// (Refs #2560 § Diplomatic sub-validators): a free function that closes over
/// [DiplomaticSubValidatorContext] instead of a bespoke class.
({OrderValidationResult result, int treasury}) validateJoinEmpireOverture({
  required DiplomaticSubValidatorContext ctx,
  required String targetId,
  required DiplomacyRelation? rel,
  required OvertureStage currentStage,
  required int treasury,
}) {
  if (currentStage != OvertureStage.nap) {
    return rejectDiplomaticSub(
      'Join Empire requires existing Non-Aggression Pact with that faction',
      treasury,
    );
  }
  final score = rel?.score ?? relationScoreNeutral;
  if (score < relationScoreMinFriendly) {
    return rejectDiplomaticSub(
      'Join Empire requires at least Friendly relations (score >= $relationScoreMinFriendly)',
      treasury,
    );
  }
  if (isGreatPower(
    ctx.game,
    targetId,
    factionMembership: ctx.factionMembership,
  )) {
    return _validateJoinEmpireTowardGreatPower(ctx, targetId, treasury);
  }
  if (!isMinorOrTribe(
    ctx.game,
    targetId,
    factionMembership: ctx.factionMembership,
  )) {
    return rejectDiplomaticSub(
      'Join Empire target must be a Minor Nation, Tribe, or Great Power',
      treasury,
    );
  }
  final cost = joinEmpireCostForMinorOrTribe(ctx.game, targetId);
  if (treasury < cost) {
    return rejectDiplomaticSub(
      'Join Empire requires £$cost (scales with target size); treasury is $treasury',
      treasury,
    );
  }
  return acceptDiplomaticSub(treasury);
}

({OrderValidationResult result, int treasury})
_validateJoinEmpireTowardGreatPower(
  DiplomaticSubValidatorContext ctx,
  String targetId,
  int treasury,
) {
  final submitter = ctx.game.playerById(ctx.playerId);
  if (submitter?.techUnlocked?[kTechIdEmpireBuilding] != true) {
    return rejectDiplomaticSub(
      'Empire Building tech required for Join Empire toward a Great Power',
      treasury,
    );
  }
  if (!isGreatPowerNearlyDefeatedForJoinEmpire(
    ctx.game,
    targetId,
    factionMembership: ctx.factionMembership,
  )) {
    return rejectDiplomaticSub(
      'Join Empire toward Great Power requires target to be nearly defeated (at most 3 provinces and original capital not held by target)',
      treasury,
    );
  }
  return acceptDiplomaticSub(treasury);
}
