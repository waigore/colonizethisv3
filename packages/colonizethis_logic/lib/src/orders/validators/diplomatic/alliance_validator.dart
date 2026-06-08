import 'package:colonizethis_diplomacy/src/diplomacy/diplomacy_resolver.dart';
import 'diplomatic_sub_validator.dart';

/// Type-specific validator for [DiplomaticOrderType.alliance] orders.
/// SPEC/program/orders.md § Diplomatic orders / alliance.
DiplomaticSubValidator allianceSubValidator(
  DiplomaticSubValidatorContext ctx,
) => relationDiplomaticSubValidator(ctx, ({
  required order,
  required relation,
  required treasury,
}) {
  final targetId = order.targetFactionId;
  if (!isGreatPower(
    ctx.game,
    targetId,
    factionMembership: ctx.factionMembership,
  )) {
    return rejectDiplomaticSub(
      'Alliance target must be a Great Power',
      treasury,
    );
  }
  final atWar = relation?.atWar ?? false;
  if (atWar) {
    return rejectDiplomaticSub(
      'Cannot form alliance while at war with that faction',
      treasury,
    );
  }
  return acceptDiplomaticSub(treasury);
});
