// Unit tests for `phase_planner_goal_filter.dart` (Refs #2509 S5).
//
// Pins the structural contract of the goal-scoring phase resolvers:
//
//   - `resolvePhaseGoalSuppressColonialPressure` — EXPAND + COLONIAL-lite only.
//   - `resolvePhaseGoalColonialPressureActive` — COLONIAL only.
//
// The two resolvers are disjoint: at most one returns `true` for any phase.
// Field-equal with legacy `strategic_ai.dart` / `goal_manager.dart` computes
// on the production path where `observerGoalPhaseFor` runs once per turn.

import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_goal_filter.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('resolvePhaseGoalSuppressColonialPressure', () {
    test('structural matrix', () {
      expect(
        resolvePhaseGoalSuppressColonialPressure(ObserverGoalPhase.expand),
        isTrue,
      );
      expect(
        resolvePhaseGoalSuppressColonialPressure(
          ObserverGoalPhase.colonialLite,
        ),
        isTrue,
      );
      expect(
        resolvePhaseGoalSuppressColonialPressure(ObserverGoalPhase.colonial),
        isFalse,
      );
      expect(
        resolvePhaseGoalSuppressColonialPressure(ObserverGoalPhase.develop),
        isFalse,
      );
    });

    test('deterministic across three calls per phase (Must-have #7)', () {
      for (final phase in ObserverGoalPhase.values) {
        final a = resolvePhaseGoalSuppressColonialPressure(phase);
        final b = resolvePhaseGoalSuppressColonialPressure(phase);
        final c = resolvePhaseGoalSuppressColonialPressure(phase);
        expect(a, b);
        expect(b, c);
      }
    });
  });

  group('resolvePhaseGoalColonialPressureActive', () {
    test('structural matrix', () {
      expect(
        resolvePhaseGoalColonialPressureActive(ObserverGoalPhase.colonial),
        isTrue,
      );
      expect(
        resolvePhaseGoalColonialPressureActive(ObserverGoalPhase.expand),
        isFalse,
      );
      expect(
        resolvePhaseGoalColonialPressureActive(ObserverGoalPhase.colonialLite),
        isFalse,
      );
      expect(
        resolvePhaseGoalColonialPressureActive(ObserverGoalPhase.develop),
        isFalse,
      );
    });

    test('deterministic across three calls per phase (Must-have #7)', () {
      for (final phase in ObserverGoalPhase.values) {
        final a = resolvePhaseGoalColonialPressureActive(phase);
        final b = resolvePhaseGoalColonialPressureActive(phase);
        final c = resolvePhaseGoalColonialPressureActive(phase);
        expect(a, b);
        expect(b, c);
      }
    });
  });

  group('goal filter partition', () {
    test('at most one resolver is true per phase', () {
      for (final phase in ObserverGoalPhase.values) {
        final suppress = resolvePhaseGoalSuppressColonialPressure(phase);
        final colonial = resolvePhaseGoalColonialPressureActive(phase);
        expect(suppress && colonial, isFalse);
      }
    });

    test(
      'COLONIAL is the only phase with colonial pressure and no suppress',
      () {
        for (final phase in ObserverGoalPhase.values) {
          final suppress = resolvePhaseGoalSuppressColonialPressure(phase);
          final colonial = resolvePhaseGoalColonialPressureActive(phase);
          if (phase == ObserverGoalPhase.colonial) {
            expect(suppress, isFalse);
            expect(colonial, isTrue);
          } else {
            expect(colonial, isFalse);
          }
        }
      },
    );
  });
}
