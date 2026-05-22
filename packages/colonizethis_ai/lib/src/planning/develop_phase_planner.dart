/// DEVELOP-phase planner (Refs #2509 S4 / S10).
///
/// First slice of the single-goal phase-planner architecture described in
/// [GitHub issue #2509](https://github.com/waigore/colonizethisv3/issues/2509)
/// and `SPEC/ai/ai-architecture.md` § Observer goal phases. Each phase
/// dispatches to a self-contained pure-function planner module that makes
/// one primary decision per domain with no cross-phase score aggregation.
///
/// DEVELOP phase goal: improve owned territory (extractable tile coverage).
/// No new wars, no New World acquisition, no colonial cargo for new
/// objectives — only defend + improve. Callers are expected to dispatch to
/// this module **only** when `observerGoalPhaseFor` resolves to
/// `ObserverGoalPhase.develop`; the planner functions themselves do not
/// re-check the phase (suppression is structural, per the issue spec).
///
/// Wiring this module into the orchestrator and removing the legacy
/// `developPhaseGpPeaceTargets` helper from `observer_goal_phase.dart`
/// are out of scope for this slice (tracked under S5 / S1 of #2509). The
/// in-module contract documented here matches the issue spec:
///
///   `planDevelopPeace(game, snapshot) → List<String>`
///     Returns all at-war Great Power faction ids (deterministic, sorted
///     ascending). No exceptions: every GP front is peaced so the
///     orchestrator can drive improvement-first civilian work in the
///     DEVELOP phase.
library;

import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';

/// Returns every Great Power currently at war with the active player as a
/// deterministic ascending-sorted list of `factionId`s.
///
/// This is the DEVELOP-phase peace contract from the #2509 S10
/// single-goal architecture: peace **all** at-war Great Powers, no
/// exceptions (no blocker preservation, no minor-first short-circuit).
///
/// Inputs:
///   - [game]: used to filter [ThreatSummary.atWarWith] down to Great
///     Power factions via [Game.playerById]. Tribes and minor nations are
///     not GPs and are pursued through other diplomacy paths.
///   - [snapshot]: per-player [AIWorldSnapshot] supplying the at-war
///     faction roster from [ThreatSummary.atWarWith].
///
/// Output: a new `List<String>` of GP `factionId`s sorted ascending. Empty
/// when no Great Power wars are active. The function is pure and
/// deterministic — identical inputs always yield identical lists (Refs
/// #2509 Must-have #7).
List<String> planDevelopPeace({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  return <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null) factionId,
  ]..sort();
}
