import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'incremental_candidate_validator.dart';
import 'order_resolution_context.dart';

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

bool probeOrderAccepted<T>({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Orders baseOrders,
  required T candidate,
  required bool Function(IncrementalCandidateValidator validator, T candidate)
  probeWithValidator,
  Map<String, TileMapResult>? tileMapByRegion,
  IncrementalCandidateValidator? sharedCandidateValidator,
  OrderResolutionContext? resolution,
  DiplomacyFactionMembership? factionMembership,
  void Function()? onBeforeProbe,
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
  onBeforeProbe?.call();
  return probeWithValidator(validator, candidate);
}
