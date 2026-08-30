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

/// Tabu key: capital generation, choice depth, province id.
typedef LockedAssignerTabuKey = (
  int capitalGeneration,
  int choiceDepth,
  String provinceId,
);

/// One DFS stack frame.
typedef LockedAssignerPlacement = ({
  String faction,
  String province,
  bool lockedSeed,
});

/// DFS return codes for the outer search loop.
const int lockedAssignerDfsOk = 0;
const int lockedAssignerDfsDeadEnd = 1;
const int lockedAssignerDfsBudget = 2;
