/// EXPAND-phase peer-peace: below-quota peer GP (Refs #3967; #4365 Slice A).
library;

import '../perception/perception_snapshot.dart';
import 'expand_peace_frontier_helpers.dart'
    show
        anyMinorOwnsOldWorldProvince,
        hasUninvadedOldWorldMinor,
        isMutualBelowQuotaPlateauPeer,
        isOldWorldGpOnlyInvadableFrontier,
        soleAtWarGreatPowerId;
import 'planning_helpers.dart' show gpAtWarPeaceTargetsWhere;
import 'planning_imports.dart';

export 'expand_phase_planner_peer_peace_tribe_distraction.dart';

/// Max OW gap peaced across while uninvaded OW minors remain (Refs #2509).
const int _kMaxPeerOwGapWithMinors = 3;

/// Max OW gap peaced across when no uninvaded OW minor pivot remains.
const int _kMaxPeerOwGapWithoutMinors = 1;

/// Below-quota peer GP peace targets for the EXPAND peer-stalled pivot.
List<String> belowQuotaPeerGpPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  if (!isBelowObserverConquestQuota(ownOw)) {
    return const [];
  }
  final minorsOnMap = anyMinorOwnsOldWorldProvince(game);
  final gpOnlyFrontier = isOldWorldGpOnlyInvadableFrontier(
    game: game,
    snapshot: snapshot,
  );
  final soleGpWar = soleAtWarGreatPowerId(game: game, snapshot: snapshot);
  // Route the GP at-war filter + ascending-`factionId` sort through the shared
  // [gpAtWarPeaceTargetsWhere] collector skeleton (Refs #3717 expand-peace
  // dedup). Byte-identical: the inline loop skipped non-GP `atWarWith` entries
  // and sorted the result, exactly what the shared helper does; the per-enemy
  // arms (below-quota partner gate, mutual-plateau carve-out, symmetric OW-gap
  // cap, stronger-self guard, sole-GP-blocker hold-open) translate one-to-one
  // into the caller-specific `keep` predicate with no cross-enemy state.
  return gpAtWarPeaceTargetsWhere(
    game: game,
    snapshot: snapshot,
    keep: (factionId) {
      final partnerOw = provinceCountOwnedBy(game, factionId);
      if (!isBelowObserverConquestQuota(partnerOw)) {
        return false;
      }
      final mutualPlateau = isMutualBelowQuotaPlateauPeer(
        ownOw: ownOw,
        partnerOw: partnerOw,
      );
      if (!minorsOnMap && !mutualPlateau) {
        return false;
      }
      if (mutualPlateau &&
          gpOnlyFrontier &&
          !hasUninvadedOldWorldMinor(game: game, snapshot: snapshot)) {
        return true;
      }
      final maxPeerOwGap =
          hasUninvadedOldWorldMinor(game: game, snapshot: snapshot)
          ? _kMaxPeerOwGapWithMinors
          : _kMaxPeerOwGapWithoutMinors;
      if ((partnerOw - ownOw).abs() > maxPeerOwGap) {
        return false;
      }
      if (!mutualPlateau && ownOw > partnerOw) {
        return false;
      }
      if (gpOnlyFrontier &&
          soleGpWar == factionId &&
          !hasUninvadedOldWorldMinor(game: game, snapshot: snapshot)) {
        return false;
      }
      return true;
    },
  );
}

