import 'diplomatic_sub_validator.dart';

/// Type-specific validator for [DiplomaticOrderType.revokeBoycott] orders
/// (Refs #3753 R6).
///
/// Valid only when the target is a Great Power and an **active** boycott for the
/// `(issuer, target)` pair currently exists. No treasury cost.
/// SPEC/program/orders.md § Diplomatic orders; SPEC/game/diplomacy.md § GP–Tribe
/// Rules (Boycott).
DiplomaticSubValidator revokeBoycottSubValidator(
  DiplomaticSubValidatorContext ctx,
) => delegatedDiplomaticSubValidator(({
  required order,
  required treasury,
}) {
  final notGpRejection = rejectIfNotGreatPowerTarget(
    ctx: ctx,
    targetId: order.targetFactionId,
    rejectionReason: 'Revoke Boycott target must be a Great Power',
    treasury: treasury,
  );
  if (notGpRejection != null) return notGpRejection;

  final hasBoycott = ctx.game.boycottStates.any(
    (b) => b.gpId == ctx.playerId && b.targetGpId == order.targetFactionId,
  );
  if (!hasBoycott) {
    return rejectDiplomaticSub(
      'No active boycott against that Great Power to revoke',
      treasury,
    );
  }

  return acceptDiplomaticSub(treasury);
});
