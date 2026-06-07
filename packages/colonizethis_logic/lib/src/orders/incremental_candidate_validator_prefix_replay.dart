part of 'incremental_candidate_validator.dart';

// Accepted-prefix replay validators for build / work / recruit / diplomatic
// candidate probes (Refs #2394, #2692 S7). Split out of
// incremental_candidate_validator.dart by concern to keep each library file
// at or below the repo non-comment line limit; shares the parent library's
// private scope via `part`.

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
    final player = _player();
    if (player == null) return false;
    if (_cachedRecruitWorkerPrefixReplaySucceeded == false) {
      return false;
    }
    if (_cachedPostRecruitWorkerPrefixEconomy == null) {
      final prefixValidator = RecruitWorkerOrderValidator.withProjectedEconomy(
        player: player,
        stockpile: player.stockpile,
        treasury: player.treasury,
        workerPool: player.workerPool,
      );
      final existing =
          basePrefix.recruitWorkerOrdersByPlayerId[playerId] ??
          const <RecruitWorkerOrder>[];
      for (final order in existing) {
        final result = prefixValidator.validate(order, previousRejected: false);
        if (!result.isAccepted) {
          _cachedRecruitWorkerPrefixReplaySucceeded = false;
          return false;
        }
      }
      _cachedRecruitWorkerPrefixReplaySucceeded = true;
      _cachedPostRecruitWorkerPrefixEconomy = (
        stockpile: prefixValidator.stockpile,
        treasury: prefixValidator.treasury,
        workers: prefixValidator.workers,
      );
    }
    final snap = _cachedPostRecruitWorkerPrefixEconomy!;
    final candidateValidator = RecruitWorkerOrderValidator.withProjectedEconomy(
      player: player,
      stockpile: Stockpile(
        quantities: Map<String, int>.from(snap.stockpile.quantities),
      ),
      treasury: snap.treasury,
      workerPool: snap.workers,
    );
    return candidateValidator
        .validate(candidate, previousRejected: false)
        .isAccepted;
  }

  bool isBuildAccepted(BuildUnitOrder candidate) {
    final player = _player();
    if (player == null) return false;
    if (_cachedBuildPrefixReplaySucceeded == false) {
      return false;
    }
    final builds =
        basePrefix.buildUnitOrdersByPlayerId[playerId] ??
        const <BuildUnitOrder>[];
    if (_cachedPostBuildPrefixEconomy == null) {
      final prefixValidator = BuildOrderValidator.withProjectedEconomy(
        game: game,
        player: player,
        stockpile: player.stockpile,
        treasury:
            player.treasury +
            pendingRichesTreasuryDelta(
              stockpile: player.stockpile,
              richesCashMultiplier: game.richesCashMultiplier,
            ),
        workerPool: player.workerPool,
      );
      for (final existing in builds) {
        final result = prefixValidator.validate(
          existing,
          previousRejected: false,
        );
        if (!result.isAccepted) {
          _cachedBuildPrefixReplaySucceeded = false;
          return false;
        }
      }
      _cachedBuildPrefixReplaySucceeded = true;
      _cachedPostBuildPrefixEconomy = (
        stockpile: prefixValidator.stockpile,
        treasury: prefixValidator.treasury,
        workers: prefixValidator.workers,
      );
    }
    final snap = _cachedPostBuildPrefixEconomy!;
    final candidateStockpile = Stockpile(
      quantities: Map<String, int>.from(snap.stockpile.quantities),
    );
    final candidateValidator = BuildOrderValidator.withProjectedEconomy(
      game: game,
      player: player,
      stockpile: candidateStockpile,
      treasury:
          snap.treasury +
          pendingRichesTreasuryDelta(
            stockpile: candidateStockpile,
            richesCashMultiplier: game.richesCashMultiplier,
          ),
      workerPool: snap.workers,
    );
    return candidateValidator
        .validate(candidate, previousRejected: false)
        .isAccepted;
  }

  bool isWorkAccepted(WorkOrder candidate) {
    final player = _player();
    if (player == null) return false;
    if (_cachedWorkPrefixReplaySucceeded == false) {
      return false;
    }
    final prefix = _ensurePostWorkPrefixState(player);
    if (prefix == null) {
      return false;
    }
    final workValidator = createWorkOrderValidator(
      game: game,
      player: player,
      playerId: playerId,
      resolution: (
        view: view,
        unitsById: unitsById,
        provinceById: view.provincesById,
      ),
      topology: topology,
      diplomaticOrders: diplomaticOrders,
      tileMapByRegion: tileMapByRegion,
      civilianDraftMoveUnitIds: _civilianDraftMoveUnitIds(),
      devExclusiveTiles: Set<String>.from(prefix.devExclusive),
      stockpile: Stockpile(
        quantities: Map<String, int>.from(prefix.stockpile.quantities),
      ),
      treasury: prefix.treasury,
      factionMembership: _factionMembership(),
      initialSeenUnitIds: prefix.seenUnitIds,
    );
    return workValidator
        .validate(candidate, previousRejected: false)
        .isAccepted;
  }

  bool isDiplomaticAccepted(DiplomaticOrder candidate) {
    final player = _player();
    if (player == null) return false;
    if (_cachedDiplomaticPrefixReplaySucceeded == false) {
      return false;
    }
    final economy = _projectEconomyAfterAcceptedBuildAndWorkOrders(player);
    final membership = _factionMembership();

    if (_cachedPostDiplomaticPrefixState == null) {
      final prefixValidator = DiplomaticOrderValidator(
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
          _cachedDiplomaticPrefixReplaySucceeded = false;
          return false;
        }
      }
      _cachedDiplomaticPrefixReplaySucceeded = true;
      _cachedPostDiplomaticPrefixState = prefixValidator
          .capturePrefixCheckpoint();
    }

    final checkpoint = _cachedPostDiplomaticPrefixState!;
    final candidateValidator = DiplomaticOrderValidator.fromPrefixCheckpoint(
      game: game,
      playerId: playerId,
      checkpoint: checkpoint,
      factionMembership: membership,
    );
    return candidateValidator
        .validate(candidate, previousRejected: false)
        .result
        .isAccepted;
  }
}
