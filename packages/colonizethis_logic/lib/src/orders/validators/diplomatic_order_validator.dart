import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../constants.dart';
import '../../diplomacy/diplomacy_resolver.dart';
import '../order_validation_result.dart';

import 'stateful_validator.dart';

/// Validates diplomatic orders for a single player in submission order.
/// SPEC/program/orders.md § Diplomatic orders.
class DiplomaticOrderValidator extends StatefulValidator {
  final Game _game;
  final String _playerId;

  /// Types already accepted toward each target this turn. SPEC/program/orders.md § diplomatic cap.
  final Map<String, Set<DiplomaticOrderType>> _typesByTarget =
      <String, Set<DiplomaticOrderType>>{};

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
       );

  int get treasury => treasuryState;

  ({OrderValidationResult result, int treasury}) _reject(String reason) =>
      (result: OrderValidationResult.rejected(reason), treasury: treasuryState);

  ({OrderValidationResult result, int treasury}) _accept() =>
      (result: OrderValidationResult.accepted(), treasury: treasuryState);

  ({OrderValidationResult result, int treasury}) _acceptRecordingTarget(
    String targetId,
    DiplomaticOrderType type,
  ) {
    _typesByTarget
        .putIfAbsent(targetId, () => <DiplomaticOrderType>{})
        .add(type);
    return _accept();
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

    final rel = getRelation(_game, _playerId, targetId);
    final atWar = rel?.atWar ?? false;
    final atPeace = rel == null || rel.atPeace;

    switch (order.type) {
      case DiplomaticOrderType.declareWar:
        if (!atPeace) {
          return _reject('Already at war with that faction');
        }
        return _acceptRecordingTarget(targetId, order.type);

      case DiplomaticOrderType.offerPeace:
        if (!atWar) {
          return _reject(
            'Cannot offer peace when not at war with that faction',
          );
        }
        return _acceptRecordingTarget(targetId, order.type);

      case DiplomaticOrderType.alliance:
        if (!isGreatPower(_game, targetId)) {
          return _reject('Alliance target must be a Great Power');
        }
        if (atWar) {
          return _reject('Cannot form alliance while at war with that faction');
        }
        return _acceptRecordingTarget(targetId, order.type);

      case DiplomaticOrderType.establishOverture:
        return _validateEstablishOverture(order, targetId, rel, atWar: atWar);

      case DiplomaticOrderType.grantAid:
        return _validateGrantAid(targetId, order);

      case DiplomaticOrderType.setSubsidy:
        return _validateSetSubsidy(targetId, order);
    }
  }

  ({OrderValidationResult result, int treasury}) _validateEstablishOverture(
    DiplomaticOrder order,
    String targetId,
    DiplomacyRelation? rel, {
    required bool atWar,
  }) {
    final stage = order.overtureStage;
    if (stage == null || stage == OvertureStage.none) {
      return _reject('Overture stage is required for establishOverture');
    }
    if (!isMinorOrTribe(_game, targetId) && !isGreatPower(_game, targetId)) {
      return _reject(
        'Overtures are only valid toward Minor Nations, Tribes, or Great Powers',
      );
    }
    if (atWar) {
      return _reject(
        'Cannot establish overture while at war with that faction',
      );
    }

    final overture = getOverture(_game, _playerId, targetId);
    final currentStage = overture?.stage ?? OvertureStage.none;

    return switch (stage) {
      OvertureStage.tradeConsulate => _validateOvertureTradeConsulate(
        order,
        targetId,
        currentStage,
      ),
      OvertureStage.embassy => _validateOvertureEmbassy(
        order,
        targetId,
        currentStage,
      ),
      OvertureStage.nap => _validateOvertureNap(order, targetId, currentStage),
      OvertureStage.joinEmpire => _validateOvertureJoinEmpire(
        order,
        targetId,
        rel,
        currentStage,
      ),
      OvertureStage.none => _reject(
        'Overture stage is required for establishOverture',
      ),
    };
  }

  ({OrderValidationResult result, int treasury})
  _validateOvertureTradeConsulate(
    DiplomaticOrder order,
    String targetId,
    OvertureStage currentStage,
  ) {
    if (currentStage != OvertureStage.none) {
      return _reject('Trade Consulate requires no existing overture');
    }
    final stage = OvertureStage.tradeConsulate;
    if (_minorTribeOvertureRequiresDiplomaticExpertise(targetId, stage) &&
        !_playerHasDiplomaticExpertise()) {
      return _reject(
        'Diplomatic Expertise tech required for overtures with Minor Nations and Tribes',
      );
    }
    if (treasuryState < overtureConsulateCost) {
      return _reject(
        'Insufficient treasury for Trade Consulate (need $overtureConsulateCost)',
      );
    }
    treasuryState -= overtureConsulateCost;
    return _acceptRecordingTarget(targetId, order.type);
  }

  ({OrderValidationResult result, int treasury}) _validateOvertureEmbassy(
    DiplomaticOrder order,
    String targetId,
    OvertureStage currentStage,
  ) {
    if (currentStage != OvertureStage.tradeConsulate) {
      return _reject(
        'Embassy requires existing Trade Consulate with that faction',
      );
    }
    final stage = OvertureStage.embassy;
    if (_minorTribeOvertureRequiresDiplomaticExpertise(targetId, stage) &&
        !_playerHasDiplomaticExpertise()) {
      return _reject(
        'Diplomatic Expertise tech required for overtures with Minor Nations and Tribes',
      );
    }
    if (treasuryState < overtureEmbassyCost) {
      return _reject(
        'Insufficient treasury for Embassy (need $overtureEmbassyCost)',
      );
    }
    treasuryState -= overtureEmbassyCost;
    return _acceptRecordingTarget(targetId, order.type);
  }

  ({OrderValidationResult result, int treasury}) _validateOvertureNap(
    DiplomaticOrder order,
    String targetId,
    OvertureStage currentStage,
  ) {
    if (currentStage != OvertureStage.embassy) {
      return _reject(
        'Non-Aggression Pact requires existing Embassy with that faction',
      );
    }
    final stage = OvertureStage.nap;
    if (_minorTribeOvertureRequiresDiplomaticExpertise(targetId, stage) &&
        !_playerHasDiplomaticExpertise()) {
      return _reject(
        'Diplomatic Expertise tech required for overtures with Minor Nations and Tribes',
      );
    }
    return _acceptRecordingTarget(targetId, order.type);
  }

  ({OrderValidationResult result, int treasury}) _validateOvertureJoinEmpire(
    DiplomaticOrder order,
    String targetId,
    DiplomacyRelation? rel,
    OvertureStage currentStage,
  ) {
    if (currentStage != OvertureStage.nap) {
      return _reject(
        'Join Empire requires existing Non-Aggression Pact with that faction',
      );
    }
    final score = rel?.score ?? relationScoreNeutral;
    if (score < relationScoreMinFriendly) {
      return _reject(
        'Join Empire requires at least Friendly relations (score >= $relationScoreMinFriendly)',
      );
    }
    if (isGreatPower(_game, targetId)) {
      return _validateJoinEmpireTowardGreatPower(order, targetId);
    }
    if (!isMinorOrTribe(_game, targetId)) {
      return _reject(
        'Join Empire target must be a Minor Nation, Tribe, or Great Power',
      );
    }
    final cost = joinEmpireCostForMinorOrTribe(_game, targetId);
    if (treasuryState < cost) {
      return _reject(
        'Join Empire requires £$cost (scales with target size); treasury is $treasuryState',
      );
    }
    return _acceptRecordingTarget(targetId, order.type);
  }

  ({OrderValidationResult result, int treasury})
  _validateJoinEmpireTowardGreatPower(DiplomaticOrder order, String targetId) {
    final submitter = _game.playerById(_playerId);
    if (submitter?.techUnlocked?[kTechIdEmpireBuilding] != true) {
      return _reject(
        'Empire Building tech required for Join Empire toward a Great Power',
      );
    }
    if (!isGreatPowerNearlyDefeatedForJoinEmpire(_game, targetId)) {
      return _reject(
        'Join Empire toward Great Power requires target to be nearly defeated (at most 3 provinces and original capital not held by target)',
      );
    }
    return _acceptRecordingTarget(targetId, order.type);
  }

  ({OrderValidationResult result, int treasury}) _validateGrantAid(
    String targetId,
    DiplomaticOrder order,
  ) {
    final amount = order.amount ?? 0;
    if (amount <= 0) {
      return _reject('GrantAid amount must be positive');
    }
    if (amount < grantAidAmountStep) {
      return _reject('GrantAid amount must be at least £$grantAidAmountStep');
    }
    if (amount % grantAidAmountStep != 0) {
      return _reject(
        'GrantAid amount must be a multiple of £$grantAidAmountStep',
      );
    }
    final overture = getOverture(_game, _playerId, targetId);
    if (overture == null || !overture.hasEmbassy) {
      return _reject('Embassy required for GrantAid');
    }
    if (treasuryState < amount) {
      return _reject('Insufficient treasury for GrantAid (need $amount)');
    }
    treasuryState -= amount;
    return _acceptRecordingTarget(targetId, order.type);
  }

  ({OrderValidationResult result, int treasury}) _validateSetSubsidy(
    String targetId,
    DiplomaticOrder order,
  ) {
    final amount = order.amount ?? 0;
    if (amount <= 0) {
      return _reject('SetSubsidy amount must be positive');
    }
    if (amount < setSubsidyAmountStep) {
      return _reject(
        'SetSubsidy amount must be at least £$setSubsidyAmountStep',
      );
    }
    if (amount % setSubsidyAmountStep != 0) {
      return _reject(
        'SetSubsidy amount must be a multiple of £$setSubsidyAmountStep',
      );
    }
    final overture = getOverture(_game, _playerId, targetId);
    if (overture == null || !overture.hasConsulate) {
      return _reject('Consulate or Embassy required for SetSubsidy');
    }
    if (treasuryState < amount) {
      return _reject('Insufficient treasury for SetSubsidy (need $amount)');
    }
    treasuryState -= amount;
    return _acceptRecordingTarget(targetId, order.type);
  }

  bool _minorTribeOvertureRequiresDiplomaticExpertise(
    String targetId,
    OvertureStage stage,
  ) {
    if (!isMinorOrTribe(_game, targetId)) return false;
    return stage == OvertureStage.tradeConsulate ||
        stage == OvertureStage.embassy ||
        stage == OvertureStage.nap;
  }

  bool _playerHasDiplomaticExpertise() {
    for (final p in _game.players) {
      if (p.id == _playerId) {
        return p.techUnlocked?[kTechIdDiplomaticExpertise] == true;
      }
    }
    return false;
  }
}
