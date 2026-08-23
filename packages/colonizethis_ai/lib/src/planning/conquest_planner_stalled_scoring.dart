import '../util/faction_query.dart';
import 'expand_peace_frontier_helpers.dart';
import 'planning_helpers.dart' show oldWorldProvinceLeadOver;
import 'planning_imports.dart';
import 'conquest_planner_stalled_scoring_geo.dart';

export 'conquest_planner_stalled_scoring_geo.dart';

// Geographic peer-war lock helpers and stalled-expansion army-move
// score deltas extracted from conquest_planner.dart (Refs #3967 step 4).

double stalledExpansionArmyMoveScoreDelta(
  StalledExpansionArmyMoveScoreDeltaInput input,
) {
  final geoLockPeerGpId = geographicPeerWarLockPeerGpId(input.snapshot);
  final geoLockActive =
      geoLockPeerGpId != null &&
      expandIsGeographicPeerWarLock(
        snapshot: input.snapshot,
        peerGpId: geoLockPeerGpId,
      ) &&
      input.snapshot.conquest.oldWorldProvincesOwned <=
          provinceCountOwnedBy(input.game, geoLockPeerGpId);
  if (geoLockActive &&
      isGeographicPeerLockMinorTransitDestination(
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
      !isGeographicPeerLockMinorTransitDestination(
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
  if (isOnAtWarMinorOrTribeFrontier(
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
