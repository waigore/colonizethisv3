import 'package:colonizethis_models/colonizethis_models.dart';

import '../../constants.dart';
import '../../diplomacy/diplomacy_resolver.dart';
import '../order_validation_result.dart';

import 'diplomatic/alliance_validator.dart';
import 'diplomatic/declare_war_validator.dart';
import 'diplomatic/diplomatic_sub_validator.dart';
import 'diplomatic/establish_overture_validator.dart';
import 'diplomatic/grant_aid_validator.dart';
import 'diplomatic/offer_peace_validator.dart';
import 'diplomatic/set_subsidy_validator.dart';
import 'stateful_validator.dart';

/// Validates diplomatic orders for a single player in submission order.
/// SPEC/program/orders.md § Diplomatic orders.
///
/// Cross-cutting checks (target existence, self-targeting, the per-target
/// diplomatic-order cap) live here. Type-specific rules are dispatched to
/// per-type [DiplomaticSubValidator] implementations under
/// `lib/src/orders/validators/diplomatic/`.
class DiplomaticOrderValidator extends StatefulValidator {
  final Game _game;
  final String _playerId;

  /// Types already accepted toward each target this turn. SPEC/program/orders.md § diplomatic cap.
  final Map<String, Set<DiplomaticOrderType>> _typesByTarget =
      <String, Set<DiplomaticOrderType>>{};

  late final Map<DiplomaticOrderType, DiplomaticSubValidator> _subValidators;

  DiplomaticOrderValidator({
    required Game game,
    required String playerId,
    required int initialTreasury,
  }) : _game = game,
       _playerId = playerId,
       super(
         stockpileState: game.playerById(playerId)?.stockpile ?? Stockpile.empty,
         treasuryState: initialTreasury,
         workerPoolState:
             game.playerById(playerId)?.workerPool ?? WorkerPool.empty,
       ) {
    _subValidators = <DiplomaticOrderType, DiplomaticSubValidator>{
      DiplomaticOrderType.declareWar: DeclareWarSubValidator(
        game: _game,
        playerId: _playerId,
      ),
      DiplomaticOrderType.offerPeace: OfferPeaceSubValidator(
        game: _game,
        playerId: _playerId,
      ),
      DiplomaticOrderType.alliance: AllianceSubValidator(
        game: _game,
        playerId: _playerId,
      ),
      DiplomaticOrderType.establishOverture: EstablishOvertureSubValidator(
        game: _game,
        playerId: _playerId,
      ),
      DiplomaticOrderType.grantAid: GrantAidSubValidator(
        game: _game,
        playerId: _playerId,
      ),
      DiplomaticOrderType.setSubsidy: SetSubsidySubValidator(
        game: _game,
        playerId: _playerId,
      ),
    };
  }

  int get treasury => treasuryState;

  ({OrderValidationResult result, int treasury}) _reject(String reason) =>
      (result: OrderValidationResult.rejected(reason), treasury: treasuryState);

  ({OrderValidationResult result, int treasury}) _acceptRecordingTarget(
    String targetId,
    DiplomaticOrderType type,
  ) {
    _typesByTarget
        .putIfAbsent(targetId, () => <DiplomaticOrderType>{})
        .add(type);
    return (result: OrderValidationResult.accepted(), treasury: treasuryState);
  }

  bool _canAddDiplomaticOrder(String targetId, DiplomaticOrderType type) {
    final existing = _typesByTarget[targetId] ?? const <DiplomaticOrderType>{};
    if (existing.contains(type)) return false;
    const economic = {
      DiplomaticOrderType.grantAid,
      DiplomaticOrderType.setSubsidy,
    };
    final isEconomic = economic.contains(type);
    final hasNonEconomic = existing.any((t) => !economic.contains(t));
    if (hasNonEconomic && isEconomic) return false;
    if (!isEconomic && existing.isNotEmpty) return false;
    return true;
  }

  /// Validate a single [DiplomaticOrder], given whether a previous order
  /// for this player in this turn has already been rejected.
  ///
  /// Returns the [OrderValidationResult] and updated treasury.
  ({OrderValidationResult result, int treasury}) validate(
    DiplomaticOrder order, {
    required bool previousRejected,
  }) {
    return shortCircuitIfPreviousRejectedWithTreasury(
      previousRejected: previousRejected,
      currentTreasury: treasuryState,
      body: () => _validateOne(order),
    );
  }

  ({OrderValidationResult result, int treasury}) _validateOne(
    DiplomaticOrder order,
  ) {
    final targetId = order.targetFactionId;

    if (targetId == _playerId) {
      return _reject('Cannot target own faction with diplomatic order');
    }

    final targetExists =
        isGreatPower(_game, targetId) || isMinorOrTribe(_game, targetId);
    if (!targetExists) {
      return _reject('Target faction not found');
    }

    if (!_canAddDiplomaticOrder(targetId, order.type)) {
      return _reject(
        'Already have a diplomatic order for this faction this turn',
      );
    }

    final subResult = _subValidators[order.type]!.validate(
      order: order,
      treasury: treasuryState,
    );
    if (!subResult.result.isAccepted) {
      return (result: subResult.result, treasury: treasuryState);
    }
    treasuryState = subResult.treasury;
    return _acceptRecordingTarget(targetId, order.type);
  }
}
