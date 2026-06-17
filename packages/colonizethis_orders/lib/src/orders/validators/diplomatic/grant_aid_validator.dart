import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'diplomatic_sub_validator.dart';

/// Type-specific validator for [DiplomaticOrderType.grantAid] orders.
/// Owns amount-step rules, embassy requirement, and treasury debit on accept.
/// SPEC/program/orders.md § Diplomatic orders / grant aid.
DiplomaticSubValidator grantAidSubValidator(
  DiplomaticSubValidatorContext ctx,
) => delegatedDiplomaticSubValidator(({required order, required treasury}) {
  return economicDiplomaticSubValidation(
    ctx: ctx,
    order: order,
    treasury: treasury,
    amountStep: grantAidAmountStep,
    overtureGate: (overture) => overture != null && overture.hasEmbassy,
    overtureRejectionReason: 'Embassy required for GrantAid',
    insufficientTreasuryReason:
        'Insufficient treasury for GrantAid (need {amount})',
    label: 'GrantAid',
  );
});
