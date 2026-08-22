import 'package:colonizethis_models/colonizethis_models.dart';
import 'incremental_candidate_validator.dart';
import 'order_validators.dart';

/// Army-move and naval acceptors for [IncrementalCandidateValidator]
/// (Refs #4587 wave 10). Uses the validator's public cache / membership
/// surface so this library stays a standalone sibling, not a `part of`.
extension IncrementalCandidateValidatorArmyNaval
    on IncrementalCandidateValidator {
  bool isArmyMoveAccepted(ArmyMoveOrder candidate) {
    const validator = ArmyMoveValidator();
    return validator
        .validate(
          candidate,
          game,
          playerId,
          diplomaticOrders,
          view,
          topology,
          previousRejected: false,
          armiesById: _armiesById(),
          factionMembership: factionMembershipSnapshot,
        )
        .isAccepted;
  }

  Map<String, Army> _armiesById() {
    final cached = cache.armiesById;
    if (cached != null) {
      return cached;
    }
    final computed = <String, Army>{
      for (final a in game.worldState.armies) a.id: a,
    };
    cache.armiesById = computed;
    return computed;
  }

  NavalOrderValidator _navalOrderValidator() {
    final cached = cache.navalOrderValidator;
    if (cached != null) {
      return cached;
    }
    final built = NavalOrderValidator(
      game: game,
      topology: topology,
      playerId: playerId,
    );
    cache.navalOrderValidator = built;
    return built;
  }

  bool isNavalMoveAccepted(NavalMoveOrder candidate) {
    return _navalOrderValidator()
        .validateNavalMove(candidate, previousRejected: false)
        .isAccepted;
  }

  bool isNavalMissionAccepted(NavalMissionOrder candidate) {
    return _navalOrderValidator()
        .validateNavalMission(candidate, previousRejected: false)
        .isAccepted;
  }
}
