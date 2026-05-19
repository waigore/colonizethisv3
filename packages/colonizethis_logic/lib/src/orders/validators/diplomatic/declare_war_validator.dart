import 'diplomatic_sub_validator.dart';

/// Type-specific validator for [DiplomaticOrderType.declareWar] orders.
/// SPEC/program/orders.md § Diplomatic orders / declare war.
DiplomaticSubValidator declareWarSubValidator(
  DiplomaticSubValidatorContext ctx,
) => relationDiplomaticSubValidator(ctx, ({
  required order,
  required relation,
  required treasury,
}) {
  final atPeace = relation == null || relation.atPeace;
  if (!atPeace) {
    return rejectDiplomaticSub('Already at war with that faction', treasury);
  }
  return acceptDiplomaticSub(treasury);
});
