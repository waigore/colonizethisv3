/// Accepted-prefix replay validators for [IncrementalCandidateValidator]
/// (Refs #2394, #2692 S7, Category B).
///
/// Promoted from the `part of 'incremental_candidate_validator.dart'` fragments
/// `incremental_candidate_validator_prefix_replay.dart` and
/// `incremental_candidate_validator_projection.dart` to standalone libraries
/// with explicit imports (Refs #3543 — de-part-file orders).
///
/// Wave 5 slice C splits diplomatic replay and shared economy-projection probes
/// into companion libraries; recruit/build prefix acceptance is table-driven
/// via [ProjectedResourcePrefixReplayConfig].
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'incremental_candidate_validator.dart';
import 'incremental_candidate_validator_replay_shared.dart';
import 'order_validator_factory.dart';
import 'order_validators.dart';
import 'projected_resource_prefix_replay_config.dart';

export 'incremental_candidate_validator_diplomatic_replay.dart';

final _recruitWorkerPrefixReplayConfig =
    ProjectedResourcePrefixReplayConfig<RecruitWorkerOrder,
        RecruitWorkerOrderValidator>(
  existingOrders: (validator) =>
      validator.basePrefix.recruitWorkerOrdersByPlayerId[validator.playerId] ??
      const <RecruitWorkerOrder>[],
  readPrefixReplaySucceeded: (cache) => cache.recruitWorkerPrefixReplaySucceeded,
  readCachedLedgers: (cache) => cache.postRecruitWorkerPrefixEconomy,
  writePrefixReplaySucceeded: (cache, value) {
    cache.recruitWorkerPrefixReplaySucceeded = value;
  },
  writeCachedLedgers: (cache, ledgers) {
    cache.postRecruitWorkerPrefixEconomy = ledgers;
  },
  createValidator: (player, ledgers, _) =>
      createProjectedRecruitWorkerValidator(
        player: player,
        stockpile: ledgers.stockpile,
        treasury: ledgers.treasury,
        workerPool: ledgers.workers,
      ),
  readLedgers: (validator) => (
    stockpile: validator.stockpile,
    treasury: validator.treasury,
    workers: validator.workers,
  ),
  validate: (validator, order) =>
      validator.validate(order, previousRejected: false),
);

final _buildPrefixReplayConfig =
    ProjectedResourcePrefixReplayConfig<BuildUnitOrder, BuildOrderValidator>(
  existingOrders: (validator) =>
      validator.basePrefix.buildUnitOrdersByPlayerId[validator.playerId] ??
      const <BuildUnitOrder>[],
  readPrefixReplaySucceeded: (cache) => cache.buildPrefixReplaySucceeded,
  readCachedLedgers: (cache) => cache.postBuildPrefixEconomy,
  writePrefixReplaySucceeded: (cache, value) {
    cache.buildPrefixReplaySucceeded = value;
  },
  writeCachedLedgers: (cache, ledgers) {
    cache.postBuildPrefixEconomy = ledgers;
  },
  createValidator: (player, ledgers, validator) =>
      createProjectedBuildValidator(
        game: validator.game,
        player: player,
        stockpile: ledgers.stockpile,
        treasury: ledgers.treasury,
        workerPool: ledgers.workers,
      ),
  readLedgers: (validator) => (
    stockpile: validator.stockpile,
    treasury: validator.treasury,
    workers: validator.workers,
  ),
  validate: (validator, order) =>
      validator.validate(order, previousRejected: false),
);

extension IncrementalCandidateValidatorPrefixReplay
    on IncrementalCandidateValidator {
  /// Validates a [RecruitWorkerOrder] candidate against accepted recruit
  /// worker orders in [basePrefix] (Refs #2692 S7,
  /// SPEC/program/order-suggestions.md § Recruit worker orders).
  ///
  /// Mirrors the order-engine recruit worker phase: existing recruit orders
  /// in [basePrefix] are replayed in submission order against the player's
  /// snapshot worker pool / stockpile / treasury so the candidate sees the
  /// post-prefix peasant reservation ledger.
  bool isRecruitWorkerAccepted(RecruitWorkerOrder candidate) {
    final player = replayProbePlayer();
    if (player == null) return false;
    return acceptIncrementalProjectedResourceCandidate(
      validator: this,
      player: player,
      config: _recruitWorkerPrefixReplayConfig,
      candidate: candidate,
    );
  }

  bool isBuildAccepted(BuildUnitOrder candidate) {
    final player = replayProbePlayer();
    if (player == null) return false;
    return acceptIncrementalProjectedResourceCandidate(
      validator: this,
      player: player,
      config: _buildPrefixReplayConfig,
      candidate: candidate,
    );
  }

  bool isWorkAccepted(WorkOrder candidate) {
    final player = replayProbePlayer();
    if (player == null) return false;
    if (cache.workPrefixReplaySucceeded == false) {
      return false;
    }
    final prefix = ensurePostWorkPrefixState(player);
    if (prefix == null) {
      return false;
    }
    final workValidator = workOrderValidatorForReplayProbe(
      player: player,
      stockpile: Stockpile(quantities: prefix.stockpile.copyQuantities()),
      treasury: prefix.treasury,
      devExclusiveTiles: Set<String>.from(prefix.devExclusive),
      initialSeenUnitIds: prefix.seenUnitIds,
    );
    return workValidator
        .validate(candidate, previousRejected: false)
        .isAccepted;
  }
}
