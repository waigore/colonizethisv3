import 'observer_colonial_verify.dart';
import 'observer_conquest_verify.dart';

/// Exit code when verify-run artifact writes would exceed [kObserverVerifyArtifactSizeCapBytes].
const int kExitArtifactSizeCapExceeded = 7;

/// Hard cap on total bytes under `observer-traces/<gameId>/` for verify runs (Refs #2534).
const int kObserverVerifyArtifactSizeCapBytes = 300 * 1024 * 1024;

/// Turn numbers for which [ObserverSnapshot] JSON is written in minimal trace mode.
Set<int> requiredObserverSnapshotTurns({
  required bool verifyConquest,
  required bool verifyColonialExpansion,
}) {
  final turns = <int>{};
  if (verifyConquest) {
    turns.add(1);
    turns.add(kObserverConquestCanonicalTurns);
  }
  if (verifyColonialExpansion) {
    turns.add(kObserverColonialCanonicalTurn);
  }
  return turns;
}

/// Tracks cumulative artifact bytes for a single game trace directory.
class ObserverArtifactBudget {
  ObserverArtifactBudget({int capBytes = kObserverVerifyArtifactSizeCapBytes})
      : capBytes = capBytes;

  final int capBytes;
  var bytesWritten = 0;

  bool wouldExceed(int additionalBytes) =>
      bytesWritten + additionalBytes > capBytes;

  void recordBytes(int additionalBytes) {
    bytesWritten += additionalBytes;
  }
}
