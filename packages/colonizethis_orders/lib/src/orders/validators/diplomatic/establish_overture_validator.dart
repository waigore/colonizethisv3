import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import '../../order_validation_result.dart';
import 'diplomatic_sub_validator.dart';
import 'join_empire_validator.dart';

/// Type-specific validator for [DiplomaticOrderType.establishOverture] orders.
/// Owns the per-stage rules (`tradeConsulate`, `embassy`, `nap`) and delegates
/// [OvertureStage.joinEmpire] to [validateJoinEmpireOverture].
/// SPEC/program/orders.md § Diplomatic orders / overtures.
DiplomaticSubValidator establishOvertureSubValidator(
  DiplomaticSubValidatorContext ctx,
) => relationDiplomaticSubValidator(ctx, ({
  required order,
  required relation,
  required treasury,
}) {
  final stage = order.overtureStage;
  if (stage == null || stage == OvertureStage.none) {
    return rejectDiplomaticSub(
      'Overture stage is required for establishOverture',
      treasury,
    );
  }
  final targetId = order.targetFactionId;
  if (!_isMinorTribeOrGreatPower(ctx, targetId)) {
    return rejectDiplomaticSub(
      'Overtures are only valid toward Minor Nations, Tribes, or Great Powers',
      treasury,
    );
  }
  if (relation?.atWar == true) {
    return rejectDiplomaticSub(
      'Cannot establish overture while at war with that faction',
      treasury,
    );
  }

  final currentStage =
      getOverture(ctx.game, ctx.playerId, targetId)?.stage ??
      OvertureStage.none;

  return switch (stage) {
    OvertureStage.tradeConsulate => _validateTradeConsulate(
      ctx,
      targetId,
      currentStage,
      treasury,
    ),
    OvertureStage.embassy => _validateEmbassy(
      ctx,
      targetId,
      currentStage,
      treasury,
    ),
    OvertureStage.nap => _validateNap(ctx, targetId, currentStage, treasury),
    OvertureStage.joinEmpire => validateJoinEmpireOverture(
      ctx: ctx,
      targetId: targetId,
      rel: relation,
      currentStage: currentStage,
      treasury: treasury,
    ),
    OvertureStage.none => rejectDiplomaticSub(
      'Overture stage is required for establishOverture',
      treasury,
    ),
  };
});

bool _isMinorTribeOrGreatPower(
  DiplomaticSubValidatorContext ctx,
  String targetId,
) =>
    isMinorOrTribe(
      ctx.game,
      targetId,
      factionMembership: ctx.factionMembership,
    ) ||
    isGreatPower(ctx.game, targetId, factionMembership: ctx.factionMembership);

({OrderValidationResult result, int treasury}) _validateTradeConsulate(
  DiplomaticSubValidatorContext ctx,
  String targetId,
  OvertureStage currentStage,
  int treasury,
) {
  if (currentStage != OvertureStage.none) {
    return rejectDiplomaticSub(
      'Trade Consulate requires no existing overture',
      treasury,
    );
  }
  if (_minorTribeStageRequiresDiplomaticExpertise(
        ctx,
        targetId,
        OvertureStage.tradeConsulate,
      ) &&
      !ctx.hasDiplomaticExpertise) {
    return rejectDiplomaticSub(
      'Diplomatic Expertise tech required for overtures with Minor Nations and Tribes',
      treasury,
    );
  }
  return validateTreasuryDebit(
    treasury: treasury,
    cost: overtureConsulateCost,
    reason:
        'Insufficient treasury for Trade Consulate (need $overtureConsulateCost)',
  );
}

({OrderValidationResult result, int treasury}) _validateEmbassy(
  DiplomaticSubValidatorContext ctx,
  String targetId,
  OvertureStage currentStage,
  int treasury,
) {
  final stageRejection = rejectIfOvertureStageMismatch(
    currentStage: currentStage,
    requiredStage: OvertureStage.tradeConsulate,
    reason: 'Embassy requires existing Trade Consulate with that faction',
    treasury: treasury,
  );
  if (stageRejection != null) return stageRejection;
  if (_minorTribeStageRequiresDiplomaticExpertise(
        ctx,
        targetId,
        OvertureStage.embassy,
      ) &&
      !ctx.hasDiplomaticExpertise) {
    return rejectDiplomaticSub(
      'Diplomatic Expertise tech required for overtures with Minor Nations and Tribes',
      treasury,
    );
  }
  return validateTreasuryDebit(
    treasury: treasury,
    cost: overtureEmbassyCost,
    reason: 'Insufficient treasury for Embassy (need $overtureEmbassyCost)',
  );
}

({OrderValidationResult result, int treasury}) _validateNap(
  DiplomaticSubValidatorContext ctx,
  String targetId,
  OvertureStage currentStage,
  int treasury,
) {
  final stageRejection = rejectIfOvertureStageMismatch(
    currentStage: currentStage,
    requiredStage: OvertureStage.embassy,
    reason: 'Non-Aggression Pact requires existing Embassy with that faction',
    treasury: treasury,
  );
  if (stageRejection != null) return stageRejection;
  if (_minorTribeStageRequiresDiplomaticExpertise(
        ctx,
        targetId,
        OvertureStage.nap,
      ) &&
      !ctx.hasDiplomaticExpertise) {
    return rejectDiplomaticSub(
      'Diplomatic Expertise tech required for overtures with Minor Nations and Tribes',
      treasury,
    );
  }
  return acceptDiplomaticSub(treasury);
}

bool _minorTribeStageRequiresDiplomaticExpertise(
  DiplomaticSubValidatorContext ctx,
  String targetId,
  OvertureStage stage,
) {
  if (!isMinorOrTribe(
    ctx.game,
    targetId,
    factionMembership: ctx.factionMembership,
  )) {
    return false;
  }
  return stage == OvertureStage.tradeConsulate ||
      stage == OvertureStage.embassy ||
      stage == OvertureStage.nap;
}
