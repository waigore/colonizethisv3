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
  final atWar = relation?.atWar ?? false;
  if (!atWar) {
    return rejectDiplomaticSub(
      'Cannot offer peace when not at war with that faction',
      treasury,
    );
  }
  return acceptDiplomaticSub(treasury);
});
