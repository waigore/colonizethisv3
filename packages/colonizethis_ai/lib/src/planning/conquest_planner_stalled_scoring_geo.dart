import '../perception/perception_snapshot.dart';
import '../util/faction_query.dart';
import 'expand_peace_frontier_helpers.dart';
import 'planning_imports.dart';

bool isOnAtWarMinorOrTribeFrontier({
  required Game game,
  required Map<String, String?> provinceOwner,
  required String destRegion,
  required Iterable<String> destNeighborLocals,
  required Iterable<String> atWarWith,
}) {
  for (final n in destNeighborLocals) {
    final nOwner = provinceOwner[ProvinceId.full(destRegion, n)] ?? '';
    if (!atWarWith.contains(nOwner)) continue;
    if (isMinorOrTribeFaction(game, nOwner)) return true;
  }
  return false;
}

/// Sole at-war Great Power peer when [expandIsGeographicPeerWarLock] holds.
String? geographicPeerWarLockPeerGpId(AIWorldSnapshot snapshot) {
  final adjacentOwners = snapshot.conquest.adjacentOwnerFactionIdsSorted;
  if (adjacentOwners.length != 1) {
    return null;
  }
  return adjacentOwners.single;
}

bool provinceNeighborOwnedByAtWarMinorOrTribe({
  required Game game,
  required Map<String, String?> provinceOwner,
  required String regionId,
  required Iterable<String> neighborLocals,
  required Iterable<String> atWarWith,
}) {
  for (final n in neighborLocals) {
    final nOwner = provinceOwner[ProvinceId.full(regionId, n)] ?? '';
    if (!atWarWith.contains(nOwner)) continue;
    if (isMinorOrTribeFaction(game, nOwner)) return true;
  }
  return false;
}

/// Shared destination inputs for geographic peer-lock transit checks
/// (Refs #3997).
final class GeographicPeerLockTransitInput {
  const GeographicPeerLockTransitInput({
    required this.nationId,
    required this.game,
    required this.topology,
    required this.snapshot,
    required this.provinceOwner,
    required this.destOwner,
    required this.destRegion,
    required this.destNeighborLocals,
    required this.peerGpId,
  });

  final String nationId;
  final Game game;
  final MapTopology topology;
  final AIWorldSnapshot snapshot;
  final Map<String, String?> provinceOwner;
  final String destOwner;
  final String destRegion;
  final Iterable<String> destNeighborLocals;
  final String peerGpId;
}

/// Shared destination inputs for stalled-expansion army-move score deltas
/// (Refs #3997).
final class StalledExpansionArmyMoveScoreDeltaInput {
  const StalledExpansionArmyMoveScoreDeltaInput({
    required this.move,
    required this.nationId,
    required this.game,
    required this.topology,
    required this.snapshot,
    required this.provinceOwner,
    required this.invadable,
    required this.destOwner,
    required this.destRegion,
    required this.destNeighborLocals,
    required this.declaredWarTargetFactionId,
  });

  final ArmyMoveOrder move;
  final String nationId;
  final Game game;
  final MapTopology topology;
  final AIWorldSnapshot snapshot;
  final Map<String, String?> provinceOwner;
  final Set<String> invadable;
  final String destOwner;
  final String destRegion;
  final Iterable<String> destNeighborLocals;
  final String? declaredWarTargetFactionId;

  GeographicPeerLockTransitInput transitInput(String peerGpId) {
    return GeographicPeerLockTransitInput(
      nationId: nationId,
      game: game,
      topology: topology,
      snapshot: snapshot,
      provinceOwner: provinceOwner,
      destOwner: destOwner,
      destRegion: destRegion,
      destNeighborLocals: destNeighborLocals,
      peerGpId: peerGpId,
    );
  }
}

/// Whether [input.move]'s destination is a stalled-expansion march step toward
/// an at-war minor/tribe reachable only through the geographic peer-war lock
/// (Refs #2847 § H4-b).
bool isGeographicPeerLockMinorTransitDestination(
  GeographicPeerLockTransitInput input,
) {
  final atWarWith = input.snapshot.threats.atWarWith;
  if (input.destOwner == input.peerGpId) {
    return provinceNeighborOwnedByAtWarMinorOrTribe(
      game: input.game,
      provinceOwner: input.provinceOwner,
      regionId: input.destRegion,
      neighborLocals: input.destNeighborLocals,
      atWarWith: atWarWith,
    );
  }
  if (input.destOwner != input.nationId) {
    return false;
  }
  for (final peerLocal in input.destNeighborLocals) {
    final peerFull = ProvinceId.full(input.destRegion, peerLocal);
    if ((input.provinceOwner[peerFull] ?? '') != input.peerGpId) continue;
    final beyondPeer = neighborProvinceIdsInRegion(
      input.topology,
      input.destRegion,
      peerLocal,
    );
    if (provinceNeighborOwnedByAtWarMinorOrTribe(
      game: input.game,
      provinceOwner: input.provinceOwner,
      regionId: input.destRegion,
      neighborLocals: beyondPeer,
      atWarWith: atWarWith,
    )) {
      return true;
    }
  }
  return false;
}
