import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'incremental_candidate_validator.dart';
import 'order_resolution_context.dart';
import 'order_suggestion_pass_context.dart';

/// Dedup/sort key for a [NavalMoveOrder] candidate: dock moves key on the
/// destination port province, sea moves on the destination sea zone. Shared by
/// the existing-target index, per-candidate dedup, and the final sort so all
/// three stay in lockstep (Refs #3714).
String _navalMoveTargetKey(NavalMoveOrder o) => o.isDock
    ? 'port:${o.destinationPortProvinceId}'
    : (o.destinationSeaZoneId ?? '');

void _addAcceptedSeaZoneCandidates({
  required IncrementalCandidateValidator candidateValidator,
  required MapTopology topology,
  required Fleet fleet,
  required String cur,
  required Map<String, Set<String>> existingByFleet,
  required List<NavalMoveOrder> suggestions,
}) {
  emitAcceptedCandidates<NavalMoveOrder>(
    candidates: [
      for (final node in topology.nodes)
        if (node.type == TopologyNodeType.seaZone &&
            (cur == node.id || isAdjacentSeaSeaZone(topology, cur, node.id)))
          NavalMoveOrder(fleetId: fleet.id, destinationSeaZoneId: node.id),
    ],
    accept: candidateValidator.isNavalMoveAccepted,
    into: suggestions,
    existingByEntity: existingByFleet,
    entityId: (o) => o.fleetId,
    dedupKey: _navalMoveTargetKey,
  );
}

void _addAcceptedDockCandidatesForSeaFleet({
  required IncrementalCandidateValidator candidateValidator,
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Fleet fleet,
  required String cur,
  required Map<String, Set<String>> existingByFleet,
  required List<NavalMoveOrder> suggestions,
}) {
  final zoneRegionId = regionIdForSeaZone(topology, cur);
  if (zoneRegionId == null) return;
  final adjacentLocalIds = provinceIdsAdjacentToSeaZone(
    topology,
    cur,
    regionId: zoneRegionId,
  );
  final candidates = <NavalMoveOrder>[];
  for (final localId in adjacentLocalIds) {
    final fullProvinceId = ProvinceId.isPrefixed(localId)
        ? localId
        : ProvinceId.full(zoneRegionId, localId);
    final province = game.worldState.tryGetProvince(fullProvinceId);
    if (province?.ownerId != playerId) continue;
    candidates.add(
      NavalMoveOrder(
        fleetId: fleet.id,
        destinationPortProvinceId: fullProvinceId,
      ),
    );
  }
  emitAcceptedCandidates<NavalMoveOrder>(
    candidates: candidates,
    accept: candidateValidator.isNavalMoveAccepted,
    into: suggestions,
    existingByEntity: existingByFleet,
    entityId: (o) => o.fleetId,
    dedupKey: _navalMoveTargetKey,
  );
}

void _addAcceptedMovesFromPortFleet({
  required IncrementalCandidateValidator candidateValidator,
  required MapTopology topology,
  required Fleet fleet,
  required Map<String, Set<String>> existingByFleet,
  required List<NavalMoveOrder> suggestions,
}) {
  final inPortProvinceId = fleet.inPortAtProvinceId;
  if (inPortProvinceId == null) return;
  final rl = regionAndLocalProvinceForFleetInPort(
    inPortProvinceId,
    fleet.regionId,
  );
  final pNode = provinceTopologyNodeId(topology, rl.localId, rl.regionId);
  if (pNode == null) return;
  emitAcceptedCandidates<NavalMoveOrder>(
    candidates: [
      for (final destId in seaZonesAdjacentToProvince(topology, pNode))
        NavalMoveOrder(fleetId: fleet.id, destinationSeaZoneId: destId),
    ],
    accept: candidateValidator.isNavalMoveAccepted,
    into: suggestions,
    existingByEntity: existingByFleet,
    entityId: (o) => o.fleetId,
    dedupKey: _navalMoveTargetKey,
  );
}

/// Suggests naval move orders for fleets owned by [view.playerId]. SPEC/program/naval-movement-resolution.md.
///
/// Throughput hook: callers that enumerate multiple suggestion families against
/// the same `(game, view.playerId, currentOrders)` may supply
/// [sharedCandidateValidator] to amortize `PlayerView` / units-by-id
/// construction (Refs #2394, `SPEC/program/order-suggestions.md` § Throughput
/// bounds).
List<NavalMoveOrder> suggestNavalMoveOrders(
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
    familyLabel: 'suggestNavalMoveOrders',
    sharedCandidateValidator: sharedCandidateValidator,
    resolution: resolution,
    includeFactionMembershipInBuild: false,
    useBuildIncrementalWrapper: false,
  );
  final playerId = pass.playerId;
  final suggestions = <NavalMoveOrder>[];
  final candidateValidator = pass.candidateValidator;
  final existingByFleet = indexExistingTargetsByEntityId(
    currentOrders.navalMoveOrdersByPlayerId[playerId],
    (o) => o.fleetId,
    _navalMoveTargetKey,
    skipEmptyTargets: true,
  );

  final homeFleetId = homeFleetIdFor(playerId);
  for (final fleet in game.worldState.fleets) {
    if (fleet.ownerId != playerId || fleet.id == homeFleetId) continue;
    if (fleet.isAtSea) {
      final cur = fleet.seaZoneId;
      if (cur == null) continue;
      _addAcceptedSeaZoneCandidates(
        candidateValidator: candidateValidator,
        topology: topology,
        fleet: fleet,
        cur: cur,
        existingByFleet: existingByFleet,
        suggestions: suggestions,
      );
      _addAcceptedDockCandidatesForSeaFleet(
        candidateValidator: candidateValidator,
        game: game,
        topology: topology,
        playerId: playerId,
        fleet: fleet,
        cur: cur,
        existingByFleet: existingByFleet,
        suggestions: suggestions,
      );
    } else {
      _addAcceptedMovesFromPortFleet(
        candidateValidator: candidateValidator,
        topology: topology,
        fleet: fleet,
        existingByFleet: existingByFleet,
        suggestions: suggestions,
      );
    }
  }

  suggestions.sort((a, b) {
    final c = a.fleetId.compareTo(b.fleetId);
    if (c != 0) return c;
    return _navalMoveTargetKey(a).compareTo(_navalMoveTargetKey(b));
  });
  pass.logExit(candidateCount: suggestions.length);
  return suggestions;
}

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
