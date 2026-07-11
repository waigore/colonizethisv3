part of 'conquest_planner.dart';

// Geographic peer-war lock helpers and stalled-expansion army-move
// score deltas extracted from conquest_planner.dart (Refs #3967 step 4).

bool _isOnAtWarMinorOrTribeFrontier({
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
String? _geographicPeerWarLockPeerGpId(AIWorldSnapshot snapshot) {
  final adjacentOwners = snapshot.conquest.adjacentOwnerFactionIdsSorted;
  if (adjacentOwners.length != 1) {
    return null;
  }
  return adjacentOwners.single;
}

bool _provinceNeighborOwnedByAtWarMinorOrTribe({
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

/// Whether [move]'s destination is a stalled-expansion march step toward an
/// at-war minor/tribe reachable only through the geographic peer-war lock
/// (Refs #2847 § H4-b).
bool _isGeographicPeerLockMinorTransitDestination({
  required ArmyMoveOrder move,
  required String nationId,
  required Game game,
  required MapTopology topology,
  required AIWorldSnapshot snapshot,
  required Map<String, String?> provinceOwner,
  required String destOwner,
  required String destRegion,
  required Iterable<String> destNeighborLocals,
  required String peerGpId,
}) {
  final atWarWith = snapshot.threats.atWarWith;
  if (destOwner == peerGpId) {
    return _provinceNeighborOwnedByAtWarMinorOrTribe(
      game: game,
      provinceOwner: provinceOwner,
      regionId: destRegion,
      neighborLocals: destNeighborLocals,
      atWarWith: atWarWith,
    );
  }
  if (destOwner != nationId) {
    return false;
  }
  for (final peerLocal in destNeighborLocals) {
    final peerFull = ProvinceId.full(destRegion, peerLocal);
    if ((provinceOwner[peerFull] ?? '') != peerGpId) continue;
    final beyondPeer = neighborProvinceIdsInRegion(
      topology,
      destRegion,
      peerLocal,
    );
    if (_provinceNeighborOwnedByAtWarMinorOrTribe(
      game: game,
      provinceOwner: provinceOwner,
      regionId: destRegion,
      neighborLocals: beyondPeer,
      atWarWith: atWarWith,
    )) {
      return true;
    }
  }
  return false;
}

double _stalledExpansionArmyMoveScoreDelta({
  required ArmyMoveOrder move,
  required String nationId,
  required Game game,
  required MapTopology topology,
  required AIWorldSnapshot snapshot,
  required Map<String, String?> provinceOwner,
  required Set<String> invadable,
  required String destOwner,
  required String destRegion,
  required Iterable<String> destNeighborLocals,
  required String? declaredWarTargetFactionId,
}) {
  final geoLockPeerGpId = _geographicPeerWarLockPeerGpId(snapshot);
  final geoLockActive =
      geoLockPeerGpId != null &&
      expandIsGeographicPeerWarLock(
        snapshot: snapshot,
        peerGpId: geoLockPeerGpId,
      ) &&
      snapshot.conquest.oldWorldProvincesOwned <=
          provinceCountOwnedBy(game, geoLockPeerGpId);
  if (geoLockActive &&
      _isGeographicPeerLockMinorTransitDestination(
        move: move,
        nationId: nationId,
        game: game,
        topology: topology,
        snapshot: snapshot,
        provinceOwner: provinceOwner,
        destOwner: destOwner,
        destRegion: destRegion,
        destNeighborLocals: destNeighborLocals,
        peerGpId: geoLockPeerGpId,
      )) {
    return kConquestArmyMoveAdjacentAtWarFrontierBonus +
        kConquestArmyMoveStalledDeclaredTargetBonus;
  }
  final atWarMinorOrTribe =
      destOwner.isNotEmpty &&
      destOwner != nationId &&
      snapshot.threats.atWarWith.contains(destOwner) &&
      isMinorOrTribeFaction(game, destOwner);
  final atWarGpInvadableBlocker =
      !geoLockActive &&
      destOwner.isNotEmpty &&
      destOwner != nationId &&
      snapshot.threats.atWarWith.contains(destOwner) &&
      game.playerById(destOwner) != null &&
      snapshot.conquest.invadableProvinceIdsSorted.any(
        (pid) => provinceOwner[pid] == destOwner,
      );
  final peerDeclaredWarWithoutMinorTransit =
      geoLockActive &&
      declaredWarTargetFactionId == geoLockPeerGpId &&
      destOwner == geoLockPeerGpId &&
      !_isGeographicPeerLockMinorTransitDestination(
        move: move,
        nationId: nationId,
        game: game,
        topology: topology,
        snapshot: snapshot,
        provinceOwner: provinceOwner,
        destOwner: destOwner,
        destRegion: destRegion,
        destNeighborLocals: destNeighborLocals,
        peerGpId: geoLockPeerGpId,
      );
  final targetsDeclaredOrAtWarEnemy =
      (declaredWarTargetFactionId != null &&
          destOwner == declaredWarTargetFactionId &&
          !peerDeclaredWarWithoutMinorTransit) ||
      atWarMinorOrTribe ||
      atWarGpInvadableBlocker;
  if (targetsDeclaredOrAtWarEnemy) {
    var delta = atWarGpInvadableBlocker
        ? kConquestArmyMoveStalledGpInvadableBlockerBonus
        : kConquestArmyMoveStalledDeclaredTargetBonus;
    if (atWarMinorOrTribe &&
        isBelowObserverConquestQuota(
          snapshot.conquest.oldWorldProvincesOwned,
        )) {
      delta += kConquestArmyMoveStalledDeclaredTargetBonus;
    }
    if (atWarGpInvadableBlocker) {
      final deficit = oldWorldProvinceLeadOver(
        game: game,
        snapshot: snapshot,
        factionId: destOwner,
      );
      if (deficit > 0) {
        delta +=
            deficit * kConquestArmyMoveStalledBehindGpBlockerBonusPerProvince;
      }
    }
    if (invadable.contains(move.destinationProvinceId)) {
      delta += kConquestArmyMoveStalledDeclaredTargetInvadableBonus;
    }
    return delta;
  }
  if (destOwner != nationId) return 0;
  if (_isOnAtWarMinorOrTribeFrontier(
    game: game,
    provinceOwner: provinceOwner,
    destRegion: destRegion,
    destNeighborLocals: destNeighborLocals,
    atWarWith: snapshot.threats.atWarWith,
  )) {
    return kConquestArmyMoveAdjacentAtWarFrontierBonus;
  }
  return -0.95;
}
