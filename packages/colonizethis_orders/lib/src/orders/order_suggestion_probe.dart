import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'incremental_candidate_validator.dart';
import 'order_resolution_context.dart';
import 'order_suggestion_probe_validator.dart';
export 'order_suggestion_probe_validator.dart';

bool isMoveOrderAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders baseOrders,
  MoveOrder candidate, {
  IncrementalCandidateValidator? sharedCandidateValidator,
  OrderResolutionContext? resolution,
  DiplomacyFactionMembership? factionMembership,
}) {
  // Stateless candidate-probe path: validate the candidate against an
  // already-accepted [baseOrders] without re-running full-pass
  // [validatePlayerOrdersWithContext]. SPEC/program/order-suggestions.md
  // § Incremental candidate validation; SPEC/program/order-engine.md
  // § Validation (candidate-probe context). Refs #2237.
  return probeOrderAccepted<MoveOrder>(
    game: game,
    topology: topology,
    playerId: playerId,
    baseOrders: baseOrders,
    candidate: candidate,
    resolution: resolution,
    factionMembership: factionMembership,
    sharedCandidateValidator: sharedCandidateValidator,
    probeWithValidator: (validator, c) => validator.isMoveAccepted(c),
  );
}

bool isArmyMoveOrderAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders baseOrders,
  ArmyMoveOrder candidate, {
  IncrementalCandidateValidator? sharedCandidateValidator,
  OrderResolutionContext? resolution,
  DiplomacyFactionMembership? factionMembership,
}) {
  // Stateless candidate-probe path: validate the candidate against
  // [baseOrders]'s diplomatic context without re-running full-pass
  // [validatePlayerOrdersWithContext]. SPEC/program/order-suggestions.md
  // § Incremental candidate validation. Refs #2237.
  return probeOrderAccepted<ArmyMoveOrder>(
    game: game,
    topology: topology,
    playerId: playerId,
    baseOrders: baseOrders,
    candidate: candidate,
    resolution: resolution,
    factionMembership: factionMembership,
    sharedCandidateValidator: sharedCandidateValidator,
    probeWithValidator: (validator, c) => validator.isArmyMoveAccepted(c),
  );
}

bool isWorkOrderAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders baseOrders,
  WorkOrder candidate, {
  Map<String, TileMapResult>? tileMapByRegion,
  IncrementalCandidateValidator? sharedCandidateValidator,
  OrderResolutionContext? resolution,
  DiplomacyFactionMembership? factionMembership,
}) {
  return probeOrderAccepted<WorkOrder>(
    game: game,
    topology: topology,
    playerId: playerId,
    baseOrders: baseOrders,
    candidate: candidate,
    tileMapByRegion: tileMapByRegion,
    resolution: resolution,
    factionMembership: factionMembership,
    sharedCandidateValidator: sharedCandidateValidator,
    onBeforeProbe: bumpOrderSuggestionWorkOrderAcceptanceProbeIfTracking,
    probeWithValidator: isWorkOrderAcceptedWithValidator,
  );
}

bool isBuildOrderAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders baseOrders,
  BuildUnitOrder candidate, {
  IncrementalCandidateValidator? sharedCandidateValidator,
  OrderResolutionContext? resolution,
  DiplomacyFactionMembership? factionMembership,
}) {
  return probeOrderAccepted<BuildUnitOrder>(
    game: game,
    topology: topology,
    playerId: playerId,
    baseOrders: baseOrders,
    candidate: candidate,
    resolution: resolution,
    factionMembership: factionMembership,
    sharedCandidateValidator: sharedCandidateValidator,
    probeWithValidator: isBuildOrderAcceptedWithValidator,
  );
}

bool isNavalMoveOrderAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders baseOrders,
  NavalMoveOrder candidate, {
  IncrementalCandidateValidator? sharedCandidateValidator,
  OrderResolutionContext? resolution,
  DiplomacyFactionMembership? factionMembership,
}) {
  // Stateless candidate-probe path. SPEC/program/order-suggestions.md
  // § Incremental candidate validation. Refs #2237.
  return probeOrderAccepted<NavalMoveOrder>(
    game: game,
    topology: topology,
    playerId: playerId,
    baseOrders: baseOrders,
    candidate: candidate,
    resolution: resolution,
    factionMembership: factionMembership,
    sharedCandidateValidator: sharedCandidateValidator,
    probeWithValidator: (validator, c) => validator.isNavalMoveAccepted(c),
  );
}

bool isNavalMissionOrderAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders baseOrders,
  NavalMissionOrder candidate, {
  IncrementalCandidateValidator? sharedCandidateValidator,
  OrderResolutionContext? resolution,
  DiplomacyFactionMembership? factionMembership,
}) {
  // Stateless candidate-probe path. SPEC/program/order-suggestions.md
  // § Incremental candidate validation. Refs #2237.
  return probeOrderAccepted<NavalMissionOrder>(
    game: game,
    topology: topology,
    playerId: playerId,
    baseOrders: baseOrders,
    candidate: candidate,
    resolution: resolution,
    factionMembership: factionMembership,
    sharedCandidateValidator: sharedCandidateValidator,
    probeWithValidator: (validator, c) => validator.isNavalMissionAccepted(c),
  );
}

bool isDiplomaticOrderAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders baseOrders,
  DiplomaticOrder candidate, {
  Map<String, TileMapResult>? tileMapByRegion,

  /// When callers probe many candidates for the same `(game, topology,
  /// playerId)` (for example diplomatic suggestion loops), they may pass
  /// [resolution] built once to skip redundant `buildPlayerView` and unit-map
  /// scans. Refs #2394, #2836; `SPEC/program/order-suggestions.md` § Throughput
  /// bounds.
  OrderResolutionContext? resolution,
  DiplomacyFactionMembership? factionMembership,
  IncrementalCandidateValidator? sharedCandidateValidator,
}) {
  return probeOrderAccepted<DiplomaticOrder>(
    game: game,
    topology: topology,
    playerId: playerId,
    baseOrders: baseOrders,
    candidate: candidate,
    tileMapByRegion: tileMapByRegion,
    resolution: resolution,
    factionMembership: factionMembership,
    sharedCandidateValidator: sharedCandidateValidator,
    probeWithValidator: (validator, c) => validator.isDiplomaticAccepted(c),
  );
}

/// Validates [candidate] with an existing [validator] built for the same
/// `(game, topology, playerId, baseOrders, …)` tuple as this probe.
///
/// Callers that evaluate many diplomatic candidates against the same
/// [Orders] prefix should build one [IncrementalCandidateValidator] per
/// prefix and reuse it here instead of calling [isDiplomaticOrderAccepted]
/// repeatedly (Refs #2394, `SPEC/program/order-suggestions.md` § Throughput
/// bounds).
bool isDiplomaticOrderAcceptedWithValidator(
  IncrementalCandidateValidator validator,
  DiplomaticOrder candidate,
) {
  return validator.isDiplomaticAccepted(candidate);
}

bool isBuildOrderAcceptedWithValidator(
  IncrementalCandidateValidator validator,
  BuildUnitOrder candidate,
) {
  return validator.isBuildAccepted(candidate);
}

bool isWorkOrderAcceptedWithValidator(
  IncrementalCandidateValidator validator,
  WorkOrder candidate,
) {
  bumpOrderSuggestionWorkOrderAcceptanceProbeIfTracking();
  return validator.isWorkAccepted(candidate);
}
