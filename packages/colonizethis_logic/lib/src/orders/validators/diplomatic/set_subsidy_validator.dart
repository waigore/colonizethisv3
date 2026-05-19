import '../../../diplomacy/diplomacy_resolver.dart';
import 'diplomatic_sub_validator.dart';

/// Type-specific validator for [DiplomaticOrderType.setSubsidy] orders.
/// Owns amount-step rules, consulate requirement, and treasury debit on accept.
/// SPEC/program/orders.md § Diplomatic orders / set subsidy.
DiplomaticSubValidator setSubsidySubValidator(
  DiplomaticSubValidatorContext ctx,
) => delegatedDiplomaticSubValidator(({required order, required treasury}) {
  final amount = order.amount ?? 0;
  if (amount <= 0) {
    return rejectDiplomaticSub('SetSubsidy amount must be positive', treasury);
  }
  if (amount < setSubsidyAmountStep) {
    return rejectDiplomaticSub(
      'SetSubsidy amount must be at least £$setSubsidyAmountStep',
      treasury,
    );
  }
  if (amount % setSubsidyAmountStep != 0) {
    return rejectDiplomaticSub(
      'SetSubsidy amount must be a multiple of £$setSubsidyAmountStep',
      treasury,
    );
  }
  final overture = getOverture(ctx.game, ctx.playerId, order.targetFactionId);
  if (overture == null || !overture.hasConsulate) {
    return rejectDiplomaticSub(
      'Consulate or Embassy required for SetSubsidy',
      treasury,
    );
  }
  if (treasury < amount) {
    return rejectDiplomaticSub(
      'Insufficient treasury for SetSubsidy (need $amount)',
      treasury,
    );
  }
  return acceptDiplomaticSub(treasury - amount);
});
