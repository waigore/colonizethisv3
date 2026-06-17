import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'diplomatic_sub_validator.dart';

/// Type-specific validator for [DiplomaticOrderType.setSubsidy] orders.
/// Owns amount-step rules, consulate requirement, and treasury debit on accept.
/// SPEC/program/orders.md § Diplomatic orders / set subsidy.
DiplomaticSubValidator setSubsidySubValidator(
  DiplomaticSubValidatorContext ctx,
) => delegatedDiplomaticSubValidator(({required order, required treasury}) {
  return economicDiplomaticSubValidation(
    ctx: ctx,
    order: order,
    treasury: treasury,
    amountStep: setSubsidyAmountStep,
    overtureGate: (overture) => overture != null && overture.hasConsulate,
    overtureRejectionReason:
        'Consulate or Embassy required for SetSubsidy',
    insufficientTreasuryReason:
        'Insufficient treasury for SetSubsidy (need {amount})',
    label: 'SetSubsidy',
  );
});
