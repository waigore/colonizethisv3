import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../../diplomacy/diplomacy_resolver.dart';
import '../../order_validation_result.dart';
import 'diplomatic_sub_validator.dart';
import 'join_empire_validator.dart';

/// Type-specific validator for [DiplomaticOrderType.establishOverture] orders.
/// Owns the per-stage rules (`tradeConsulate`, `embassy`, `nap`) and delegates
/// [OvertureStage.joinEmpire] to [JoinEmpireOvertureValidator].
/// SPEC/program/orders.md § Diplomatic orders / overtures.
class EstablishOvertureSubValidator implements DiplomaticSubValidator {
  EstablishOvertureSubValidator({
    required DiplomaticSubValidatorContext context,
  }) : game = context.game,
       playerId = context.playerId,
       factionMembership = context.factionMembership;

  final Game game;
  final String playerId;
  final DiplomacyFactionMembership? factionMembership;

  @override
  ({OrderValidationResult result, int treasury}) validate({
    required DiplomaticOrder order,
    required int treasury,
  }) {
    final stage = order.overtureStage;
    if (stage == null || stage == OvertureStage.none) {
      return rejectDiplomaticSub(
        'Overture stage is required for establishOverture',
        treasury,
      );
    }
    final targetId = order.targetFactionId;
    if (!isMinorOrTribe(game, targetId, factionMembership: factionMembership) &&
        !isGreatPower(game, targetId, factionMembership: factionMembership)) {
      return rejectDiplomaticSub(
        'Overtures are only valid toward Minor Nations, Tribes, or Great Powers',
        treasury,
      );
    }
    final rel = getRelation(game, playerId, targetId);
    final atWar = rel?.atWar ?? false;
    if (atWar) {
      return rejectDiplomaticSub(
        'Cannot establish overture while at war with that faction',
        treasury,
      );
    }

    final overture = getOverture(game, playerId, targetId);
    final currentStage = overture?.stage ?? OvertureStage.none;

    return switch (stage) {
      OvertureStage.tradeConsulate => _validateTradeConsulate(
        targetId,
        currentStage,
        treasury,
      ),
      OvertureStage.embassy => _validateEmbassy(
        targetId,
        currentStage,
        treasury,
      ),
      OvertureStage.nap => _validateNap(targetId, currentStage, treasury),
      OvertureStage.joinEmpire =>
        JoinEmpireOvertureValidator(
          game: game,
          playerId: playerId,
          factionMembership: factionMembership,
        ).validate(
          targetId: targetId,
          rel: rel,
          currentStage: currentStage,
          treasury: treasury,
        ),
      OvertureStage.none => rejectDiplomaticSub(
        'Overture stage is required for establishOverture',
        treasury,
      ),
    };
  }

  ({OrderValidationResult result, int treasury}) _validateTradeConsulate(
    String targetId,
    OvertureStage currentStage,
    int treasury,
  ) {
    if (currentStage != OvertureStage.none) {
      return rejectDiplomaticSub(
        'Trade Consulate requires no existing overture',
        treasury,
      );
    }
    if (_minorTribeOvertureRequiresDiplomaticExpertise(
          targetId,
          OvertureStage.tradeConsulate,
        ) &&
        !_playerHasDiplomaticExpertise()) {
      return rejectDiplomaticSub(
        'Diplomatic Expertise tech required for overtures with Minor Nations and Tribes',
        treasury,
      );
    }
    if (treasury < overtureConsulateCost) {
      return rejectDiplomaticSub(
        'Insufficient treasury for Trade Consulate (need $overtureConsulateCost)',
        treasury,
      );
    }
    return acceptDiplomaticSub(treasury - overtureConsulateCost);
  }

  ({OrderValidationResult result, int treasury}) _validateEmbassy(
    String targetId,
    OvertureStage currentStage,
    int treasury,
  ) {
    if (currentStage != OvertureStage.tradeConsulate) {
      return rejectDiplomaticSub(
        'Embassy requires existing Trade Consulate with that faction',
        treasury,
      );
    }
    if (_minorTribeOvertureRequiresDiplomaticExpertise(
          targetId,
          OvertureStage.embassy,
        ) &&
        !_playerHasDiplomaticExpertise()) {
      return rejectDiplomaticSub(
        'Diplomatic Expertise tech required for overtures with Minor Nations and Tribes',
        treasury,
      );
    }
    if (treasury < overtureEmbassyCost) {
      return rejectDiplomaticSub(
        'Insufficient treasury for Embassy (need $overtureEmbassyCost)',
        treasury,
      );
    }
    return acceptDiplomaticSub(treasury - overtureEmbassyCost);
  }

  ({OrderValidationResult result, int treasury}) _validateNap(
    String targetId,
    OvertureStage currentStage,
    int treasury,
  ) {
    if (currentStage != OvertureStage.embassy) {
      return rejectDiplomaticSub(
        'Non-Aggression Pact requires existing Embassy with that faction',
        treasury,
      );
    }
    if (_minorTribeOvertureRequiresDiplomaticExpertise(
          targetId,
          OvertureStage.nap,
        ) &&
        !_playerHasDiplomaticExpertise()) {
      return rejectDiplomaticSub(
        'Diplomatic Expertise tech required for overtures with Minor Nations and Tribes',
        treasury,
      );
    }
    return acceptDiplomaticSub(treasury);
  }

  bool _minorTribeOvertureRequiresDiplomaticExpertise(
    String targetId,
    OvertureStage stage,
  ) {
    if (!isMinorOrTribe(game, targetId, factionMembership: factionMembership)) {
      return false;
    }
    return stage == OvertureStage.tradeConsulate ||
        stage == OvertureStage.embassy ||
        stage == OvertureStage.nap;
  }

  bool _playerHasDiplomaticExpertise() {
    for (final p in game.players) {
      if (p.id == playerId) {
        return p.techUnlocked?[kTechIdDiplomaticExpertise] == true;
      }
    }
    return false;
  }
}
