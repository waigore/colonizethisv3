/// EXPAND-phase peer-peace: zero-regiment and mutual-exhausted stalemate peace (Refs #3967 step 4).
///
/// Topic split from `expand_phase_planner_peer_peace.dart`; public
/// symbols remain re-exported by that barrel.
library;

import '../perception/perception_snapshot.dart';
import 'army_conquest_prep.dart' show regimentCountForPlayer;
import 'planning_helpers.dart'
    show
        gpFactionIdsAtWarWith,
        isOwnOldWorldExpansionStalled,
        mutualExhaustedGpStalemateSideQualifies,
        nonGreatPowerAtWarPeaceTargetsWhere;
import 'planning_imports.dart';

/// Returns the deterministic ascending-sorted list of at-war Great Power
/// `factionId`s the active player should `offerPeace` toward this turn
/// when EXPAND-stalled with zero standing regiments — the survival peace
/// arm that releases every GP front so the planner can rebuild a force
/// before any further declare-war or conquest pass.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `stalledZeroRegimentGpPeaceTargets` peace decider previously hosted
/// in `diplomacy_planner_peace_targets.dart`. Implements
/// `SPEC/ai/ai-architecture.md` § Diplomacy targeting — "when stalled
/// below quota with zero regiments, peace every at-war Great Power so
/// rebuild is not blocked by futile fronts (seed-42 gp5/gp6)". This
/// helper covers the GP-vs-GP fronts; the parallel minor/tribe arm is
/// [stalledZeroRegimentAllFactionPeaceTargets] (still hosted in
/// `diplomacy_planner_peace_targets.dart` at this slice — separate
/// canonical-home migration).
///
/// Returns `const []` for either of the outer guards (each `continue`s
/// past the firing branch):
///   1. [isStalledOldWorldExpansion] is `false` for
///      [ConquestSummary.oldWorldProvincesOwned] — outside the stalled
///      OW band the rebuild-peace arm does not engage and the broader
///      EXPAND peace deciders ([planExpandPeace], the
///      `_expandRatchetGreatPowerPeaceTargets` survival chain) own the
///      decision.
///   2. [regimentCountForPlayer] is strictly greater than zero — when
///      the active player still has at least one standing regiment the
///      planner can press the existing GP wars and the zero-regiment
///      survival shortcut does not apply.
///
/// When both guards pass, the function peaces every at-war Great Power
/// (filtered via [Game.playerById] so minors and tribes route to the
/// companion [stalledZeroRegimentAllFactionPeaceTargets]); the returned
/// list is sorted ascending by `factionId` for deterministic ordering
/// regardless of the iteration order of [ThreatSummary.atWarWith]
/// (Refs #2509 Must-have #7).
///
/// `diplomacy_planner_peace_targets.dart` previously retained a thin delegating stub
/// for legacy callers (the existing
/// `diplomacy_planner_below_quota_peace_part3_test.dart` § "all GP wars
/// when stalled" fixture and the in-file
/// `_survivalGreatPowerPeaceTargets` / `collectStalledGreatPowerPeaceTargets`
/// `zeroRegimentBlockerPeace` / `stalledOwExpansionNeedsPeacePass`
/// consumer chains) so the now-completed S1 deletion of that file leaves no
/// orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// lists (Refs #2509 Must-have #7). Linear in [ThreatSummary.atWarWith]
/// (each at-war faction is inspected once); constant-time on the outer
/// guard arms.
List<String> stalledZeroRegimentGpPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isZeroRegimentSurvivalOwContext(
    snapshot.conquest.oldWorldProvincesOwned,
  )) {
    return const [];
  }
  if (regimentCountForPlayer(game, snapshot.playerId) > 0) {
    return const [];
  }
  final targets = gpFactionIdsAtWarWith(game, snapshot);
  return targets;
}

/// Returns the deterministic single-element list with the sole at-war
/// Great Power's `factionId` when both the active player and the lone GP
/// enemy have zero standing regiments — the mutual-stalemate reset arm
/// that exits a regiment-exhausted GP-only frontier.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `mutualZeroRegimentGpStalematePeaceTargets` peace decider previously
/// hosted in `diplomacy_planner_peace_targets.dart`. Implements the
/// "zero-regiment mutual stalemate" carve-out from
/// `SPEC/ai/ai-architecture.md` § Diplomacy targeting — without this
/// arm, two GPs that have driven each other to zero regiments on a
/// GP-only invadable frontier stay locked at war with no armies until
/// one side rebuilds, which the [stalledZeroRegimentGpPeaceTargets]
/// general arm cannot resolve when the partner is the canonical OW
/// frontier blocker (the GP-only-frontier carve-out in
/// `collectStalledGreatPowerPeaceTargets` would otherwise re-add the
/// blocker to the keep-at-war set). The mutually-exhausted variant
/// [mutualExhaustedBelowQuotaGpStalematePeaceTargets] (still hosted in
/// `diplomacy_planner_peace_targets.dart` at this slice — separate
/// canonical-home migration) covers the same stalemate at non-zero but
/// critically low regiment counts.
///
/// Returns `const []` for any of the outer guards (in order):
///   1. [isStalledOldWorldExpansion] is `false` for
///      [ConquestSummary.oldWorldProvincesOwned] — outside the stalled
///      OW band the planner is still pressing OW expansion and the
///      mutual-stalemate reset does not apply.
///   2. [regimentCountForPlayer] is strictly greater than zero for the
///      active player — the reset only fires when this GP has already
///      exhausted its standing army.
///   3. The active player has anything other than exactly one Great
///      Power in [ThreatSummary.atWarWith] (filtered via
///      [Game.playerById]). Multi-GP wars are handled by the broader
///      [multiFrontNonBlockerGpPeaceTargets] family; zero-GP wars
///      cannot return a peace target.
///   4. The sole GP enemy still has at least one standing regiment
///      ([regimentCountForPlayer] strictly greater than zero) — the
///      reset requires both sides to be exhausted so neither can press
///      the war forward.
///
/// When every guard passes, the function returns the single-element
/// list containing the lone enemy's `factionId` (one element so sort
/// order is trivial).
///
/// `diplomacy_planner_peace_targets.dart` previously retained a thin delegating stub
/// for legacy callers (the in-file
/// `_survivalGreatPowerPeaceTargets` / `collectStalledGreatPowerPeaceTargets`
/// `zeroRegimentBlockerPeace` / `stalledOwExpansionNeedsPeacePass`
/// consumer chains) so the now-completed S1 deletion of that file leaves no
/// orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// lists (Refs #2509 Must-have #7). Linear in [ThreatSummary.atWarWith]
/// for the GP-war filter; constant-time on every other arm.
List<String> mutualZeroRegimentGpStalematePeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isOwnOldWorldExpansionStalled(snapshot)) {
    return const [];
  }
  if (regimentCountForPlayer(game, snapshot.playerId) > 0) {
    return const [];
  }
  final gpWars = gpFactionIdsAtWarWith(game, snapshot);
  if (gpWars.length != 1) {
    return const [];
  }
  final enemy = gpWars.single;
  if (regimentCountForPlayer(game, enemy) > 0) {
    return const [];
  }
  return [enemy];
}

/// Returns the deterministic ascending-sorted list of at-war minor and
/// tribe `factionId`s the active player should `offerPeace` toward when
/// below the observer quota, stalled, and holding zero standing regiments.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `stalledZeroRegimentAllFactionPeaceTargets` peace decider previously
/// hosted in `diplomacy_planner_peace_targets.dart`. Implements
/// `SPEC/ai/ai-architecture.md` § Diplomacy targeting — the minor/tribe
/// companion to [stalledZeroRegimentGpPeaceTargets] (GP-vs-GP fronts).
///
/// Returns `const []` when [isBelowObserverConquestQuota] is `false`,
/// [isStalledOldWorldExpansion] is `false`, or the active player still
/// holds at least one standing regiment. When all guards pass, peaces
/// every at-war faction that is not a Great Power ([Game.playerById]
/// is `null`), sorted ascending (Refs #2509 Must-have #7).
///
/// `diplomacy_planner_peace_targets.dart` previously retained a thin delegating stub
/// for legacy callers until the now-completed S1 deletion of that file.
List<String> stalledZeroRegimentAllFactionPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isZeroRegimentSurvivalOwContext(
    snapshot.conquest.oldWorldProvincesOwned,
  )) {
    return const [];
  }
  if (regimentCountForPlayer(game, snapshot.playerId) > 0) {
    return const [];
  }
  // Route the non-GP (minor + tribe) at-war filter + ascending sort through the
  // shared [nonGreatPowerAtWarPeaceTargetsWhere] collector (Refs #3749 step 5
  // expand-peace collector dedup). Byte-identical to the inline
  // `playerById == null` comprehension + `..sort()`: the collector keeps the
  // bare non-GP `playerById == null` membership test (not the minor/tribe
  // membership predicates) so absorbed-faction at-war ids are preserved.
  return nonGreatPowerAtWarPeaceTargetsWhere(game: game, snapshot: snapshot);
}

/// Returns the sole at-war GP enemy when both sides are mutual-plateau peers
/// below quota and mutually exhausted in regiments and treasury.
///
/// Canonical home (Refs #2509 S1) for
/// `mutualExhaustedBelowQuotaGpStalematePeaceTargets`.
List<String> mutualExhaustedBelowQuotaGpStalematePeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  // Route the duplicated per-side "mutual-exhausted below-quota GP stalemate"
  // qualification through the shared [mutualExhaustedGpStalemateSideQualifies]
  // helper (Refs #3717 offer-peace / expand-peace scoring-skeleton dedup). The
  // helper bundles the same side-effect-free guards (min-OW + below-quota +
  // stalled + known player + treasury/regiment exhaustion) the inline checks
  // applied for both the active player and the enemy GP, so the result is
  // byte-identical; the inter-side `(enemyOw - ownOw).abs()` proximity gate
  // stays here.
  if (!mutualExhaustedGpStalemateSideQualifies(
    game: game,
    factionId: snapshot.playerId,
    ow: ownOw,
  )) {
    return const [];
  }
  final gpWars = gpFactionIdsAtWarWith(game, snapshot);
  if (gpWars.length != 1) {
    return const [];
  }
  final enemy = gpWars.single;
  final enemyOw = provinceCountOwnedBy(game, enemy);
  if (!mutualExhaustedGpStalemateSideQualifies(
    game: game,
    factionId: enemy,
    ow: enemyOw,
  )) {
    return const [];
  }
  if ((enemyOw - ownOw).abs() > 1) {
    return const [];
  }
  return [enemy];
}
