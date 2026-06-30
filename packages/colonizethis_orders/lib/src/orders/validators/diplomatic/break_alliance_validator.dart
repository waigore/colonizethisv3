import 'diplomatic_sub_validator.dart';

/// Type-specific validator for [DiplomaticOrderType.breakAlliance] orders.
///
/// Valid only when the target is a Great Power with which the issuer currently
/// holds a **formal alliance**. Because entering war clears the pair's
/// `formalAlliance` (war invariant — a treaty cannot coexist with war), an
/// at-war pair has no alliance to break, so this validator rejects it via the
/// `formalAlliance` check. No treasury cost. SPEC/program/orders.md § Diplomatic
/// orders / break alliance; SPEC/game/diplomacy.md § Alliances.
DiplomaticSubValidator breakAllianceSubValidator(
  DiplomaticSubValidatorContext ctx,
) => relationDiplomaticSubValidator(ctx, ({
  required order,
  required relation,
  required treasury,
}) {
  final notGpRejection = rejectIfNotGreatPowerTarget(
    ctx: ctx,
    targetId: order.targetFactionId,
    rejectionReason: 'Break Alliance target must be a Great Power',
    treasury: treasury,
  );
  if (notGpRejection != null) return notGpRejection;
  if (!(relation?.formalAlliance ?? false)) {
    return rejectDiplomaticSub(
      'No formal alliance to break with that faction',
      treasury,
    );
  }
  return acceptDiplomaticSub(treasury);
});
