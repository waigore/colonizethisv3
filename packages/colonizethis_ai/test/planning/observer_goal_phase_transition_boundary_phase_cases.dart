// Case bodies for `observerGoalPhaseFor` OW-boundary pins (Refs #4310 Slice D).

import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_test/test.dart';

import '../support/observer_goal_phase_transition_boundary_test_support.dart';

void registerObserverGoalPhaseTransitionBoundaryPhaseCases() {
  group('observerGoalPhaseFor OW-boundary transition', () {
    test('OW=10 lands in COLONIAL (at-quota boundary)', () {
      final game = observerGoalPhaseTransitionBoundaryGameAtQuota();
      final snapshot = observerGoalPhaseTransitionBoundaryColonialSnapshot();
      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.colonial,
        reason:
            'OW=10 is exactly at quota (`isBelowObserverConquestQuota(10)` '
            'is false). With colonial acquisition targets visible the GP '
            'must enter COLONIAL. A regression that flipped the boundary '
            'to `<=` (or set the constant to 11) would put OW=10 back in '
            'EXPAND and starve NW acquisition from turn 100 onward.',
      );
    });

    test('OW=9 falls back to EXPAND (just-below-quota boundary)', () {
      final game = observerGoalPhaseTransitionBoundaryGameJustBelowQuota();
      final snapshot = observerGoalPhaseTransitionBoundaryExpandSnapshot();
      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.expand,
        reason:
            'OW=9 is one below quota and turn=110 < '
            'kObserverColonialLiteMinTurn=120, so COLONIAL-lite is not '
            'eligible. Issue #2509 phase-transition guard requires the '
            'GP to re-enter EXPAND immediately on the OW loss (no '
            'hysteresis band at quota+1) so a single OW regression cannot '
            'be masked by lingering colonial work.',
      );
    });

    test('alternating OW=10 and OW=9 calls produce alternating phases', () {
      final gameAtQuota = observerGoalPhaseTransitionBoundaryGameAtQuota();
      final gameJustBelowQuota =
          observerGoalPhaseTransitionBoundaryGameJustBelowQuota();
      final atQuotaSnapshot =
          observerGoalPhaseTransitionBoundaryColonialSnapshot();
      final justBelowQuotaSnapshot =
          observerGoalPhaseTransitionBoundaryExpandSnapshot();
      final phases = <ObserverGoalPhase>[];
      for (var i = 0; i < 3; i++) {
        phases.add(
          observerGoalPhaseFor(snapshot: atQuotaSnapshot, game: gameAtQuota),
        );
        phases.add(
          observerGoalPhaseFor(
            snapshot: justBelowQuotaSnapshot,
            game: gameJustBelowQuota,
          ),
        );
      }
      expect(
        phases,
        const <ObserverGoalPhase>[
          ObserverGoalPhase.colonial,
          ObserverGoalPhase.expand,
          ObserverGoalPhase.colonial,
          ObserverGoalPhase.expand,
          ObserverGoalPhase.colonial,
          ObserverGoalPhase.expand,
        ],
        reason:
            '`observerGoalPhaseFor` must be a pure function of its '
            'snapshot + game inputs. A cached previous-phase memoizer '
            'with hysteresis would surface as a non-alternating phase '
            'sequence here (for example two consecutive COLONIAL entries '
            'after a province loss).',
      );
    });
  });
}
