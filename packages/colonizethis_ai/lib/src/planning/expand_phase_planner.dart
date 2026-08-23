/// EXPAND-phase planner (Refs #2509 S2 / S10; #4602 Slice A).
///
/// Cite `SPEC/ai/ai-architecture.md` § Observer goal phases and
/// `SPEC/ai/phase-planner-architecture.md` rather than restating the
/// EXPAND suppression essay here.
library;

import '../perception/perception_snapshot.dart';
import 'planning_imports.dart' hide cheapestRegimentBuildTreasuryCost;
import 'expand_peace_frontier_helpers.dart';
import 'planning_helpers.dart'
    show gpFactionIdsAtWarWith, peaceTargetsExcludingBlocker;

export 'expand_peace_frontier_helpers.dart';
export 'expand_phase_planner_peer_peace.dart';
export 'expand_phase_planner_economy.dart';
export 'expand_phase_planner_feedstock_acquisition.dart';
export 'expand_phase_planner_gp_blocker_peace.dart';
export 'expand_phase_planner_military.dart';
export 'expand_phase_planner_peace_default_start.dart';
export 'expand_phase_planner_peace_targets.dart';
export 'expand_phase_planner_declare_war.dart';

/// Returns the deterministic list of at-war Great Powers the active player
/// should `offerPeace` toward this turn while in EXPAND phase.
///
/// Contract (issue #2509 § EXPAND phase planner § planExpandPeace, extended
/// by issue #2847 § H4 § H4-a):
///
///   "Peace ALL at-war Great Powers, with ONE exception:
///    → Keep fighting the GP that owns the primary invadable OW frontier
///      blocker (primaryInvadableOldWorldGpBlocker), UNLESS:
///      - It's a mutual-plateau sole GP war on a GP-only cleared frontier
///        with no uninvaded minors (peace to exit stalemate), OR
///      - The sole at-war GP is the only owner of OW provinces adjacent to
///        the active player's territory (geographic peer-war lock) and both
///        sides are in the mutual-plateau below-quota band — the uninvaded
///        OW minor pivot is unreachable from the active player's anchors,
///        so the minor-pivot guard is irrelevant (Refs #2847 § H4-a)."
///
/// Inputs:
///   - [game]: used to (a) filter [ThreatSummary.atWarWith] down to Great
///     Power factions via [Game.playerById]; (b) compute the primary OW
///     frontier blocker by mapping invadable OW provinces to current
///     owners; (c) detect uninvaded OW minors still in play; (d) check
///     whether the invadable OW frontier is held only by GPs (no minor
///     border).
///   - [snapshot]: per-player [AIWorldSnapshot] supplying
///     [ThreatSummary.atWarWith], [ConquestSummary.invadableProvinceIdsSorted],
///     [ConquestSummary.adjacentOwnerFactionIdsSorted], and
///     [ConquestSummary.oldWorldProvincesOwned] for the mutual-plateau
///     comparison.
///
/// Output:
///   - Empty list when no Great Powers are at war with the active player.
///   - Empty list when the sole at-war GP **is** the primary OW invadable
///     blocker and neither carve-out applies (keep fighting the blocker;
///     default EXPAND posture).
///   - All GPs sorted ascending when the primary blocker is `null` or not
///     among the at-war GPs (peace ALL: the legacy "no exception applies"
///     case).
///   - All GPs except the blocker sorted ascending when the blocker is
///     among the at-war GPs and no carve-out fires (peace ALL
///     except the blocker).
///   - The single GP (still sorted as a 1-element list) when the
///     mutual-plateau sole-GP carve-out fires: exactly one GP at war,
///     that GP owns the primary OW invadable blocker, both sides are in
///     the stalled below-quota plateau band
///     ([isMutualBelowQuotaPlateauPeer]), the invadable frontier is
///     GP-only ([isOldWorldGpOnlyInvadableFrontier]), and no uninvaded
///     OW minors remain ([hasUninvadedOldWorldMinor] is false).
///   - The single GP (still sorted as a 1-element list) when the
///     geographic peer-war lock carve-out fires: exactly one GP at war,
///     that GP owns the primary OW invadable blocker, both sides are in
///     the mutual-plateau below-quota band, and
///     [ConquestSummary.adjacentOwnerFactionIdsSorted] is exactly
///     `[blocker]` — the at-war peer GP is the only faction owning OW
///     provinces adjacent to the active player's anchors, so any
///     uninvaded OW minor is geographically unreachable (Refs #2847
///     § H4-a).
///
/// The function is pure and deterministic — identical inputs always yield
/// identical lists (Refs #2509 Must-have #7).
List<String> planExpandPeace({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final gpWars = gpFactionIdsAtWarWith(game, snapshot);
  if (gpWars.isEmpty) {
    return const [];
  }

  final blocker = primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  if (blocker == null || !gpWars.contains(blocker)) {
    return gpWars..sort();
  }

  if (gpWars.length == 1 &&
      isMutualBelowQuotaPlateauPeer(
        ownOw: snapshot.conquest.oldWorldProvincesOwned,
        partnerOw: provinceCountOwnedBy(game, blocker),
      )) {
    if (expandIsGeographicPeerWarLock(snapshot: snapshot, peerGpId: blocker)) {
      return List<String>.unmodifiable(gpWars);
    }
    if (isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot) &&
        !hasUninvadedOldWorldMinor(game: game, snapshot: snapshot)) {
      return List<String>.unmodifiable(gpWars);
    }
  }

  return peaceTargetsExcludingBlocker(factionIds: gpWars, blocker: blocker);
}
