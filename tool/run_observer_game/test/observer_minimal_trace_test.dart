import 'package:colonizethis_test/test.dart';

import 'package:run_observer_game/observer_minimal_trace.dart';
import 'package:run_observer_game/observer_workforce_verify.dart';

void main() {
  group('requiredObserverSnapshotTurns', () {
    test('no flags returns empty set (defensive)', () {
      expect(
        requiredObserverSnapshotTurns(
          verifyConquest: false,
          verifyColonialExpansion: false,
        ),
        isEmpty,
      );
    });

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

    test('workforce only requires the canonical workforce turn', () {
      expect(
        requiredObserverSnapshotTurns(
          verifyConquest: false,
          verifyColonialExpansion: false,
          verifyWorkforce: true,
        ),
        {kObserverWorkforceCanonicalTurn},
      );
    });

    test('verifyWorkforce defaults to false', () {
      expect(
        requiredObserverSnapshotTurns(
          verifyConquest: false,
          verifyColonialExpansion: false,
        ),
        requiredObserverSnapshotTurns(
          verifyConquest: false,
          verifyColonialExpansion: false,
          verifyWorkforce: false,
        ),
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

    test('conquest + workforce de-duplicates turn 100', () {
      expect(
        requiredObserverSnapshotTurns(
          verifyConquest: true,
          verifyColonialExpansion: false,
          verifyWorkforce: true,
        ),
        {1, 100},
      );
    });

    test(
      'all three verify flags request distinct snapshot turns 1, 100, 150',
      () {
        expect(
          requiredObserverSnapshotTurns(
            verifyConquest: true,
            verifyColonialExpansion: true,
            verifyWorkforce: true,
          ),
          {1, 100, 150},
        );
      },
    );
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
