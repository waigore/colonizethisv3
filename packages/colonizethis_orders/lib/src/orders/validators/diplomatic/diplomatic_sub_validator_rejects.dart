import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import '../../order_validation_result.dart';
import 'diplomatic_sub_validator.dart';

/// Rejects when [targetId] is not a Great Power; otherwise `null`.
({OrderValidationResult result, int treasury})? rejectIfNotGreatPowerTarget({
  required DiplomaticSubValidatorContext ctx,
  required String targetId,
  required String rejectionReason,
  required int treasury,
}) {
  if (!isGreatPower(
    ctx.game,
    targetId,
    factionMembership: ctx.factionMembership,
  )) {
    return rejectDiplomaticSub(rejectionReason, treasury);
  }
  return null;
}

/// Returns a rejection when a post-break bilateral cooldown blocks overture-class
/// orders toward Great Power [targetId]; otherwise `null`.
({OrderValidationResult result, int treasury})?
rejectIfAllianceBreakCooldownActive({
  required DiplomaticSubValidatorContext ctx,
  required String targetId,
  required int treasury,
}) {
  if (!isGreatPower(
    ctx.game,
    targetId,
    factionMembership: ctx.factionMembership,
  )) {
    return null;
  }
  if (!isAllianceBreakCooldownActive(ctx.game, ctx.playerId, targetId)) {
    return null;
  }
  return rejectDiplomaticSub(kAllianceBreakCooldownRejectionReason, treasury);
}

/// Returns a rejection when [relation] is at war; otherwise `null`.
({OrderValidationResult result, int treasury})? rejectDiplomaticSubIfAtWar({
  required DiplomacyRelation? relation,
  required String reason,
  required int treasury,
}) {
  if (relation?.atWar ?? false) {
    return rejectDiplomaticSub(reason, treasury);
  }
  return null;
}

/// Returns a rejection when [relation] is not at war; otherwise `null`.
({OrderValidationResult result, int treasury})? rejectDiplomaticSubIfAtPeace({
  required DiplomacyRelation? relation,
  required String reason,
  required int treasury,
}) {
  if (!(relation?.atWar ?? false)) {
    return rejectDiplomaticSub(reason, treasury);
  }
  return null;
}

/// Validates positive [amount] on [step] increments for economic diplomatic orders.
({OrderValidationResult result, int treasury})? rejectIfInvalidAmountMultiple({
  required int amount,
  required int step,
  required String label,
  required int treasury,
}) {
  if (amount <= 0) {
    return rejectDiplomaticSub('$label amount must be positive', treasury);
  }
  if (amount < step) {
    return rejectDiplomaticSub(
      '$label amount must be at least £$step',
      treasury,
    );
  }
  if (amount % step != 0) {
    return rejectDiplomaticSub(
      '$label amount must be a multiple of £$step',
      treasury,
    );
  }
  return null;
}

/// Rejects when [treasury] is below [cost]; otherwise debits and accepts.
({OrderValidationResult result, int treasury}) validateTreasuryDebit({
  required int treasury,
  required int cost,
  required String reason,
}) {
  if (treasury < cost) {
    return rejectDiplomaticSub(reason, treasury);
  }
  return acceptDiplomaticSub(treasury - cost);
}

/// Rejects when [currentStage] does not equal [requiredStage].
({OrderValidationResult result, int treasury})? rejectIfOvertureStageMismatch({
  required OvertureStage currentStage,
  required OvertureStage requiredStage,
  required String reason,
  required int treasury,
}) {
  if (currentStage != requiredStage) {
    return rejectDiplomaticSub(reason, treasury);
  }
  return null;
}

/// Shared amount-step + overture-gate + treasury-debit path for grant aid and
/// set subsidy sub-validators.
({OrderValidationResult result, int treasury}) economicDiplomaticSubValidation({
  required DiplomaticSubValidatorContext ctx,
  required DiplomaticOrder order,
  required int treasury,
  required int amountStep,
  required bool Function(OvertureState? overture) overtureGate,
  required String overtureRejectionReason,
  required String insufficientTreasuryReason,
  required String label,
}) {
  final amount = order.amount ?? 0;
  final amountRejection = rejectIfInvalidAmountMultiple(
    amount: amount,
    step: amountStep,
    label: label,
    treasury: treasury,
  );
  if (amountRejection != null) return amountRejection;

  final overture = getOverture(ctx.game, ctx.playerId, order.targetFactionId);
  final cooldownRejection = rejectIfAllianceBreakCooldownActive(
    ctx: ctx,
    targetId: order.targetFactionId,
    treasury: treasury,
  );
  if (cooldownRejection != null) return cooldownRejection;
  if (!overtureGate(overture)) {
    return rejectDiplomaticSub(overtureRejectionReason, treasury);
  }

  return validateTreasuryDebit(
    treasury: treasury,
    cost: amount,
    reason: insufficientTreasuryReason.replaceAll('{amount}', '$amount'),
  );
}
