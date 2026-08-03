import '../perception/perception_snapshot.dart';
import '../util/faction_query.dart';
import 'expand_phase_planner_gp_blocker_peace_pivot.dart';
import 'expand_phase_planner_peace_targets.dart';
import 'expand_peace_frontier_helpers.dart';
import 'planning_helpers.dart';
import 'planning_imports.dart';

/// Returns the deterministic ascending-sorted list of at-war minor and
/// tribe `factionId`s the active player should `offerPeace` toward in
/// EXPAND while stalled, dropping every "distraction" minor / tribe war
/// except the focused-minor target and the primary OW frontier GP
/// blocker, or `const []` when the distraction-peace pivot does not
/// apply.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `stalledExpansionDistractionPeaceTargets` peace decider previously
/// hosted in `diplomacy_planner_peace_targets.dart`. The decider
/// implements the EXPAND-phase "while stalled in OW expansion, peace
/// every at-war minor / tribe distraction front so the planner can
/// concentrate on the focused minor target and the primary OW frontier
/// GP blocker" pivot. The companion GP-blocker preservation
/// ([primaryInvadableOldWorldGpBlocker]) keeps a single GP war open
/// when [isStalledOldWorldGpBlockerFocus] applies — the focused-minor
/// preservation ([stalledFocusMinorTarget]) keeps a single minor war
/// open when an at-war minor still owns an invadable OW frontier
/// province.
///
/// Returns `const []` for any of the outer guards (in order):
///   1. [isStalledOldWorldExpansion] is `false` for
///      [ConquestSummary.oldWorldProvincesOwned] — only the stalled
///      OW band routes through this distraction-peace decider.
///   2. [ThreatSummary.atWarWith] is empty — nothing to peace.
///   3. Neither `minorsOwnInvadable` (any invadable OW province is
///      owned by an OW minor) nor [isStalledOldWorldGpBlockerFocus]
///      is true — no minor-on-frontier pivot and no GP-blocker-focus
///      band so the distraction-peace pivot does not own the decision.
///
/// When the guards pass:
///   * `keepMinor` ← [stalledFocusMinorTarget] when an OW minor still
///     owns at least one invadable OW province (preserve the focused
///     minor war so the planner can finish that frontier); otherwise
///     `null`.
///   * `keepGp` ← [primaryInvadableOldWorldGpBlocker] when the GP-only
///     invadable-frontier band fires ([isStalledOldWorldGpBlockerFocus]
///     is true); otherwise `null`.
///   * Walks [ThreatSummary.atWarWith] in iteration order and keeps
///     every minor / tribe entry that is **not** `keepMinor`, **not**
///     `keepGp`, and is a minor or tribe per the shared
///     [isMinorOrTribeFaction] predicate ([Game.minorNations] /
///     [Game.tribes] membership). GPs are dropped because the
///     GP-blocker and peer-GP peace deciders own that decision.
///   * Sorts the result ascending so emission order is deterministic
///     for fixed inputs (Refs #2509 Must-have #7).
///
/// `diplomacy_planner_peace_targets.dart` previously retained a thin delegating
/// stub for the legacy `diplomacy_planner_stalled_peace_test.dart`
/// fixture and the in-file `_expandRatchetGreatPowerPeaceTargets` /
/// `stalledOwExpansionNeedsPeacePass` consumer chains until the
/// now-completed S1 deletion of that file.
///
/// Pure and deterministic — identical inputs always yield identical
/// output (Refs #2509 Must-have #7). Linear in
/// [ConquestSummary.invadableProvinceIdsSorted] for the
/// `minorsOwnInvadable` scan plus a single pass over
/// [ThreatSummary.atWarWith]; matches the budget-rule note in
/// `colonizethis-turn-resolution-budget.mdc` (no global province /
/// tile scans introduced by the move).
List<String> stalledExpansionDistractionPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isOwnOldWorldExpansionStalled(snapshot)) {
    return const [];
  }
  if (snapshot.threats.atWarWith.isEmpty) {
    return const [];
  }
  final pivot = resolveStalledMinorOrGpBlockerPivot(
    game: game,
    snapshot: snapshot,
  );
  if (pivot == null) {
    return const [];
  }
  final minorsOwnInvadable = pivot.minorsOwnInvadable;
  final gpBlockerFocus = pivot.gpBlockerFocus;
  final keepMinor = minorsOwnInvadable
      ? stalledFocusMinorTarget(game: game, snapshot: snapshot)
      : null;
  final keepGp = gpBlockerFocus
      ? primaryInvadableOldWorldGpBlocker(game: game, snapshot: snapshot)
      : null;
  final targets = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (factionId != keepMinor &&
          factionId != keepGp &&
          isMinorOrTribeFaction(game, factionId))
        factionId,
  ]..sort();
  return targets;
}
