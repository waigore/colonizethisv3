import 'package:colonizethis_models/colonizethis_models.dart';

import '../../../diplomacy/diplomacy_resolver.dart';
import '../../order_validation_result.dart';
import 'diplomatic_sub_validator.dart';

/// Type-specific validator for [DiplomaticOrderType.setSubsidy] orders.
/// Owns amount-step rules, consulate requirement, and treasury debit on accept.
/// SPEC/program/orders.md § Diplomatic orders / set subsidy.
class SetSubsidySubValidator implements DiplomaticSubValidator {
  const SetSubsidySubValidator({required this.game, required this.playerId});

  final Game game;
  final String playerId;

  @override
  ({OrderValidationResult result, int treasury}) validate({
    required DiplomaticOrder order,
    required int treasury,
  }) {
    final amount = order.amount ?? 0;
    if (amount <= 0) {
      return rejectDiplomaticSub(
        'SetSubsidy amount must be positive',
        treasury,
      );
    }
    if (amount < setSubsidyAmountStep) {
      return rejectDiplomaticSub(
        'SetSubsidy amount must be at least £$setSubsidyAmountStep',
        treasury,
      );
    }
    if (amount % setSubsidyAmountStep != 0) {
      return rejectDiplomaticSub(
        'SetSubsidy amount must be a multiple of £$setSubsidyAmountStep',
        treasury,
      );
    }
    final overture = getOverture(game, playerId, order.targetFactionId);
    if (overture == null || !overture.hasConsulate) {
      return rejectDiplomaticSub(
        'Consulate or Embassy required for SetSubsidy',
        treasury,
      );
    }
    if (treasury < amount) {
      return rejectDiplomaticSub(
        'Insufficient treasury for SetSubsidy (need $amount)',
        treasury,
      );
    }
    return acceptDiplomaticSub(treasury - amount);
  }
}
