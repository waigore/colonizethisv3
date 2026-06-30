import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'diplomatic_sub_validator.dart';

/// Type-specific validator for [DiplomaticOrderType.setSubsidy] orders.
///
/// Percentage subsidy model (Refs #3753 R3): the subsidy value is carried in
/// `DiplomaticOrder.amount` as a whole percentage that must be valid
/// ([isValidSubsidyPercent] — 5–20, step 5). Subsidies are only available from
/// a Great Power to a **Minor Nation or Tribe** (no GP→GP subsidies), and
/// require an **Embassy** with the target (R2 — a Trade Consulate alone is
/// insufficient). The percent model charges **no** upfront treasury cost, so
/// treasury is returned unchanged on accept.
/// SPEC/program/orders.md § Diplomatic orders / set subsidy;
/// SPEC/game/diplomacy.md § Diplomatic Order Types.
DiplomaticSubValidator setSubsidySubValidator(
  DiplomaticSubValidatorContext ctx,
) => delegatedDiplomaticSubValidator(({required order, required treasury}) {
  final targetId = order.targetFactionId;
  final cooldownRejection = rejectIfAllianceBreakCooldownActive(
    ctx: ctx,
    targetId: targetId,
    treasury: treasury,
  );
  if (cooldownRejection != null) return cooldownRejection;
  if (!isMinorOrTribe(
    ctx.game,
    targetId,
    factionMembership: ctx.factionMembership,
  )) {
    return rejectDiplomaticSub(
      'Subsidies are only available for Minor Nations and Tribes',
      treasury,
    );
  }

  final percent = order.amount ?? 0;
  if (!isValidSubsidyPercent(percent)) {
    return rejectDiplomaticSub(
      'Subsidy must be $kSubsidyPercentMin–$kSubsidyPercentMax% '
      'in steps of $kSubsidyPercentStep',
      treasury,
    );
  }

  final overture = getOverture(ctx.game, ctx.playerId, targetId);
  if (overture == null || !overture.hasEmbassy) {
    return rejectDiplomaticSub('Embassy required for SetSubsidy', treasury);
  }

  return acceptDiplomaticSub(treasury);
});
