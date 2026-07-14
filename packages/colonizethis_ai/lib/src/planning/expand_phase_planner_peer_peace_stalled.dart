/// EXPAND-phase peer-peace: stalled futile GP, GP-distraction tribe, and multi-front non-blocker (Refs #3967 step 4).
///
/// Topic split from `expand_phase_planner_peer_peace.dart`; public
/// symbols remain re-exported by that barrel.
library;

import '../perception/perception_snapshot.dart';
import 'expand_peace_frontier_helpers.dart'
    show primaryInvadableOldWorldGpBlocker;
import 'planning_helpers.dart'
    show
        anyInvadableProvinceOwnedByMinor,
        factionOwnsInvadableOldWorldProvince,
        gpAtWarPeaceTargetsWhere,
        gpFactionIdsAtWarWith,
        isAtWarWithAnyGreatPower,
        isOwnOldWorldExpansionStalled,
        peaceTargetsExcludingBlocker,
        tribeAtWarPeaceTargetsWhere;
import 'planning_imports.dart';

/// Returns the deterministic ascending-sorted list of at-war Great Power
/// `factionId`s the active player should `offerPeace` toward in EXPAND
/// when stalled below the observer quota and minors still hold
/// invadable Old World land — the legacy "stalled futile GP" peace
/// pivot — or `const []` when the pivot does not apply this turn.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `stalledFutileGpPeaceTargets` peace decider previously hosted in
/// `diplomacy_planner_peace_targets.dart`. The decider implements the
/// EXPAND-phase "while stalled with a minor still on the invadable
/// frontier, peace every at-war Great Power that owns none of the
/// invadable OW provinces" pivot — distracting GP wars are dropped so
/// the planner can focus regiments on the invadable minor frontier.
///
/// Returns `const []` for any of the outer guards (in order):
///   1. [isStalledOldWorldExpansion] is `false` for
///      [ConquestSummary.oldWorldProvincesOwned] — the planner is
///      not in the stalled OW band so the futile-GP shortcut does
///      not apply (above-quota collectors take over).
///   2. [ConquestSummary.invadableProvinceIdsSorted] is empty — no
///      OW invasion target exists so a futile-GP diagnosis is not
///      possible this turn.
///   3. No minor owns any province in
///      [ConquestSummary.invadableProvinceIdsSorted] — the frontier
///      is GP-only / unowned, so the "stalled with minors still
///      holding invadable land" precondition is missing and the
///      `stalledGpBlockerFocusPeaceTargets` collector owns the
///      decision instead.
///
/// When the guards pass, the function peaces every at-war Great
/// Power (filtered via [Game.playerById]) that does **not** own any
/// province in [ConquestSummary.invadableProvinceIdsSorted] — GPs
/// that own at least one invadable OW province are kept at war
/// (active blockers that
/// `stalledGpBlockerFocusPeaceTargets` / `stalledStrongerGpBlockerPeaceTarget`
/// will route through their own arms). The output is sorted
/// ascending by `factionId` for deterministic ordering.
///
/// `diplomacy_planner_peace_targets.dart` previously retained a thin delegating
/// stub for legacy callers (the existing
/// `diplomacy_planner_stalled_peace_test.dart` § `stalledFutileGpPeaceTargets`
/// fixture and the `_expandRatchetGreatPowerPeaceTargets` /
/// `stalledOwExpansionNeedsPeacePass` consumer chains within
/// `diplomacy_planner_peace_targets.dart` itself) so the planned S1
/// deletion of that file leaves no orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// lists (Refs #2509 Must-have #7). Linear in
/// [ThreatSummary.atWarWith], plus a single [getProvinceOwnerMap]
/// pass shared with the `minorsOwnInvadable` precondition scan,
/// matching the budget-rule note in
/// `colonizethis-turn-resolution-budget.mdc` (no global province /
/// tile scans introduced by the move).
List<String> stalledFutileGpPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isOwnOldWorldExpansionStalled(snapshot)) {
    return const [];
  }
  if (snapshot.conquest.invadableProvinceIdsSorted.isEmpty) {
    return const [];
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final minorsOwnInvadable = anyInvadableProvinceOwnedByMinor(
    game: game,
    snapshot: snapshot,
    provinceOwner: provinceOwner,
  );
  if (!minorsOwnInvadable) {
    return const [];
  }
  // Route the GP at-war filter + ascending-`factionId` sort through the shared
  // [gpAtWarPeaceTargetsWhere] collector skeleton (Refs #3717 expand-peace
  // dedup), matching the sibling deciders in this family. Byte-identical: the
  // inline loop skipped non-GP `atWarWith` entries and sorted the result,
  // exactly what the shared helper does; only the invadable-owner exclusion
  // remains caller-specific here.
  return gpAtWarPeaceTargetsWhere(
    game: game,
    snapshot: snapshot,
    keep: (factionId) => !factionOwnsInvadableOldWorldProvince(
      snapshot: snapshot,
      provinceOwner: provinceOwner,
      factionId: factionId,
    ),
  );
}

/// Returns the deterministic ascending-sorted list of at-war tribe
/// `factionId`s the active player should `offerPeace` toward in
/// EXPAND when stalled below the observer quota and at least one
/// at-war Great Power is on the same map — the legacy "GP-distraction
/// tribe peace" pivot — or `const []` when the pivot does not apply
/// this turn.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `atWarGpDistractionTribePeaceTargets` peace decider previously
/// hosted in `diplomacy_planner_peace_targets.dart`. The decider
/// implements the EXPAND-phase "while OW-stalled and at war with at
/// least one Great Power, peace every at-war tribe so regiments
/// concentrate on the OW consolidation push" pivot. Tribes are
/// distractions during a GP war regardless of which province they
/// own — they do not block OW invadable progress and their wars
/// drain regiments / treasury away from the GP front. (Tribes are
/// non-Great-Power, non-Minor factions registered under
/// [Game.tribes]; see `colonizethis-data` faction taxonomy.)
///
/// Returns `const []` for any of the outer guards (in order):
///   1. [isStalledOldWorldExpansion] is `false` for
///      [ConquestSummary.oldWorldProvincesOwned] — the planner is
///      not in the stalled OW band so the GP-distraction tribe
///      shortcut does not apply.
///   2. No at-war Great Power is present in
///      [ThreatSummary.atWarWith] (filtered via [Game.playerById])
///      — without an active GP front there is no OW consolidation
///      pressure to justify peacing tribes.
///
/// When the guards pass, the function emits every at-war tribe
/// (membership tested via [Game.tribes]) sorted ascending by
/// `factionId` for deterministic ordering. Minors and at-war Great
/// Powers in [ThreatSummary.atWarWith] are filtered out — minors
/// are routed through the focus / futile minor collectors and GPs
/// through the GP-blocker / consolidate collectors.
///
/// `diplomacy_planner_peace_targets.dart` previously retained a thin delegating
/// stub for legacy callers (the
/// `_expandRatchetGreatPowerPeaceTargets` / `collectStalledGreatPowerPeaceTargets`
/// consumer chains within `diplomacy_planner_peace_targets.dart`
/// itself, the `stalledOwExpansionNeedsPeacePass` predicate, and any
/// COLONIAL-phase tribe-peace flag consumers via
/// `collectStalledGreatPowerPeaceTargets`) so the now-completed S1 deletion
/// of that file leaves no orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// lists (Refs #2509 Must-have #7). Linear in
/// [ThreatSummary.atWarWith] across both filter passes, no global
/// province / tile scans introduced by the move, matching the
/// budget-rule note in `colonizethis-turn-resolution-budget.mdc`.
List<String> atWarGpDistractionTribePeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isOwnOldWorldExpansionStalled(snapshot)) {
    return const [];
  }
  final atWarWithGp = isAtWarWithAnyGreatPower(game, snapshot);
  if (!atWarWithGp) {
    return const [];
  }
  // Route the at-war-tribe filter + ascending sort through the shared
  // [tribeAtWarPeaceTargetsWhere] collector (Refs #3717 expand-peace
  // scoring-skeleton dedup), matching the sibling GP/minor collectors. This
  // decider keeps every at-war tribe (no extra predicate), so no `keep` is
  // supplied; byte-identical to the inline `isTribeFaction` + sort.
  return tribeAtWarPeaceTargetsWhere(game: game, snapshot: snapshot);
}

/// When fighting 2+ Great Powers, peace every non-blocker GP; also peace a
/// sole non-blocker GP war while invadable OW remains (Refs #2509).
///
/// Canonical home (Refs #2509 S1) for `multiFrontNonBlockerGpPeaceTargets`.
List<String> multiFrontNonBlockerGpPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final gpWars = gpFactionIdsAtWarWith(game, snapshot);
  if (gpWars.isEmpty) {
    return const [];
  }
  if (!isOwnOldWorldExpansionStalled(snapshot) &&
      snapshot.conquest.invadableProvinceIdsSorted.isEmpty) {
    return const [];
  }
  var blocker = primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  if (blocker == null) {
    var bestOw = 0;
    for (final factionId in gpWars) {
      final ow = provinceCountOwnedBy(game, factionId);
      if (ow > bestOw) {
        bestOw = ow;
        blocker = factionId;
      }
    }
  }
  if (blocker == null) {
    return const [];
  }
  if (gpWars.length == 1 && gpWars.single != blocker) {
    return gpWars;
  }
  if (gpWars.length <= 1) {
    return const [];
  }
  return peaceTargetsExcludingBlocker(factionIds: gpWars, blocker: blocker);
}
