import 'package:colonizethis_diplomacy/src/diplomacy/diplomacy_resolver.dart';
import 'diplomatic_sub_validator.dart';

/// Type-specific validator for [DiplomaticOrderType.establishFtp] orders.
/// SPEC/game/world-market.md § Favored Trading Partner.
DiplomaticSubValidator establishFtpSubValidator(
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
      'FTP target must be a Great Power',
      treasury,
    );
  }
  if (relation?.atWar ?? false) {
    return rejectDiplomaticSub(
      'Cannot establish FTP while at war with that faction',
      treasury,
    );
  }
  if (hasFtpPartnership(ctx.game, ctx.playerId, targetId)) {
    return rejectDiplomaticSub(
      'FTP already established with that faction',
      treasury,
    );
  }
  if (!hasEmbassyOverture(ctx.game, ctx.playerId, targetId)) {
    return rejectDiplomaticSub(
      'FTP requires an embassy with the target',
      treasury,
    );
  }
  final score = relation?.score ?? relationScoreNeutral;
  if (score < relationScoreMinFtp) {
    return rejectDiplomaticSub(
      'FTP requires relation score >= $relationScoreMinFtp',
      treasury,
    );
  }
  return acceptDiplomaticSub(treasury);
});
