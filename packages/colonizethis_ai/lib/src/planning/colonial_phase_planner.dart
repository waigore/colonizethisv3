/// COLONIAL-phase planner (Refs #2509 S3 / S10).
///
/// Phase planner module from the single-goal architecture in
/// [GitHub issue #2509](https://github.com/waigore/colonizethisv3/issues/2509)
/// and `SPEC/ai/ai-architecture.md` § Observer goal phases. The planner is a
/// pure-function module that makes one primary decision per domain with no
/// cross-phase score aggregation.
///
/// COLONIAL phase goal: transfer every `newWorld|` province to GP ownership
/// using the fastest legal acquisition path (Join Empire, `purchase_land`,
/// or `declareWar` + invasion). Callers are expected to dispatch to this
/// module **only** when `observerGoalPhaseFor` resolves to
/// `ObserverGoalPhase.colonial`; the planner functions themselves do not
/// re-check the phase, matching the convention established by
/// `develop_phase_planner.dart` (Refs #2509 S4) and
/// `expand_phase_planner.dart` (Refs #2509 S2).
///
/// Wiring this module into the orchestrator, replacing the legacy
/// `colonialPhaseGpPeaceTargets` helper in `observer_goal_phase.dart`, and
/// retiring the `colonial_pressure.dart` / `diplomacy_planner_peace_targets.dart`
/// ratchet helpers are out of scope for this slice (tracked under S5 / S1
/// of #2509). Both the legacy `colonialPhaseGpPeaceTargets` helper and the
/// new `planColonialPeace` function remain pinned at the function-unit
/// level until the orchestrator rewrite reconciles them, so this slice
/// carries **zero behavior change** and **zero regression risk** for live
/// AI play.
///
/// In-module contracts shipped to date (see issue #2509 § COLONIAL phase
/// planner for the full set, including the deferred
/// `planColonialAcquisition`, `planColonialMilitary`, `planColonialNaval`,
/// `planColonialCivilian`, `planColonialLiteOvertures`, and
/// `planColonialLiteNaval`):
///
///   `planColonialPeace(game, snapshot) → List<String>`
///     Returns the deterministic list of at-war Great Powers the active
///     player should `offerPeace` toward in COLONIAL. Defaults to peacing
///     **all** at-war GPs except the one identified by
///     [primaryColonialGpBlocker] (the GP owning the most invadable
///     `newWorld|` provinces -- the primary colonial NW frontier blocker).
///     The new spec text from issue #2509 § COLONIAL phase planner §
///     planColonialPeace is "Peace all at-war Great Powers, with ONE
///     exception: Keep fighting a GP that owns a province blocking the
///     primary colonial NW target". Tribe and minor at-war factions are
///     filtered out via [Game.playerById] returning `null` for non-player
///     ids -- COLONIAL diplomatic peace is GP-vs-GP only; tribe/minor
///     colonial wars are pursued through other phase-planner contracts
///     (`planColonialAcquisition` for `establishOverture` / Join Empire
///     / `purchase_land`, `planColonialMilitary` for NW conquest army
///     moves) which are deferred to follow-up S3 slices.
library;

import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';
import 'observer_goal_phase.dart' show primaryColonialGpBlocker;

/// Returns the deterministic list of at-war Great Powers the active player
/// should `offerPeace` toward this turn while in COLONIAL phase.
///
/// Contract (issue #2509 § COLONIAL phase planner § planColonialPeace):
///
///   "Peace all at-war Great Powers, with ONE exception:
///    → Keep fighting a GP that owns a province blocking the primary
///      colonial NW target (primaryColonialGpBlocker).
///
///    Never peace tribe/minor colonial targets until:
///    → Objective met (tribe no longer owns the target NW province), OR
///    → War is unwinnable (zero regiments, no treasury, can't build)."
///
/// The tribe/minor exception is handled structurally by this function: a
/// tribe or minor in [ThreatSummary.atWarWith] does not satisfy
/// `game.playerById(factionId) != null` (only [Player] entries are
/// returned from that lookup), so non-GP factions are filtered out before
/// the blocker pass. `offerPeace` toward tribes / minors therefore is
/// **never** emitted by this planner — the tribe / minor war-continuation
/// rule is preserved by exclusion. Conversely, `establishOverture`,
/// `purchase_land`, and NW conquest are emitted by sibling phase-planner
/// functions (`planColonialAcquisition`, `planColonialMilitary` —
/// deferred to follow-up S3 slices) rather than reasoned about here.
///
/// Inputs:
///   - [game]: used to (a) filter [ThreatSummary.atWarWith] down to
///     Great Power factions via [Game.playerById]; (b) compute the
///     primary colonial NW frontier blocker via
///     [primaryColonialGpBlocker], which maps the active player's
///     visible invadable NW provinces to their current owners and picks
///     the GP with the largest invadable-NW ownership share.
///   - [snapshot]: per-player [AIWorldSnapshot] supplying
///     [ThreatSummary.atWarWith] and
///     [ColonialSummary.invadableNewWorldProvinceIdsSorted] (consumed
///     transitively by [primaryColonialGpBlocker]).
///
/// Output:
///   - Empty list when no Great Powers are at war with the active
///     player (the GP filter loop produces an empty `gpWars` and the
///     trailing sort is a no-op).
///   - All GPs sorted ascending when the blocker is `null` (no
///     invadable NW province is owned by a Great Power) or when the
///     blocker is not among the at-war GPs (the membership guard arm).
///     The legacy "no exception applies" path: peace **all** live GP
///     fronts.
///   - All GPs except the blocker sorted ascending when the blocker is
///     among the at-war GPs (canonical COLONIAL-peace happy path:
///     keep fighting the colonial blocker, peace every other GP front).
///   - Empty list when the active player is at war with exactly one
///     GP **and** that GP is the colonial blocker (the lone war IS the
///     blocker war -- keep fighting it; nothing else to peace).
///   - The single GP (as a 1-element list) when the active player is
///     at war with exactly one GP and that GP is **not** the colonial
///     blocker. This is the explicit divergence from the legacy
///     [colonialPhaseGpPeaceTargets] helper, which short-circuits with
///     `return const []` when `gpWars.length <= 1`. The new spec wording
///     "Peace all at-war Great Powers" does not carry the legacy
///     `>= 2 GPs` guard: every non-blocker GP front must peace so the
///     orchestrator (#2509 S5) can drive NW acquisition / improvement
///     work without an idle GP-vs-GP distraction war.
///
/// The function is pure and deterministic — identical inputs always yield
/// identical lists (Refs #2509 Must-have #7).
List<String> planColonialPeace({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final gpWars = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null) factionId,
  ];
  if (gpWars.isEmpty) {
    return const [];
  }

  final blocker = primaryColonialGpBlocker(game: game, snapshot: snapshot);
  if (blocker == null || !gpWars.contains(blocker)) {
    return gpWars..sort();
  }

  return <String>[
    for (final factionId in gpWars)
      if (factionId != blocker) factionId,
  ]..sort();
}
