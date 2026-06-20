/// Accepted-prefix replay validators and economy-projection probe helpers for
/// [IncrementalCandidateValidator] (Refs #2394, #2692 S7, Category B).
///
/// Promoted from the `part of 'incremental_candidate_validator.dart'` fragments
/// `incremental_candidate_validator_prefix_replay.dart` and
/// `incremental_candidate_validator_projection.dart` to a single standalone
/// library with explicit imports (Refs #3543 — de-part-file orders; the
/// extraction-shape policy in `SPEC/program/dart-file-non-comment-line-size.md`
/// § Extraction shape requires standalone libraries rather than part fragments).
///
/// The two extensions stay in one library so their private probe helpers
/// (`_player`, `_ensurePostWorkPrefixState`, etc.) remain shared without
/// widening the package surface; the per-pass memoization slots they read and
/// write live on [IncrementalCandidateValidator.cache]
/// ([IncrementalCandidateValidatorCache]). Behaviour is unchanged from the
/// previous part-fragment caches.
library;

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'incremental_candidate_validator.dart';
import 'order_validators.dart';
import 'unit_type_helpers.dart';
import 'validator_bundle.dart';

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
    if (cache.recruitWorkerPrefixReplaySucceeded == false) {
      return false;
    }
    if (cache.postRecruitWorkerPrefixEconomy == null) {
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
          cache.recruitWorkerPrefixReplaySucceeded = false;
          return false;
        }
      }
      cache.recruitWorkerPrefixReplaySucceeded = true;
      cache.postRecruitWorkerPrefixEconomy = (
        stockpile: prefixValidator.stockpile,
        treasury: prefixValidator.treasury,
        workers: prefixValidator.workers,
      );
    }
    final snap = cache.postRecruitWorkerPrefixEconomy!;
    final candidateValidator = RecruitWorkerOrderValidator.withProjectedEconomy(
      player: player,
      stockpile: Stockpile(quantities: snap.stockpile.copyQuantities()),
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
    if (cache.buildPrefixReplaySucceeded == false) {
      return false;
    }
    final builds =
        basePrefix.buildUnitOrdersByPlayerId[playerId] ??
        const <BuildUnitOrder>[];
    if (cache.postBuildPrefixEconomy == null) {
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
          cache.buildPrefixReplaySucceeded = false;
          return false;
        }
      }
      cache.buildPrefixReplaySucceeded = true;
      cache.postBuildPrefixEconomy = (
        stockpile: prefixValidator.stockpile,
        treasury: prefixValidator.treasury,
        workers: prefixValidator.workers,
      );
    }
    final snap = cache.postBuildPrefixEconomy!;
    final candidateStockpile = Stockpile(
      quantities: snap.stockpile.copyQuantities(),
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
    if (cache.workPrefixReplaySucceeded == false) {
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
      stockpile: Stockpile(quantities: prefix.stockpile.copyQuantities()),
      treasury: prefix.treasury,
      factionMembership: factionMembershipSnapshot,
      initialSeenUnitIds: prefix.seenUnitIds,
    );
    return workValidator
        .validate(candidate, previousRejected: false)
        .isAccepted;
  }

  bool isDiplomaticAccepted(DiplomaticOrder candidate) {
    return _validateDiplomaticCandidate(candidate).isAccepted;
  }

  /// Like [isDiplomaticAccepted] but returns the full [OrderValidationResult]
  /// so UI layers can surface validator rejection text on disabled controls.
  OrderValidationResult probeDiplomaticOrder(DiplomaticOrder candidate) {
    return _validateDiplomaticCandidate(
      candidate,
      playerNotFoundReason: 'Player not found',
      prefixReplayFailedReason: 'Previous invalid diplomatic order in prefix',
    );
  }

  OrderValidationResult _validateDiplomaticCandidate(
    DiplomaticOrder candidate, {
    String? playerNotFoundReason,
    String? prefixReplayFailedReason,
  }) {
    final prepared = _prepareDiplomaticCandidateValidator(
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

  ({bool ok, OrderValidationResult? reject, DiplomaticOrderValidator? validator})
  _prepareDiplomaticCandidateValidator({
    String? playerNotFoundReason,
    String? prefixReplayFailedReason,
  }) {
    final player = _player();
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
    final economy = _projectEconomyAfterAcceptedBuildAndWorkOrders(player);
    final membership = factionMembershipSnapshot;

    if (cache.postDiplomaticPrefixState == null) {
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
          cache.diplomaticPrefixReplaySucceeded = false;
          return (
            ok: false,
            reject: prefixReplayFailedReason == null
                ? null
                : result.result,
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

extension IncrementalCandidateValidatorProjection
    on IncrementalCandidateValidator {
  ({Stockpile stockpile, int treasury}) _projectEconomyAfterAcceptedBuildOrders(
    Player player,
  ) {
    final cached = cache.economyAfterBuildOrders;
    if (cached != null) {
      return cached;
    }
    final buildValidator = BuildOrderValidator.withProjectedEconomy(
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
    final builds =
        basePrefix.buildUnitOrdersByPlayerId[playerId] ??
        const <BuildUnitOrder>[];
    for (final existing in builds) {
      final result = buildValidator.validate(existing, previousRejected: false);
      if (!result.isAccepted) {
        final fallback = (
          stockpile: player.stockpile,
          treasury: player.treasury,
        );
        cache.economyAfterBuildOrders = fallback;
        return fallback;
      }
    }
    final projected = (
      stockpile: buildValidator.stockpile,
      treasury: buildValidator.treasury,
    );
    cache.economyAfterBuildOrders = projected;
    return projected;
  }

  ({Stockpile stockpile, int treasury})
  _projectEconomyAfterAcceptedBuildAndWorkOrders(Player player) {
    final cached = cache.economyAfterBuildAndWorkOrders;
    if (cached != null) {
      return cached;
    }
    final prefix = _ensurePostWorkPrefixState(player);
    if (prefix == null) {
      final afterBuild = _projectEconomyAfterAcceptedBuildOrders(player);
      cache.economyAfterBuildAndWorkOrders = afterBuild;
      return afterBuild;
    }
    final projected = (stockpile: prefix.stockpile, treasury: prefix.treasury);
    cache.economyAfterBuildAndWorkOrders = projected;
    return projected;
  }

  /// Replays accepted work orders in [basePrefix] once per validator instance,
  /// then exposes projected economy + work-order state for candidate probes
  /// and diplomatic projection (Refs #2394, Category B).
  ({
    Stockpile stockpile,
    int treasury,
    Set<String> seenUnitIds,
    Set<String> devExclusive,
  })?
  _ensurePostWorkPrefixState(Player player) {
    if (cache.workPrefixReplaySucceeded == false) {
      return null;
    }
    final cachedState = cache.postWorkPrefixState;
    if (cachedState != null) {
      return cachedState;
    }
    final afterBuild = _projectEconomyAfterAcceptedBuildOrders(player);
    final works =
        basePrefix.workOrdersByPlayerId[playerId] ?? const <WorkOrder>[];
    final baseDev = Set<String>.from(_devExclusiveTiles());
    if (works.isEmpty) {
      final proj = (
        stockpile: Stockpile(
          quantities: afterBuild.stockpile.copyQuantities(),
        ),
        treasury: afterBuild.treasury,
        seenUnitIds: <String>{},
        devExclusive: baseDev,
      );
      cache.workPrefixReplaySucceeded = true;
      cache.postWorkPrefixState = proj;
      return proj;
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
      devExclusiveTiles: baseDev,
      stockpile: afterBuild.stockpile,
      treasury: afterBuild.treasury,
      factionMembership: factionMembershipSnapshot,
    );
    for (final existing in works) {
      final result = workValidator.validate(existing, previousRejected: false);
      if (!result.isAccepted) {
        cache.workPrefixReplaySucceeded = false;
        return null;
      }
    }
    final proj = (
      stockpile: Stockpile(
        quantities: workValidator.stockpile.copyQuantities(),
      ),
      treasury: workValidator.treasury,
      seenUnitIds: {for (final w in works) w.unitId},
      devExclusive: Set<String>.from(baseDev),
    );
    cache.workPrefixReplaySucceeded = true;
    cache.postWorkPrefixState = proj;
    return proj;
  }

  Set<String> _civilianDraftMoveUnitIds() {
    final cached = cache.civilianDraftMoveUnitIds;
    if (cached != null) {
      return cached;
    }
    final ids = <String>{};
    final moves =
        basePrefix.moveOrdersByPlayerId[playerId] ?? const <MoveOrder>[];
    for (final move in moves) {
      final unit = unitsById[move.unitId];
      if (unit != null && unit.tileKey != null && unit.tileKey!.isNotEmpty) {
        ids.add(move.unitId);
      }
    }
    cache.civilianDraftMoveUnitIds = ids;
    return ids;
  }

  Set<String> _devExclusiveTiles() {
    final cached = cache.devExclusiveTiles;
    if (cached != null) {
      return cached;
    }
    final computed = devExclusiveTilesFromWorld(game.worldState, playerId);
    cache.devExclusiveTiles = computed;
    return computed;
  }

  Player? _player() => game.playerById(playerId);
}
