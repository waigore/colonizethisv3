import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/economy_phase_gates.dart';
import 'package:colonizethis_ai/src/planning/effective_labour_state.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_dispatch.dart';
import 'package:colonizethis_ai/src/planning/planning_helpers.dart';
import 'package:colonizethis_ai/src/planning/scored_candidate.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('colonialPressureScaleFromWeight', () {
    test('clamps non-null weight when requested', () {
      expect(
        colonialPressureScaleFromWeight(
          colonialPressureWeight: 1.5,
          legacyColonialPressureActive: false,
          clampToUnitInterval: true,
        ),
        1.0,
      );
      expect(
        colonialPressureScaleFromWeight(
          colonialPressureWeight: -0.25,
          legacyColonialPressureActive: true,
          clampToUnitInterval: true,
        ),
        0.0,
      );
    });

    test('maps legacy boolean when weight is null', () {
      expect(
        colonialPressureScaleFromWeight(
          colonialPressureWeight: null,
          legacyColonialPressureActive: true,
        ),
        1.0,
      );
      expect(
        colonialPressureScaleFromWeight(
          colonialPressureWeight: null,
          legacyColonialPressureActive: false,
        ),
        0.0,
      );
    });

    test('passes resolved weight through without clamp by default', () {
      expect(
        colonialPressureScaleFromWeight(
          colonialPressureWeight: 0.05,
          legacyColonialPressureActive: true,
        ),
        0.05,
      );
    });
  });

  group('planningListEquals', () {
    test('compares sorted string lists element-wise', () {
      expect(planningListEquals(['a', 'b'], ['a', 'b']), isTrue);
      expect(planningListEquals(['a'], ['b']), isFalse);
      expect(planningListEquals(['a', 'b'], ['a']), isFalse);
    });
  });

  group('sortByScore', () {
    test('orders by descending score then tie-break', () {
      final ranked = sortByScore(
        [
          const ScoredCandidate(item: 'b', score: 10),
          const ScoredCandidate(item: 'a', score: 20),
          const ScoredCandidate(item: 'c', score: 10),
        ],
        (a, b) => a.compareTo(b),
      );
      expect(ranked, ['a', 'b', 'c']);
    });
  });

  group('EffectiveLabourState', () {
    test('fromGame returns zero labour for missing player', () {
      final game = TestFixtures.minimalGame();
      expect(EffectiveLabourState.fromGame(game, 'missing').compute(), 0);
    });
  });

  group('EconomyPhaseGates', () {
    test('fromPhasePlan mirrors develop and expand quota resolvers', () {
      const develop = PhasePlanOutcome.defaultDevelop;
      const expand = PhasePlanOutcome.defaultExpand;
      const snapshot = AIWorldSnapshot(
        playerId: 'gp1',
        threats: ThreatSummary(),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        EconomyPhaseGates.fromPhasePlan(
          phasePlan: develop,
          snapshot: snapshot,
        ).developActive,
        isTrue,
      );
      expect(
        EconomyPhaseGates.fromPhasePlan(
          phasePlan: expand,
          snapshot: snapshot,
        ).expandQuotaPressure,
        isTrue,
      );
    });
  });
}
