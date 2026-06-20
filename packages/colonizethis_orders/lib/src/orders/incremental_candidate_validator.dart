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
/// Prefix-replay validators and economy-projection probe helpers live in the
/// standalone companion library `incremental_candidate_validator_replay.dart`
/// (re-exported below) so each file stays under the repo file-size policy
/// (`SPEC/program/dart-file-non-comment-line-size.md`) while declaring explicit
/// imports rather than inheriting this library's private scope via `part`
/// fragments (Refs #3543 — de-part-file orders; extraction-shape policy
/// § Extraction shape). The shared per-pass memoization slots live in
/// [IncrementalCandidateValidatorCache] (the [cache] field) so the companion
/// library can read and write them through the validator's public surface.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'incremental_candidate_validator_cache.dart';
import 'order_resolution_context.dart';
import 'order_validators.dart';

export 'incremental_candidate_validator_cache.dart';
export 'incremental_candidate_validator_replay.dart';

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

  /// Per-pass memoization slots shared with the replay/projection probe helpers
  /// in `incremental_candidate_validator_replay.dart`. A fresh holder per
  /// validator instance preserves the previous per-instance caching behaviour
  /// (Refs #2394, #2692 S7; #3543 de-part-file).
  final IncrementalCandidateValidatorCache cache =
      IncrementalCandidateValidatorCache();

  /// Per-pass [OrderResolutionContext] reused across move / work / build /
  /// recruit / naval / diplomatic probe sites that already accept the record.
  /// Mirrors the per-pass caching of [factionMembershipSnapshot] so a single
  /// suggestion pass does not allocate one record per candidate probe
  /// (Refs #2836 AC 3; SPEC/program/logic-validator-units-params.md).
  OrderResolutionContext _orderResolutionContext() {
    final cached = cache.orderResolutionContext;
    if (cached != null) {
      return cached;
    }
    final built = orderResolutionContextFromView(
      view,
      game,
      unitsById: unitsById,
    );
    cache.orderResolutionContext = built;
    return built;
  }

  DiplomacyFactionMembership _factionMembership() {
    final pre = prefetchedFactionMembership;
    if (pre != null) {
      return pre;
    }
    final cached = cache.factionMembership;
    if (cached != null) {
      return cached;
    }
    final built = DiplomacyFactionMembership.from(game);
    cache.factionMembership = built;
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
          previousRejected: false,
          armiesById: _armiesById(),
          factionMembership: _factionMembership(),
        )
        .isAccepted;
  }

  /// Lazy O(1) army lookup map. Cached for the lifetime of this validator
  /// (single suggestion pass). Avoids rebuilding `armies.where(id == ...)` per
  /// candidate probe (Refs #2394, SPEC/program/order-suggestions.md).
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

  /// One [NavalOrderValidator] per incremental pass: it snapshots fleet ids
  /// once; reuse avoids rebuilding the fleet map on every naval probe (Refs
  /// #2394, SPEC/program/order-suggestions.md).
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
