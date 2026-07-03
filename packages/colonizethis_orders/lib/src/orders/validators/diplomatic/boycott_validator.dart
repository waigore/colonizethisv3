import 'diplomatic_sub_validator.dart';

/// Type-specific validator for [DiplomaticOrderType.boycott] orders
/// (Refs #3753 R6).
///
/// Valid only when the target is **another** Great Power, the issuer **holds at
/// least one colony** (a `ColonyState` with `colonyOfGpId == issuer`), the pair
/// is **at peace**, and **no** active boycott already exists for the `(issuer,
/// target)` pair. No treasury cost. SPEC/program/orders.md § Diplomatic orders;
/// SPEC/game/diplomacy.md § GP–Tribe Rules (Boycott).
DiplomaticSubValidator boycottSubValidator(
  DiplomaticSubValidatorContext ctx,
) => relationDiplomaticSubValidator(ctx, ({
  required order,
  required relation,
  required treasury,
}) {
  final notGpRejection = rejectIfNotGreatPowerTarget(
    ctx: ctx,
    targetId: order.targetFactionId,
    rejectionReason: 'Boycott target must be a Great Power',
    treasury: treasury,
  );
  if (notGpRejection != null) return notGpRejection;

  final holdsColony = ctx.game.colonyStates.any(
    (c) => c.colonyOfGpId == ctx.playerId,
  );
  if (!holdsColony) {
    return rejectDiplomaticSub(
      'A colony is required to boycott a Great Power',
      treasury,
    );
  }

  final atWarRejection = rejectDiplomaticSubIfAtWar(
    relation: relation,
    reason: 'Cannot boycott a Great Power you are at war with',
    treasury: treasury,
  );
  if (atWarRejection != null) return atWarRejection;

  final alreadyBoycotting = ctx.game.boycottStates.any(
    (b) => b.gpId == ctx.playerId && b.targetGpId == order.targetFactionId,
  );
  if (alreadyBoycotting) {
    return rejectDiplomaticSub(
      'A boycott against that Great Power already exists',
      treasury,
    );
  }

  return acceptDiplomaticSub(treasury);
});
