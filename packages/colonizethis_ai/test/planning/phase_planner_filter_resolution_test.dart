// Unit tests for the shared `resolveFromPhasePlan` phase-filter resolution
// skeleton helper in `planning_helpers.dart` (Refs #3717 phase-filter
// resolution-skeleton dedup). The naval / conquest families route their
// `PhasePlanOutcome -> resolution` skeleton through this helper; these tests
// pin the project-or-default fallback contract directly.

import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_dispatch.dart';
import 'package:colonizethis_ai/src/planning/planning_helpers.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('resolveFromPhasePlan', () {
    const expandPlan = PhasePlanOutcome(phase: ObserverGoalPhase.expand);

    test('returns the projected resolution when project yields non-null', () {
      final result = resolveFromPhasePlan<String>(
        phasePlan: expandPlan,
        defaultResolution: 'default',
        project: (_) => 'projected',
      );
      expect(result, 'projected');
    });

    test('falls back to defaultResolution when project yields null', () {
      final result = resolveFromPhasePlan<String>(
        phasePlan: expandPlan,
        defaultResolution: 'default',
        project: (_) => null,
      );
      expect(result, 'default');
    });

    test('passes the same phasePlan instance to project', () {
      PhasePlanOutcome? seen;
      resolveFromPhasePlan<String>(
        phasePlan: expandPlan,
        defaultResolution: 'default',
        project: (plan) {
          seen = plan;
          return null;
        },
      );
      expect(identical(seen, expandPlan), isTrue);
    });

    test('evaluates project exactly once', () {
      var calls = 0;
      resolveFromPhasePlan<String>(
        phasePlan: expandPlan,
        defaultResolution: 'default',
        project: (_) {
          calls++;
          return 'projected';
        },
      );
      expect(calls, 1);
    });

    test('deterministic for identical inputs (Must-have #7)', () {
      String run() => resolveFromPhasePlan<String>(
        phasePlan: const PhasePlanOutcome(phase: ObserverGoalPhase.colonial),
        defaultResolution: 'default',
        project: (plan) => plan.phase == ObserverGoalPhase.colonial
            ? 'colonial'
            : null,
      );
      expect(run(), run());
      expect(run(), 'colonial');
    });
  });
}
