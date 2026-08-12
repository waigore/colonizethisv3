// Pins canonical home in `expand_phase_planner_gp_blocker_peace.dart`
// for `stalledExpansionDistractionPeaceTargets` (Refs #2509 S1).
//
// The decider was relocated from
// `diplomacy_planner_peace_targets.dart` so it survives the planned
// S1 deletion of that file. The canonical implementation lives in
// `expand_phase_planner_gp_blocker_peace.dart` (part of
// `expand_phase_planner.dart`); `diplomacy_planner_peace_targets.dart`
// previously retained a thin delegating stub for the legacy
// `diplomacy_planner_stalled_peace_test.dart` fixture and the in-file
// `_expandRatchetGreatPowerPeaceTargets` /
// `stalledOwExpansionNeedsPeacePass` consumer chains until the
// planned deletion.
//
// Behavioral invariants pinned at the canonical entry point:
//
//   1. Returns `const []` when
//      `isStalledOldWorldExpansion(oldWorldProvincesOwned)` is `false`
//      (above the stalled band — the at-quota / consolidate /
//      near-quota deciders own the decision instead).
//   2. Returns `const []` when `threats.atWarWith` is empty.
//   3. Returns `const []` when neither `minorsOwnInvadable` (any
//      invadable OW province owned by a minor) nor
//      `isStalledOldWorldGpBlockerFocus` is true — no minor-on-frontier
//      pivot and no GP-blocker-focus band.
//   4. Fires the minor-on-frontier arm:
//      `keepMinor = stalledFocusMinorTarget`, `keepGp = null`; peaces
//      every at-war minor / tribe except the focused minor. Great
//      Powers in the at-war set are always dropped from the result
//      because the GP-blocker / peer-GP peace deciders own that
//      decision.
//   5. Fires the GP-blocker-focus arm (GP-only invadable frontier +
//      below quota): `keepMinor = null`,
//      `keepGp = primaryInvadableOldWorldGpBlocker`; peaces every
//      at-war minor / tribe — but never any GP (the result excludes
//      Great Powers even when the primary blocker is at war).
//   6. Fires both arms simultaneously when minors own invadable
//      provinces **and** the player is also in the GP-blocker-focus
//      band: keeps both the focused minor and the primary GP blocker
//      wars open while peacing every other minor / tribe distraction.
//   7. Returned list is sorted ascending so emission order is
//      deterministic for fixed inputs (Refs #2509 Must-have #7).
//
// Determinism (Must-have #7): identical `(Game, snapshot)` inputs
// always yield identical results across repeated invocations.
//
// Stub delegation parity: the delegating stub in
// `diplomacy_planner_peace_targets.dart` returns the same value as
// the canonical helper for every representative input — required so
// the legacy `diplomacy_planner_stalled_peace_test.dart` fixture and
// in-file consumer chains agree.
//
// Thin contract for `stalledExpansionDistractionPeaceTargets` pin suite
// (Refs #4310 Slice D). Case bodies live in sibling `*_cases.dart` modules.

import 'expand_phase_planner_stalled_distraction_peace_cases.dart';

void main() {
  registerExpandPhasePlannerStalledDistractionPeaceCases();
}
