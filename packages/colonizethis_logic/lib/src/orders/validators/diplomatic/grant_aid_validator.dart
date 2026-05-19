import '../../../diplomacy/diplomacy_resolver.dart';
import 'diplomatic_sub_validator.dart';

/// Type-specific validator for [DiplomaticOrderType.grantAid] orders.
/// Owns amount-step rules, embassy requirement, and treasury debit on accept.
/// SPEC/program/orders.md § Diplomatic orders / grant aid.
DiplomaticSubValidator grantAidSubValidator(
  DiplomaticSubValidatorContext ctx,
) => delegatedDiplomaticSubValidator(({required order, required treasury}) {
  final amount = order.amount ?? 0;
  if (amount <= 0) {
    return rejectDiplomaticSub('GrantAid amount must be positive', treasury);
  }
  if (amount < grantAidAmountStep) {
    return rejectDiplomaticSub(
      'GrantAid amount must be at least £$grantAidAmountStep',
      treasury,
    );
  }
  if (amount % grantAidAmountStep != 0) {
    return rejectDiplomaticSub(
      'GrantAid amount must be a multiple of £$grantAidAmountStep',
      treasury,
    );
  }
  final overture = getOverture(ctx.game, ctx.playerId, order.targetFactionId);
  if (overture == null || !overture.hasEmbassy) {
    return rejectDiplomaticSub('Embassy required for GrantAid', treasury);
  }
  if (treasury < amount) {
    return rejectDiplomaticSub(
      'Insufficient treasury for GrantAid (need $amount)',
      treasury,
    );
  }
  return acceptDiplomaticSub(treasury - amount);
});
