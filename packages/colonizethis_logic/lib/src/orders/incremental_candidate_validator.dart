import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../diplomacy/diplomacy_resolver.dart';
import '../economy/economy_riches_to_treasury.dart';
import '../world/player_view.dart';
import '../world/unit_lookup.dart';
import 'order_validators.dart';
import 'unit_type_helpers.dart';
import 'validator_bundle.dart';

/// Incremental candidate validation primitive used by the order suggestion API
/// to evaluate single candidates against an already-accepted `basePrefix`
/// without running full-pass `validatePlayerOrdersWithContext`.
///
/// Spec: SPEC/program/order-suggestions.md § Incremental candidate validation;
/// SPEC/program/order-engine.md § Validation (candidate-probe context).
///
/// Equivalence: For any `basePrefix` whose every order is `accepted` by
/// `validatePlayerOrdersWithContext` for the player, the accept/reject decision
/// returned by these helpers for a candidate `c` is identical to running the
/// full-pass validator over `basePrefix ⊕ c` and inspecting `c`'s result.
/// This file covers all candidate types used by suggestion probes, including
/// stateful build/work/diplomatic validators via accepted-prefix replay.
class IncrementalCandidateValidator {
  IncrementalCandidateValidator._({
    required this.game,
    required this.topology,
    required this.playerId,
    required this.basePrefix,
    required this.view,
    required this.unitsById,
    required this.diplomaticOrders,
    required this.tileMapByRegion,
    this.prefetchedFactionMembership,
  });

  /// Builds a validator bound to the given `basePrefix` and player. Reuse one
  /// instance per suggestion pass to amortize the per-player view/unit lookup
  /// build cost across many candidate probes (the AI suggestion API enumerates
  /// many candidates per call).
  ///
  /// When the caller already has a `PlayerView` and/or units-by-id map computed
  /// for the same `(game, topology, playerId)` tuple, it may pass them via
  /// [view] / [unitsById] to skip the embedded `buildPlayerView` and
  /// `unitsByIdFromWorld` scans (Refs #2394, `SPEC/program/order-suggestions.md`
  /// § Throughput bounds). The shared instances must be built from the **same**
  /// inputs as the validator; behavior is undefined otherwise.
  factory IncrementalCandidateValidator.forPlayer({
    required Game game,
    required MapTopology topology,
    required String playerId,
    required Orders basePrefix,
    Map<String, TileMapResult>? tileMapByRegion,
    PlayerView? view,
    Map<String, Unit>? unitsById,
    /// When callers rebuild this validator for many `basePrefix` snapshots over
    /// the same [game] (for example simple-heuristic iterations), supplying the
    /// membership snapshot avoids repeated `DiplomacyFactionMembership.from`
    /// work. Must remain valid for [game] for the validator lifetime (Refs #2394).
    DiplomacyFactionMembership? factionMembership,
  }) {
    assert(
      view == null || view.playerId == playerId,
      'shared PlayerView playerId must match validator playerId',
    );
    final actualView = view ?? buildPlayerView(game, topology, playerId);
    final actualUnitsById = unitsById ?? unitsByIdFromWorld(game.worldState);
    final diplomaticOrders =
        basePrefix.diplomaticOrdersByPlayerId[playerId] ??
        const <DiplomaticOrder>[];
    return IncrementalCandidateValidator._(
      game: game,
      topology: topology,
      playerId: playerId,
      basePrefix: basePrefix,
      view: actualView,
      unitsById: actualUnitsById,
      diplomaticOrders: diplomaticOrders,
      tileMapByRegion: tileMapByRegion,
      prefetchedFactionMembership: factionMembership,
    );
  }

  /// Rebinds this validator to a new [basePrefix] while reusing [view],
  /// [unitsById], and [prefetchedFactionMembership] from the same suggestion
  /// pass (Refs #2394 — simple-heuristic iteration loops).
  IncrementalCandidateValidator forBasePrefix(Orders basePrefix) {
    return IncrementalCandidateValidator.forPlayer(
      game: game,
      topology: topology,
      playerId: playerId,
      basePrefix: basePrefix,
      tileMapByRegion: tileMapByRegion,
      view: view,
      unitsById: unitsById,
      factionMembership: prefetchedFactionMembership,
    );
  }

  final Game game;
  final MapTopology topology;
  final String playerId;
  final Orders basePrefix;
  final PlayerView view;
  final Map<String, Unit> unitsById;
  final List<DiplomaticOrder> diplomaticOrders;
  final Map<String, TileMapResult>? tileMapByRegion;
  final DiplomacyFactionMembership? prefetchedFactionMembership;
  Set<String>? _cachedDevExclusiveTiles;
  Set<String>? _cachedCivilianDraftMoveUnitIds;
  ({Stockpile stockpile, int treasury})? _cachedEconomyAfterBuildOrders;
  ({Stockpile stockpile, int treasury})? _cachedEconomyAfterBuildAndWorkOrders;

  /// When [false], existing work orders in [basePrefix] failed incremental
  /// replay; every [isWorkAccepted] probe must reject (Refs #2394).
  bool? _cachedWorkPrefixReplaySucceeded;
  ({Stockpile stockpile, int treasury, Set<String> seenUnitIds, Set<String>
      devExclusive})? _cachedPostWorkPrefixState;

  /// When [false], existing build orders in [basePrefix] failed incremental
  /// replay; every [isBuildAccepted] probe must reject (Refs #2394).
  bool? _cachedBuildPrefixReplaySucceeded;
  ({Stockpile stockpile, int treasury, WorkerPool workers})?
  _cachedPostBuildPrefixEconomy;
  Map<String, Army>? _cachedArmiesById;
  DiplomacyFactionMembership? _cachedFactionMembership;
  NavalOrderValidator? _cachedNavalOrderValidator;

  /// When [false], existing diplomatic orders in [basePrefix] failed incremental
  /// replay; every [isDiplomaticAccepted] probe must reject (Refs #2394).
  bool? _cachedDiplomaticPrefixReplaySucceeded;
  DiplomaticPrefixCheckpoint? _cachedPostDiplomaticPrefixState;

  DiplomacyFactionMembership _factionMembership() {
    final pre = prefetchedFactionMembership;
    if (pre != null) {
      return pre;
    }
    final cached = _cachedFactionMembership;
    if (cached != null) {
      return cached;
    }
    final built = DiplomacyFactionMembership.from(game);
    _cachedFactionMembership = built;
    return built;
  }

  /// Faction GP/minor/tribe snapshot aligned with this validator (Refs #2394).
  ///
  /// Callers that run work-target tile prefilters before incremental probes may
  /// reuse this so [rawCandidateTilesForWorkTarget] does not rebuild membership
  /// separately from the same [game] state.
  DiplomacyFactionMembership get factionMembershipSnapshot =>
      _factionMembership();

  bool isMoveAccepted(MoveOrder candidate) {
    const validator = MoveValidator();
    final standalone = validator
        .validate(
          candidate,
          game,
          playerId,
          unitsById,
          diplomaticOrders,
          view,
          topology,
          previousRejected: false,
          factionMembership: _factionMembership(),
        )
        .isAccepted;
    if (!standalone) return false;

    // Cross-cutting effect: if the candidate move would add the unit to
    // [civilianDraftMoveUnitIds] (i.e. the unit has a non-empty tileKey),
    // any existing [WorkOrder] for the same unit in [basePrefix] becomes
    // rejected via the move XOR work rule (`kReasonCivilianMoveXorWorkOrder`
    // in [WorkOrderValidator]). The full-pass approach exposes this as a
    // cascade-driven rejection in `validatePlayerOrdersWithContext`'s last
    // result; mirror it here so the incremental decision matches the
    // full-pass `addMoveOrderWithContext(...).isAccepted` contract.
    final unit = unitsById[candidate.unitId];
    final unitTileKey = unit?.tileKey;
    if (unitTileKey == null || unitTileKey.isEmpty) {
      return true;
    }
    final works =
        basePrefix.workOrdersByPlayerId[playerId] ?? const <WorkOrder>[];
    for (final w in works) {
      if (w.unitId == candidate.unitId) return false;
    }
    return true;
  }

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
          armiesById: _armiesById(),
          factionMembership: _factionMembership(),
        )
        .isAccepted;
  }

  /// Lazy O(1) army lookup map. Cached for the lifetime of this validator
  /// (single suggestion pass). Avoids rebuilding `armies.where(id == ...)` per
  /// candidate probe (Refs #2394, SPEC/program/order-suggestions.md).
  Map<String, Army> _armiesById() {
    final cached = _cachedArmiesById;
    if (cached != null) {
      return cached;
    }
    final computed = <String, Army>{
      for (final a in game.worldState.armies) a.id: a,
    };
    _cachedArmiesById = computed;
    return computed;
  }

  /// One [NavalOrderValidator] per incremental pass: it snapshots fleet ids
  /// once; reuse avoids rebuilding the fleet map on every naval probe (Refs
  /// #2394, SPEC/program/order-suggestions.md).
  NavalOrderValidator _navalOrderValidator() {
    final cached = _cachedNavalOrderValidator;
    if (cached != null) {
      return cached;
    }
    final built = NavalOrderValidator(
      game: game,
      topology: topology,
      playerId: playerId,
    );
    _cachedNavalOrderValidator = built;
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
        treasury: player.treasury +
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
      treasury: snap.treasury +
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
      view: view,
      topology: topology,
      unitsById: unitsById,
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
      _cachedPostDiplomaticPrefixState =
          prefixValidator.capturePrefixCheckpoint();
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
      treasury: player.treasury +
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
  ({Stockpile stockpile, int treasury, Set<String> seenUnitIds, Set<String>
      devExclusive})? _ensurePostWorkPrefixState(Player player) {
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
          quantities: Map<String, int>.from(afterBuild.stockpile.quantities),
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
      view: view,
      topology: topology,
      unitsById: unitsById,
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
        quantities: Map<String, int>.from(workValidator.stockpile.quantities),
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
