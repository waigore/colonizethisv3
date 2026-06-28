import 'diplomatic_sub_validator.dart';

/// Type-specific validator for [DiplomaticOrderType.breakAlliance] orders.
///
/// Valid only when the target is a Great Power with which the issuer currently
/// holds a **formal alliance**. A voluntary break is allowed whether the pair
/// is at peace or at war (the `formalAlliance` flag is independent of relation
/// state). No treasury cost. SPEC/program/orders.md § Diplomatic orders /
/// break alliance; SPEC/game/diplomacy.md § Alliances.
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
