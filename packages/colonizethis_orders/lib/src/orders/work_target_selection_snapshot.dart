import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'incremental_candidate_validator.dart';

/// Inputs for populating per-player work-target tile selection caches.
///
/// SPEC/program/order-suggestions.md — cache contract; Refs #2277 (worker reuse).
class WorkTargetSelectionSnapshot {
  const WorkTargetSelectionSnapshot({
    required this.game,
    required this.playerId,
    required this.playerView,
    required this.topology,
    required this.currentOrders,
    required this.tileMapByRegion,
    this.sharedCandidateValidator,
    this.playerOwnedProvinceIds,
  });

  final Game game;
  final String playerId;
  final PlayerView playerView;
  final MapTopology topology;
  final Orders currentOrders;
  final Map<String, TileMapResult>? tileMapByRegion;

  /// Prefixed province ids owned by [playerId]. When set on a snapshot passed to
  /// [PerPlayerWorkTargetSelectionCache.refresh], population reuses this set
  /// instead of rescanning [allProvinces] per unit × work target (Refs #2394).
  final Set<String>? playerOwnedProvinceIds;

  /// When non-null on the **output** snapshot passed to population strategies,
  /// all default population paths reuse this instance instead of rebuilding
  /// [IncrementalCandidateValidator.forPlayer] per work target (Refs #2394).
  ///
  /// Callers may also set this on the **input** snapshot passed to [refresh];
  /// when set, [refresh] reuses that validator instead of constructing one
  /// (must match the same `(game, topology, playerId, currentOrders, …)` tuple).
  final IncrementalCandidateValidator? sharedCandidateValidator;
}

typedef WorkTargetSelectionPopulationStrategy =
    Set<String> Function(WorkTargetSelectionSnapshot snapshot);
