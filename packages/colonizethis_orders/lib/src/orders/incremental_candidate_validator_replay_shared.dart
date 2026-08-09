/// Shared economy-projection and work-prefix probe helpers for incremental
/// candidate replay libraries (Refs #4109 wave 5 slice C).
///
/// Public extension methods replace the previous library-private `_player` /
/// `_ensurePostWorkPrefixState` helpers so diplomatic, prefix-replay, and
/// projection extensions can share one implementation without `part of`
/// coupling.
library;

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'incremental_candidate_validator.dart';
import 'order_validator_factory.dart';
import 'order_validators.dart';
import 'projected_economy_prefix_replay.dart';
import 'unit_type_helpers.dart';

extension IncrementalCandidateValidatorReplayShared
    on IncrementalCandidateValidator {
  Player? replayProbePlayer() => game.playerById(playerId);

  ({Stockpile stockpile, int treasury}) projectEconomyAfterAcceptedBuildOrders(
    Player player,
  ) {
    final cached = cache.economyAfterBuildOrders;
    if (cached != null) {
      return cached;
    }
    final builds =
        basePrefix.buildUnitOrdersByPlayerId[playerId] ??
        const <BuildUnitOrder>[];
    bool? prefixReplaySucceeded;
    ProjectedResourceLedgers? cachedLedgers;
    final snap = ensureProjectedResourcePrefixReplay<BuildUnitOrder,
        BuildOrderValidator>(
      prefixReplaySucceeded: prefixReplaySucceeded,
      cachedLedgers: cachedLedgers,
      setPrefixReplaySucceeded: (value) => prefixReplaySucceeded = value,
      setCachedLedgers: (ledgers) => cachedLedgers = ledgers,
      existingOrders: builds,
      createPrefixValidator: () => createProjectedBuildValidator(
        game: game,
        player: player,
        stockpile: player.stockpile,
        treasury: player.treasury,
        workerPool: player.workerPool,
      ),
      validate: (validator, order) =>
          validator.validate(order, previousRejected: false),
      readLedgers: (validator) => (
        stockpile: validator.stockpile,
        treasury: validator.treasury,
        workers: validator.workers,
      ),
    );
    if (snap == null) {
      final fallback = (
        stockpile: player.stockpile,
        treasury: player.treasury,
      );
      cache.economyAfterBuildOrders = fallback;
      return fallback;
    }
    final projected = (stockpile: snap.stockpile, treasury: snap.treasury);
    cache.economyAfterBuildOrders = projected;
    return projected;
  }

  ({Stockpile stockpile, int treasury})
  projectEconomyAfterAcceptedBuildAndWorkOrders(Player player) {
    final cached = cache.economyAfterBuildAndWorkOrders;
    if (cached != null) {
      return cached;
    }
    final prefix = ensurePostWorkPrefixState(player);
    if (prefix == null) {
      final afterBuild = projectEconomyAfterAcceptedBuildOrders(player);
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
  ensurePostWorkPrefixState(Player player) {
    if (cache.workPrefixReplaySucceeded == false) {
      return null;
    }
    final cachedState = cache.postWorkPrefixState;
    if (cachedState != null) {
      return cachedState;
    }
    final afterBuild = projectEconomyAfterAcceptedBuildOrders(player);
    final works =
        basePrefix.workOrdersByPlayerId[playerId] ?? const <WorkOrder>[];
    final baseDev = Set<String>.from(replayDevExclusiveTiles());
    if (works.isEmpty) {
      final proj = (
        stockpile: Stockpile(quantities: afterBuild.stockpile.copyQuantities()),
        treasury: afterBuild.treasury,
        seenUnitIds: <String>{},
        devExclusive: baseDev,
      );
      cache.workPrefixReplaySucceeded = true;
      cache.postWorkPrefixState = proj;
      return proj;
    }
    final workValidator = workOrderValidatorForReplayProbe(
      player: player,
      stockpile: afterBuild.stockpile,
      treasury: afterBuild.treasury,
      devExclusiveTiles: baseDev,
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

  Set<String> replayCivilianDraftMoveUnitIds() {
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

  /// Shared work-validator construction for prefix replay and candidate probes
  /// (Refs #3971 — 2+ call sites across replay libraries).
  WorkOrderValidator workOrderValidatorForReplayProbe({
    required Player player,
    required Stockpile stockpile,
    required int treasury,
    required Set<String> devExclusiveTiles,
    Set<String> initialSeenUnitIds = const <String>{},
  }) {
    return createWorkOrderValidator(
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
      civilianDraftMoveUnitIds: replayCivilianDraftMoveUnitIds(),
      devExclusiveTiles: devExclusiveTiles,
      stockpile: stockpile,
      treasury: treasury,
      factionMembership: factionMembershipSnapshot,
      initialSeenUnitIds: initialSeenUnitIds,
    );
  }

  Set<String> replayDevExclusiveTiles() {
    final cached = cache.devExclusiveTiles;
    if (cached != null) {
      return cached;
    }
    final computed = devExclusiveTilesFromWorld(game.worldState, playerId);
    cache.devExclusiveTiles = computed;
    return computed;
  }
}
