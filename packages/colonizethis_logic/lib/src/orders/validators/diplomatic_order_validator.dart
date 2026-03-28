import 'package:colonizethis_models/colonizethis_models.dart';

import '../../diplomacy/diplomacy_resolver.dart';
import '../../diplomacy/diplomacy_relation_lookup.dart';
import '../order_validation_result.dart';

/// Validates diplomatic orders for a single player in submission order.
/// SPEC/program/orders.md § Diplomatic orders.
class DiplomaticOrderValidator {
  final Game _game;
  final String _playerId;

  int _treasury;

  /// Non-economic types: at most one toward a target per turn.
  final Set<String> _nonEconomicTargetsThisTurn = <String>{};

  /// At most one grantAid per target (may pair with one setSubsidy).
  final Set<String> _grantAidTargetsThisTurn = <String>{};

  /// At most one setSubsidy per target (may pair with one grantAid).
  final Set<String> _setSubsidyTargetsThisTurn = <String>{};

  DiplomaticOrderValidator({
    required Game game,
    required String playerId,
    required int initialTreasury,
  })  : _game = game,
        _playerId = playerId,
        _treasury = initialTreasury;

  int get treasury => _treasury;

  ({OrderValidationResult result, int treasury}) _reject(String reason) => (
        result: OrderValidationResult.rejected(reason),
        treasury: _treasury,
      );

  ({OrderValidationResult result, int treasury}) _accept() => (
        result: OrderValidationResult.accepted(),
        treasury: _treasury,
      );

  ({OrderValidationResult result, int treasury}) _acceptNonEconomic(
    String targetId,
  ) {
    _nonEconomicTargetsThisTurn.add(targetId);
    return _accept();
  }

  ({OrderValidationResult result, int treasury}) _acceptGrantAid(
    String targetId,
  ) {
    _grantAidTargetsThisTurn.add(targetId);
    return _accept();
  }

  ({OrderValidationResult result, int treasury}) _acceptSetSubsidy(
    String targetId,
  ) {
    _setSubsidyTargetsThisTurn.add(targetId);
    return _accept();
  }

  /// Validate a single [DiplomaticOrder], given whether a previous order
  /// for this player in this turn has already been rejected.
  ///
  /// Returns the [OrderValidationResult] and updated treasury.
  ({
    OrderValidationResult result,
    int treasury,
  }) validate(
    DiplomaticOrder order, {
    required bool previousRejected,
  }) {
    return shortCircuitIfPreviousRejectedWithTreasury(
      previousRejected: previousRejected,
      currentTreasury: _treasury,
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

    switch (order.type) {
      case DiplomaticOrderType.declareWar:
      case DiplomaticOrderType.offerPeace:
      case DiplomaticOrderType.alliance:
      case DiplomaticOrderType.establishOverture:
        if (_nonEconomicTargetsThisTurn.contains(targetId) ||
            _grantAidTargetsThisTurn.contains(targetId) ||
            _setSubsidyTargetsThisTurn.contains(targetId)) {
          return _reject(
            'Already have a diplomatic order for this faction this turn',
          );
        }
        break;
      case DiplomaticOrderType.grantAid:
        if (_nonEconomicTargetsThisTurn.contains(targetId) ||
            _grantAidTargetsThisTurn.contains(targetId)) {
          return _reject(
            'Already have a diplomatic order for this faction this turn',
          );
        }
        break;
      case DiplomaticOrderType.setSubsidy:
        if (_nonEconomicTargetsThisTurn.contains(targetId) ||
            _setSubsidyTargetsThisTurn.contains(targetId)) {
          return _reject(
            'Already have a diplomatic order for this faction this turn',
          );
        }
        break;
    }

    final rel = getRelation(_game, _playerId, targetId);
    final atWar = rel?.atWar ?? false;
    final atPeace = rel == null || rel.atPeace;

    switch (order.type) {
      case DiplomaticOrderType.declareWar:
        if (!atPeace) {
          return _reject('Already at war with that faction');
        }
        return _acceptNonEconomic(targetId);

      case DiplomaticOrderType.offerPeace:
        if (!atWar) {
          return _reject(
            'Cannot offer peace when not at war with that faction',
          );
        }
        return _acceptNonEconomic(targetId);

      case DiplomaticOrderType.alliance:
        if (!isGreatPower(_game, targetId)) {
          return _reject('Alliance target must be a Great Power');
        }
        if (atWar) {
          return _reject(
            'Cannot form alliance while at war with that faction',
          );
        }
        return _acceptNonEconomic(targetId);

      case DiplomaticOrderType.establishOverture:
        final stage = order.overtureStage;
        if (stage == null || stage == OvertureStage.none) {
          return _reject(
            'Overture stage is required for establishOverture',
          );
        }
        if (!isMinorOrTribe(_game, targetId) &&
            !isGreatPower(_game, targetId)) {
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

        if (stage == OvertureStage.tradeConsulate) {
          if (currentStage != OvertureStage.none) {
            return _reject('Trade Consulate requires no existing overture');
          }
          if (_treasury < overtureConsulateCost) {
            return _reject(
              'Insufficient treasury for Trade Consulate (need $overtureConsulateCost)',
            );
          }
          _treasury -= overtureConsulateCost;
        } else if (stage == OvertureStage.embassy) {
          if (currentStage != OvertureStage.tradeConsulate) {
            return _reject(
              'Embassy requires existing Trade Consulate with that faction',
            );
          }
          if (_treasury < overtureEmbassyCost) {
            return _reject(
              'Insufficient treasury for Embassy (need $overtureEmbassyCost)',
            );
          }
          _treasury -= overtureEmbassyCost;
        } else if (stage == OvertureStage.nap) {
          if (currentStage != OvertureStage.embassy) {
            return _reject(
              'Non-Aggression Pact requires existing Embassy with that faction',
            );
          }
        } else if (stage == OvertureStage.joinEmpire) {
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
          final cost = joinEmpireCostForMinorOrTribe(_game, targetId);
          if (_treasury < cost) {
            return _reject(
              'Join Empire requires £$cost (scales with target size); treasury is $_treasury',
            );
          }
        }

        return _acceptNonEconomic(targetId);

      case DiplomaticOrderType.grantAid:
        final amount = order.amount ?? 0;
        if (amount <= 0) {
          return _reject('GrantAid amount must be positive');
        }
        if (amount % grantAidAmountStep != 0) {
          return _reject(
            'GrantAid amount must be a positive multiple of £$grantAidAmountStep',
          );
        }
        final overture = getOverture(_game, _playerId, targetId);
        if (overture == null || !overture.hasEmbassy) {
          return _reject('Embassy required for GrantAid');
        }
        if (_treasury < amount) {
          return _reject('Insufficient treasury for GrantAid (need $amount)');
        }
        _treasury -= amount;
        return _acceptGrantAid(targetId);

      case DiplomaticOrderType.setSubsidy:
        final amount = order.amount ?? 0;
        if (amount <= 0) {
          return _reject('SetSubsidy amount must be positive');
        }
        if (amount % setSubsidyAmountStep != 0) {
          return _reject(
            'SetSubsidy amount must be a positive multiple of £$setSubsidyAmountStep',
          );
        }
        final overture = getOverture(_game, _playerId, targetId);
        if (overture == null || !overture.hasConsulate) {
          return _reject('Consulate or Embassy required for SetSubsidy');
        }
        if (_treasury < amount) {
          return _reject(
            'Insufficient treasury for SetSubsidy (need $amount)',
          );
        }
        _treasury -= amount;
        return _acceptSetSubsidy(targetId);
    }
  }
}
