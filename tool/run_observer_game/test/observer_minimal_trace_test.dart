import 'package:colonizethis_test/test.dart';

import 'package:run_observer_game/observer_minimal_trace.dart';

void main() {
  group('requiredObserverSnapshotTurns', () {
    test('conquest only requires turns 1 and 100', () {
      expect(
        requiredObserverSnapshotTurns(
          verifyConquest: true,
          verifyColonialExpansion: false,
        ),
        {1, 100},
      );
    });

    test('colonial only requires turn 150', () {
      expect(
        requiredObserverSnapshotTurns(
          verifyConquest: false,
          verifyColonialExpansion: true,
        ),
        {150},
      );
    });

    test('both verify flags require turns 1, 100, and 150', () {
      expect(
        requiredObserverSnapshotTurns(
          verifyConquest: true,
          verifyColonialExpansion: true,
        ),
        {1, 100, 150},
      );
    });
  });

  group('ObserverArtifactBudget', () {
    test('rejects writes that would exceed cap', () {
      final budget = ObserverArtifactBudget(capBytes: 20);
      budget.recordBytes(10);
      expect(budget.wouldExceed(11), isTrue);
      expect(budget.wouldExceed(10), isFalse);
    });
  });
}
