// SPEC/program/locked-province-assigner.md — shared types/constants for the
// locked assigner cluster (Refs #4086 Slice B de-part).

/// Default cap on backtracks **while growing one faction** before cross-faction
/// unwind or capital restart (#1830 / phased assigner).
const int kDefaultBacktrackLimitPerFaction = 20;

/// Kept for call sites that still import the old name; equals [kDefaultBacktrackLimitPerFaction].
const int kMaxBacktracksPerLandmassBeforeCapitalRestart =
    kDefaultBacktrackLimitPerFaction;

/// Optional counters for tests (AC-14 / AC-15).
final class LockedAssignerObservation {
  int backtracks = 0;
  int capitalRestarts = 0;
}
