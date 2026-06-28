import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'diplomatic_sub_validator.dart';

/// Type-specific validator for [DiplomaticOrderType.setSubsidy] orders.
/// Owns amount-step rules, embassy requirement, and treasury debit on accept.
/// SPEC/program/orders.md § Diplomatic orders / set subsidy;
/// SPEC/game/diplomacy.md § Diplomatic Order Types (Refs #3753 R2 — economic
/// actions require an Embassy; a Trade Consulate alone is insufficient).
DiplomaticSubValidator setSubsidySubValidator(
  DiplomaticSubValidatorContext ctx,
) => delegatedDiplomaticSubValidator(({required order, required treasury}) {
  return economicDiplomaticSubValidation(
    ctx: ctx,
    order: order,
    treasury: treasury,
    amountStep: setSubsidyAmountStep,
    overtureGate: (overture) => overture != null && overture.hasEmbassy,
    overtureRejectionReason: 'Embassy required for SetSubsidy',
    insufficientTreasuryReason:
        'Insufficient treasury for SetSubsidy (need {amount})',
    label: 'SetSubsidy',
  );
});
