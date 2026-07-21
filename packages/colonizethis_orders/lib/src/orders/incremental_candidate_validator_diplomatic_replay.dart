/// Diplomatic accepted-prefix replay for [IncrementalCandidateValidator]
/// (Refs #2394, #4109 wave 5 slice C).
library;

import 'package:colonizethis_economy/colonizethis_economy.dart'
    show OrderValidationResult;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'incremental_candidate_validator.dart';
import 'incremental_candidate_validator_replay_shared.dart';
import 'order_validator_factory.dart';
import 'order_validators.dart';

extension IncrementalCandidateValidatorDiplomaticReplay
    on IncrementalCandidateValidator {
  bool isDiplomaticAccepted(DiplomaticOrder candidate) {
    return validateDiplomaticReplayCandidate(candidate).isAccepted;
  }

  /// Like [isDiplomaticAccepted] but returns the full [OrderValidationResult]
  /// so UI layers can surface validator rejection text on disabled controls.
  OrderValidationResult probeDiplomaticOrder(DiplomaticOrder candidate) {
    return validateDiplomaticReplayCandidate(
      candidate,
      playerNotFoundReason: 'Player not found',
      prefixReplayFailedReason: 'Previous invalid diplomatic order in prefix',
    );
  }

  OrderValidationResult validateDiplomaticReplayCandidate(
    DiplomaticOrder candidate, {
    String? playerNotFoundReason,
    String? prefixReplayFailedReason,
  }) {
    final prepared = prepareDiplomaticReplayCandidateValidator(
      playerNotFoundReason: playerNotFoundReason,
      prefixReplayFailedReason: prefixReplayFailedReason,
    );
    if (!prepared.ok) {
      return prepared.reject ??
          OrderValidationResult.rejected('Diplomatic order rejected');
    }
    return prepared.validator!
        .validate(candidate, previousRejected: false)
        .result;
  }

  ({
    bool ok,
    OrderValidationResult? reject,
    DiplomaticOrderValidator? validator,
  })
  prepareDiplomaticReplayCandidateValidator({
    String? playerNotFoundReason,
    String? prefixReplayFailedReason,
  }) {
    final player = replayProbePlayer();
    if (player == null) {
      return (
        ok: false,
        reject: playerNotFoundReason == null
            ? null
            : OrderValidationResult.rejected(playerNotFoundReason),
        validator: null,
      );
    }
    if (cache.diplomaticPrefixReplaySucceeded == false) {
      return (
        ok: false,
        reject: prefixReplayFailedReason == null
            ? null
            : OrderValidationResult.rejected(prefixReplayFailedReason),
        validator: null,
      );
    }
    final economy = projectEconomyAfterAcceptedBuildAndWorkOrders(player);
    final membership = factionMembershipSnapshot;

    if (cache.postDiplomaticPrefixState == null) {
      final prefixValidator = createProjectedDiplomaticValidator(
        game: game,
        playerId: playerId,
        initialTreasury: economy.treasury,
        factionMembership: membership,
      );
      for (final existing in diplomaticOrders) {
        final result = prefixValidator.validate(
          existing,
          previousRejected: false,
        );
        if (!result.result.isAccepted) {
          cache.diplomaticPrefixReplaySucceeded = false;
          return (
            ok: false,
            reject: prefixReplayFailedReason == null ? null : result.result,
            validator: null,
          );
        }
      }
      cache.diplomaticPrefixReplaySucceeded = true;
      cache.postDiplomaticPrefixState = prefixValidator
          .capturePrefixCheckpoint();
    }

    final checkpoint = cache.postDiplomaticPrefixState!;
    final candidateValidator = DiplomaticOrderValidator.fromPrefixCheckpoint(
      game: game,
      playerId: playerId,
      checkpoint: checkpoint,
      factionMembership: membership,
    );
    return (ok: true, reject: null, validator: candidateValidator);
  }
}
