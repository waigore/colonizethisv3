import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import '../order_validation_result.dart';

import 'diplomatic/alliance_validator.dart';
import 'diplomatic/break_alliance_validator.dart';
import 'diplomatic/declare_war_validator.dart';
import 'diplomatic/diplomatic_sub_validator.dart';
import 'diplomatic/establish_ftp_validator.dart';
import 'diplomatic/establish_overture_validator.dart';
import 'diplomatic/grant_aid_validator.dart';
import 'diplomatic/offer_peace_validator.dart';
import 'diplomatic/set_subsidy_validator.dart';
import 'stateful_validator.dart';

/// Treasury and per-target diplomatic caps after replaying an accepted
/// [Orders] prefix. Used to evaluate incremental diplomatic candidates without
/// O(E) prefix replay per probe (Refs #2394, SPEC/program/order-suggestions.md).
final class DiplomaticPrefixCheckpoint {
  DiplomaticPrefixCheckpoint._({
    required this.treasury,
    required Map<String, Set<DiplomaticOrderType>> typesByTarget,
  }) : typesByTarget = {
         for (final e in typesByTarget.entries)
           e.key: Set<DiplomaticOrderType>.from(e.value),
       };

  final int treasury;
  final Map<String, Set<DiplomaticOrderType>> typesByTarget;
}

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
  final DiplomacyFactionMembership? _factionMembership;

  /// Types already accepted toward each target this turn. SPEC/program/orders.md § diplomatic cap.
  final Map<String, Set<DiplomaticOrderType>> _typesByTarget =
      <String, Set<DiplomaticOrderType>>{};

  late final Map<DiplomaticOrderType, DiplomaticSubValidator> _subValidators;

  DiplomaticOrderValidator({
    required Game game,
    required String playerId,
    required int initialTreasury,
    DiplomacyFactionMembership? factionMembership,
  }) : _game = game,
       _playerId = playerId,
       _factionMembership = factionMembership,
       super(
         stockpileState:
             game.playerById(playerId)?.stockpile ?? Stockpile.empty,
         treasuryState: initialTreasury,
         workerPoolState:
             game.playerById(playerId)?.workerPool ?? WorkerPool.empty,
       ) {
    final subValidatorContext = DiplomaticSubValidatorContext(
      game: _game,
      playerId: _playerId,
      factionMembership: _factionMembership,
    );
    _subValidators = <DiplomaticOrderType, DiplomaticSubValidator>{
      DiplomaticOrderType.declareWar: declareWarSubValidator(
        subValidatorContext,
      ),
      DiplomaticOrderType.offerPeace: offerPeaceSubValidator(
        subValidatorContext,
      ),
      DiplomaticOrderType.alliance: allianceSubValidator(subValidatorContext),
      DiplomaticOrderType.breakAlliance: breakAllianceSubValidator(
        subValidatorContext,
      ),
      DiplomaticOrderType.establishOverture: establishOvertureSubValidator(
        subValidatorContext,
      ),
      DiplomaticOrderType.establishFtp: establishFtpSubValidator(
        subValidatorContext,
      ),
      DiplomaticOrderType.grantAid: grantAidSubValidator(subValidatorContext),
      DiplomaticOrderType.setSubsidy: setSubsidySubValidator(
        subValidatorContext,
      ),
    };
  }

  /// Validator state cloned from [checkpoint] for a single candidate probe.
  /// Does not replay prefix orders; mirrors post-prefix state only.
  factory DiplomaticOrderValidator.fromPrefixCheckpoint({
    required Game game,
    required String playerId,
    required DiplomaticPrefixCheckpoint checkpoint,
    DiplomacyFactionMembership? factionMembership,
  }) {
    final validator = DiplomaticOrderValidator(
      game: game,
      playerId: playerId,
      initialTreasury: checkpoint.treasury,
      factionMembership: factionMembership,
    );
    for (final e in checkpoint.typesByTarget.entries) {
      validator._typesByTarget[e.key] = Set<DiplomaticOrderType>.from(e.value);
    }
    return validator;
  }

  /// Captures treasury and accepted diplomatic caps after validating prefix
  /// orders in submission order.
  DiplomaticPrefixCheckpoint capturePrefixCheckpoint() {
    return DiplomaticPrefixCheckpoint._(
      treasury: treasuryState,
      typesByTarget: {
        for (final e in _typesByTarget.entries)
          e.key: Set<DiplomaticOrderType>.from(e.value),
      },
    );
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
        isGreatPower(_game, targetId, factionMembership: _factionMembership) ||
        isMinorOrTribe(_game, targetId, factionMembership: _factionMembership);
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
