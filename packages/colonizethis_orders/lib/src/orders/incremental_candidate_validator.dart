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
///
/// Prefix-replay validators and economy-projection helpers live in `part of`
/// concern files (`incremental_candidate_validator_prefix_replay.dart`,
/// `incremental_candidate_validator_projection.dart`) to keep each file below
/// the repo file-size policy (`SPEC/program/dart-file-non-comment-line-size.md`);
/// they share this library's private scope so behaviour is unchanged (Refs
/// #3290 Phase 0 file decomposition).
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/src/game_player_lookup.dart';
import 'package:colonizethis_diplomacy/src/diplomacy/diplomacy_resolver.dart';
import 'package:colonizethis_economy/src/economy/economy_riches_to_treasury.dart';
import 'package:colonizethis_world/src/world/player_view.dart';
import 'order_resolution_context.dart';
import 'order_validation_result.dart';
import 'order_validators.dart';
import 'unit_type_helpers.dart';
import 'validator_bundle.dart';

part 'incremental_candidate_validator_prefix_replay.dart';
part 'incremental_candidate_validator_projection.dart';

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
  /// When the caller already built [resolution] for this suggestion pass, pass
  /// it to skip embedded `buildPlayerView` and unit-map scans (Refs #2394,
  /// #2836; `SPEC/program/order-suggestions.md` § Throughput bounds). The
  /// shared instance must be built from the **same** inputs as the validator;
  /// behavior is undefined otherwise.
  factory IncrementalCandidateValidator.forPlayer({
    required Game game,
    required MapTopology topology,
    required String playerId,
    required Orders basePrefix,
    Map<String, TileMapResult>? tileMapByRegion,
    OrderResolutionContext? resolution,

    /// When callers rebuild this validator for many `basePrefix` snapshots over
    /// the same [game] (for example simple-heuristic iterations), supplying the
    /// membership snapshot avoids repeated `DiplomacyFactionMembership.from`
    /// work. Must remain valid for [game] for the validator lifetime (Refs #2394).
    DiplomacyFactionMembership? factionMembership,
  }) {
    final ctx =
        resolution ??
        buildOrderResolutionContext(
          game: game,
          topology: topology,
          playerId: playerId,
        );
    assert(
      ctx.view.playerId == playerId,
      'OrderResolutionContext view playerId must match validator playerId',
    );
    final actualView = ctx.view;
    final actualUnitsById = ctx.unitsById;
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
      resolution: (
        view: view,
        unitsById: unitsById,
        provinceById: view.provincesById,
      ),
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
  ({
    Stockpile stockpile,
    int treasury,
    Set<String> seenUnitIds,
    Set<String> devExclusive,
  })?
  _cachedPostWorkPrefixState;

  /// When [false], existing build orders in [basePrefix] failed incremental
  /// replay; every [isBuildAccepted] probe must reject (Refs #2394).
  bool? _cachedBuildPrefixReplaySucceeded;
  ({Stockpile stockpile, int treasury, WorkerPool workers})?
  _cachedPostBuildPrefixEconomy;

  /// When [false], existing recruit worker orders in [basePrefix] failed
  /// incremental replay; every [isRecruitWorkerAccepted] probe must reject
  /// (Refs #2692 S7).
  bool? _cachedRecruitWorkerPrefixReplaySucceeded;
  ({Stockpile stockpile, int treasury, WorkerPool workers})?
  _cachedPostRecruitWorkerPrefixEconomy;
  Map<String, Army>? _cachedArmiesById;
  DiplomacyFactionMembership? _cachedFactionMembership;
  NavalOrderValidator? _cachedNavalOrderValidator;
  OrderResolutionContext? _cachedOrderResolutionContext;

  /// Per-pass [OrderResolutionContext] reused across move / work / build /
  /// recruit / naval / diplomatic probe sites that already accept the record.
  /// Mirrors the per-pass caching of [_factionMembership] and
  /// [_armiesById] so a single suggestion pass does not allocate one record
  /// per candidate probe (Refs #2836 AC 3;
  /// SPEC/program/logic-validator-units-params.md).
  OrderResolutionContext _orderResolutionContext() {
    final cached = _cachedOrderResolutionContext;
    if (cached != null) {
      return cached;
    }
    final built = orderResolutionContextFromView(
      view,
      game,
      unitsById: unitsById,
    );
    _cachedOrderResolutionContext = built;
    return built;
  }

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
          _orderResolutionContext(),
          diplomaticOrders,
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
}
