part of 'incremental_candidate_validator.dart';

// Economy projection and work-prefix replay helpers for incremental candidate
// validation (Refs #2394 Category B). Split out of
// incremental_candidate_validator.dart by concern to keep each library file
// at or below the repo non-comment line limit; shares the parent library's
// private scope via `part`.

extension IncrementalCandidateValidatorProjection
    on IncrementalCandidateValidator {
  ({Stockpile stockpile, int treasury}) _projectEconomyAfterAcceptedBuildOrders(
    Player player,
  ) {
    final cached = _cachedEconomyAfterBuildOrders;
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
        _cachedEconomyAfterBuildOrders = fallback;
        return fallback;
      }
    }
    final projected = (
      stockpile: buildValidator.stockpile,
      treasury: buildValidator.treasury,
    );
    _cachedEconomyAfterBuildOrders = projected;
    return projected;
  }

  ({Stockpile stockpile, int treasury})
  _projectEconomyAfterAcceptedBuildAndWorkOrders(Player player) {
    final cached = _cachedEconomyAfterBuildAndWorkOrders;
    if (cached != null) {
      return cached;
    }
    final prefix = _ensurePostWorkPrefixState(player);
    if (prefix == null) {
      final afterBuild = _projectEconomyAfterAcceptedBuildOrders(player);
      _cachedEconomyAfterBuildAndWorkOrders = afterBuild;
      return afterBuild;
    }
    final projected = (stockpile: prefix.stockpile, treasury: prefix.treasury);
    _cachedEconomyAfterBuildAndWorkOrders = projected;
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
    if (_cachedWorkPrefixReplaySucceeded == false) {
      return null;
    }
    final cachedState = _cachedPostWorkPrefixState;
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
      _cachedWorkPrefixReplaySucceeded = true;
      _cachedPostWorkPrefixState = proj;
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
      factionMembership: _factionMembership(),
    );
    for (final existing in works) {
      final result = workValidator.validate(existing, previousRejected: false);
      if (!result.isAccepted) {
        _cachedWorkPrefixReplaySucceeded = false;
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
    _cachedWorkPrefixReplaySucceeded = true;
    _cachedPostWorkPrefixState = proj;
    return proj;
  }

  Set<String> _civilianDraftMoveUnitIds() {
    final cached = _cachedCivilianDraftMoveUnitIds;
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
    _cachedCivilianDraftMoveUnitIds = ids;
    return ids;
  }

  Set<String> _devExclusiveTiles() {
    final cached = _cachedDevExclusiveTiles;
    if (cached != null) {
      return cached;
    }
    final computed = devExclusiveTilesFromWorld(game.worldState, playerId);
    _cachedDevExclusiveTiles = computed;
    return computed;
  }

  Player? _player() => game.playerById(playerId);
}
