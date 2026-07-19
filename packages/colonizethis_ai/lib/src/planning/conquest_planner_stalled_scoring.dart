import '../perception/perception_snapshot.dart';
import '../util/faction_query.dart';
import 'expand_phase_planner.dart' show expandIsGeographicPeerWarLock;
import 'planning_helpers.dart' show oldWorldProvinceLeadOver;
import 'planning_imports.dart';

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

/// Shared destination inputs for geographic peer-lock transit checks
/// (Refs #3997).
final class _GeographicPeerLockTransitInput {
  const _GeographicPeerLockTransitInput({
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

  _GeographicPeerLockTransitInput transitInput(String peerGpId) {
    return _GeographicPeerLockTransitInput(
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
bool _isGeographicPeerLockMinorTransitDestination(
  _GeographicPeerLockTransitInput input,
) {
  final atWarWith = input.snapshot.threats.atWarWith;
  if (input.destOwner == input.peerGpId) {
    return _provinceNeighborOwnedByAtWarMinorOrTribe(
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
    if (_provinceNeighborOwnedByAtWarMinorOrTribe(
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

double stalledExpansionArmyMoveScoreDelta(
  StalledExpansionArmyMoveScoreDeltaInput input,
) {
  final geoLockPeerGpId = _geographicPeerWarLockPeerGpId(input.snapshot);
  final geoLockActive =
      geoLockPeerGpId != null &&
      expandIsGeographicPeerWarLock(
        snapshot: input.snapshot,
        peerGpId: geoLockPeerGpId,
      ) &&
      input.snapshot.conquest.oldWorldProvincesOwned <=
          provinceCountOwnedBy(input.game, geoLockPeerGpId);
  if (geoLockActive &&
      _isGeographicPeerLockMinorTransitDestination(
        input.transitInput(geoLockPeerGpId),
      )) {
    return kConquestArmyMoveAdjacentAtWarFrontierBonus +
        kConquestArmyMoveStalledDeclaredTargetBonus;
  }
  final atWarMinorOrTribe =
      input.destOwner.isNotEmpty &&
      input.destOwner != input.nationId &&
      input.snapshot.threats.atWarWith.contains(input.destOwner) &&
      isMinorOrTribeFaction(input.game, input.destOwner);
  final atWarGpInvadableBlocker =
      !geoLockActive &&
      input.destOwner.isNotEmpty &&
      input.destOwner != input.nationId &&
      input.snapshot.threats.atWarWith.contains(input.destOwner) &&
      input.game.playerById(input.destOwner) != null &&
      input.snapshot.conquest.invadableProvinceIdsSorted.any(
        (pid) => input.provinceOwner[pid] == input.destOwner,
      );
  final peerDeclaredWarWithoutMinorTransit =
      geoLockActive &&
      input.declaredWarTargetFactionId == geoLockPeerGpId &&
      input.destOwner == geoLockPeerGpId &&
      !_isGeographicPeerLockMinorTransitDestination(
        input.transitInput(geoLockPeerGpId),
      );
  final targetsDeclaredOrAtWarEnemy =
      (input.declaredWarTargetFactionId != null &&
          input.destOwner == input.declaredWarTargetFactionId &&
          !peerDeclaredWarWithoutMinorTransit) ||
      atWarMinorOrTribe ||
      atWarGpInvadableBlocker;
  if (targetsDeclaredOrAtWarEnemy) {
    var delta = atWarGpInvadableBlocker
        ? kConquestArmyMoveStalledGpInvadableBlockerBonus
        : kConquestArmyMoveStalledDeclaredTargetBonus;
    if (atWarMinorOrTribe &&
        isBelowObserverConquestQuota(
          input.snapshot.conquest.oldWorldProvincesOwned,
        )) {
      delta += kConquestArmyMoveStalledDeclaredTargetBonus;
    }
    if (atWarGpInvadableBlocker) {
      final deficit = oldWorldProvinceLeadOver(
        game: input.game,
        snapshot: input.snapshot,
        factionId: input.destOwner,
      );
      if (deficit > 0) {
        delta +=
            deficit * kConquestArmyMoveStalledBehindGpBlockerBonusPerProvince;
      }
    }
    if (input.invadable.contains(input.move.destinationProvinceId)) {
      delta += kConquestArmyMoveStalledDeclaredTargetInvadableBonus;
    }
    return delta;
  }
  if (input.destOwner != input.nationId) return 0;
  if (_isOnAtWarMinorOrTribeFrontier(
    game: input.game,
    provinceOwner: input.provinceOwner,
    destRegion: input.destRegion,
    destNeighborLocals: input.destNeighborLocals,
    atWarWith: input.snapshot.threats.atWarWith,
  )) {
    return kConquestArmyMoveAdjacentAtWarFrontierBonus;
  }
  return -0.95;
}
