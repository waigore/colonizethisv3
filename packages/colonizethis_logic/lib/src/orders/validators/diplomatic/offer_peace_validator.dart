import 'package:colonizethis_models/colonizethis_models.dart';

import '../../../diplomacy/diplomacy_resolver.dart';
import '../../order_validation_result.dart';
import 'diplomatic_sub_validator.dart';

/// Type-specific validator for [DiplomaticOrderType.offerPeace] orders.
/// SPEC/program/orders.md § Diplomatic orders / offer peace.
class OfferPeaceSubValidator implements DiplomaticSubValidator {
  const OfferPeaceSubValidator({required this.game, required this.playerId});

  final Game game;
  final String playerId;

  @override
  ({OrderValidationResult result, int treasury}) validate({
    required DiplomaticOrder order,
    required int treasury,
  }) {
    final rel = getRelation(game, playerId, order.targetFactionId);
    final atWar = rel?.atWar ?? false;
    if (!atWar) {
      return rejectDiplomaticSub(
        'Cannot offer peace when not at war with that faction',
        treasury,
      );
    }
    return acceptDiplomaticSub(treasury);
  }
}
