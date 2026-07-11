/// EXPAND-phase peer-peace: below-quota peer GP and regiment-thin tribe distraction (Refs #3967 step 4).
///
/// Topic split from `expand_phase_planner_peer_peace.dart`; public
/// symbols remain re-exported by that barrel.
library;

import '../perception/perception_snapshot.dart';
import 'army_conquest_prep.dart' show regimentCountForPlayer;
import 'expand_peace_frontier_helpers.dart'
    show
        anyMinorOwnsOldWorldProvince,
        hasUninvadedOldWorldMinor,
        isMutualBelowQuotaPlateauPeer,
        isOldWorldGpOnlyInvadableFrontier,
        soleAtWarGreatPowerId;
import 'planning_helpers.dart'
    show
        gpAtWarPeaceTargetsWhere,
        isOwnOldWorldBelowConquestQuota,
        tribeAtWarPeaceTargetsWhere;
import 'planning_imports.dart';

/// Maximum OW province gap a below-quota peer war is peaced across when an
/// uninvaded OW minor pivot remains on the map (Refs #2509).
///
/// While at least one OW minor still owns provinces and is not already at
/// war with the active player, the EXPAND-phase peer-stalled peace decider
/// [belowQuotaPeerGpPeaceTargets] is allowed to peace below-quota Great
/// Power peers within this OW deficit so the planner can pivot off mutual
/// gp5/gp6 distraction wars and chase the minor frontier instead. Once the
/// last uninvaded minor has been declared on, the gap collapses to
/// [_kMaxPeerOwGapWithoutMinors] (1) to keep the below-quota peer-stalled
/// pivot tight (no arbitrary GP-war dumps on far-apart peers).
///
/// Equivalent to the legacy magic value `3` in
/// `colonial_pressure.dart::belowQuotaPeerGpPeaceTargets`; named here as a
/// private constant so the canonical move documents the SPEC contract
/// (`SPEC/ai/ai-architecture.md` § Observer goal phases EXPAND
/// "While uninvaded OW minors remain, also peace below-quota GP peers
/// within three provinces") without changing the runtime value.
const int _kMaxPeerOwGapWithMinors = 3;

/// Maximum OW province gap a below-quota peer war is peaced across when no
/// uninvaded OW minor pivot remains (Refs #2509).
///
/// Companion to [_kMaxPeerOwGapWithMinors]: once every on-map minor is
/// already at war with the active player (or no minors remain at all), the
/// EXPAND-phase peer-stalled peace decider [belowQuotaPeerGpPeaceTargets]
/// only peaces below-quota Great Power peers within one OW province of the
/// active player. Equivalent to the legacy magic value `1` in
/// `colonial_pressure.dart::belowQuotaPeerGpPeaceTargets`.
const int _kMaxPeerOwGapWithoutMinors = 1;

/// Returns the deterministic ascending-sorted list of at-war below-quota
/// Great Power `factionId`s the active player should `offerPeace` toward
/// in EXPAND when the peer-stalled peace pivot applies, or `const []`
/// when the pivot does not fire this turn.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `belowQuotaPeerGpPeaceTargets` peace decider previously hosted in
/// `colonial_pressure.dart`. The decider implements the EXPAND-phase
/// "peace other below-quota Great Powers in peer-stalled wars while
/// minors remain on the map" pivot for seed-42 gp5/gp6 (mutual gp5/gp6
/// distraction wars). It composes the canonical helpers
/// [isOldWorldGpOnlyInvadableFrontier], [soleAtWarGreatPowerId],
/// [isMutualBelowQuotaPlateauPeer], and [hasUninvadedOldWorldMinor] with
/// the below-quota peer-gap band table from `SPEC/ai/ai-architecture.md`
/// § Observer goal phases (EXPAND) "While uninvaded OW minors remain,
/// also peace below-quota GP peers within three provinces".
///
/// Returns `const []` for the outer guard:
///   * [isBelowObserverConquestQuota] is `false` for
///     [ConquestSummary.oldWorldProvincesOwned] — at or above the
///     observer OW quota the quota-met futile-peace collectors
///     ([quotaMetFutileBelowQuotaGpPeaceTargets] et al, still in
///     `colonial_pressure.dart` at this slice) take over.
///
/// When the outer guard passes, the function iterates
/// [ThreatSummary.atWarWith] and selects below-quota Great Power peers
/// (filtered via [Game.playerById]; partners passing
/// [isBelowObserverConquestQuota] only) per the two-arm contract:
///
///   * **Mutual-plateau GP-only-frontier carve-out** — when the peer
///     war is a mutual-plateau sole-GP stalemate
///     ([isMutualBelowQuotaPlateauPeer] is `true`) on a GP-only
///     invadable frontier ([isOldWorldGpOnlyInvadableFrontier] is
///     `true`) with no uninvaded OW minors remaining
///     ([hasUninvadedOldWorldMinor] is `false`), peace the lone GP
///     partner so the planner can exit the stalemate even when the
///     standard peer-gap / stronger-self guards would otherwise hold
///     the war open. This carve-out fires unconditionally — the peer
///     stays in the result regardless of the OW gap.
///
///   * **Standard peer-gap arm** — every other shape. The arm fires
///     only when at least one minor still owns OW provinces (the
///     `minorsOnMap` precondition; not the same as
///     `hasUninvadedOldWorldMinor` because an on-map minor already at
///     war with the active player still satisfies `minorsOnMap` but
///     not `hasUninvadedOldWorldMinor`) or when the mutual-plateau
///     guard fires above. The arm then enforces three gates in order:
///       1. **Symmetric OW-gap cap** — `(partnerOw - ownOw).abs()` must
///          be within `[_kMaxPeerOwGapWithMinors]` (`3`) when an
///          uninvaded minor pivot remains, otherwise within
///          `[_kMaxPeerOwGapWithoutMinors]` (`1`). The cap prevents
///          the weaker peer from dumping below-quota GP wars at
///          arbitrary OW gaps.
///       2. **Stronger-self symmetry guard** — when the peer war is
///          not a mutual-plateau and the active player holds more OW
///          provinces than the partner (`ownOw > partnerOw`), the
///          partner is **not** peaced; only the weaker peer pivots
///          off the distraction war (the spec is symmetric around the
///          mutual-plateau equality band).
///       3. **Sole-GP-blocker hold-open** — when the GP-only-frontier
///          arm fires ([isOldWorldGpOnlyInvadableFrontier] is `true`)
///          and the partner is the sole at-war GP
///          ([soleAtWarGreatPowerId] returns the partner's id) with
///          an uninvaded minor pivot still missing
///          ([hasUninvadedOldWorldMinor] is `false`), the war is held
///          open (the partner is skipped) so the planner keeps
///          fighting the lone GP blocker. The mutual-plateau
///          carve-out above intentionally short-circuits before this
///          guard so a mutual-plateau sole-GP stalemate still peaces
///          out even on a GP-only frontier.
///
/// The returned list is sorted ascending by `factionId` for
/// deterministic ordering (Must-have #7). Tribes, minors, and at-war
/// GPs that fail [isBelowObserverConquestQuota] are dropped silently.
///
/// `colonial_pressure.dart` previously retained a thin delegating stub for legacy
/// callers (the existing `colonial_pressure_test.dart` and
/// `colonial_pressure_peer_gap_boundary_test.dart` fixtures, the
/// `diplomacy_planner.dart` /
/// `diplomacy_planner_peace_targets.dart` /
/// `diplomatic_candidate_scoring_offer_peace.dart` consumer chain, and
/// the related `colonial_pressure_*` branch-coverage fixtures that
/// reference the peer-gap helper) so the now-completed S1 deletion of that
/// file leaves no orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// lists (Refs #2509 Must-have #7). Linear in [ThreatSummary.atWarWith]
/// with one [provinceCountOwnedBy] scan per at-war faction; the
/// composed [isOldWorldGpOnlyInvadableFrontier],
/// [soleAtWarGreatPowerId], [isMutualBelowQuotaPlateauPeer], and
/// [hasUninvadedOldWorldMinor] helpers are themselves linear in the
/// OW invadable / minor sets, matching the budget-rule note in
/// `colonizethis-turn-resolution-budget.mdc` (no global province /
/// tile scans introduced by the move).
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

/// Returns the deterministic ascending-sorted list of at-war tribe
/// `factionId`s the active player should `offerPeace` toward in EXPAND
/// while below the observer OW quota with a regiment count too small to
/// split across multiple fronts, or `const []` when the
/// distraction-peace pivot does not apply.
///
/// Tribe analogue of [belowQuotaMultiMinorDistractionPeaceTargets]
/// (Refs #2847 § H5). The minor decider concentrates a regiment-thin
/// below-quota GP on its focused OW minor by peacing every *other*
/// at-war minor; this decider drops the parallel *tribe* distraction
/// fronts the minor decider deliberately ignores (its guard keeps only
/// [Game.minorNations] members).
///
/// Distinct from [atWarGpDistractionTribePeaceTargets], which fires only
/// when an at-war Great Power front is present (the COLONIAL-phase
/// consolidation pivot). The seed-42 gp4 stall is a below-quota EXPAND
/// GP at peace with every Great Power yet diluted across several
/// simultaneous tribe wars, so the GP-front guard never admits it; this
/// decider supplies the missing below-quota tribe-distraction pivot.
///
/// **Old-World-conquest-value preservation:** only *pure distraction*
/// tribes are peaced — a tribe that owns **zero** Old World provinces
/// (`oldWorldProvinceCountOwnedBy(game, tribeId) == 0`). Such a tribe
/// offers no OW conquest value, so its war only drains the thin regiment
/// pool. A tribe that owns **any** OW province is kept at war: it is
/// either the immediately invadable frontier, a next-hop multi-turn
/// march target (Refs #2847 § H4-b minor-transit frontier march), or a
/// distant-but-real slow conquest the EXPAND ratchet would still
/// complete. Peacing it would forfeit OW gain. This keeps the pivot
/// surgical: it releases the regiment pool from value-less tribe fronts
/// (seed-42 gp4) while protecting the productive / en-route tribe wars
/// the EXPAND ratchet is winning (seed-42 gp3 / gp6 OW-tribe baselines).
///
/// Returns `const []` for any of the outer guards (in order), mirroring
/// [belowQuotaMultiMinorDistractionPeaceTargets]:
///   1. [isBelowObserverConquestQuota] is `false` for
///      [ConquestSummary.oldWorldProvincesOwned].
///   2. `regimentCount <= 0` — the zero-regiment survival deciders own
///      the peace decision below the affordability gate.
///   3. `regimentCount >= kBelowQuotaPeaceMinRegimentsBeforeDeclareWar`
///      — a force able to project across multiple fronts can sustain
///      the tribe wars while it walks the EXPAND ratchet.
///   4. [ConquestSummary.invadableProvinceIdsSorted] is empty — no OW
///      frontier means no consolidation push to concentrate on.
///
/// When the guards pass it peaces every at-war tribe (membership tested
/// via [Game.tribes]) that owns zero Old World provinces
/// (`oldWorldProvinceCountOwnedBy(game, tribeId) == 0`), sorted ascending
/// for deterministic ordering.
///
/// Pure and deterministic — identical inputs always yield identical
/// lists (Refs #2509 Must-have #7). Linear in [ThreatSummary.atWarWith]
/// with one [oldWorldProvinceCountOwnedBy] lookup per at-war tribe
/// (itself bounded by the per-faction province index); no new global
/// province / tile scans introduced, matching the budget-rule note in
/// `colonizethis-turn-resolution-budget.mdc`.
List<String> belowQuotaRegimentThinTribeDistractionPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isOwnOldWorldBelowConquestQuota(snapshot)) {
    return const [];
  }
  final regimentCount = regimentCountForPlayer(game, snapshot.playerId);
  if (regimentCount <= 0 ||
      regimentCount >= kBelowQuotaPeaceMinRegimentsBeforeDeclareWar) {
    return const [];
  }
  if (snapshot.conquest.invadableProvinceIdsSorted.isEmpty) {
    return const [];
  }
  // Route the at-war-tribe filter + ascending sort through the shared
  // [tribeAtWarPeaceTargetsWhere] collector (Refs #3717 expand-peace
  // scoring-skeleton dedup); only the zero-OW-province distraction exclusion
  // remains caller-specific. Byte-identical to the inline `isTribeFaction` +
  // zero-OW predicate + sort.
  return tribeAtWarPeaceTargetsWhere(
    game: game,
    snapshot: snapshot,
    keep: (factionId) => oldWorldProvinceCountOwnedBy(game, factionId) == 0,
  );
}
