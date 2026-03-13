import 'package:colonizethis_models/colonizethis_models.dart';

import '../../constants.dart';
import '../../diplomacy/diplomacy_resolver.dart';
import '../order_validation_result.dart';

/// Validates diplomatic orders for a single player in submission order.
/// SPEC/program/orders.md § Diplomatic orders.
class DiplomaticOrderValidator {
  final Game _game;
  final String _playerId;

  int _treasury;

  /// Track establish-overture targets to enforce "at most one per target per turn".
  final Set<String> _overtureTargetsThisTurn = <String>{};

  DiplomaticOrderValidator({
    required Game game,
    required String playerId,
    required int initialTreasury,
  })  : _game = game,
        _playerId = playerId,
        _treasury = initialTreasury;

  int get treasury => _treasury;

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
    if (previousRejected) {
      return (
        result: previousInvalidOrderResult,
        treasury: _treasury,
      );
    }

    final targetId = order.targetFactionId;

    if (targetId == _playerId) {
      return (
        result: const OrderValidationResult(
          status: OrderValidationStatus.rejected,
          reason: 'Cannot target own faction with diplomatic order',
        ),
        treasury: _treasury,
      );
    }

    final targetExists =
        isGreatPower(_game, targetId) || isMinorOrTribe(_game, targetId);
    if (!targetExists) {
      return (
        result: const OrderValidationResult(
          status: OrderValidationStatus.rejected,
          reason: 'Target faction not found',
        ),
        treasury: _treasury,
      );
    }

    final rel = getRelation(_game, _playerId, targetId);
    final atWar = rel?.atWar ?? false;
    final atPeace = rel == null || rel.atPeace;

    switch (order.type) {
      case DiplomaticOrderType.declareWar:
        if (!atPeace) {
          return (
            result: const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'Already at war with that faction',
            ),
            treasury: _treasury,
          );
        }
        return (
          result: const OrderValidationResult(
            status: OrderValidationStatus.accepted,
          ),
          treasury: _treasury,
        );

      case DiplomaticOrderType.offerPeace:
        if (!atWar) {
          return (
            result: const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'Cannot offer peace when not at war with that faction',
            ),
            treasury: _treasury,
          );
        }
        return (
          result: const OrderValidationResult(
            status: OrderValidationStatus.accepted,
          ),
          treasury: _treasury,
        );

      case DiplomaticOrderType.alliance:
        if (!isGreatPower(_game, targetId)) {
          return (
            result: const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'Alliance target must be a Great Power',
            ),
            treasury: _treasury,
          );
        }
        if (atWar) {
          return (
            result: const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'Cannot form alliance while at war with that faction',
            ),
            treasury: _treasury,
          );
        }
        return (
          result: const OrderValidationResult(
            status: OrderValidationStatus.accepted,
          ),
          treasury: _treasury,
        );

      case DiplomaticOrderType.establishOverture:
        final stage = order.overtureStage;
        if (stage == null || stage == OvertureStage.none) {
          return (
            result: const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'Overture stage is required for establishOverture',
            ),
            treasury: _treasury,
          );
        }
        if (!isMinorOrTribe(_game, targetId) &&
            !isGreatPower(_game, targetId)) {
          return (
            result: const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason:
                  'Overtures are only valid toward Minor Nations, Tribes, or Great Powers',
            ),
            treasury: _treasury,
          );
        }
        if (atWar) {
          return (
            result: const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason:
                  'Cannot establish overture while at war with that faction',
            ),
            treasury: _treasury,
          );
        }

        // Enforce at most one Establish Overture per (player, target) per turn.
        if (_overtureTargetsThisTurn.contains(targetId)) {
          return (
            result: const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason:
                  'Already have an Establish Overture order for this faction this turn',
            ),
            treasury: _treasury,
          );
        }

        final overture = getOverture(_game, _playerId, targetId);
        final currentStage = overture?.stage ?? OvertureStage.none;

        if (stage == OvertureStage.tradeConsulate) {
          if (currentStage != OvertureStage.none) {
            return (
              result: const OrderValidationResult(
                status: OrderValidationStatus.rejected,
                reason: 'Trade Consulate requires no existing overture',
              ),
              treasury: _treasury,
            );
          }
          if (_treasury < overtureConsulateCost) {
            return (
              result: OrderValidationResult(
                status: OrderValidationStatus.rejected,
                reason:
                    'Insufficient treasury for Trade Consulate (need $overtureConsulateCost)',
              ),
              treasury: _treasury,
            );
          }
          _treasury -= overtureConsulateCost;
        } else if (stage == OvertureStage.embassy) {
          if (currentStage != OvertureStage.tradeConsulate) {
            return (
              result: const OrderValidationResult(
                status: OrderValidationStatus.rejected,
                reason:
                    'Embassy requires existing Trade Consulate with that faction',
              ),
              treasury: _treasury,
            );
          }
          if (_treasury < overtureEmbassyCost) {
            return (
              result: OrderValidationResult(
                status: OrderValidationStatus.rejected,
                reason:
                    'Insufficient treasury for Embassy (need $overtureEmbassyCost)',
              ),
              treasury: _treasury,
            );
          }
          _treasury -= overtureEmbassyCost;
        } else if (stage == OvertureStage.nap) {
          if (currentStage != OvertureStage.embassy) {
            return (
              result: const OrderValidationResult(
                status: OrderValidationStatus.rejected,
                reason:
                    'Non-Aggression Pact requires existing Embassy with that faction',
              ),
              treasury: _treasury,
            );
          }
        } else if (stage == OvertureStage.joinEmpire) {
          if (currentStage != OvertureStage.nap) {
            return (
              result: const OrderValidationResult(
                status: OrderValidationStatus.rejected,
                reason:
                    'Join Empire requires existing Non-Aggression Pact with that faction',
              ),
              treasury: _treasury,
            );
          }
          final score = rel?.score ?? relationScoreNeutral;
          if (score < relationScoreMinFriendly) {
            return (
              result: OrderValidationResult(
                status: OrderValidationStatus.rejected,
                reason:
                    'Join Empire requires at least Friendly relations (score >= $relationScoreMinFriendly)',
              ),
              treasury: _treasury,
            );
          }
          final cost = joinEmpireCostForMinorOrTribe(_game, targetId);
          if (_treasury < cost) {
            return (
              result: OrderValidationResult(
                status: OrderValidationStatus.rejected,
                reason:
                    'Join Empire requires £$cost (scales with target size); treasury is $_treasury',
              ),
              treasury: _treasury,
            );
          }
        }

        _overtureTargetsThisTurn.add(targetId);
        return (
          result: const OrderValidationResult(
            status: OrderValidationStatus.accepted,
          ),
          treasury: _treasury,
        );

      case DiplomaticOrderType.grantAid:
        final amount = order.amount ?? 0;
        if (amount <= 0) {
          return (
            result: const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'GrantAid amount must be positive',
            ),
            treasury: _treasury,
          );
        }
        final overture = getOverture(_game, _playerId, targetId);
        if (overture == null || !overture.hasEmbassy) {
          return (
            result: const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'Embassy required for GrantAid',
            ),
            treasury: _treasury,
          );
        }
        if (_treasury < amount) {
          return (
            result: OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'Insufficient treasury for GrantAid (need $amount)',
            ),
            treasury: _treasury,
          );
        }
        _treasury -= amount;
        return (
          result: const OrderValidationResult(
            status: OrderValidationStatus.accepted,
          ),
          treasury: _treasury,
        );

      case DiplomaticOrderType.setSubsidy:
        final amount = order.amount ?? 0;
        if (amount <= 0) {
          return (
            result: const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'SetSubsidy amount must be positive',
            ),
            treasury: _treasury,
          );
        }
        final overture = getOverture(_game, _playerId, targetId);
        if (overture == null || !overture.hasConsulate) {
          return (
            result: const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'Consulate or Embassy required for SetSubsidy',
            ),
            treasury: _treasury,
          );
        }
        if (_treasury < amount) {
          return (
            result: OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'Insufficient treasury for SetSubsidy (need $amount)',
            ),
            treasury: _treasury,
          );
        }
        _treasury -= amount;
        return (
          result: const OrderValidationResult(
            status: OrderValidationStatus.accepted,
          ),
          treasury: _treasury,
        );
    }
  }
}

