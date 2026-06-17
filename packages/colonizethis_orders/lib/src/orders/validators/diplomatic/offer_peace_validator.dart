import 'diplomatic_sub_validator.dart';

/// Type-specific validator for [DiplomaticOrderType.offerPeace] orders.
/// SPEC/program/orders.md § Diplomatic orders / offer peace.
DiplomaticSubValidator offerPeaceSubValidator(
  DiplomaticSubValidatorContext ctx,
) => relationDiplomaticSubValidator(ctx, ({
  required order,
  required relation,
  required treasury,
}) {
  final atPeaceRejection = rejectDiplomaticSubIfAtPeace(
    relation: relation,
    reason: 'Cannot offer peace when not at war with that faction',
    treasury: treasury,
  );
  if (atPeaceRejection != null) return atPeaceRejection;
  return acceptDiplomaticSub(treasury);
});
