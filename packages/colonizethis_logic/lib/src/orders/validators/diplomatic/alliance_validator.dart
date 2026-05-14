import 'package:colonizethis_models/colonizethis_models.dart';

import '../../../diplomacy/diplomacy_resolver.dart';
import '../../order_validation_result.dart';
import 'diplomatic_sub_validator.dart';

/// Type-specific validator for [DiplomaticOrderType.alliance] orders.
/// SPEC/program/orders.md § Diplomatic orders / alliance.
class AllianceSubValidator implements DiplomaticSubValidator {
  const AllianceSubValidator({
    required this.game,
    required this.playerId,
    this.factionMembership,
  });

  final Game game;
  final String playerId;

  /// Optional precomputed faction classification snapshot reused across
  /// per-candidate probes to avoid linear `game.players` scans (Refs #2394).
  final DiplomacyFactionMembership? factionMembership;

  @override
  ({OrderValidationResult result, int treasury}) validate({
    required DiplomaticOrder order,
    required int treasury,
  }) {
    final targetId = order.targetFactionId;
    if (!isGreatPower(game, targetId, factionMembership: factionMembership)) {
      return rejectDiplomaticSub(
        'Alliance target must be a Great Power',
        treasury,
      );
    }
    final rel = getRelation(game, playerId, targetId);
    final atWar = rel?.atWar ?? false;
    if (atWar) {
      return rejectDiplomaticSub(
        'Cannot form alliance while at war with that faction',
        treasury,
      );
    }
    return acceptDiplomaticSub(treasury);
  }
}
