import 'diplomatic_sub_validator.dart';

/// Type-specific validator for [DiplomaticOrderType.alliance] orders.
/// SPEC/program/orders.md § Diplomatic orders / alliance.
DiplomaticSubValidator allianceSubValidator(
  DiplomaticSubValidatorContext ctx,
) => relationDiplomaticSubValidator(ctx, ({
  required order,
  required relation,
  required treasury,
}) {
  final targetId = order.targetFactionId;
  final notGpRejection = rejectIfNotGreatPowerTarget(
    ctx: ctx,
    targetId: targetId,
    rejectionReason: 'Alliance target must be a Great Power',
    treasury: treasury,
  );
  if (notGpRejection != null) return notGpRejection;
  final atWarRejection = rejectDiplomaticSubIfAtWar(
    relation: relation,
    reason: 'Cannot form alliance while at war with that faction',
    treasury: treasury,
  );
  if (atWarRejection != null) return atWarRejection;
  return acceptDiplomaticSub(treasury);
});
