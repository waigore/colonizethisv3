import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'incremental_candidate_validator.dart';
import 'order_resolution_context.dart';
import 'order_suggestion_pass_context.dart';

/// Suggests naval mission orders for fleets owned by [view.playerId]. Phase 6.
///
/// Throughput hook: see [suggestNavalMoveOrders] [sharedCandidateValidator].
List<NavalMissionOrder> suggestNavalMissionOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders, {
  OrderResolutionContext? resolution,
  IncrementalCandidateValidator? sharedCandidateValidator,
}) {
  final pass = SuggestionPassContext.forPlayerView(
    view: view,
    game: game,
    topology: topology,
    currentOrders: currentOrders,
    familyLabel: 'suggestNavalMissionOrders',
    sharedCandidateValidator: sharedCandidateValidator,
    resolution: resolution,
    includeFactionMembershipInBuild: false,
    useBuildIncrementalWrapper: false,
  );
  final playerId = pass.playerId;
  final suggestions = <NavalMissionOrder>[];
  final candidateValidator = pass.candidateValidator;
  final existingByFleet = <String>{
    for (final o
        in currentOrders.navalMissionOrdersByPlayerId[playerId] ?? const [])
      o.fleetId,
  };

  // Fleet-level dedup (any existing mission for the fleet) is expressed as a
  // candidate-enumeration filter; the shared emitter then probes/collects.
  emitAcceptedCandidates<NavalMissionOrder>(
    candidates: [
      for (final fleet in game.worldState.fleets)
        if (fleet.ownerId == playerId && !existingByFleet.contains(fleet.id))
          for (final mission in FleetMission.values)
            NavalMissionOrder(fleetId: fleet.id, mission: mission.name),
    ],
    accept: candidateValidator.isNavalMissionAccepted,
    into: suggestions,
  );

  suggestions.sort((a, b) {
    final c = a.fleetId.compareTo(b.fleetId);
    if (c != 0) return c;
    return a.mission.compareTo(b.mission);
  });
  pass.logExit(candidateCount: suggestions.length);
  return suggestions;
}
