import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_diplomacy/src/diplomacy/diplomacy_resolver.dart';
import 'package:colonizethis_world/src/world/player_view.dart';
import 'incremental_candidate_validator.dart';
import 'order_resolution_context.dart';

export 'package:colonizethis_diplomacy/src/diplomacy/overture_stage_helpers.dart';

final orderSuggestionLog = packageLogger('order_suggestion');

bool _orderSuggestionTrackWorkOrderAcceptanceProbes = false;
int _orderSuggestionWorkOrderAcceptanceProbeCount = 0;

/// Test hook: enable counting of order-engine work-order acceptance probes.
void setOrderSuggestionWorkOrderAcceptanceProbeTrackingForTests(bool enabled) {
  _orderSuggestionTrackWorkOrderAcceptanceProbes = enabled;
  _orderSuggestionWorkOrderAcceptanceProbeCount = 0;
}

/// Test hook: probes counted while tracking is enabled (Refs #2133).
int get orderSuggestionWorkOrderAcceptanceProbeCountForTests =>
    _orderSuggestionWorkOrderAcceptanceProbeCount;

void bumpOrderSuggestionWorkOrderAcceptanceProbeIfTracking() {
  if (_orderSuggestionTrackWorkOrderAcceptanceProbes) {
    _orderSuggestionWorkOrderAcceptanceProbeCount++;
  }
}

int _incrementalCandidateValidatorBuildCountForTests = 0;

/// Test hook: reset [incrementalCandidateValidatorBuildCountForTests] (Refs #2394).
void resetIncrementalCandidateValidatorBuildCountForTests() {
  _incrementalCandidateValidatorBuildCountForTests = 0;
}

/// Test hook: [buildIncrementalCandidateValidator] invocations since last reset.
int get incrementalCandidateValidatorBuildCountForTests =>
    _incrementalCandidateValidatorBuildCountForTests;

IncrementalCandidateValidator buildIncrementalCandidateValidator({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Orders baseOrders,
  Map<String, TileMapResult>? tileMapByRegion,
  OrderResolutionContext? resolution,

  /// When callers already built membership for this [game], pass it to avoid a
  /// second [DiplomacyFactionMembership.from] inside the validator.
  DiplomacyFactionMembership? factionMembership,
}) {
  _incrementalCandidateValidatorBuildCountForTests++;
  return IncrementalCandidateValidator.forPlayer(
    game: game,
    topology: topology,
    playerId: playerId,
    basePrefix: baseOrders,
    tileMapByRegion: tileMapByRegion,
    resolution: resolution,
    factionMembership: factionMembership,
  );
}

/// Resolves the [IncrementalCandidateValidator] for a stateless candidate probe.
///
/// When [sharedCandidateValidator] is supplied for the same suggestion pass,
/// rebinds via [IncrementalCandidateValidator.forBasePrefix] when [baseOrders]
/// differs from the embedded prefix; otherwise reuses the instance without
/// incrementing [incrementalCandidateValidatorBuildCountForTests]. Refs #2394.
IncrementalCandidateValidator incrementalValidatorForCandidateProbe({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Orders baseOrders,
  Map<String, TileMapResult>? tileMapByRegion,
  OrderResolutionContext? resolution,
  DiplomacyFactionMembership? factionMembership,
  IncrementalCandidateValidator? sharedCandidateValidator,
}) {
  assert(
    sharedCandidateValidator == null ||
        sharedCandidateValidator.playerId == playerId,
    'sharedCandidateValidator playerId must match playerId',
  );
  final shared = sharedCandidateValidator;
  if (shared != null) {
    return shared.basePrefix == baseOrders
        ? shared
        : shared.forBasePrefix(baseOrders);
  }
  return buildIncrementalCandidateValidator(
    game: game,
    topology: topology,
    playerId: playerId,
    baseOrders: baseOrders,
    tileMapByRegion: tileMapByRegion,
    resolution: resolution,
    factionMembership: factionMembership,
  );
}

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
  final validator = incrementalValidatorForCandidateProbe(
    game: game,
    topology: topology,
    playerId: playerId,
    baseOrders: baseOrders,
    resolution: resolution,
    factionMembership: factionMembership,
    sharedCandidateValidator: sharedCandidateValidator,
  );
  return validator.isMoveAccepted(candidate);
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
  final validator = incrementalValidatorForCandidateProbe(
    game: game,
    topology: topology,
    playerId: playerId,
    baseOrders: baseOrders,
    resolution: resolution,
    factionMembership: factionMembership,
    sharedCandidateValidator: sharedCandidateValidator,
  );
  return validator.isArmyMoveAccepted(candidate);
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
  final validator = incrementalValidatorForCandidateProbe(
    game: game,
    topology: topology,
    playerId: playerId,
    baseOrders: baseOrders,
    tileMapByRegion: tileMapByRegion,
    resolution: resolution,
    factionMembership: factionMembership,
    sharedCandidateValidator: sharedCandidateValidator,
  );
  return isWorkOrderAcceptedWithValidator(validator, candidate);
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
  final validator = incrementalValidatorForCandidateProbe(
    game: game,
    topology: topology,
    playerId: playerId,
    baseOrders: baseOrders,
    resolution: resolution,
    factionMembership: factionMembership,
    sharedCandidateValidator: sharedCandidateValidator,
  );
  return isBuildOrderAcceptedWithValidator(validator, candidate);
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
  final validator = incrementalValidatorForCandidateProbe(
    game: game,
    topology: topology,
    playerId: playerId,
    baseOrders: baseOrders,
    resolution: resolution,
    factionMembership: factionMembership,
    sharedCandidateValidator: sharedCandidateValidator,
  );
  return validator.isNavalMoveAccepted(candidate);
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
  final validator = incrementalValidatorForCandidateProbe(
    game: game,
    topology: topology,
    playerId: playerId,
    baseOrders: baseOrders,
    resolution: resolution,
    factionMembership: factionMembership,
    sharedCandidateValidator: sharedCandidateValidator,
  );
  return validator.isNavalMissionAccepted(candidate);
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
  final validator = incrementalValidatorForCandidateProbe(
    game: game,
    topology: topology,
    playerId: playerId,
    baseOrders: baseOrders,
    tileMapByRegion: tileMapByRegion,
    resolution: resolution,
    factionMembership: factionMembership,
    sharedCandidateValidator: sharedCandidateValidator,
  );
  return validator.isDiplomaticAccepted(candidate);
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

Orders appendDiplomaticOrderForTrial(
  Orders orders,
  String playerId,
  DiplomaticOrder order,
) {
  final prev =
      orders.diplomaticOrdersByPlayerId[playerId] ?? const <DiplomaticOrder>[];
  return orders.copyWith(
    diplomaticOrdersByPlayerId: {
      ...orders.diplomaticOrdersByPlayerId,
      playerId: [...prev, order],
    },
  );
}
